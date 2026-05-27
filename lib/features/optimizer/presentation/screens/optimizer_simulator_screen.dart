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

class OptimizerSimulatorScreen extends ConsumerStatefulWidget {
  const OptimizerSimulatorScreen({super.key});

  @override
  ConsumerState<OptimizerSimulatorScreen> createState() =>
      _OptimizerSimulatorScreenState();
}

class _OptimizerSimulatorScreenState
    extends ConsumerState<OptimizerSimulatorScreen> {
  OptimizerSimulationMode _mode = OptimizerSimulationMode.onTime;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(optimizerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Optimizer Simulator'),
        backgroundColor: AppColors.background,
      ),
      body: async.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          final result = WorkOptimizer.simulate(data.plan, _mode);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text('Scenario', style: AppTextStyles.headlineSmall),
              const Gap(10),
              _ModePicker(
                selected: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const Gap(16),
              _ResultGrid(result: result, plan: data.plan),
              const Gap(16),
              _ScenarioNote(mode: _mode, result: result),
              const Gap(20),
              const Text('Projected Days', style: AppTextStyles.headlineSmall),
              const Gap(10),
              if (result.days.isEmpty)
                const _EmptySimulation()
              else
                ...result.days.map((day) => _SimulationDayTile(day: day)),
            ],
          );
        },
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.selected,
    required this.onChanged,
  });

  final OptimizerSimulationMode selected;
  final ValueChanged<OptimizerSimulationMode> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: OptimizerSimulationMode.values.map((mode) {
          final isSelected = mode == selected;
          return ChoiceChip(
            selected: isSelected,
            label: Text(mode.label),
            avatar: Icon(_modeIcon(mode), size: 18),
            selectedColor: AppColors.primary.withValues(alpha: 0.12),
            labelStyle: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            onSelected: (_) => onChanged(mode),
          );
        }).toList(),
      );
}

class _ResultGrid extends StatelessWidget {
  const _ResultGrid({required this.result, required this.plan});
  final OptimizerSimulationResult result;
  final WorkOptimizationPlan plan;

  @override
  Widget build(BuildContext context) {
    final balance =
        result.shortfallMinutes > 0 ? result.shortfall : result.surplus;
    final balanceLabel = result.shortfallMinutes > 0 ? 'Shortfall' : 'Surplus';
    final balanceColor =
        result.shortfallMinutes > 0 ? AppColors.error : AppColors.success;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.05,
      children: [
        _MetricCard(
          label: 'Projected Total',
          value: result.projectedTotal.formatted,
          icon: Icons.insights_outlined,
          color: AppColors.primary,
        ),
        _MetricCard(
          label: balanceLabel,
          value: balance.formatted,
          icon: result.shortfallMinutes > 0
              ? Icons.warning_amber_outlined
              : Icons.check_circle_outline,
          color: balanceColor,
        ),
        _MetricCard(
          label: 'Valid Days',
          value: '${result.validDays}/${result.days.length}',
          icon: Icons.fact_check_outlined,
          color: AppColors.success,
        ),
        _MetricCard(
          label: 'Already Worked',
          value: plan.worked.formatted,
          icon: Icons.history_toggle_off,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _ScenarioNote extends StatelessWidget {
  const _ScenarioNote({required this.mode, required this.result});
  final OptimizerSimulationMode mode;
  final OptimizerSimulationResult result;

  @override
  Widget build(BuildContext context) {
    final color =
        result.shortfallMinutes > 0 ? AppColors.warning : AppColors.info;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_modeIcon(mode), color: color, size: 22),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label, style: AppTextStyles.labelLarge),
                const Gap(2),
                Text(_modeDescription(mode), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationDayTile extends StatelessWidget {
  const _SimulationDayTile({required this.day});
  final OptimizerSimulationDay day;

  @override
  Widget build(BuildContext context) => Container(
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
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEE').format(day.date),
                    style: AppTextStyles.labelSmall,
                  ),
                  Text('${day.date.day}', style: AppTextStyles.headlineSmall),
                ],
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(day.date.formattedDateShort,
                            style: AppTextStyles.labelLarge),
                      ),
                      Icon(
                        day.isValid
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color:
                            day.isValid ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                  const Gap(4),
                  Text(
                    '${day.checkIn.formattedTime} - ${day.checkOut.formattedTime}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ChipText('Adds ${day.worked.formatted}'),
                      _ChipText(day.isValid ? 'Valid day' : 'Under 4h'),
                    ],
                  ),
                ],
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

class _EmptySimulation extends StatelessWidget {
  const _EmptySimulation();

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
            Icon(Icons.event_available_outlined,
                color: AppColors.success, size: 24),
            const Gap(12),
            const Expanded(
              child: Text(
                'No remaining days are available to simulate.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

IconData _modeIcon(OptimizerSimulationMode mode) => switch (mode) {
      OptimizerSimulationMode.onTime => Icons.route_outlined,
      OptimizerSimulationMode.checkIn30Late => Icons.snooze_outlined,
      OptimizerSimulationMode.checkIn60Late => Icons.access_time_outlined,
      OptimizerSimulationMode.checkOut60Late => Icons.more_time_outlined,
      OptimizerSimulationMode.minimumOnly => Icons.compress_outlined,
    };

String _modeDescription(OptimizerSimulationMode mode) => switch (mode) {
      OptimizerSimulationMode.onTime =>
        'Uses the optimized check-in and checkout plan exactly.',
      OptimizerSimulationMode.checkIn30Late =>
        'Starts every remaining day 30 minutes later and moves checkout with it.',
      OptimizerSimulationMode.checkIn60Late =>
        'Starts every remaining day 1 hour later and moves checkout with it.',
      OptimizerSimulationMode.checkOut60Late =>
        'Works 1 extra hour after the optimized checkout each remaining day.',
      OptimizerSimulationMode.minimumOnly =>
        'Works only the 4-hour minimum on each remaining day.',
    };
