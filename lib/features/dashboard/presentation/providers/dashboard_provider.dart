import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/holidays_provider.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardData {
  const DashboardData({
    required this.cycle,
    required this.cycleSummary,
    required this.weeklySummary,
    required this.availableCredit,
    required this.workingDaysInCycle,
    required this.workingDaysRemaining,
  });

  final WorkCycle cycle;
  final CycleSummary cycleSummary;
  final WeeklySummary weeklySummary;
  final Duration availableCredit;
  final int workingDaysInCycle;
  final int workingDaysRemaining;
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final profile = ref.watch(profileProvider);
  final userId = profile?.id;
  if (userId == null) throw const AuthException('Not authenticated');

  final extraRest = profile?.restDays.toSet() ?? <int>{};
  final holidaysAsync = ref.watch(holidaysProvider);
  final holidays =
      holidaysAsync.maybeWhen(data: (h) => h.dates, orElse: () => <DateTime>{});

  final repo = ref.read(attendanceRepositoryProvider);
  final cycle = WorkCycleCalculator.currentCycle();
  final week = WorkCycleCalculator.currentWeek();

  final workingDaysTotal = WorkCycleCalculator.countWorkingDays(
    start: cycle.start,
    end: cycle.end,
    extraRestWeekdays: extraRest,
    holidays: holidays,
  );
  final workingDaysRemaining = WorkCycleCalculator.remainingWorkingDays(
    cycle: cycle,
    extraRestWeekdays: extraRest,
    holidays: holidays,
  );

  final cycleSummaries = await repo.fetchSummaries(
    userId: userId,
    cycleStart: cycle.start,
    cycleEnd: cycle.end,
  );

  final credit = await repo.fetchAvailableCredit(
    userId: userId,
    cycleStart: cycle.start,
  );

  final cycleDays = cycleSummaries
      .map((s) => (
            date: s.summaryDate,
            workedMinutes: s.totalWorkedMinutes,
            hasException: s.hasApprovedException,
          ))
      .toList();

  final cycleResult = HoursRuleEngine.summariseCycle(
    days: cycleDays,
    workingDaysInCycle: workingDaysTotal,
    workingDaysRemaining: workingDaysRemaining,
  );

  final thisWeekDays = cycleSummaries.where((s) {
    return !s.summaryDate.isBefore(week.start) &&
        !s.summaryDate.isAfter(week.end);
  }).toList();

  final workingDaysInWeek = WorkCycleCalculator.countWorkingDays(
    start: week.start,
    end: week.end,
    extraRestWeekdays: extraRest,
    holidays: holidays,
  );

  final weekResult = HoursRuleEngine.summariseWeek(
    days: thisWeekDays
        .map((s) => (
              workedMinutes: s.totalWorkedMinutes,
              hasException: s.hasApprovedException,
            ))
        .toList(),
    workingDaysInWeek: workingDaysInWeek,
  );

  return DashboardData(
    cycle: cycle,
    cycleSummary: cycleResult,
    weeklySummary: weekResult,
    availableCredit: credit,
    workingDaysInCycle: workingDaysTotal,
    workingDaysRemaining: workingDaysRemaining,
  );
});
