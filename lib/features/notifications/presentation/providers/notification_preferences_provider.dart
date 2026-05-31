import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/services/notification_service.dart';

class NotificationPrefs {
  const NotificationPrefs({
    this.arrivalReminder = true,
    this.arrivalReminderTime = '08:00',
    this.departureReminder = true,
    this.departureReminderTime = '14:30',
    this.missedCheckinAlert = true,
    this.missedCheckoutAlert = true,
    this.tomorrowPreview = true,
    this.weeklySummary = true,
    this.cycleEndWarning = true,
    this.earlyLeaveRecommendation = true,
  });

  final bool arrivalReminder;
  final String arrivalReminderTime;
  final bool departureReminder;
  final String departureReminderTime;
  final bool missedCheckinAlert;
  final bool missedCheckoutAlert;
  final bool tomorrowPreview;
  final bool weeklySummary;
  final bool cycleEndWarning;
  final bool earlyLeaveRecommendation;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      arrivalReminder: json['arrival_reminder'] as bool? ?? true,
      arrivalReminderTime: _parseDbTime(
        json['arrival_reminder_time'],
        fallback: '08:00',
      ),
      departureReminder: json['departure_reminder'] as bool? ?? true,
      departureReminderTime: _parseDbTime(
        json['departure_reminder_time'],
        fallback: '14:30',
      ),
      missedCheckinAlert: json['missed_checkin_alert'] as bool? ?? true,
      missedCheckoutAlert: json['missed_checkout_alert'] as bool? ?? true,
      tomorrowPreview: json['tomorrow_preview'] as bool? ?? true,
      weeklySummary: json['weekly_summary'] as bool? ?? true,
      cycleEndWarning: json['cycle_end_warning'] as bool? ?? true,
      earlyLeaveRecommendation:
          json['early_leave_recommendation'] as bool? ?? true,
    );
  }

  NotificationPrefs copyWith({
    bool? arrivalReminder,
    String? arrivalReminderTime,
    bool? departureReminder,
    String? departureReminderTime,
    bool? missedCheckinAlert,
    bool? missedCheckoutAlert,
    bool? tomorrowPreview,
    bool? weeklySummary,
    bool? cycleEndWarning,
    bool? earlyLeaveRecommendation,
  }) =>
      NotificationPrefs(
        arrivalReminder: arrivalReminder ?? this.arrivalReminder,
        arrivalReminderTime: arrivalReminderTime ?? this.arrivalReminderTime,
        departureReminder: departureReminder ?? this.departureReminder,
        departureReminderTime:
            departureReminderTime ?? this.departureReminderTime,
        missedCheckinAlert: missedCheckinAlert ?? this.missedCheckinAlert,
        missedCheckoutAlert: missedCheckoutAlert ?? this.missedCheckoutAlert,
        tomorrowPreview: tomorrowPreview ?? this.tomorrowPreview,
        weeklySummary: weeklySummary ?? this.weeklySummary,
        cycleEndWarning: cycleEndWarning ?? this.cycleEndWarning,
        earlyLeaveRecommendation:
            earlyLeaveRecommendation ?? this.earlyLeaveRecommendation,
      );

  Map<String, dynamic> _toMap() => {
        'arrival_reminder': arrivalReminder,
        'arrival_reminder_time': '$arrivalReminderTime:00',
        'departure_reminder': departureReminder,
        'departure_reminder_time': '$departureReminderTime:00',
        'missed_checkin_alert': missedCheckinAlert,
        'missed_checkout_alert': missedCheckoutAlert,
        'tomorrow_preview': tomorrowPreview,
        'weekly_summary': weeklySummary,
        'cycle_end_warning': cycleEndWarning,
        'early_leave_recommendation': earlyLeaveRecommendation,
      };
}

class NotificationPrefsNotifier
    extends StateNotifier<AsyncValue<NotificationPrefs>> {
  NotificationPrefsNotifier(this._client, this._userId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final SupabaseClient _client;
  final String _userId;

  Future<void> _load() async {
    if (_userId.isEmpty) {
      state = const AsyncValue.data(NotificationPrefs());
      return;
    }
    try {
      final data = await _client
          .from(AppConstants.tableNotificationPreferences)
          .select()
          .eq('user_id', _userId)
          .single();
      final prefs = NotificationPrefs.fromJson(data);
      state = AsyncValue.data(prefs);
      // Reschedule in case alarms were lost (device reboot, app update, etc.)
      await _rescheduleLocal(prefs);
    } catch (e) {
      // No saved row yet — persist defaults so future loads find them.
      const defaults = NotificationPrefs();
      state = const AsyncValue.data(NotificationPrefs());
      try {
        await _client.rpc(
            'upsert_notification_prefs', params: {'prefs': defaults._toMap()});
      } catch (_) {}
      // Schedule alarms using defaults — first-install case.
      await _rescheduleLocal(defaults);
    }
  }

  Future<void> update(NotificationPrefs prefs) async {
    if (_userId.isEmpty) return;
    final prev = state;
    state = AsyncValue.data(prefs);

    try {
      await _client.rpc(
          'upsert_notification_prefs', params: {'prefs': prefs._toMap()});
    } catch (e) {
      state = prev; // Rollback only when DB write fails
      throw mapException(e);
    }

    // Best-effort: alarm scheduling is independent of DB persistence.
    try {
      await _rescheduleLocal(prefs);
    } catch (_) {}
  }

  /// Switches to schedule-based arrival alarms (semester mode).
  /// Cancels the manual daily arrival alarm and replaces it with per-weekday
  /// alarms derived from the user's timetable. The departure reminder keeps
  /// its manual time (the daily departure is handled by the check-in event).
  Future<void> scheduleSmartAlarms(
      Map<int, ({int hour, int minute})> perDay) async {
    final prefs = state.valueOrNull;
    if (prefs == null || !prefs.arrivalReminder) return;
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance
        .cancelArrivalReminder(); // drop the manual daily alarm
    await NotificationService.instance.scheduleSmartArrivalAlarms(perDay);
  }

  Future<void> switchToManualAlarms() async {
    final prefs = state.valueOrNull;
    if (prefs == null) return;
    await NotificationService.instance.cancelSmartArrivalAlarms();
    await _rescheduleLocal(prefs);
  }

  Future<void> _rescheduleLocal(NotificationPrefs prefs) async {
    final svc = NotificationService.instance;
    // Cancel every managed notification ID so there are never stale duplicates.
    // alarmSchedulerProvider re-schedules smart arrival notifications right
    // after this returns when in semester mode.
    await svc.cancelAllLocalAlarms();

    // Request once — the service guards against concurrent / duplicate calls.
    await svc.requestPermissions();

    if (prefs.arrivalReminder) {
      final p = parseReminderTime(prefs.arrivalReminderTime);
      await svc.scheduleArrivalReminder(hour: p.hour, minute: p.minute);
    }

    if (prefs.departureReminder) {
      final p = parseReminderTime(prefs.departureReminderTime);
      await svc.scheduleDepartureReminder(hour: p.hour, minute: p.minute);
    }

    // Missed check-in: fires daily at arrival time + 2 h.
    if (prefs.missedCheckinAlert) {
      final p = parseReminderTime(prefs.arrivalReminderTime);
      var h = p.hour + 2;
      if (h >= 24) h = 10;
      await svc.scheduleMissedCheckinReminder(hour: h, minute: p.minute);
    }

    // Missed check-out: fires daily at departure time + 2 h.
    if (prefs.missedCheckoutAlert) {
      final p = parseReminderTime(prefs.departureReminderTime);
      var h = p.hour + 2;
      if (h >= 24) h = 18;
      await svc.scheduleMissedCheckoutReminder(hour: h, minute: p.minute);
    }

    // Tomorrow preview: daily at 20:00.
    if (prefs.tomorrowPreview) {
      await svc.scheduleTomorrowPreview();
    }

    // Weekly summary: every Thursday at 19:00.
    if (prefs.weeklySummary) {
      await svc.scheduleWeeklySummary();
    }

    // Cycle-end warning: every month on the 12th at 20:00 (3 days before close).
    if (prefs.cycleEndWarning) {
      await svc.scheduleCycleEndWarning();
    }
  }
}

({int hour, int minute}) parseReminderTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) {
    throw const ValidationException('Reminder time must be in HH:mm format.');
  }

  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    throw const ValidationException('Reminder time is outside a valid day.');
  }
  return (hour: hour, minute: minute);
}

String _parseDbTime(dynamic value, {required String fallback}) {
  if (value is! String) return fallback;

  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) return fallback;

  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return fallback;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;

  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

final notificationPrefsProvider = StateNotifierProvider<
    NotificationPrefsNotifier, AsyncValue<NotificationPrefs>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return NotificationPrefsNotifier(ref.read(supabaseClientProvider), userId);
});
