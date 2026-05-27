import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../providers/today_provider.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to keep the live timer fresh.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(attendanceProvider);
    final todayAsync = ref.watch(todayProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayProvider);
          ref.read(attendanceProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(DateTime.now()),
                    style: AppTextStyles.headlineMedium,
                  ),
                  Text(
                    DateFormat('d MMMM yyyy').format(DateTime.now()),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push(Routes.notifications),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Gap(8),
                  todayAsync.maybeWhen(
                    data: (state) => state.isHoliday
                        ? _HolidayBanner(name: state.holidayName)
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  _CheckInCard(attendance: attendance),
                  const Gap(16),
                  todayAsync.when(
                    loading: () => const AppLoading(),
                    error: (e, _) => _ErrorTile(message: e.toString()),
                    data: (state) => Column(
                      children: [
                        if (state.result != null) _MetricsCard(state: state),
                        if (state.result != null &&
                            state.result!.creditEarned > Duration.zero) ...[
                          const Gap(16),
                          _OvertimeCard(result: state.result!),
                        ],
                        if (state.todayEntries.isNotEmpty) ...[
                          const Gap(16),
                          _ScheduleCard(entries: state.todayEntries),
                        ],
                        if (attendance.error != null) ...[
                          const Gap(8),
                          _ErrorTile(message: attendance.error!),
                        ],
                      ],
                    ),
                  ),
                  const Gap(16),
                  _CorrectionsLink(),
                  const Gap(24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Holiday banner ────────────────────────────────────────────────────────────

class _HolidayBanner extends StatelessWidget {
  const _HolidayBanner({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_outlined, color: Color(0xFFB8860B)),
          const Gap(10),
          Expanded(
            child: Text(
              name != null
                  ? 'Public holiday: $name — no work required today'
                  : 'Today is a public holiday — no work required',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: const Color(0xFF7A5C00)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check-in/out card ─────────────────────────────────────────────────────────

class _CheckInCard extends ConsumerWidget {
  const _CheckInCard({required this.attendance});
  final AttendanceState attendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIn = attendance.isCheckedIn;
    final session = attendance.activeSession;
    final elapsed = session != null
        ? DateTime.now().difference(session.checkInTime)
        : Duration.zero;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIn
              ? [AppColors.primaryLight, AppColors.primary]
              : [AppColors.surface, AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isIn ? null : Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          if (isIn) ...[
            Text(
              elapsed.clockFormat,
              style: AppTextStyles.timerDisplay
                  .copyWith(color: Colors.white, fontSize: 56),
            ),
            const Gap(4),
            Text(
              'Checked in at ${DateFormat('HH:mm').format(session!.checkInTime)}',
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 14, color: Color(0xCCFFFFFF)),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: attendance.isCheckingOut
                  ? null
                  : () async {
                      final ok = await ref
                          .read(attendanceProvider.notifier)
                          .checkOut();
                      if (ok && context.mounted) {
                        ref.invalidate(todayProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Checked out successfully')),
                        );
                      }
                    },
              icon: attendance.isCheckingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.logout_rounded),
              label: const Text('Check Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.login_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const Gap(16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Not checked in',
                        style: AppTextStyles.headlineSmall),
                    Text(
                      DateFormat('HH:mm').format(DateTime.now()),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const Gap(20),
            ElevatedButton.icon(
              onPressed: attendance.isCheckingIn
                  ? null
                  : () async {
                      final ok =
                          await ref.read(attendanceProvider.notifier).checkIn();
                      if (ok && context.mounted) {
                        ref.invalidate(todayProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checked in!')),
                        );
                      }
                    },
              icon: attendance.isCheckingIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login_rounded),
              label: const Text('Check In'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Metrics card ──────────────────────────────────────────────────────────────

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.state});
  final TodayState state;

  @override
  Widget build(BuildContext context) {
    final r = state.result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Progress", style: AppTextStyles.headlineSmall),
          const Gap(16),
          _MetricRow(
            label: 'Worked so far',
            value: r.workedDuration.formatted,
            icon: Icons.schedule,
            color: AppColors.primary,
          ),
          const Gap(10),
          if (r.earliestValidDeparture != null)
            _MetricRow(
              label: 'Minimum valid stay until',
              value: DateFormat('HH:mm').format(r.earliestValidDeparture!),
              icon: Icons.timer_outlined,
              color: AppColors.warning,
            ),
          if (r.earliestValidDeparture != null) const Gap(10),
          if (r.earliestSafeDeparture != null)
            _MetricRow(
              label: state.availableCredit.isNegative
                  ? 'Must stay until (debt repayment)'
                  : state.availableCredit.isZero
                      ? 'Target checkout at'
                      : 'Earliest safe leave (with credit)',
              value: DateFormat('HH:mm').format(r.earliestSafeDeparture!),
              icon: Icons.exit_to_app_outlined,
              color: state.availableCredit.isNegative
                  ? AppColors.error
                  : AppColors.success,
            ),
          if (!state.availableCredit.isZero) ...[
            const Gap(10),
            _MetricRow(
              label: state.availableCredit.isNegative
                  ? 'Credit debt'
                  : 'Available credit',
              value: state.availableCredit.formatted,
              icon: state.availableCredit.isNegative
                  ? Icons.trending_down_outlined
                  : Icons.savings_outlined,
              color: state.availableCredit.isNegative
                  ? AppColors.error
                  : AppColors.accent,
            ),
          ],
          const Gap(16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  r.canLeaveNow ? AppColors.successLight : AppColors.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              r.recommendation,
              style: AppTextStyles.bodyMedium.copyWith(
                color: r.canLeaveNow ? AppColors.success : AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(10),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
        ],
      );
}

// ── Overtime card ─────────────────────────────────────────────────────────────

class _OvertimeCard extends StatelessWidget {
  const _OvertimeCard({required this.result});
  final DailyCalculationResult result;

  @override
  Widget build(BuildContext context) {
    final overtime = result.creditEarned;
    final canLeave = result.canLeaveNow;
    final departure = result.earliestSafeDeparture;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: canLeave ? AppColors.successLight : AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canLeave
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canLeave
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              canLeave
                  ? Icons.exit_to_app_rounded
                  : Icons.trending_up_rounded,
              color: canLeave ? AppColors.success : AppColors.accent,
              size: 24,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canLeave ? 'You can leave now' : 'Overtime accumulating',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: canLeave ? AppColors.success : AppColors.accent,
                  ),
                ),
                const Gap(2),
                Text(
                  departure != null
                      ? 'Earliest safe departure: ${_fmt(departure)}'
                      : '+${overtime.formatted} earned today',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: canLeave
                        ? AppColors.success
                        : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${overtime.formatted}',
            style: AppTextStyles.headlineSmall.copyWith(
              color: canLeave ? AppColors.success : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Schedule card ─────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entries});
  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Schedule",
                  style: AppTextStyles.headlineSmall),
              TextButton(
                onPressed: () => context.push(Routes.schedule),
                child: const Text('Edit'),
              ),
            ],
          ),
          const Gap(8),
          ...entries.map((e) => _ScheduleEntryTile(entry: e)),
        ],
      ),
    );
  }
}

class _ScheduleEntryTile extends StatelessWidget {
  const _ScheduleEntryTile({required this.entry});
  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              '${entry.startTime} – ${entry.endTime}  ${entry.title}',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corrections link ──────────────────────────────────────────────────────────

class _CorrectionsLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push(Routes.correctionForm),
      icon: const Icon(Icons.edit_note_outlined, size: 18),
      label: const Text('Submit a correction request'),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
      );
}
