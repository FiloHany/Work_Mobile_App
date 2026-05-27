import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles both local (scheduled) and remote (FCM) notifications.
///
/// Architecture:
///   - Local: flutter_local_notifications — arrival/departure reminders,
///     missed-check alerts (scheduled on-device daily).
///   - Remote: FCM — cycle-end warnings, early-leave recommendations,
///     weekly summaries pushed from backend/edge-function.
///
/// Device tokens are registered in Supabase device_tokens table.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _localPlugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _fcm;

  // ── Channel IDs ───────────────────────────────────────────────────────────
  static const _channelReminders = 'attendance_reminders';
  static const _channelAlerts = 'attendance_alerts';
  static const _channelSummaries = 'summaries';

  // ── Notification IDs ──────────────────────────────────────────────────────
  static const _idArrivalReminder = 1;   // manual daily arrival
  static const _idDepartureReminder = 2; // manual daily departure
  static const _idMissedCheckin = 3;
  static const _idMissedCheckout = 4;
  static const _idEarlyLeaveAlert = 5;   // one-time "you can leave now"
  // IDs 10–16: smart per-weekday arrival (10=Sun, 11=Mon, …, 16=Sat)
  static const _smartArrivalBase = 10;
  // IDs 100–115: repeating missed check-in reminders (up to 16 slots = 8 h)
  static const _checkInReminderBase = 100;
  static const _checkInReminderCount = 16;

  // ── Permission guard ──────────────────────────────────────────────────────
  // Prevents the PlatformException(permissionRequestInProgress) that fires when
  // requestPermissions() is called multiple times concurrently.  On Android,
  // only ONE system dialog can be open at a time and both FCM and
  // flutter_local_notifications request the same POST_NOTIFICATIONS permission.
  bool _permissionsGranted = false;
  bool _requestingPermissions = false;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createAndroidChannels();

    try {
      _fcm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      // FCM initialization failed - app will continue without push notifications
      debugPrint('FirebaseMessaging init failed: $e');
      _fcm = null;
    }
  }

  Future<void> requestPermissions() async {
    // Already granted — skip entirely so no dialog appears again.
    if (_permissionsGranted) return;
    // Another call is already waiting for the system dialog — bail out so we
    // never trigger PlatformException(permissionRequestInProgress).
    if (_requestingPermissions) return;

    _requestingPermissions = true;
    try {
      final androidPlugin = _localPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Android: use the local-notifications plugin as the single entry point.
        // Do NOT also call _fcm?.requestPermission() here — both request the
        // same POST_NOTIFICATIONS permission and trigger a second dialog while
        // the first is still open, causing permissionRequestInProgress.
        final granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        if (granted) await androidPlugin.requestExactAlarmsPermission();
        _permissionsGranted = granted;
      } else {
        // iOS / macOS: FCM handles the permission dialog.
        await _fcm?.requestPermission(
            alert: true, badge: true, sound: true);
        _permissionsGranted = true;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    } finally {
      _requestingPermissions = false;
    }
  }

  /// Fires an immediate test notification so you can verify the whole pipeline
  /// (channel setup, icon, sound) works on the current device/emulator.
  Future<void> showTestNotification() async {
    await _localPlugin.show(
      97,
      'Test notification ✓',
      'Notifications are wired up and working.',
      _notifDetails(_channelAlerts, 'Alerts'),
    );
  }

  /// Schedules a one-time alarm [secondsFromNow] seconds in the future.
  /// Use this to confirm that exact-alarm scheduling fires correctly.
  Future<void> scheduleTestAlarm({int secondsFromNow = 5}) async {
    await _localPlugin.cancel(98);
    final target =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: secondsFromNow));
    await _localPlugin.zonedSchedule(
      98,
      'Test alarm ✓',
      'Alarm fired $secondsFromNow s after you tapped — scheduling works.',
      target,
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Resets permission state — only for use in tests.
  @visibleForTesting
  void resetPermissionStateForTest() {
    _permissionsGranted = false;
    _requestingPermissions = false;
  }

  /// Exposes guard state — only for use in tests.
  @visibleForTesting
  bool get isPermissionsGranted => _permissionsGranted;

  Future<String?> get fcmToken async => _fcm?.getToken();

  // ── Schedule local reminders ──────────────────────────────────────────────

  Future<void> scheduleArrivalReminder({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idArrivalReminder);
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await _localPlugin.zonedSchedule(
      _idArrivalReminder,
      'Time to head in',
      'Don\'t forget to check in today.',
      scheduledTime,
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDepartureReminder({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idDepartureReminder);
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await _localPlugin.zonedSchedule(
      _idDepartureReminder,
      'Remember to check out',
      'Tap to log your departure time.',
      scheduledTime,
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showMissedCheckinAlert() async {
    await _localPlugin.show(
      _idMissedCheckin,
      'Missed check-in?',
      'You haven\'t checked in today. Submit a correction if needed.',
      _notifDetails(_channelAlerts, 'Alerts'),
    );
  }

  /// Schedules daily repeating reminders every 30 minutes starting at
  /// [startHour]:[startMinute] until 18:00 (up to [_checkInReminderCount] slots).
  /// Call [cancelCheckInReminders] when the user checks in.
  Future<void> scheduleRepeatingCheckInReminders({
    required int startHour,
    required int startMinute,
  }) async {
    await cancelCheckInReminders();
    int hour = startHour;
    int minute = startMinute;
    for (int i = 0; i < _checkInReminderCount; i++) {
      if (hour >= 18) break;
      await _localPlugin.zonedSchedule(
        _checkInReminderBase + i,
        'You haven\'t checked in yet',
        'Open the app to record your attendance.',
        _nextInstanceOfTime(hour, minute),
        _notifDetails(_channelAlerts, 'Alerts'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      minute += 30;
      if (minute >= 60) {
        minute -= 60;
        hour++;
      }
    }
  }

  Future<void> cancelCheckInReminders() async {
    for (int i = 0; i < _checkInReminderCount; i++) {
      await _localPlugin.cancel(_checkInReminderBase + i);
    }
  }

  Future<void> showMissedCheckoutAlert() async {
    await _localPlugin.show(
      _idMissedCheckout,
      'Don\'t forget to check out',
      'Your attendance session is still open.',
      _notifDetails(_channelAlerts, 'Alerts'),
    );
  }

  Future<void> showEarlyLeaveRecommendation(String message) async {
    await _localPlugin.show(
      5,
      'You can leave early today',
      message,
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
    );
  }

  Future<void> scheduleMissedCheckinReminder({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idMissedCheckin);
    await _localPlugin.zonedSchedule(
      _idMissedCheckin,
      'Have you checked in today?',
      'Don\'t forget to record your attendance.',
      _nextInstanceOfTime(hour, minute),
      _notifDetails(_channelAlerts, 'Alerts'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMissedCheckinReminder() =>
      _localPlugin.cancel(_idMissedCheckin);

  Future<void> scheduleMissedCheckoutReminder({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idMissedCheckout);
    await _localPlugin.zonedSchedule(
      _idMissedCheckout,
      'Have you checked out?',
      'Make sure to record your departure time.',
      _nextInstanceOfTime(hour, minute),
      _notifDetails(_channelAlerts, 'Alerts'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMissedCheckoutReminder() =>
      _localPlugin.cancel(_idMissedCheckout);

  Future<void> cancelAll() => _localPlugin.cancelAll();

  Future<void> cancelArrivalReminder() =>
      _localPlugin.cancel(_idArrivalReminder);

  Future<void> cancelDepartureReminder() =>
      _localPlugin.cancel(_idDepartureReminder);

  /// Cancels every locally-managed alarm ID so that [_rescheduleLocal] always
  /// starts from a clean slate regardless of which mode was previously active.
  Future<void> cancelAllLocalAlarms() async {
    await _localPlugin.cancel(_idArrivalReminder);
    await _localPlugin.cancel(_idDepartureReminder);
    await _localPlugin.cancel(_idMissedCheckin);
    await _localPlugin.cancel(_idMissedCheckout);
    for (int i = 0; i < 7; i++) {
      await _localPlugin.cancel(_smartArrivalBase + i);
    }
  }

  // ── Smart per-weekday arrival alarms (semester mode) ──────────────────────

  /// Schedules a weekly arrival alarm for each day in [perDay].
  /// Key = schedule day index (0=Sun … 6=Sat),
  /// value = (hour, minute) to ring the alarm.
  Future<void> scheduleSmartArrivalAlarms(
    Map<int, ({int hour, int minute})> perDay,
  ) async {
    await cancelSmartArrivalAlarms();
    for (final e in perDay.entries) {
      final scheduled =
          _nextInstanceOfWeekdayAndTime(e.key, e.value.hour, e.value.minute);
      await _localPlugin.zonedSchedule(
        _smartArrivalBase + e.key,
        'Time to head in',
        'Your first session starts soon.',
        scheduled,
        _notifDetails(_channelReminders, 'Attendance Reminders'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelSmartArrivalAlarms() async {
    for (int i = 0; i < 7; i++) {
      await _localPlugin.cancel(_smartArrivalBase + i);
    }
  }

  // ── One-time "you can leave now" alert ────────────────────────────────────

  /// Schedules a single alert today at [hour]:[minute].
  /// Silently skipped if the time has already passed.
  Future<void> scheduleEarlyLeaveAlert({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idEarlyLeaveAlert);
    final now = tz.TZDateTime.now(tz.local);
    final target =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) return;
    await _localPlugin.zonedSchedule(
      _idEarlyLeaveAlert,
      'You can leave now ✓',
      'You have completed your required hours for today.',
      target,
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents → fires once, not repeating.
    );
  }

  Future<void> cancelEarlyLeaveAlert() =>
      _localPlugin.cancel(_idEarlyLeaveAlert);

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _createAndroidChannels() async {
    final plugin = _localPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelReminders,
      'Attendance Reminders',
      description: 'Daily arrival and departure reminders',
      importance: Importance.high,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelAlerts,
      'Alerts',
      description: 'Missed check-in/out alerts',
      importance: Importance.high,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelSummaries,
      'Summaries & Tips',
      description: 'Weekly summaries and smart recommendations',
      importance: Importance.defaultImportance,
    ));
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (e) {
      debugPrint('Timezone initialisation failed: $e');
    }
  }

  NotificationDetails _notifDetails(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    return nextInstanceOfTime(
      location: tz.local,
      hour: hour,
      minute: minute,
    );
  }

  /// Returns the next occurrence of [scheduleDay] (0=Sun … 6=Sat) at [hour]:[minute].
  /// Uses [DateTimeComponents.dayOfWeekAndTime] so the alarm repeats weekly.
  tz.TZDateTime _nextInstanceOfWeekdayAndTime(
      int scheduleDay, int hour, int minute) {
    // Schedule system: 0=Sun, 1=Mon … 6=Sat.
    // TZDateTime weekday: Mon=1 … Sun=7.
    final tzWeekday = scheduleDay == 0 ? DateTime.sunday : scheduleDay;
    final now = tz.TZDateTime.now(tz.local);
    var candidate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (candidate.weekday != tzWeekday) {
      candidate = candidate.add(const Duration(days: 1));
    }
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  @visibleForTesting
  static tz.TZDateTime nextInstanceOfTime({
    required tz.Location location,
    required int hour,
    required int minute,
    tz.TZDateTime? now,
  }) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Must be between 0 and 23.');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'Must be between 0 and 59.');
    }

    final effectiveNow = now ?? tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      effectiveNow.year,
      effectiveNow.month,
      effectiveNow.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(effectiveNow)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigate via router — handled in main.dart via deep link.
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    // Show as local notification when app is in foreground.
    if (message.notification != null) {
      _localPlugin.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        _notifDetails(_channelSummaries, 'Summaries & Tips'),
      );
    }
  }
}

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
