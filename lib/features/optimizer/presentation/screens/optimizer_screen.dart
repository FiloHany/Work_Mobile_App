import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/engine/work_optimizer.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/optimizer_provider.dart';

class OptimizerScreen extends ConsumerWidget {
  const OptimizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(optimizerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Work Optimizer'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(optimizerProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(optimizerProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (data.hasIgnoredScheduleEntries) ...[
                _WarningBanner(count: data.ignoredScheduleEntries),
                const Gap(12),
              ],
              _SummaryGrid(data: data),
              const Gap(16),
              _RecommendationCard(plan: data.plan),
              const Gap(16),
              if (data.plan.today != null) ...[
                _TodayPlan(day: data.plan.today!),
                const Gap(16),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daily Targets',
                      style: AppTextStyles.headlineSmall,
                    ),
                  ),
                  Text(
                    'Updated ${data.generatedAt.formattedTime}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const Gap(10),
              if (data.plan.days.isEmpty)
                const _EmptyPlan()
              else
                ...data.plan.days.map((day) => _DayPlanTile(day: day)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});
  final OptimizerData data;

  @override
  Widget build(BuildContext context) {
    final plan = data.plan;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.05,
      children: [
        _MetricCard(
          label: 'Worked',
          value: plan.worked.formatted,
          icon: Icons.timer_outlined,
          color: AppColors.primary,
        ),
        _MetricCard(
          label: 'Required',
          value: plan.totalRequired.formatted,
          icon: Icons.flag_outlined,
          color: AppColors.textSecondary,
        ),
        _MetricCard(
          label: 'Remaining',
          value: plan.remainingRequired.formatted,
          icon: Icons.pending_actions_outlined,
          color: plan.remainingRequiredMinutes == 0
              ? AppColors.success
              : AppColors.warning,
        ),
        _MetricCard(
          label: 'Projected',
          value: plan.projectedWorked.formatted,
          icon: Icons.insights_outlined,
          color: plan.isCovered ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.plan});
  final WorkOptimizationPlan plan;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              plan.isCovered
                  ? Icons.check_circle_outline
                  : Icons.route_outlined,
              color: plan.isCovered ? AppColors.success : AppColors.primary,
              size: 24,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.isCovered ? 'Cycle Covered' : 'Optimizer Plan',
                    style: AppTextStyles.headlineSmall,
                  ),
                  const Gap(4),
                  Text(plan.recommendation, style: AppTextStyles.bodyMedium),
                  if (plan.projectedSurplusMinutes > 0) ...[
                    const Gap(6),
                    Text(
                      'Projected surplus: ${plan.projectedSurplus.formatted}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _TodayPlan extends StatelessWidget {
  const _TodayPlan({required this.day});
  final DailyOptimization day;

  @override
  Widget build(BuildContext context) {
    final remaining =
        day.additionalMinutes == 0 ? 'Ready now' : day.additional.formatted;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                day.isActive ? Icons.work_history_outlined : Icons.today,
                color: AppColors.primary,
              ),
              const Gap(10),
              const Expanded(
                child: Text("Today's Optimized Plan",
                    style: AppTextStyles.headlineSmall),
              ),
            ],
          ),
          const Gap(14),
          _InfoRow(
            label: 'Exact target',
            value: day.target.formatted,
          ),
          _InfoRow(
            label: day.isActive ? 'Still needed' : 'Planned duration',
            value: remaining,
          ),
          _InfoRow(
            label: 'Check in',
            value: day.recommendedCheckIn.formattedTime,
          ),
          _InfoRow(
            label: 'Check out',
            value: day.recommendedCheckOut.formattedTime,
          ),
        ],
      ),
    );
  }
}

class _DayPlanTile extends StatelessWidget {
  const _DayPlanTile({required this.day});
  final DailyOptimization day;

  @override
  Widget build(BuildContext context) {
    final subtitle = day.hasSchedule
        ? 'Schedule span ${day.scheduleSpan.formatted}'
        : 'No schedule block';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: day.isToday
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE').format(day.date),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: day.isToday
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${day.date.day}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color:
                        day.isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day.date.formattedDateShort,
                    style: AppTextStyles.labelLarge),
                const Gap(2),
                Text(subtitle, style: AppTextStyles.bodySmall),
                if (day.alreadyWorkedMinutes > 0)
                  Text(
                    'Already worked ${day.alreadyWorked.formatted}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ChipText('Target ${day.target.formatted}'),
                    _ChipText(
                      '${day.recommendedCheckIn.formattedTime} - ${day.recommendedCheckOut.formattedTime}',
                    ),
                    if (day.additionalMinutes > 0)
                      _ChipText('Add ${day.additional.formatted}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined,
                color: AppColors.warning, size: 20),
            const Gap(10),
            Expanded(
              child: Text(
                '$count invalid schedule ${count == 1 ? 'entry was' : 'entries were'} ignored.',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTextStyles.headlineSmall.copyWith(color: color)),
                  Text(label, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(value, style: AppTextStyles.labelLarge),
          ],
        ),
      );
}

class _ChipText extends StatelessWidget {
  const _ChipText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: AppTextStyles.labelSmall),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: child,
      );
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan();

  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          children: [
            Icon(Icons.event_available_outlined,
                color: AppColors.success, size: 24),
            const Gap(12),
            const Expanded(
              child: Text(
                'No remaining workdays need optimization in this cycle.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      );
}
