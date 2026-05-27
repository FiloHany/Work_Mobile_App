import '../constants/work_rules.dart';
import '../extensions/datetime_extensions.dart';

/// Immutable record of a work cycle's date boundaries.
class WorkCycle {
  const WorkCycle({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool get isActive {
    final today = DateTime.now().dateOnly;
    return today.isBetween(start, end);
  }

  int get totalCalendarDays => end.difference(start).inDays + 1;

  @override
  String toString() => 'WorkCycle(${start.isoDate} → ${end.isoDate})';
}

/// Pure calculation functions for the 16th→15th work cycle.
/// No Flutter or Supabase dependencies — safe to test without mocks.
abstract final class WorkCycleCalculator {
  /// Returns the work cycle that contains [reference] (defaults to today).
  ///
  /// Cycle rule: starts on the 16th of month M, ends on the 15th of month M+1.
  static WorkCycle currentCycle([DateTime? reference]) {
    final d = (reference ?? DateTime.now()).dateOnly;

    final DateTime start;
    final DateTime end;

    if (d.day >= WorkRules.cycleStartDay) {
      // Second half of month: cycle started on the 16th of this month.
      start = DateTime(d.year, d.month, WorkRules.cycleStartDay);
      // End is 15th of next month — handle year roll-over.
      final nextMonth = d.month == 12 ? 1 : d.month + 1;
      final nextYear = d.month == 12 ? d.year + 1 : d.year;
      end = DateTime(nextYear, nextMonth, WorkRules.cycleEndDay);
    } else {
      // First half of month: cycle started on 16th of previous month.
      final prevMonth = d.month == 1 ? 12 : d.month - 1;
      final prevYear = d.month == 1 ? d.year - 1 : d.year;
      start = DateTime(prevYear, prevMonth, WorkRules.cycleStartDay);
      end = DateTime(d.year, d.month, WorkRules.cycleEndDay);
    }

    return WorkCycle(start: start, end: end);
  }

  /// Returns the work cycle immediately before [reference]'s cycle.
  static WorkCycle previousCycle([DateTime? reference]) {
    final current = currentCycle(reference);
    // One day before current cycle start is inside the previous cycle.
    final dayInPrev = current.start.subtract(const Duration(days: 1));
    return currentCycle(dayInPrev);
  }

  /// Returns the work cycle immediately after [reference]'s cycle.
  static WorkCycle nextCycle([DateTime? reference]) {
    final current = currentCycle(reference);
    final dayInNext = current.end.add(const Duration(days: 1));
    return currentCycle(dayInNext);
  }

  /// Counts working days (Sun–Thu by default) between [start] and [end]
  /// inclusive, excluding any dates in [holidays] and any weekday in
  /// [extraRestWeekdays] (for a user's personal second rest day).
  static int countWorkingDays({
    required DateTime start,
    required DateTime end,
    Set<DateTime> holidays = const {},
    Set<int> extraRestWeekdays = const {},
  }) {
    int count = 0;
    DateTime cursor = start.dateOnly;
    final endDate = end.dateOnly;

    while (!cursor.isAfter(endDate)) {
      if (WorkRules.workWeekDays.contains(cursor.weekday) &&
          !extraRestWeekdays.contains(cursor.weekday) &&
          !holidays.contains(cursor)) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  /// Returns all working days between [start] and [end] inclusive.
  static List<DateTime> workingDaysBetween({
    required DateTime start,
    required DateTime end,
    Set<DateTime> holidays = const {},
    Set<int> extraRestWeekdays = const {},
  }) {
    final days = <DateTime>[];
    DateTime cursor = start.dateOnly;
    final endDate = end.dateOnly;

    while (!cursor.isAfter(endDate)) {
      if (WorkRules.workWeekDays.contains(cursor.weekday) &&
          !extraRestWeekdays.contains(cursor.weekday) &&
          !holidays.contains(cursor)) {
        days.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  /// Working days remaining in [cycle] from today (or [from]) onward.
  static int remainingWorkingDays({
    required WorkCycle cycle,
    DateTime? from,
    Set<DateTime> holidays = const {},
    Set<int> extraRestWeekdays = const {},
  }) {
    final start = (from ?? DateTime.now()).dateOnly;
    if (start.isAfter(cycle.end)) return 0;
    final effectiveStart = start.isBefore(cycle.start) ? cycle.start : start;
    return countWorkingDays(
      start: effectiveStart,
      end: cycle.end,
      holidays: holidays,
      extraRestWeekdays: extraRestWeekdays,
    );
  }

  /// Total required minutes for a cycle with [workingDays] working days.
  static int requiredMinutesForCycle(int workingDays) =>
      workingDays * WorkRules.standardDailyTarget.inMinutes;

  /// The current Sunday–Thursday work week containing [reference].
  static ({DateTime start, DateTime end}) currentWeek([DateTime? reference]) {
    final d = (reference ?? DateTime.now()).dateOnly;
    // Dart weekday: Mon=1 … Sat=6, Sun=7. Offset to find the preceding Sunday:
    final offsetToSunday = d.weekday == DateTime.sunday ? 0 : d.weekday;
    final sunday = d.subtract(Duration(days: offsetToSunday));
    final thursday = sunday.add(const Duration(days: 4));
    return (start: sunday, end: thursday);
  }
}
