import '../constants/work_rules.dart';
import '../extensions/datetime_extensions.dart';
import '../extensions/duration_extensions.dart';
import 'work_cycle_calculator.dart';

enum OptimizerSimulationMode {
  onTime,
  checkIn30Late,
  checkIn60Late,
  checkOut60Late,
  minimumOnly;

  String get label => switch (this) {
        OptimizerSimulationMode.onTime => 'Follow optimizer',
        OptimizerSimulationMode.checkIn30Late => 'Check in 30m late',
        OptimizerSimulationMode.checkIn60Late => 'Check in 1h late',
        OptimizerSimulationMode.checkOut60Late => 'Check out 1h late',
        OptimizerSimulationMode.minimumOnly => 'Minimum only',
      };
}

class OptimizerScheduleBlock {
  const OptimizerScheduleBlock({
    required this.dayOfWeek,
    required this.startMinute,
    required this.endMinute,
  });

  /// 0 = Sunday, 1 = Monday ... 6 = Saturday.
  final int dayOfWeek;
  final int startMinute;
  final int endMinute;

  int get durationMinutes =>
      (endMinute - startMinute).clamp(0, 24 * 60).toInt();
}

class OptimizerWorkedDay {
  const OptimizerWorkedDay({
    required this.date,
    required this.workedMinutes,
  });

  final DateTime date;
  final int workedMinutes;
}

class DailyOptimization {
  const DailyOptimization({
    required this.date,
    required this.alreadyWorkedMinutes,
    required this.targetMinutes,
    required this.additionalMinutes,
    required this.scheduleMinutes,
    required this.scheduleSpanMinutes,
    required this.recommendedCheckIn,
    required this.recommendedCheckOut,
    required this.isToday,
    required this.isActive,
  });

  final DateTime date;
  final int alreadyWorkedMinutes;
  final int targetMinutes;
  final int additionalMinutes;
  final int scheduleMinutes;
  final int scheduleSpanMinutes;
  final DateTime recommendedCheckIn;
  final DateTime recommendedCheckOut;
  final bool isToday;
  final bool isActive;

  Duration get alreadyWorked => Duration(minutes: alreadyWorkedMinutes);
  Duration get target => Duration(minutes: targetMinutes);
  Duration get additional => Duration(minutes: additionalMinutes);
  Duration get scheduleTime => Duration(minutes: scheduleMinutes);
  Duration get scheduleSpan => Duration(minutes: scheduleSpanMinutes);

  bool get hasSchedule => scheduleMinutes > 0;
  bool get isValidIfCompleted =>
      targetMinutes >= WorkRules.minimumValidDay.inMinutes;
}

class WorkOptimizationPlan {
  const WorkOptimizationPlan({
    required this.cycle,
    required this.totalRequiredMinutes,
    required this.workedMinutes,
    required this.remainingRequiredMinutes,
    required this.plannedAdditionalMinutes,
    required this.projectedWorkedMinutes,
    required this.projectedSurplusMinutes,
    required this.days,
    required this.recommendation,
  });

  final WorkCycle cycle;
  final int totalRequiredMinutes;
  final int workedMinutes;
  final int remainingRequiredMinutes;
  final int plannedAdditionalMinutes;
  final int projectedWorkedMinutes;
  final int projectedSurplusMinutes;
  final List<DailyOptimization> days;
  final String recommendation;

  Duration get totalRequired => Duration(minutes: totalRequiredMinutes);
  Duration get worked => Duration(minutes: workedMinutes);
  Duration get remainingRequired => Duration(minutes: remainingRequiredMinutes);
  Duration get plannedAdditional => Duration(minutes: plannedAdditionalMinutes);
  Duration get projectedWorked => Duration(minutes: projectedWorkedMinutes);
  Duration get projectedSurplus => Duration(minutes: projectedSurplusMinutes);
  DailyOptimization? get today {
    for (final day in days) {
      if (day.isToday) return day;
    }
    return null;
  }

  bool get isCovered => projectedWorkedMinutes >= totalRequiredMinutes;
}

class OptimizerSimulationDay {
  const OptimizerSimulationDay({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.workedMinutes,
    required this.isValid,
  });

  final DateTime date;
  final DateTime checkIn;
  final DateTime checkOut;
  final int workedMinutes;
  final bool isValid;

  Duration get worked => Duration(minutes: workedMinutes);
}

class OptimizerSimulationResult {
  const OptimizerSimulationResult({
    required this.mode,
    required this.projectedTotalMinutes,
    required this.surplusMinutes,
    required this.shortfallMinutes,
    required this.validDays,
    required this.days,
  });

  final OptimizerSimulationMode mode;
  final int projectedTotalMinutes;
  final int surplusMinutes;
  final int shortfallMinutes;
  final int validDays;
  final List<OptimizerSimulationDay> days;

  Duration get projectedTotal => Duration(minutes: projectedTotalMinutes);
  Duration get surplus => Duration(minutes: surplusMinutes);
  Duration get shortfall => Duration(minutes: shortfallMinutes);
}

abstract final class WorkOptimizer {
  static WorkOptimizationPlan buildPlan({
    required WorkCycle cycle,
    required DateTime now,
    required List<OptimizerWorkedDay> workedDays,
    required List<OptimizerScheduleBlock> scheduleBlocks,
    DateTime? activeCheckIn,
    Set<int> extraRestWeekdays = const {},
    Set<DateTime> holidays = const {},
  }) {
    final today = now.dateOnly;
    final workedByDate = <DateTime, int>{};
    for (final day in workedDays) {
      final key = day.date.dateOnly;
      workedByDate[key] = (workedByDate[key] ?? 0) + day.workedMinutes;
    }

    if (activeCheckIn != null) {
      final activeDate = activeCheckIn.toLocal().dateOnly;
      final activeWorked = now.difference(activeCheckIn).nonNegative.inMinutes;
      workedByDate[activeDate] = (workedByDate[activeDate] ?? 0) + activeWorked;
    }

    final allCycleDays = WorkCycleCalculator.workingDaysBetween(
      start: cycle.start,
      end: cycle.end,
      extraRestWeekdays: extraRestWeekdays,
      holidays: holidays,
    );
    final totalRequired =
        allCycleDays.length * WorkRules.standardDailyTarget.inMinutes;
    final worked = workedByDate.values.fold<int>(0, (sum, m) => sum + m);
    final remainingRequired =
        (totalRequired - worked).clamp(0, totalRequired).toInt();

    final remainingDates = allCycleDays.where((day) {
      if (day.isBefore(today)) return false;
      final hasCompletedToday = day.isSameDay(today) &&
          workedDays.any((d) => d.date.isSameDay(today));
      final hasActiveToday =
          activeCheckIn != null && activeCheckIn.toLocal().isSameDay(day);
      return !hasCompletedToday || hasActiveToday;
    }).toList();

    if (remainingDates.isEmpty) {
      return WorkOptimizationPlan(
        cycle: cycle,
        totalRequiredMinutes: totalRequired,
        workedMinutes: worked,
        remainingRequiredMinutes: remainingRequired,
        plannedAdditionalMinutes: 0,
        projectedWorkedMinutes: worked,
        projectedSurplusMinutes:
            (worked - totalRequired).clamp(0, worked).toInt(),
        days: const [],
        recommendation: remainingRequired == 0
            ? 'Cycle target is already covered.'
            : 'No remaining workdays in this cycle.',
      );
    }

    final specs = remainingDates
        .map((date) => _DaySpec.from(
              date: date,
              now: now,
              alreadyWorked: workedByDate[date] ?? 0,
              scheduleBlocks: scheduleBlocks,
              activeCheckIn: activeCheckIn,
            ))
        .toList();

    final minAdditional = specs.fold<int>(0, (sum, d) => sum + d.minAdditional);
    final plannedAdditional = remainingRequired == 0
        ? specs.fold<int>(0, (sum, d) => sum + d.activeMinimumAdditional)
        : remainingRequired.clamp(minAdditional, 1000000).toInt();
    final extraPool = plannedAdditional - minAdditional;
    final allocatedExtra = _allocateExtra(specs, extraPool);

    final days = <DailyOptimization>[];
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final additional = spec.minAdditional + allocatedExtra[i];
      final targetMinutes = spec.alreadyWorked + additional;
      final checkIn = spec.effectiveCheckIn;
      final checkOut = checkIn.add(Duration(minutes: targetMinutes));
      final scheduleEnd = spec.scheduleEnd == null
          ? checkOut
          : spec.date.add(Duration(minutes: spec.scheduleEnd!));
      final scheduledOrTargetCheckOut =
          checkOut.isBefore(scheduleEnd) ? scheduleEnd : checkOut;
      final recommendedCheckOut =
          scheduledOrTargetCheckOut.isBefore(now) && spec.isActive
              ? now
              : scheduledOrTargetCheckOut;
      final effectiveTarget = recommendedCheckOut
          .difference(checkIn)
          .inMinutes
          .clamp(0, 1000000)
          .toInt();

      days.add(DailyOptimization(
        date: spec.date,
        alreadyWorkedMinutes: spec.alreadyWorked,
        targetMinutes: effectiveTarget,
        additionalMinutes: (effectiveTarget - spec.alreadyWorked)
            .clamp(0, effectiveTarget)
            .toInt(),
        scheduleMinutes: spec.scheduleMinutes,
        scheduleSpanMinutes: spec.scheduleSpanMinutes,
        recommendedCheckIn: checkIn,
        recommendedCheckOut: recommendedCheckOut,
        isToday: spec.date.isSameDay(today),
        isActive: spec.isActive,
      ));
    }

    final effectivePlannedAdditional =
        days.fold<int>(0, (sum, day) => sum + day.additionalMinutes);
    final projectedWorked = worked + effectivePlannedAdditional;
    final projectedSurplus =
        (projectedWorked - totalRequired).clamp(0, projectedWorked).toInt();

    return WorkOptimizationPlan(
      cycle: cycle,
      totalRequiredMinutes: totalRequired,
      workedMinutes: worked,
      remainingRequiredMinutes: remainingRequired,
      plannedAdditionalMinutes: effectivePlannedAdditional,
      projectedWorkedMinutes: projectedWorked,
      projectedSurplusMinutes: projectedSurplus,
      days: days,
      recommendation: _recommendation(
        remainingRequired: remainingRequired,
        plannedAdditional: effectivePlannedAdditional,
        projectedSurplus: projectedSurplus,
        today: _firstToday(days),
      ),
    );
  }

  static OptimizerSimulationResult simulate(
    WorkOptimizationPlan plan,
    OptimizerSimulationMode mode,
  ) {
    final days = plan.days.map((day) {
      final minimum = WorkRules.minimumValidDay.inMinutes;
      final target = switch (mode) {
        OptimizerSimulationMode.minimumOnly => minimum,
        OptimizerSimulationMode.checkOut60Late => day.targetMinutes + 60,
        _ => day.targetMinutes,
      };
      final checkInDelay = switch (mode) {
        OptimizerSimulationMode.checkIn30Late => 30,
        OptimizerSimulationMode.checkIn60Late => 60,
        _ => 0,
      };
      final checkIn =
          day.recommendedCheckIn.add(Duration(minutes: checkInDelay));
      final checkOut = checkIn.add(Duration(minutes: target));
      final additional =
          (target - day.alreadyWorkedMinutes).clamp(0, target).toInt();
      return OptimizerSimulationDay(
        date: day.date,
        checkIn: checkIn,
        checkOut: checkOut,
        workedMinutes: additional,
        isValid: target >= minimum,
      );
    }).toList();

    final simulatedAdditional =
        days.fold<int>(0, (sum, day) => sum + day.workedMinutes);
    final projectedTotal = plan.workedMinutes + simulatedAdditional;
    final surplus = (projectedTotal - plan.totalRequiredMinutes)
        .clamp(0, projectedTotal)
        .toInt();
    final shortfall = (plan.totalRequiredMinutes - projectedTotal)
        .clamp(0, plan.totalRequiredMinutes)
        .toInt();

    return OptimizerSimulationResult(
      mode: mode,
      projectedTotalMinutes: projectedTotal,
      surplusMinutes: surplus,
      shortfallMinutes: shortfall,
      validDays: days.where((day) => day.isValid).length,
      days: days,
    );
  }

  static List<int> _allocateExtra(List<_DaySpec> specs, int extraPool) {
    if (extraPool <= 0) return List.filled(specs.length, 0);

    final weights = specs.map((s) => s.weight).toList();
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    if (totalWeight <= 0) {
      final base = extraPool ~/ specs.length;
      final allocations = List.filled(specs.length, base);
      for (var i = 0; i < extraPool - (base * specs.length); i++) {
        allocations[i] += 1;
      }
      return allocations;
    }

    final allocations = <int>[];
    var used = 0;
    for (var i = 0; i < specs.length; i++) {
      final value = (extraPool * weights[i]) ~/ totalWeight;
      allocations.add(value);
      used += value;
    }

    var cursor = 0;
    while (used < extraPool) {
      allocations[cursor % allocations.length] += 1;
      used++;
      cursor++;
    }
    return allocations;
  }

  static String _recommendation({
    required int remainingRequired,
    required int plannedAdditional,
    required int projectedSurplus,
    required DailyOptimization? today,
  }) {
    if (remainingRequired == 0 && plannedAdditional == 0) {
      return 'Your cycle target is already covered.';
    }
    if (today != null && today.isActive) {
      final left = today.additionalMinutes;
      if (left == 0) return 'You can check out now and stay on plan.';
      return 'Work ${Duration(minutes: left).formatted} more today; planned checkout is ${today.recommendedCheckOut.formattedTime}.';
    }
    if (today != null) {
      return 'Start at ${today.recommendedCheckIn.formattedTime} and work ${today.target.formatted} today.';
    }
    if (projectedSurplus > 0) {
      return 'Minimum/schedule constraints create ${Duration(minutes: projectedSurplus).formatted} projected surplus.';
    }
    return 'Follow the daily plan to cover the remaining cycle target.';
  }

  static DailyOptimization? _firstToday(List<DailyOptimization> days) {
    for (final day in days) {
      if (day.isToday) return day;
    }
    return null;
  }
}

class _DaySpec {
  const _DaySpec({
    required this.date,
    required this.alreadyWorked,
    required this.scheduleMinutes,
    required this.scheduleSpanMinutes,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.minAdditional,
    required this.activeMinimumAdditional,
    required this.weight,
    required this.effectiveCheckIn,
    required this.isActive,
  });

  final DateTime date;
  final int alreadyWorked;
  final int scheduleMinutes;
  final int scheduleSpanMinutes;
  final int? scheduleStart;
  final int? scheduleEnd;
  final int minAdditional;
  final int activeMinimumAdditional;
  final int weight;
  final DateTime effectiveCheckIn;
  final bool isActive;

  factory _DaySpec.from({
    required DateTime date,
    required DateTime now,
    required int alreadyWorked,
    required List<OptimizerScheduleBlock> scheduleBlocks,
    required DateTime? activeCheckIn,
  }) {
    final dbDow = date.weekday == DateTime.sunday ? 0 : date.weekday;
    final blocks = scheduleBlocks.where((b) => b.dayOfWeek == dbDow).toList();
    final scheduleMinutes =
        blocks.fold<int>(0, (sum, block) => sum + block.durationMinutes);
    final scheduleStart = blocks.isEmpty
        ? null
        : blocks.map((b) => b.startMinute).reduce((a, b) => a < b ? a : b);
    final scheduleEnd = blocks.isEmpty
        ? null
        : blocks.map((b) => b.endMinute).reduce((a, b) => a > b ? a : b);
    final scheduleSpan = scheduleStart == null || scheduleEnd == null
        ? 0
        : scheduleEnd - scheduleStart;
    final dayMinimum = [
      WorkRules.minimumValidDay.inMinutes,
      scheduleSpan,
    ].reduce((a, b) => a > b ? a : b);
    final minAdditional =
        (dayMinimum - alreadyWorked).clamp(0, dayMinimum).toInt();
    final activeMinimumAdditional =
        activeCheckIn != null && activeCheckIn.toLocal().isSameDay(date)
            ? minAdditional
            : 0;
    final plannedStart = scheduleStart ?? 8 * 60;
    final scheduledCheckIn = date.add(Duration(minutes: plannedStart));
    final isToday = date.isSameDay(now);
    final isActive =
        activeCheckIn != null && activeCheckIn.toLocal().isSameDay(date);
    final effectiveCheckIn = isActive
        ? activeCheckIn.toLocal()
        : isToday && now.isAfter(scheduledCheckIn)
            ? now
            : scheduledCheckIn;

    return _DaySpec(
      date: date,
      alreadyWorked: alreadyWorked,
      scheduleMinutes: scheduleMinutes,
      scheduleSpanMinutes: scheduleSpan.clamp(0, 24 * 60).toInt(),
      scheduleStart: scheduleStart,
      scheduleEnd: scheduleEnd,
      minAdditional: minAdditional,
      activeMinimumAdditional: activeMinimumAdditional,
      weight: scheduleMinutes > 0
          ? scheduleMinutes
          : WorkRules.standardDailyTarget.inMinutes,
      effectiveCheckIn: effectiveCheckIn,
      isActive: isActive,
    );
  }
}
