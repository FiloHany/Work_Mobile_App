import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_preferences_provider.dart';
import 'smart_alarm_provider.dart';

/// Always-on provider that keeps local alarm schedules in sync with
/// both notification preferences and the computed smart alarm times.
///
/// Watched from [AppShell] so it stays active for the entire session.
/// Handles three cases:
///   • App restart in semester mode — prefs load triggers smart alarm setup.
///   • Schedule change at runtime   — smart times change triggers reschedule.
///   • Mode switch (semester ↔ exams/summer) — smart times go null/non-null.
final alarmSchedulerProvider = Provider<void>((ref) {
  // 1. React to smart-alarm time changes (covers runtime schedule updates
  //    and semester-mode toggles). fireImmediately handles app-restart case
  //    when times are already computed before this provider is first watched.
  ref.listen<Map<int, ({int hour, int minute})>?>(
    smartAlarmTimesProvider,
    (_, next) {
      if (next != null) {
        ref.read(notificationPrefsProvider.notifier).scheduleSmartAlarms(next);
      } else {
        ref.read(notificationPrefsProvider.notifier).switchToManualAlarms();
      }
    },
    fireImmediately: true,
  );

  // 2. When prefs finish loading, re-apply smart alarms if times are ready.
  //    This covers the race where smart times resolve before prefs do:
  //    step 1 fires but scheduleSmartAlarms returns early (prefs == null),
  //    so we retry once prefs arrive.
  ref.listen<AsyncValue<NotificationPrefs>>(
    notificationPrefsProvider,
    (_, next) {
      next.whenData((_) {
        final times = ref.read(smartAlarmTimesProvider);
        if (times != null) {
          ref.read(notificationPrefsProvider.notifier).scheduleSmartAlarms(times);
        }
      });
    },
    fireImmediately: true,
  );
});
