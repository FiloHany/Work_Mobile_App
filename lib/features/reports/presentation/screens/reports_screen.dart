import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(
              title: 'Current Cycle',
              subtitle:
                  '${DateFormat('d MMM').format(data.cycle.start)} – ${DateFormat('d MMM').format(data.cycle.end)}',
            ),
            const Gap(12),
            _StatCard(
              label: 'Hours Worked',
              value: data.cycleSummary.totalWorked.formatted,
              sub: 'of ${data.cycleSummary.totalRequired.formatted} required',
              icon: Icons.schedule,
              color: AppColors.primary,
            ),
            const Gap(10),
            _StatCard(
              label: 'Time Credit',
              value: data.availableCredit.formatted,
              sub: 'available to use',
              icon: Icons.savings_outlined,
              color: AppColors.accent,
            ),
            const Gap(10),
            _StatCard(
              label: 'Valid Days',
              value: '${data.cycleSummary.validDays}',
              sub: 'of ${data.cycleSummary.workingDaysPassed} days worked',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            const Gap(10),
            _StatCard(
              label: 'Insufficient Days',
              value: '${data.cycleSummary.insufficientDays}',
              sub: 'days below 4-hour minimum',
              icon: Icons.warning_amber_outlined,
              color: AppColors.error,
            ),
            const Gap(10),
            _StatCard(
              label: 'Working Days Remaining',
              value: '${data.workingDaysRemaining}',
              sub: 'days left in cycle',
              icon: Icons.event_outlined,
              color: AppColors.textSecondary,
            ),
            const Gap(24),
            _SectionHeader(title: 'This Week'),
            const Gap(12),
            _StatCard(
              label: 'Weekly Hours',
              value: data.weeklySummary.totalWorked.formatted,
              sub: 'of 35h weekly target',
              icon: Icons.bar_chart_outlined,
              color: AppColors.primaryLight,
            ),
            const Gap(24),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.cycleSummary),
              icon: const Icon(Icons.summarize_outlined),
              label: const Text('Full Cycle Summary'),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.optimizer),
              icon: const Icon(Icons.auto_awesome_motion_outlined),
              label: const Text('Work Optimizer'),
            ),
            const Gap(12),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.correctionsHistory),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Correction Requests'),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          if (subtitle != null) Text(subtitle!, style: AppTextStyles.bodySmall),
        ],
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(value, style: AppTextStyles.headlineMedium),
                Text(sub, style: AppTextStyles.labelSmall),
              ],
            ),
          ],
        ),
      );
}
