import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/engine/work_cycle_calculator.dart';
import 'package:work_app/core/engine/work_optimizer.dart';

// All multi-day cycles use Sun 16 Mar → Thu 20 Mar 2025 — exactly 5 Egyptian
// working days (Sun–Thu; Friday is the only rest day).

void main() {
  group('WorkOptimizer.buildPlan', () {
    test('distributes exact daily targets across remaining workdays', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 16), // Sunday
        end: DateTime(2025, 3, 20),   // Thursday
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 16, 7), // Sunday morning
        workedDays: const [],
        scheduleBlocks: const [],
      );

      expect(plan.totalRequiredMinutes, 35 * 60);
      expect(plan.projectedWorkedMinutes, 35 * 60);
      expect(plan.days, hasLength(5));
      expect(plan.days.every((day) => day.targetMinutes == 7 * 60), isTrue);
      expect(plan.days.first.recommendedCheckIn, DateTime(2025, 3, 16, 8));
      expect(plan.days.first.recommendedCheckOut, DateTime(2025, 3, 16, 15));
    });

    test('uses schedule span as the daily minimum when it exceeds 4 hours', () {
      // Single-day Monday cycle; schedule block covers Mon (dayOfWeek 1).
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 17), // Monday
        end: DateTime(2025, 3, 17),
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 17, 7),
        workedDays: const [],
        scheduleBlocks: const [
          OptimizerScheduleBlock(
            dayOfWeek: 1, // Monday (0=Sun, 1=Mon … 6=Sat)
            startMinute: 8 * 60,
            endMinute: 17 * 60,
          ),
        ],
      );

      expect(plan.days.single.targetMinutes, 9 * 60);
      expect(plan.projectedSurplusMinutes, 2 * 60);
      expect(plan.days.single.recommendedCheckIn, DateTime(2025, 3, 17, 8));
      expect(plan.days.single.recommendedCheckOut, DateTime(2025, 3, 17, 17));
    });

    test('has no maximum daily cap when a large deficit must be recovered', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 16), // Sunday
        end: DateTime(2025, 3, 20),   // Thursday
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 20, 7), // Last day (Thursday)
        workedDays: const [],
        scheduleBlocks: const [],
      );

      // All 5 days' worth of hours must be recovered on the last day.
      expect(plan.days, hasLength(1));
      expect(plan.days.single.targetMinutes, 35 * 60);
      // checkIn 8:00 + 35 h = next day 19:00
      expect(plan.days.single.recommendedCheckOut, DateTime(2025, 3, 21, 19));
      expect(plan.isCovered, isTrue);
    });

    test('late active check-in moves checkout to preserve required hours', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 17), // Monday
        end: DateTime(2025, 3, 17),
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 17, 10),
        workedDays: const [],
        scheduleBlocks: const [
          OptimizerScheduleBlock(
            dayOfWeek: 1,
            startMinute: 8 * 60,
            endMinute: 15 * 60,
          ),
        ],
        activeCheckIn: DateTime(2025, 3, 17, 10),
      );

      expect(plan.today, isNotNull);
      expect(plan.today!.isActive, isTrue);
      expect(plan.today!.recommendedCheckIn, DateTime(2025, 3, 17, 10));
      expect(plan.today!.recommendedCheckOut, DateTime(2025, 3, 17, 17));
      expect(plan.today!.additionalMinutes, 7 * 60);
    });

    test('active elapsed time is not double-counted in projection', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 17), // Monday
        end: DateTime(2025, 3, 17),
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 17, 10),
        workedDays: const [],
        scheduleBlocks: const [],
        activeCheckIn: DateTime(2025, 3, 17, 8),
      );

      expect(plan.workedMinutes, 2 * 60);
      expect(plan.today!.targetMinutes, 7 * 60);
      expect(plan.today!.additionalMinutes, 5 * 60);
      expect(plan.projectedWorkedMinutes, 7 * 60);
    });
  });

  group('WorkOptimizer.simulate', () {
    test('models minimum-only and late checkout outcomes', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 16), // Sunday
        end: DateTime(2025, 3, 20),   // Thursday (5 work days)
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 16, 7),
        workedDays: const [],
        scheduleBlocks: const [],
      );

      final onTime = WorkOptimizer.simulate(
        plan,
        OptimizerSimulationMode.onTime,
      );
      final minimumOnly = WorkOptimizer.simulate(
        plan,
        OptimizerSimulationMode.minimumOnly,
      );
      final lateCheckout = WorkOptimizer.simulate(
        plan,
        OptimizerSimulationMode.checkOut60Late,
      );

      expect(onTime.projectedTotalMinutes, 35 * 60);   // 5 × 7 h
      expect(onTime.shortfallMinutes, 0);
      expect(minimumOnly.projectedTotalMinutes, 20 * 60); // 5 × 4 h minimum
      expect(minimumOnly.shortfallMinutes, 15 * 60);
      expect(lateCheckout.projectedTotalMinutes, 40 * 60); // 5 × (7+1) h
      expect(lateCheckout.surplusMinutes, 5 * 60);
    });

    test('late check-in shifts simulated checkout without changing target', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 17), // Monday
        end: DateTime(2025, 3, 17),
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 17, 7),
        workedDays: const [],
        scheduleBlocks: const [],
      );

      final result = WorkOptimizer.simulate(
        plan,
        OptimizerSimulationMode.checkIn60Late,
      );

      expect(result.projectedTotalMinutes, 7 * 60);
      expect(result.days.single.checkIn, DateTime(2025, 3, 17, 9));
      expect(result.days.single.checkOut, DateTime(2025, 3, 17, 16));
    });

    test('active elapsed time is not double-counted by the simulator', () {
      final cycle = WorkCycle(
        start: DateTime(2025, 3, 17), // Monday
        end: DateTime(2025, 3, 17),
      );
      final plan = WorkOptimizer.buildPlan(
        cycle: cycle,
        now: DateTime(2025, 3, 17, 10),
        workedDays: const [],
        scheduleBlocks: const [],
        activeCheckIn: DateTime(2025, 3, 17, 8),
      );
      final result = WorkOptimizer.simulate(
        plan,
        OptimizerSimulationMode.onTime,
      );

      expect(result.days.single.workedMinutes, 5 * 60);
      expect(result.projectedTotalMinutes, 7 * 60);
    });
  });
}
