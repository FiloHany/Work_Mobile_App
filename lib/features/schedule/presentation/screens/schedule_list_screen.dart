import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../domain/entities/schedule_entry.dart';
import '../providers/schedule_provider.dart';

// Ordered Sat→Thu (Saturday=6, then Sun=0..Thu=4)
const _orderedDays = [6, 0, 1, 2, 3, 4];
const _dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

class ScheduleListScreen extends ConsumerWidget {
  const ScheduleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Import from photo',
            onPressed: () => context
                .push(Routes.scheduleOcrImport)
                .then((_) => ref.read(scheduleProvider.notifier).load()),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add entry',
            onPressed: () => context
                .push(Routes.scheduleEditor)
                .then((_) => ref.read(scheduleProvider.notifier).load()),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoading()
          : state.entries.isEmpty
              ? const _EmptySchedule()
              : _ScheduleByDay(byDay: state.byDay),
    );
  }
}

class _ScheduleByDay extends StatelessWidget {
  const _ScheduleByDay({required this.byDay});
  final Map<int, List<ScheduleEntry>> byDay;

  @override
  Widget build(BuildContext context) {
    // Show days in Sat→Thu order, skip days with no entries.
    final days = _orderedDays.where((d) => byDay.containsKey(d)).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: days.map((d) {
        final entries = byDay[d]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dayNames[d], style: AppTextStyles.headlineSmall),
            const Gap(8),
            ...entries.map((e) => _EntryTile(entry: e)),
            const Gap(16),
          ],
        );
      }).toList(),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry});
  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      '${entry.startTime.substring(0, 5)} – ${entry.endTime.substring(0, 5)}',
      entry.entryType.label,
      if (entry.groupName != null) entry.groupName!,
      if (entry.location != null) entry.location!,
    ].join('  •  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor(entry.entryType),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => context
                .push('${Routes.scheduleEditor}?id=${entry.id}')
                .then((_) => ref.read(scheduleProvider.notifier).load()),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete entry?'),
                  content: Text('Remove "${entry.title}" from your schedule?'),
                  actions: [
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, true),
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(scheduleProvider.notifier).deleteEntry(entry.id);
              }
            },
          ),
        ],
      ),
    );
  }

  Color _typeColor(ScheduleEntryType t) => switch (t) {
        ScheduleEntryType.lecture => AppColors.primary,
        ScheduleEntryType.section => AppColors.accent,
        ScheduleEntryType.lab => AppColors.warning,
        ScheduleEntryType.meeting => AppColors.info,
        ScheduleEntryType.officeHours => AppColors.success,
        ScheduleEntryType.requiredPresence => AppColors.primaryLight,
        ScheduleEntryType.free => AppColors.textHint,
      };
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 56, color: AppColors.textHint),
            const Gap(16),
            const Text('No schedule entries yet',
                style: AppTextStyles.headlineMedium),
            const Gap(8),
            const Text('Tap + to add manually, or use the scan icon to import from a photo.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      );
}
