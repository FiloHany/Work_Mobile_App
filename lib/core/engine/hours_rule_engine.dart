import '../constants/work_rules.dart';
import '../extensions/datetime_extensions.dart';
import '../extensions/duration_extensions.dart';

// ─────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────

enum DayStatus { insufficient, validBelowTarget, targetMet, excused }

class DailyCalculationResult {
  const DailyCalculationResult({
    required this.status,
    required this.workedDuration,
    required this.creditEarned,
    required this.deficit,
    required this.earliestValidDeparture,
    required this.earliestTargetDeparture,
    required this.earliestSafeDeparture,
    required this.recommendation,
    required this.canLeaveNow,
  });

  final DayStatus status;
  final Duration workedDuration;

  /// Extra hours beyond 7 h standard — added to the credit pool.
  final Duration creditEarned;

  /// Hours below 7 h standard — does NOT reduce credit pool.
  final Duration deficit;

  /// Earliest checkout for a day to count as valid (check-in + 4 h).
  final DateTime? earliestValidDeparture;

  /// Earliest checkout to meet the 7 h standard (check-in + 7 h).
  final DateTime? earliestTargetDeparture;

  /// Earliest checkout when available credit is applied
  /// (never earlier than check-in + 4 h).
  final DateTime? earliestSafeDeparture;

  final String recommendation;
  final bool canLeaveNow;

  bool get isValid =>
      status == DayStatus.validBelowTarget ||
      status == DayStatus.targetMet ||
      status == DayStatus.excused;

  bool get isInsufficient => status == DayStatus.insufficient;
  bool get isTargetMet => status == DayStatus.targetMet;
}

class CycleSummary {
  const CycleSummary({
    required this.totalWorkedMinutes,
    required this.totalRequiredMinutes,
    required this.totalCreditMinutes,
    required this.totalDeficitMinutes,
    required this.validDays,
    required this.insufficientDays,
    required this.workingDaysInCycle,
    required this.workingDaysPassed,
    required this.workingDaysRemaining,
    required this.isOnTrack,
  });

  final int totalWorkedMinutes;
  final int totalRequiredMinutes;
  final int totalCreditMinutes;
  final int totalDeficitMinutes;
  final int validDays;
  final int insufficientDays;
  final int workingDaysInCycle;
  final int workingDaysPassed;
  final int workingDaysRemaining;
  final bool isOnTrack;

  Duration get totalWorked => Duration(minutes: totalWorkedMinutes);
  Duration get totalRequired => Duration(minutes: totalRequiredMinutes);
  Duration get totalCredit => Duration(minutes: totalCreditMinutes);
  Duration get totalDeficit => Duration(minutes: totalDeficitMinutes);

  int get remainingMinutes => (totalRequiredMinutes - totalWorkedMinutes)
      .clamp(0, totalRequiredMinutes);

  double get progressPercent => totalRequiredMinutes == 0
      ? 0
      : (totalWorkedMinutes / totalRequiredMinutes).clamp(0.0, 1.0);
}

class WeeklySummary {
  const WeeklySummary({
    required this.totalWorkedMinutes,
    required this.workingDaysInWeek,
    required this.validDays,
    required this.insufficientDays,
  });

  final int totalWorkedMinutes;
  final int workingDaysInWeek;
  final int validDays;
  final int insufficientDays;

  Duration get totalWorked => Duration(minutes: totalWorkedMinutes);
  Duration get weeklyTarget => workingDaysInWeek == 0
      ? Duration.zero
      : Duration(
          minutes: workingDaysInWeek * WorkRules.standardDailyTarget.inMinutes);

  int get remainingMinutes {
    final target = weeklyTarget.inMinutes;
    return (target - totalWorkedMinutes).clamp(0, target > 0 ? target : 0);
  }

  double get progressPercent {
    final target = weeklyTarget.inMinutes;
    if (target == 0) return 0;
    return (totalWorkedMinutes / target).clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────
// Engine — pure Dart, zero Flutter dependencies
// ─────────────────────────────────────────────

/// Core business-rule engine for attendance and hours calculations.
///
/// All methods are static and side-effect free. Pass in data; get results back.
/// Tests can call this directly without mocking anything.
abstract final class HoursRuleEngine {
  // ── Active-session analysis ──────────────────────────────────────────────

  /// Analyse an ongoing or completed session.
  ///
  /// [checkIn]          — recorded check-in timestamp.
  /// [checkOut]         — recorded check-out (null means still checked in).
  /// [availableCredit]  — accumulated credit from previous days *in this cycle*.
  /// [hasException]     — admin-approved exception overrides the 4 h minimum.
  /// Rounds a time up (ceil) to the nearest 15-minute boundary.
  /// e.g. 8:01 → 8:15, 8:15 → 8:15, 8:30 → 8:30, 8:31 → 8:45.
  static DateTime _roundUpToQuarter(DateTime t) {
    final dayStart = DateTime(t.year, t.month, t.day);
    final elapsedMs = t.difference(dayStart).inMilliseconds;
    const boundaryMs = 15 * 60 * 1000;
    final rem = elapsedMs % boundaryMs;
    if (rem == 0) return t;
    return dayStart.add(Duration(milliseconds: elapsedMs - rem + boundaryMs));
  }

  /// Check-in rounds UP: 8:01 → 8:15, 8:52 → 9:00.
  static DateTime roundCheckIn(DateTime checkIn) => _roundUpToQuarter(checkIn);

  /// Check-out rounds UP: 16:46 → 17:00, 16:45 → 16:45.
  static DateTime roundCheckOut(DateTime checkOut) =>
      _roundUpToQuarter(checkOut);

  static DailyCalculationResult analyseSession({
    required DateTime checkIn,
    required DateTime? checkOut,
    Duration availableCredit = Duration.zero,
    bool hasException = false,
    bool isHoliday = false,
  }) {
    final effectiveCheckIn = roundCheckIn(checkIn);
    final effectiveNow =
        checkOut != null ? roundCheckOut(checkOut) : DateTime.now();
    final worked = effectiveNow.difference(effectiveCheckIn).nonNegative;

    // On a public holiday no hours are required; all worked time becomes credit.
    if (isHoliday) {
      final rec = checkOut != null
          ? 'Public holiday — ${worked.formatted} worked, all counted as time credit.'
          : 'Today is a public holiday. Any hours worked count as credit. You may leave at any time.';
      return DailyCalculationResult(
        status: DayStatus.excused,
        workedDuration: worked,
        creditEarned: worked,
        deficit: Duration.zero,
        earliestValidDeparture: null,
        earliestTargetDeparture: null,
        earliestSafeDeparture: null,
        recommendation: rec,
        canLeaveNow: checkOut == null,
      );
    }

    final creditEarned = _creditEarned(worked);
    final deficit = _deficit(worked);
    final status = _dayStatus(worked, hasException);

    final earliestValid = effectiveCheckIn.add(WorkRules.minimumValidDay);
    final earliestTarget = effectiveCheckIn.add(WorkRules.standardDailyTarget);
    final earliestSafe = _earliestSafe(effectiveCheckIn, availableCredit);

    final isSessionOpen = checkOut == null;
    final now = DateTime.now();
    final canLeaveNow = isSessionOpen &&
        (hasException ||
            now.isAfter(earliestSafe) ||
            now.isAtSameMomentAs(earliestSafe));

    final recommendation = _buildRecommendation(
      worked: worked,
      status: status,
      checkOut: checkOut,
      availableCredit: availableCredit,
      earliestValid: earliestValid,
      earliestTarget: earliestTarget,
      earliestSafe: earliestSafe,
      hasException: hasException,
    );

    return DailyCalculationResult(
      status: status,
      workedDuration: worked,
      creditEarned: creditEarned,
      deficit: deficit,
      earliestValidDeparture: earliestValid,
      earliestTargetDeparture: earliestTarget,
      earliestSafeDeparture: earliestSafe,
      recommendation: recommendation,
      canLeaveNow: canLeaveNow,
    );
  }

  // ── Cycle summary ────────────────────────────────────────────────────────

  /// Aggregate a list of daily worked-minute records into a cycle summary.
  ///
  /// [dailyWorkedMinutes]  — list of worked minutes per working day attended.
  /// [dailyExceptions]     — set of dates that have admin exceptions.
  /// [workingDaysInCycle]  — total working days the cycle contains.
  /// [workingDaysRemaining]— working days left including today.
  static CycleSummary summariseCycle({
    required List<({DateTime date, int workedMinutes, bool hasException})> days,
    required int workingDaysInCycle,
    required int workingDaysRemaining,
  }) {
    int totalWorked = 0;
    int totalCredit = 0;
    int totalDeficit = 0;
    int validDays = 0;
    int insufficientDays = 0;

    for (final d in days) {
      totalWorked += d.workedMinutes;
      final worked = Duration(minutes: d.workedMinutes);
      final status = _dayStatus(worked, d.hasException);

      if (status == DayStatus.insufficient) {
        insufficientDays++;
      } else {
        validDays++;
      }

      totalCredit += _creditEarned(worked).inMinutes;
      if (status != DayStatus.excused) {
        totalDeficit += _deficit(worked).inMinutes;
      }
    }

    final totalRequired =
        WorkRules.standardDailyTarget.inMinutes * workingDaysInCycle;

    // On-track means recorded work is at least the target for elapsed workdays.
    // `workingDaysRemaining` includes today, so this intentionally avoids
    // marking a user behind before today's session has had a chance to happen.
    final elapsedWorkingDays = (workingDaysInCycle - workingDaysRemaining)
        .clamp(0, workingDaysInCycle)
        .toInt();
    final requiredSoFar =
        WorkRules.standardDailyTarget.inMinutes * elapsedWorkingDays;
    final isOnTrack = totalWorked >= requiredSoFar;

    return CycleSummary(
      totalWorkedMinutes: totalWorked,
      totalRequiredMinutes: totalRequired,
      totalCreditMinutes: totalCredit,
      totalDeficitMinutes: totalDeficit,
      validDays: validDays,
      insufficientDays: insufficientDays,
      workingDaysInCycle: workingDaysInCycle,
      workingDaysPassed: days.length,
      workingDaysRemaining: workingDaysRemaining,
      isOnTrack: isOnTrack,
    );
  }

  // ── Weekly summary ───────────────────────────────────────────────────────

  static WeeklySummary summariseWeek({
    required List<({int workedMinutes, bool hasException})> days,
    required int workingDaysInWeek,
  }) {
    int totalWorked = 0;
    int validDays = 0;
    int insufficientDays = 0;

    for (final d in days) {
      totalWorked += d.workedMinutes;
      final status =
          _dayStatus(Duration(minutes: d.workedMinutes), d.hasException);
      if (status == DayStatus.insufficient) {
        insufficientDays++;
      } else {
        validDays++;
      }
    }

    return WeeklySummary(
      totalWorkedMinutes: totalWorked,
      workingDaysInWeek: workingDaysInWeek,
      validDays: validDays,
      insufficientDays: insufficientDays,
    );
  }

  // ── Credit pool ──────────────────────────────────────────────────────────

  /// How much credit is accumulated across all [days] in a cycle.
  static Duration totalCreditFromDays(
    List<({int workedMinutes, bool hasException})> days,
  ) {
    int minutes = 0;
    for (final d in days) {
      minutes += _creditEarned(Duration(minutes: d.workedMinutes)).inMinutes;
    }
    return Duration(minutes: minutes);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static Duration _creditEarned(Duration worked) {
    final extra = worked - WorkRules.standardDailyTarget;
    return extra.isNegative ? Duration.zero : extra;
  }

  static Duration _deficit(Duration worked) {
    if (worked >= WorkRules.standardDailyTarget) return Duration.zero;
    final d = WorkRules.standardDailyTarget - worked;
    return d.nonNegative;
  }

  static DayStatus _dayStatus(Duration worked, bool hasException) {
    if (hasException) return DayStatus.excused;
    if (worked >= WorkRules.standardDailyTarget) return DayStatus.targetMet;
    if (worked >= WorkRules.minimumValidDay) return DayStatus.validBelowTarget;
    return DayStatus.insufficient;
  }

  /// Earliest safe departure: reduce target by available credit,
  /// but NEVER below the 4-hour minimum.
  static DateTime _earliestSafe(DateTime checkIn, Duration availableCredit) {
    final reduced = WorkRules.standardDailyTarget - availableCredit;
    final target = reduced < WorkRules.minimumValidDay
        ? WorkRules.minimumValidDay
        : reduced;
    return checkIn.add(target);
  }

  static String _buildRecommendation({
    required Duration worked,
    required DayStatus status,
    required DateTime? checkOut,
    required Duration availableCredit,
    required DateTime earliestValid,
    required DateTime earliestTarget,
    required DateTime earliestSafe,
    required bool hasException,
  }) {
    final now = DateTime.now();

    // ── Session closed ──────────────────────────────────────────────────────
    if (checkOut != null) {
      switch (status) {
        case DayStatus.targetMet:
          final credit = _creditEarned(worked);
          return credit.isZero
              ? 'Daily target of 7 h met. Great work!'
              : 'Daily target met. +${credit.formatted} added to your credit balance.';
        case DayStatus.validBelowTarget:
          return 'Valid day. −${_deficit(worked).formatted} added to your credit debt.';
        case DayStatus.excused:
          return 'Day marked as valid by an approved exception.';
        case DayStatus.insufficient:
          return 'Insufficient day — less than 4 h logged. Submit a correction request if this is incorrect.';
      }
    }

    // ── Session open (currently checked in) ────────────────────────────────
    if (hasException) {
      return 'Approved exception active. You may leave at any time.';
    }

    // Credit debt: need to work beyond the standard 7 h target today.
    if (availableCredit.isNegative) {
      final debt = -availableCredit;
      if (!now.isBefore(earliestSafe)) {
        return 'Daily target met — you\'ve made up the ${debt.formatted} credit debt. '
            'You can check out whenever you are ready.';
      }
      final toSafe = earliestSafe.difference(now);
      return 'You have a ${debt.formatted} credit debt from previous short days. '
          'Stay until ${earliestSafe.formattedTime} to cover it '
          '(${toSafe.formatted} remaining).';
    }

    final canLeaveEarly = availableCredit > Duration.zero &&
        earliestSafe.isBefore(earliestTarget);

    if (!now.isBefore(earliestTarget)) {
      return 'Daily target met. You can check out whenever you are ready.';
    }

    if (canLeaveEarly) {
      if (!now.isBefore(earliestSafe)) {
        return 'Your time credit covers today\'s remaining requirement. You can leave now.';
      }
      final timeLeft = earliestSafe.difference(now);
      return 'With ${availableCredit.formatted} credit, you can leave at ${earliestSafe.formattedTime} (${timeLeft.formatted} from now). Full target at ${earliestTarget.formattedTime}.';
    }

    if (!now.isBefore(earliestValid)) {
      final toTarget = earliestTarget.difference(now);
      return 'Minimum stay reached. ${toTarget.formatted} to full daily target at ${earliestTarget.formattedTime}.';
    }

    final toValid = earliestValid.difference(now);
    return '${toValid.formatted} to minimum valid stay (${earliestValid.formattedTime}). Full target at ${earliestTarget.formattedTime}.';
  }
}
