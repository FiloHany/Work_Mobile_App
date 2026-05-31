import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/semester_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/services/notification_service.dart';
import '../providers/notification_preferences_provider.dart';
import '../providers/smart_alarm_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationPrefsProvider);
    final semesterMode = ref.watch(semesterModeProvider).maybeWhen(
          data: (m) => m,
          orElse: () => SemesterMode.semester,
        );
    final smartTimes = ref.watch(smartAlarmTimesProvider);
    final isSmartMode = semesterMode == SemesterMode.semester;

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm & Notification Settings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (prefs) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Arrival alarm ───────────────────────────────────────────────
            Text('Arrival Alarm', style: AppTextStyles.headlineSmall),
            const Gap(12),
            if (isSmartMode) ...[
              _SmartAlarmBanner(
                smartTimes: smartTimes,
                enabled: prefs.arrivalReminder,
                onToggle: (v) => ref
                    .read(notificationPrefsProvider.notifier)
                    .update(prefs.copyWith(arrivalReminder: v)),
              ),
            ] else ...[
              _SwitchTile(
                title: 'Arrival reminder',
                subtitle: 'Daily reminder to check in on time',
                value: prefs.arrivalReminder,
                onChanged: (v) => ref
                    .read(notificationPrefsProvider.notifier)
                    .update(prefs.copyWith(arrivalReminder: v)),
              ),
              if (prefs.arrivalReminder)
                _TimeTile(
                  title: 'Alarm time',
                  time: prefs.arrivalReminderTime,
                  onChanged: (t) => ref
                      .read(notificationPrefsProvider.notifier)
                      .update(prefs.copyWith(arrivalReminderTime: t)),
                ),
            ],
            const Gap(24),

            // ── Departure / early-leave alarm ───────────────────────────────
            Text('Departure Alarm', style: AppTextStyles.headlineSmall),
            const Gap(4),
            Text(
              isSmartMode
                  ? 'Fires automatically when you have completed 7 h after check-in.'
                  : 'A fixed daily reminder to check out.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
            const Gap(12),
            if (!isSmartMode) ...[
              _SwitchTile(
                title: 'Departure reminder',
                subtitle: 'Reminder to check out at end of day',
                value: prefs.departureReminder,
                onChanged: (v) => ref
                    .read(notificationPrefsProvider.notifier)
                    .update(prefs.copyWith(departureReminder: v)),
              ),
              if (prefs.departureReminder)
                _TimeTile(
                  title: 'Reminder time',
                  time: prefs.departureReminderTime,
                  onChanged: (t) => ref
                      .read(notificationPrefsProvider.notifier)
                      .update(prefs.copyWith(departureReminderTime: t)),
                ),
            ] else
              _InfoTile(
                icon: Icons.notifications_active_outlined,
                color: AppColors.success,
                text:
                    'A "You can leave now" alert fires automatically at check-in time + 7 h. '
                    'It cancels the moment you check out.',
              ),
            const Gap(24),

            // ── Semester mode note / switch ─────────────────────────────────
            if (!isSmartMode) ...[
              _InfoTile(
                icon: Icons.info_outline,
                color: AppColors.info,
                text:
                    'Switch to Regular Semester mode in Settings → Semester Mode '
                    'to enable schedule-optimized alarms.',
                trailing: TextButton(
                  onPressed: () {
                    context.pop();
                    // User can then tap the Settings tab to change semester mode.
                  },
                  child: const Text('Go back'),
                ),
              ),
              const Gap(24),
            ],

            // ── Alerts ──────────────────────────────────────────────────────
            Text('Alerts', style: AppTextStyles.headlineSmall),
            const Gap(12),
            _SwitchTile(
              title: 'Missed check-in alert',
              subtitle: 'Alert if no check-in detected by mid-morning',
              value: prefs.missedCheckinAlert,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(missedCheckinAlert: v)),
            ),
            const Divider(),
            _SwitchTile(
              title: 'Missed check-out alert',
              subtitle: 'Alert if a session is left open',
              value: prefs.missedCheckoutAlert,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(missedCheckoutAlert: v)),
            ),
            const Gap(24),

            // ── Summaries ───────────────────────────────────────────────────
            Text('Summaries & Tips', style: AppTextStyles.headlineSmall),
            const Gap(12),
            _SwitchTile(
              title: "Tomorrow's preview",
              subtitle: "Evening summary of tomorrow's schedule",
              value: prefs.tomorrowPreview,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(tomorrowPreview: v)),
            ),
            const Divider(),
            _SwitchTile(
              title: 'Weekly summary',
              subtitle: 'Friday wrap-up of your week',
              value: prefs.weeklySummary,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(weeklySummary: v)),
            ),
            const Divider(),
            _SwitchTile(
              title: 'Cycle-end warning',
              subtitle: 'Warning 3 days before cycle closes',
              value: prefs.cycleEndWarning,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(cycleEndWarning: v)),
            ),
            const Divider(),
            _SwitchTile(
              title: 'Early-leave recommendation',
              subtitle: 'Tip when you can leave early using credit hours',
              value: prefs.earlyLeaveRecommendation,
              onChanged: (v) => ref
                  .read(notificationPrefsProvider.notifier)
                  .update(prefs.copyWith(earlyLeaveRecommendation: v)),
            ),
            // ── Test ────────────────────────────────────────────────────────
            Text('Test', style: AppTextStyles.headlineSmall),
            const Gap(4),
            Text(
              'Verify that notifications and alarms reach this device.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
            ),
            const Gap(12),
            _NotificationTestPanel(),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

// ── Smart alarm banner ────────────────────────────────────────────────────────

class _SmartAlarmBanner extends StatelessWidget {
  const _SmartAlarmBanner({
    required this.smartTimes,
    required this.enabled,
    required this.onToggle,
  });

  final Map<int, ({int hour, int minute})>? smartTimes;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    final times = smartTimes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  color: AppColors.primary, size: 18),
              const Gap(8),
              Expanded(
                child: Text(
                  'Schedule-optimized alarm',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (enabled) ...[
            const Gap(8),
            Text(
              'Rings 30 min before your first class each day.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            ),
            if (times != null && times.isNotEmpty) ...[
              const Gap(10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: times.entries.map((e) {
                  final label = e.key < 7 ? _dayLabels[e.key] : '?';
                  final h = e.value.hour.toString().padLeft(2, '0');
                  final m = e.value.minute.toString().padLeft(2, '0');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$label  $h:$m',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary)),
                  );
                }).toList(),
              ),
            ] else ...[
              const Gap(8),
              Text(
                'No schedule entries found. Add your timetable to enable this.',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon,
      required this.color,
      required this.text,
      this.trailing});
  final IconData icon;
  final Color color;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(10),
            Expanded(
                child:
                    Text(text, style: AppTextStyles.bodySmall.copyWith(color: color))),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

// ── Reusable tiles ────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.title,
    required this.time,
    required this.onChanged,
  });
  final String title;
  final String time;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: AppTextStyles.bodySmall),
        trailing: TextButton(
          child: Text(time, style: AppTextStyles.labelLarge),
          onPressed: () async {
            final parts = time.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              ),
            );
            if (picked != null) {
              onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:'
                '${picked.minute.toString().padLeft(2, '0')}',
              );
            }
          },
        ),
      );
}

// ── Notification test panel ───────────────────────────────────────────────────

class _NotificationTestPanel extends StatefulWidget {
  @override
  State<_NotificationTestPanel> createState() => _NotificationTestPanelState();
}

class _NotificationTestPanelState extends State<_NotificationTestPanel> {
  bool _firing = false;
  bool _scheduling = false;
  int _countdown = 0;
  String? _fireTimeLabel;   // e.g. "14:35:08"
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendNow() async {
    setState(() => _firing = true);
    try {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sent — swipe down from the top to see it.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _firing = false);
    }
  }

  Future<void> _scheduleAlarm() async {
    const seconds = 5;
    setState(() {
      _scheduling = true;
      _countdown = seconds;
      _fireTimeLabel = null;
    });
    try {
      await NotificationService.instance.requestPermissions();
      final fireAt = await NotificationService.instance
          .scheduleTestAlarm(secondsFromNow: seconds);

      if (!mounted) return;

      final h = fireAt.hour.toString().padLeft(2, '0');
      final m = fireAt.minute.toString().padLeft(2, '0');
      final s = fireAt.second.toString().padLeft(2, '0');
      setState(() => _fireTimeLabel = '$h:$m:$s');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarm set — look for a notification at $h:$m:$s. '
            'Keep volume up and screen on.',
          ),
          duration: const Duration(seconds: 8),
        ),
      );

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          if (mounted) setState(() { _scheduling = false; _fireTimeLabel = null; });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alarm error: $e')),
        );
        setState(() { _scheduling = false; _countdown = 0; _fireTimeLabel = null; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _firing ? null : _sendNow,
            icon: _firing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.notifications_outlined, size: 18),
            label: const Text('Send test notification now'),
          ),
          const Gap(8),
          OutlinedButton.icon(
            onPressed: _scheduling ? null : _scheduleAlarm,
            icon: _scheduling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.alarm_outlined, size: 18),
            label: Text(
              _countdown > 0
                  ? 'Firing at ${_fireTimeLabel ?? '…'}  ($_countdown s)'
                  : 'Schedule test alarm (5 s)',
            ),
          ),
        ],
      ),
    );
  }
}
