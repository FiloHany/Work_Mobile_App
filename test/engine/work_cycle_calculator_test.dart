import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/engine/work_cycle_calculator.dart';

void main() {
  group('WorkCycleCalculator.currentCycle()', () {
    test('16th of month → cycle starts on the 16th of that month', () {
      final ref = DateTime(2025, 3, 16);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 3, 16));
      expect(cycle.end, DateTime(2025, 4, 15));
    });

    test('31st of month → cycle still starts on the 16th of that month', () {
      final ref = DateTime(2025, 3, 31);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 3, 16));
      expect(cycle.end, DateTime(2025, 4, 15));
    });

    test('1st of month → cycle started on 16th of previous month', () {
      final ref = DateTime(2025, 4, 1);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 3, 16));
      expect(cycle.end, DateTime(2025, 4, 15));
    });

    test('15th of month → cycle ends today (last day of cycle)', () {
      final ref = DateTime(2025, 4, 15);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 3, 16));
      expect(cycle.end, DateTime(2025, 4, 15));
    });

    test('16th of December → year boundary handled correctly', () {
      final ref = DateTime(2025, 12, 16);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 12, 16));
      expect(cycle.end, DateTime(2026, 1, 15));
    });

    test('January 1st → cycle started Dec 16 previous year', () {
      final ref = DateTime(2026, 1, 1);
      final cycle = WorkCycleCalculator.currentCycle(ref);
      expect(cycle.start, DateTime(2025, 12, 16));
      expect(cycle.end, DateTime(2026, 1, 15));
    });
  });

  group('previousCycle and nextCycle', () {
    test('previous cycle is exactly one cycle before current', () {
      final ref = DateTime(2025, 3, 20); // in March 16-April 15 cycle
      final prev = WorkCycleCalculator.previousCycle(ref);
      expect(prev.start, DateTime(2025, 2, 16));
      expect(prev.end, DateTime(2025, 3, 15));
    });

    test('next cycle is exactly one cycle after current', () {
      final ref = DateTime(2025, 3, 20);
      final next = WorkCycleCalculator.nextCycle(ref);
      expect(next.start, DateTime(2025, 4, 16));
      expect(next.end, DateTime(2025, 5, 15));
    });
  });

  group('countWorkingDays()', () {
    // Egyptian work week: Sun–Thu + Sat (only Friday is the rest day).
    test('Sun–Thu week has 5 working days', () {
      final start = DateTime(2025, 3, 16); // Sunday
      final end = DateTime(2025, 3, 20);   // Thursday
      expect(
        WorkCycleCalculator.countWorkingDays(start: start, end: end),
        5,
      );
    });

    test('full cycle Mar 16–Apr 15 has correct working-day count', () {
      final start = DateTime(2025, 3, 16);
      final end = DateTime(2025, 4, 15);
      final count =
          WorkCycleCalculator.countWorkingDays(start: start, end: end);
      // ~4.3 weeks × 6 working days/week ≈ 26 days.
      expect(count, greaterThanOrEqualTo(24));
      expect(count, lessThanOrEqualTo(28));
    });

    test('holiday excluded from Sun–Thu week count', () {
      final start = DateTime(2025, 3, 16); // Sunday
      final end = DateTime(2025, 3, 20);   // Thursday (5 work days)
      final holidays = {DateTime(2025, 3, 19)}; // Wednesday is a holiday
      expect(
        WorkCycleCalculator.countWorkingDays(
            start: start, end: end, holidays: holidays),
        4,
      );
    });

    test('Friday-only range has 0 working days (only rest day)', () {
      // March 14, 2025 is a Friday — the sole Egyptian rest day.
      final friday = DateTime(2025, 3, 14);
      expect(
        WorkCycleCalculator.countWorkingDays(start: friday, end: friday),
        0,
      );
    });

    test('Saturday is a working day', () {
      // March 15, 2025 is a Saturday.
      final saturday = DateTime(2025, 3, 15);
      expect(
        WorkCycleCalculator.countWorkingDays(start: saturday, end: saturday),
        1,
      );
    });
  });

  group('remainingWorkingDays()', () {
    test('from cycle start → all working days remain', () {
      final cycle = WorkCycleCalculator.currentCycle(DateTime(2025, 3, 16));
      final all = WorkCycleCalculator.countWorkingDays(
          start: cycle.start, end: cycle.end);
      final remaining = WorkCycleCalculator.remainingWorkingDays(
        cycle: cycle,
        from: cycle.start,
      );
      expect(remaining, all);
    });

    test('from cycle end → 1 remaining day (the last day)', () {
      final cycle = WorkCycleCalculator.currentCycle(DateTime(2025, 3, 16));
      // Cycle ends on April 15 (Tuesday) — 1 working day including itself.
      final remaining = WorkCycleCalculator.remainingWorkingDays(
        cycle: cycle,
        from: cycle.end,
      );
      // April 15 is a Tuesday, so it counts as 1 working day.
      expect(remaining, 1);
    });

    test('from after cycle end → 0 remaining', () {
      final cycle = WorkCycleCalculator.currentCycle(DateTime(2025, 3, 16));
      final remaining = WorkCycleCalculator.remainingWorkingDays(
        cycle: cycle,
        from: cycle.end.add(const Duration(days: 1)),
      );
      expect(remaining, 0);
    });
  });

  group('currentWeek()', () {
    // Egyptian work week runs Sunday–Thursday; the week "starts" on Sunday.
    test('Wednesday returns the preceding Sunday as week start', () {
      final ref = DateTime(2025, 3, 19); // Wednesday
      final week = WorkCycleCalculator.currentWeek(ref);
      expect(week.start.weekday, DateTime.sunday);
      expect(week.end.weekday, DateTime.thursday);
      expect(week.start, DateTime(2025, 3, 16));
      expect(week.end, DateTime(2025, 3, 20));
    });

    test('Sunday returns itself as week start', () {
      final ref = DateTime(2025, 3, 16); // Sunday
      final week = WorkCycleCalculator.currentWeek(ref);
      expect(week.start, DateTime(2025, 3, 16));
      expect(week.end, DateTime(2025, 3, 20));
    });
  });
}
