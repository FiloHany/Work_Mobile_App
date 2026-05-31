import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles both local (scheduled) and remote (FCM) notifications.
///
/// All scheduled notifications use AndroidScheduleMode.inexactAllowWhileIdle —
/// no exact-alarm permission required, works on all Android versions.
///
/// Notification types:
///   Local immediate : check-in confirmation, check-out summary, test
///   Local repeating : arrival reminder, departure reminder,
///                     missed check-in, missed check-out,
///                     tomorrow preview (daily 20:00),
///                     weekly summary (Thu 19:00),
///                     cycle-end warning (12th of month 20:00)
///   One-time local  : early-leave alert (check-in + 7 h)
///   Remote (FCM)    : backend-pushed summaries and recommendations
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _localPlugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _fcm;

  // ── Channel IDs ───────────────────────────────────────────────────────────
  static const _channelReminders = 'attendance_reminders';
  static const _channelAlerts    = 'attendance_alerts';
  static const _channelSummaries = 'summaries';

  // ── Notification IDs ──────────────────────────────────────────────────────
  static const _idArrivalReminder   = 1;
  static const _idDepartureReminder = 2;
  static const _idMissedCheckin     = 3;
  static const _idMissedCheckout    = 4;
  static const _idEarlyLeaveAlert   = 5;
  static const _idCheckInConfirm    = 6;
  static const _idCheckOutSummary   = 7;
  static const _idTomorrowPreview   = 8;
  static const _idWeeklySummary     = 9;
  static const _idCycleEndWarning   = 20;
  // IDs 10–16: smart per-weekday arrival (10=Sun … 16=Sat)
  static const _smartArrivalBase    = 10;
  // IDs 100–115: repeating missed check-in slots (8 h × 2 per hour)
  static const _checkInReminderBase  = 100;
  static const _checkInReminderCount = 16;

  // ── Permission guard ──────────────────────────────────────────────────────
  bool _permissionsGranted  = false;
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
      debugPrint('FirebaseMessaging init failed: $e');
      _fcm = null;
    }
  }

  Future<void> requestPermissions() async {
    if (_permissionsGranted) return;
    if (_requestingPermissions) return;

    _requestingPermissions = true;
    try {
      final androidPlugin = _localPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // POST_NOTIFICATIONS is the only permission needed — no exact-alarm
        // permission required because we use inexactAllowWhileIdle scheduling.
        final granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        _permissionsGranted = granted;
      } else {
        // iOS / macOS: FCM handles the permission dialog.
        await _fcm?.requestPermission(alert: true, badge: true, sound: true);
        _permissionsGranted = true;
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    } finally {
      _requestingPermissions = false;
    }
  }

  // ── Immediate notifications ───────────────────────────────────────────────

  Future<void> showTestNotification() async {
    await _localPlugin.show(
      97,
      'Test notification ✓',
      'Notifications are wired up and working.',
      _notifDetails(_channelAlerts, 'Alerts'),
    );
  }

  /// Schedules a one-time test notification [secondsFromNow] seconds from now.
  /// Uses inexact scheduling — may fire a few seconds late but no permission needed.
  Future<DateTime> scheduleTestNotification({int secondsFromNow = 5}) async {
    await _localPlugin.cancel(98);
    final now    = tz.TZDateTime.now(tz.local);
    final target = now.add(Duration(seconds: secondsFromNow));
    await _localPlugin.zonedSchedule(
      98,
      'Test notification ✓',
      'Scheduled ${secondsFromNow}s ago — notifications are working.',
      target,
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return target.toLocal();
  }

  /// Fires immediately when the user checks in.
  Future<void> showCheckInConfirmation(DateTime checkInTime) async {
    final h = checkInTime.hour.toString().padLeft(2, '0');
    final m = checkInTime.minute.toString().padLeft(2, '0');
    await _localPlugin.show(
      _idCheckInConfirm,
      'Checked in ✓',
      'Session started at $h:$m — have a productive day!',
      _notifDetails(_channelReminders, 'Attendance Reminders'),
    );
  }

  /// Fires immediately when the user checks out.
  Future<void> showCheckOutSummary({
    required Duration worked,
    required Duration credit,
  }) async {
    final workedStr = _fmt(worked);
    final creditStr = credit.isNegative
        ? ' · ${_fmt(-credit)} credit debt'
        : credit.inMinutes > 0
            ? ' · +${_fmt(credit)} credit earned'
            : '';
    await _localPlugin.show(
      _idCheckOutSummary,
      'Checked out ✓',
      '$workedStr logged today$creditStr.',
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
    );
  }

  // ── Daily / weekly / cycle scheduled notifications ────────────────────────

  Future<void> scheduleArrivalReminder({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idArrivalReminder);
    await _localPlugin.zonedSchedule(
      _idArrivalReminder,
      'Time to head in',
      'Don\'t forget to check in today.',
      _nextInstanceOfTime(hour, minute),
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
    await _localPlugin.zonedSchedule(
      _idDepartureReminder,
      'Time to check out',
      'Don\'t forget to record your departure.',
      _nextInstanceOfTime(hour, minute),
      _notifDetails(_channelReminders, 'Attendance Reminders'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMissedCheckoutReminder() =>
      _localPlugin.cancel(_idMissedCheckout);

  /// Daily at 20:00 — reminds the user to check tomorrow's timetable.
  Future<void> scheduleTomorrowPreview() async {
    await _localPlugin.cancel(_idTomorrowPreview);
    await _localPlugin.zonedSchedule(
      _idTomorrowPreview,
      "Tomorrow's Schedule",
      'Open the app to review tomorrow\'s timetable and plan your arrival.',
      _nextInstanceOfTime(20, 0),
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Every Thursday at 19:00 — last working day of the Egyptian work week.
  Future<void> scheduleWeeklySummary() async {
    await _localPlugin.cancel(_idWeeklySummary);
    await _localPlugin.zonedSchedule(
      _idWeeklySummary,
      'Weekly Summary',
      'Check your weekly hours, remaining targets, and cycle progress.',
      _nextInstanceOfWeekdayAndTime(4, 19, 0), // 4 = Thursday
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Every month on the 12th at 20:00 — 3 days before cycle ends on the 15th.
  Future<void> scheduleCycleEndWarning() async {
    await _localPlugin.cancel(_idCycleEndWarning);
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, 12, 20, 0);
    if (!target.isAfter(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear  = now.month == 12 ? now.year + 1 : now.year;
      target = tz.TZDateTime(tz.local, nextYear, nextMonth, 12, 20, 0);
    }
    await _localPlugin.zonedSchedule(
      _idCycleEndWarning,
      'Work Cycle Closes in 3 Days',
      'Your cycle ends on the 15th — open the app to check remaining hours.',
      target,
      _notifDetails(_channelAlerts, 'Alerts'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // ── One-time early-leave alert ────────────────────────────────────────────

  Future<void> scheduleEarlyLeaveAlert({
    required int hour,
    required int minute,
  }) async {
    await _localPlugin.cancel(_idEarlyLeaveAlert);
    final now    = tz.TZDateTime.now(tz.local);
    final target = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) return;
    await _localPlugin.zonedSchedule(
      _idEarlyLeaveAlert,
      'You can leave now ✓',
      'You have completed your required hours for today.',
      target,
      _notifDetails(_channelSummaries, 'Summaries & Tips'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelEarlyLeaveAlert() =>
      _localPlugin.cancel(_idEarlyLeaveAlert);

  // ── Smart per-weekday arrival notifications ───────────────────────────────

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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  // ── Repeating missed check-in slots ──────────────────────────────────────

  Future<void> scheduleRepeatingCheckInReminders({
    required int startHour,
    required int startMinute,
  }) async {
    await cancelCheckInReminders();
    int hour = startHour, minute = startMinute;
    for (int i = 0; i < _checkInReminderCount; i++) {
      if (hour >= 18) break;
      await _localPlugin.zonedSchedule(
        _checkInReminderBase + i,
        'You haven\'t checked in yet',
        'Open the app to record your attendance.',
        _nextInstanceOfTime(hour, minute),
        _notifDetails(_channelAlerts, 'Alerts'),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      minute += 30;
      if (minute >= 60) { minute -= 60; hour++; }
    }
  }

  Future<void> cancelCheckInReminders() async {
    for (int i = 0; i < _checkInReminderCount; i++) {
      await _localPlugin.cancel(_checkInReminderBase + i);
    }
  }

  // ── Bulk cancel ───────────────────────────────────────────────────────────

  Future<void> cancelArrivalReminder()   => _localPlugin.cancel(_idArrivalReminder);
  Future<void> cancelDepartureReminder() => _localPlugin.cancel(_idDepartureReminder);
  Future<void> cancelAll()               => _localPlugin.cancelAll();

  /// Cancels every managed scheduled notification so _rescheduleLocal always
  /// starts from a clean slate. Immediate show() IDs (6, 7, 97, 98) are NOT
  /// cancelled here — they have already been displayed.
  Future<void> cancelAllLocalAlarms() async {
    await _localPlugin.cancel(_idArrivalReminder);
    await _localPlugin.cancel(_idDepartureReminder);
    await _localPlugin.cancel(_idMissedCheckin);
    await _localPlugin.cancel(_idMissedCheckout);
    await _localPlugin.cancel(_idEarlyLeaveAlert);
    await _localPlugin.cancel(_idTomorrowPreview);
    await _localPlugin.cancel(_idWeeklySummary);
    await _localPlugin.cancel(_idCycleEndWarning);
    for (int i = 0; i < 7; i++) {
      await _localPlugin.cancel(_smartArrivalBase + i);
    }
    for (int i = 0; i < _checkInReminderCount; i++) {
      await _localPlugin.cancel(_checkInReminderBase + i);
    }
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  Future<String?> get fcmToken async => _fcm?.getToken();

  // ── Test visibility helpers (tests only) ─────────────────────────────────

  @visibleForTesting
  void resetPermissionStateForTest() {
    _permissionsGranted     = false;
    _requestingPermissions  = false;
  }

  @visibleForTesting
  bool get isPermissionsGranted => _permissionsGranted;

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
      description: 'Missed check-in/out and cycle-end alerts',
      importance: Importance.high,
    ));
    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelSummaries,
      'Summaries & Tips',
      description: 'Weekly summaries, tomorrow preview, and smart tips',
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

  tz.TZDateTime _nextInstanceOfWeekdayAndTime(
      int scheduleDay, int hour, int minute) {
    // Schedule system: 0=Sun … 6=Sat. TZDateTime weekday: Mon=1 … Sun=7.
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
        location, effectiveNow.year, effectiveNow.month, effectiveNow.day,
        hour, minute);
    if (!scheduled.isAfter(effectiveNow)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Short duration formatter — e.g. "2h 30m", "45m".
  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
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
