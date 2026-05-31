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
          final today = DateTime.now().dateOnly;

          final upcoming = data.all
              .where((h) => !h.date.isBefore(today))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          if (upcoming.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration_outlined,
                      size: 64, color: AppColors.textHint),
                  const Gap(16),
                  Text('No upcoming holidays',
                      style: AppTextStyles.headlineSmall),
                  const Gap(8),
                  Text(
                    'All public holidays for this year have passed.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final next = upcoming.first;
          final daysUntilNext = next.date.difference(today).inDays;

          // Group by "Month YYYY" — skip the first entry since it's in the hero card.
          final rest = upcoming.skip(1).toList();
          final byMonth = <String, List<HolidayInfo>>{};
          for (final h in rest) {
            final key = DateFormat('MMMM yyyy').format(h.date);
            byMonth.putIfAbsent(key, () => []).add(h);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            children: [
              _NextHolidayHero(holiday: next, daysAway: daysUntilNext),
              const Gap(20),
              _InfoBanner(),
              if (rest.isNotEmpty) ...[
                const Gap(24),
                Text('All Upcoming', style: AppTextStyles.captionUppercase),
                const Gap(10),
                for (final entry in byMonth.entries) ...[
                  _MonthHeader(label: entry.key),
                  const Gap(6),
                  ...entry.value.map((h) => _HolidayTile(
                        holiday: h,
                        isToday: h.date == today,
                        daysAway: h.date.difference(today).inDays,
                      )),
                  const Gap(14),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Next-holiday hero card ────────────────────────────────────────────────────

class _NextHolidayHero extends StatelessWidget {
  const _NextHolidayHero({required this.holiday, required this.daysAway});
  final HolidayInfo holiday;
  final int daysAway;

  @override
  Widget build(BuildContext context) {
    final isToday = daysAway == 0;
    final isTomorrow = daysAway == 1;
    final countdownLabel = isToday
        ? 'Today!'
        : isTomorrow
            ? 'Tomorrow'
            : 'In $daysAway days';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration_outlined,
                        color: Colors.white, size: 14),
                    const Gap(5),
                    Text(
                      'Next Holiday',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  countdownLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Gap(18),
          Text(
            holiday.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Gap(6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xCCFFFFFF), size: 14),
              const Gap(6),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(holiday.date),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
          if (!isToday) ...[
            const Gap(18),
            _CountdownRow(daysAway: daysAway),
          ],
        ],
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  const _CountdownRow({required this.daysAway});
  final int daysAway;

  @override
  Widget build(BuildContext context) {
    final weeks = daysAway ~/ 7;
    final days = daysAway % 7;

    return Row(
      children: [
        if (weeks > 0) ...[
          _CountdownUnit(value: weeks, label: weeks == 1 ? 'week' : 'weeks'),
          const Gap(12),
        ],
        if (days > 0 || weeks == 0)
          _CountdownUnit(value: days, label: days == 1 ? 'day' : 'days'),
      ],
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ],
        ),
      );
}

// ── Info banner ───────────────────────────────────────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.start,
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

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(label, style: AppTextStyles.captionUppercase),
      );
}

// ── Holiday tile ──────────────────────────────────────────────────────────────

class _HolidayTile extends StatelessWidget {
  const _HolidayTile({
    required this.holiday,
    required this.isToday,
    required this.daysAway,
  });
  final HolidayInfo holiday;
  final bool isToday;
  final int daysAway;

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
          // Date badge
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
                    color:
                        isToday ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(14),
          // Name + full date
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
          const Gap(8),
          // Countdown chip
          _DaysChip(daysAway: daysAway, isToday: isToday),
        ],
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.daysAway, required this.isToday});
  final int daysAway;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final label = isToday
        ? 'Today'
        : daysAway == 1
            ? 'Tomorrow'
            : '${daysAway}d';

    final bg = isToday ? AppColors.primary : AppColors.surfaceVariant;
    final fg = isToday ? Colors.white : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
