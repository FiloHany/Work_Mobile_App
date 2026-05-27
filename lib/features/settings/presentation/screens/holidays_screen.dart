import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/providers/holidays_provider.dart';

class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Holidays'),
        actions: [
          IconButton(
            tooltip: 'Refresh from Google Calendar',
            icon: holidaysAsync.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_outlined),
            onPressed: holidaysAsync.isLoading
                ? null
                : () => ref.invalidate(holidaysProvider),
          ),
        ],
      ),
      body: holidaysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (data) {
          if (data.all.isEmpty) {
            return const Center(
              child: Text('No holidays found.'),
            );
          }

          // Group by year.
          final byYear = <int, List<HolidayInfo>>{};
          for (final h in data.all) {
            byYear.putIfAbsent(h.date.year, () => []).add(h);
          }
          final years = byYear.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _InfoBanner(),
              const Gap(20),
              for (final year in years) ...[
                _YearHeader(year: year),
                const Gap(8),
                ...byYear[year]!.map((h) => _HolidayTile(
                      holiday: h,
                      isToday: h.date == DateTime.now().dateOnly,
                    )),
                const Gap(16),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const Gap(10),
          Expanded(
            child: Text(
              'On public holidays no hours are required — '
              'any hours worked count as time credit. '
              'Dates are sourced from Google Calendar (Egyptian Holidays).',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.year});
  final int year;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          year.toString(),
          style: AppTextStyles.captionUppercase,
        ),
      );
}

class _HolidayTile extends StatelessWidget {
  const _HolidayTile({required this.holiday, required this.isToday});
  final HolidayInfo holiday;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('EEE').format(holiday.date);
    final dateLabel = DateFormat('d MMM').format(holiday.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName.toUpperCase(),
                  style: AppTextStyles.captionUppercase.copyWith(
                    fontSize: 9,
                    color: isToday ? AppColors.primary : AppColors.textHint,
                  ),
                ),
                Text(
                  holiday.date.day.toString(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holiday.name, style: AppTextStyles.bodyMedium),
                const Gap(2),
                Text(
                  '$dayName, $dateLabel ${holiday.date.year}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
