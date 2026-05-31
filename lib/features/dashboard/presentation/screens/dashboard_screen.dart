import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/holidays_provider.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/domain/entities/schedule_entry.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            _AppBar(name: profile?.fullName.split(' ').first ?? 'there'),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: dashAsync.when(
                loading: () => const SliverFillRemaining(
                  child: AppLoading(),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text(e.toString())),
                ),
                data: (data) => SliverList(
                  delegate: SliverChildListDelegate([
                    const Gap(8),
                    _CycleCard(data: data),
                    const Gap(16),
                    _WeeklyCard(data: data),
                    const Gap(16),
                    const _WeekScheduleCard(),
                    const Gap(16),
                    _StatsRow(data: data),
                    const Gap(16),
                    _QuickActions(data: data),
                    const Gap(24),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $name 👋',
            style: AppTextStyles.headlineMedium,
          ),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.cycleSummary;
    final progress = summary.progressPercent;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Work Cycle', style: AppTextStyles.headlineSmall),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.isOnTrack
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.isOnTrack ? 'On Track' : 'Behind',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: summary.isOnTrack
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            '${DateFormat('d MMM').format(data.cycle.start)} – ${DateFormat('d MMM').format(data.cycle.end)}',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isOnTrack ? AppColors.primary : AppColors.warning,
              ),
            ),
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: AppTextStyles.labelSmall,
              ),
              Text(
                '${summary.totalWorked.formatted} / ${summary.totalRequired.formatted}',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _Metric(
                label: 'Remaining',
                value: Duration(minutes: summary.remainingMinutes).formatted,
                color: AppColors.textPrimary,
              ),
              const _Divider(),
              _Metric(
                label: data.availableCredit.isNegative ? 'Debt' : 'Credit',
                value: data.availableCredit.formatted,
                color: data.availableCredit.isNegative
                    ? AppColors.error
                    : AppColors.accent,
              ),
              const _Divider(),
              _Metric(
                label: 'Days Left',
                value: '${data.workingDaysRemaining}d',
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final weekly = data.weeklySummary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week', style: AppTextStyles.headlineSmall),
          const Gap(16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: weekly.progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.progressTrack,
            ),
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${weekly.totalWorked.formatted} of ${weekly.weeklyTarget.formatted}',
                style: AppTextStyles.labelSmall,
              ),
              Text(
                '${Duration(minutes: weekly.remainingMinutes).formatted} remaining',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              _Metric(
                label: 'Valid Days',
                value: '${weekly.validDays}',
                color: AppColors.success,
              ),
              const _Divider(),
              _Metric(
                label: 'Insufficient',
                value: '${weekly.insufficientDays}',
                color: AppColors.error,
              ),
              const _Divider(),
              _Metric(
                label: 'Days',
                value: '${weekly.workingDaysInWeek}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final s = data.cycleSummary;
    return Row(
      children: [
        Expanded(
          child: _SmallCard(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.success,
            value: '${s.validDays}',
            label: 'Valid Days',
          ),
        ),
        const Gap(12),
        Expanded(
          child: _SmallCard(
            icon: Icons.warning_amber_outlined,
            iconColor: AppColors.warning,
            value: '${s.insufficientDays}',
            label: 'Insufficient',
          ),
        ),
        const Gap(12),
        Expanded(
          child: _SmallCard(
            icon: data.availableCredit.isNegative
                ? Icons.trending_down_outlined
                : Icons.savings_outlined,
            iconColor: data.availableCredit.isNegative
                ? AppColors.error
                : AppColors.accent,
            value: data.availableCredit.formatted,
            label: data.availableCredit.isNegative ? 'Debt' : 'Credit',
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.headlineSmall),
        const Gap(12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.35,
          children: [
            _ActionButton(
              icon: Icons.auto_awesome_motion_outlined,
              label: 'Optimizer',
              onTap: () => context.push(Routes.optimizer),
            ),
            _ActionButton(
              icon: Icons.calendar_month_outlined,
              label: 'Schedule',
              onTap: () => context.push(Routes.schedule),
            ),
            _ActionButton(
              icon: Icons.edit_note_outlined,
              label: 'Correction',
              onTap: () => context.push(Routes.correctionForm),
            ),
            _ActionButton(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              onTap: () => context.push(Routes.reports),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Week Schedule card ────────────────────────────────────────────────────────

class _WeekScheduleCard extends ConsumerWidget {
  const _WeekScheduleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final profile = ref.watch(profileProvider);

    final holidays = holidaysAsync.maybeWhen(
      data: (h) => h,
      orElse: () => const HolidaysData(),
    );
    // Convert profile rest days (DateTime.weekday values) to schedule day
    // indexes (0=Sun,1=Mon,...,6=Sat) used in the week card.
    final restDayWeekdays = profile?.restDays.toSet() ?? <int>{};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offsetToSunday = now.weekday == DateTime.sunday ? 0 : now.weekday;
    final sunday = today.subtract(Duration(days: offsetToSunday));
    final byDay = scheduleState.byDay;

    // Map schedule-card day index (0=Sun…6=Sat) → DateTime.weekday value.
    const scheduleIdxToWeekday = [7, 1, 2, 3, 4, 5, 6];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Week Schedule', style: AppTextStyles.headlineSmall),
              TextButton(
                onPressed: () => context.push(Routes.schedule),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const Gap(8),
          ...List.generate(7, (i) {
            final date = sunday.add(Duration(days: i));
            final isToday = date == today;
            // Friday (index 5) is always a rest day.
            final isFriday = i == 5;
            final isExtraRest =
                restDayWeekdays.contains(scheduleIdxToWeekday[i]);
            final isOff = isFriday || isExtraRest;
            final isHoliday = holidays.isHoliday(date);
            final holidayName = holidays.infoFor(date)?.name;
            final entries = (byDay[i] ?? [])
                .where((e) => e.entryType != ScheduleEntryType.free)
                .toList();
            return _DayTile(
              date: date,
              isToday: isToday,
              isFriday: isFriday,
              isExtraRest: isExtraRest && !isFriday,
              isOff: isOff,
              isHoliday: isHoliday,
              holidayName: holidayName,
              entries: entries,
              isLast: i == 6,
            );
          }),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.date,
    required this.isToday,
    required this.isFriday,
    required this.isExtraRest,
    required this.isOff,
    required this.isHoliday,
    required this.entries,
    required this.isLast,
    this.holidayName,
  });

  final DateTime date;
  final bool isToday;
  final bool isFriday;
  final bool isExtraRest;
  final bool isOff;
  final bool isHoliday;
  final String? holidayName;
  final List<ScheduleEntry> entries;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final effectiveOff = isOff || isHoliday;

    Color? bg;
    Color? borderColor;
    if (isToday) {
      bg = AppColors.primary.withValues(alpha: 0.07);
      borderColor = AppColors.primary.withValues(alpha: 0.25);
    } else if (isHoliday) {
      bg = const Color(0xFFFFF8E1);
    }

    final dotColor = isToday
        ? AppColors.primary
        : isHoliday
            ? const Color(0xFFFFB300)
            : effectiveOff
                ? AppColors.textHint
                : AppColors.success;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10, top: 1),
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
              Text(
                '${DateFormat('EEE').format(date)}  ${DateFormat('d MMM').format(date)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: effectiveOff && !isToday
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isToday) _Chip('Today', AppColors.primary),
              if (isHoliday)
                _Chip('Holiday', const Color(0xFFFFB300),
                    textColor: const Color(0xFF7A5800)),
              if (isFriday && !isHoliday)
                _Chip('Weekend', AppColors.textHint),
              if (isExtraRest && !isHoliday)
                _Chip('Rest Day', AppColors.textHint),
            ],
          ),
          if (isHoliday) ...[
            const Gap(4),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                holidayName ?? 'Public holiday — no work required',
                style: AppTextStyles.bodySmall
                    .copyWith(color: const Color(0xFF7A5800)),
              ),
            ),
          ] else if (!effectiveOff) ...[
            if (entries.isEmpty) ...[
              const Gap(3),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text('No entries',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint)),
              ),
            ] else ...[
              const Gap(5),
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(left: 18, bottom: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 8, top: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _entryColor(e.entryType),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.startTime.substring(0, 5)}–${e.endTime.substring(0, 5)}  ${e.title}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Color _entryColor(ScheduleEntryType t) => switch (t) {
        ScheduleEntryType.lecture => AppColors.primary,
        ScheduleEntryType.section => AppColors.accent,
        ScheduleEntryType.lab => AppColors.warning,
        ScheduleEntryType.meeting => AppColors.info,
        ScheduleEntryType.officeHours => AppColors.success,
        ScheduleEntryType.requiredPresence => AppColors.primaryLight,
        ScheduleEntryType.free => AppColors.textHint,
      };
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color, {this.textColor});
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: textColor ?? color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: child,
      );
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const Gap(10),
            Text(value,
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.textPrimary)),
            const Gap(2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(color: color),
            ),
            const Gap(2),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: AppColors.divider,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const Gap(6),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      );
}
