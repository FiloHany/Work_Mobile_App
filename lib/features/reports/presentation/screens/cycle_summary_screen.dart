import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/duration_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../providers/reports_provider.dart';

class CycleSummaryScreen extends ConsumerWidget {
  const CycleSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Summary')),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          final s = data.cycleSummary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${DateFormat('d MMM').format(data.cycle.start)} – ${DateFormat('d MMM yyyy').format(data.cycle.end)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xCCFFFFFF),
                          fontSize: 14,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        s.totalWorked.formatted,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'of ${s.totalRequired.formatted} required',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xCCFFFFFF),
                          fontSize: 14,
                        ),
                      ),
                      const Gap(16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.progressPercent,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Stats grid
                Row(
                  children: [
                    _Cell(
                        label: 'Valid Days',
                        value: '${s.validDays}',
                        color: AppColors.success),
                    const Gap(12),
                    _Cell(
                        label: 'Short Days',
                        value: '${s.insufficientDays}',
                        color: AppColors.error),
                  ],
                ),
                const Gap(12),
                Row(
                  children: [
                    _Cell(
                        label: 'Time Credit',
                        value: data.availableCredit.formatted,
                        color: AppColors.accent),
                    const Gap(12),
                    _Cell(
                        label: 'Days Remaining',
                        value: '${data.workingDaysRemaining}',
                        color: AppColors.primary),
                  ],
                ),
                const Gap(12),
                Row(
                  children: [
                    _Cell(
                        label: 'Total Deficit',
                        value: s.totalDeficit.formatted,
                        color: AppColors.warning),
                    const Gap(12),
                    _Cell(
                        label: 'Status',
                        value: s.isOnTrack ? 'On Track' : 'Behind',
                        color:
                            s.isOnTrack ? AppColors.success : AppColors.error),
                  ],
                ),
                const Gap(24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: s.isOnTrack
                        ? AppColors.successLight
                        : AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.isOnTrack
                        ? 'You are on track for this cycle. Keep it up!'
                        : 'You are behind. You need ${Duration(minutes: s.remainingMinutes).formatted} more to meet the cycle target.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          s.isOnTrack ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              const Gap(4),
              Text(value,
                  style: AppTextStyles.headlineMedium.copyWith(color: color)),
            ],
          ),
        ),
      );
}
