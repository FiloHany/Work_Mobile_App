import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/engine/hours_rule_engine.dart';
import 'package:work_app/core/constants/work_rules.dart';

void main() {
  // Fixed reference check-in: today at 08:00
  DateTime checkIn(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  DateTime checkOut(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  group('DayStatus classification', () {
    test('9 h → targetMet, +2 h credit', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(17, 0),
      );
      expect(r.status, DayStatus.targetMet);
      expect(r.workedDuration, const Duration(hours: 9));
      expect(r.creditEarned, const Duration(hours: 2));
      expect(r.deficit, Duration.zero);
      expect(r.isValid, isTrue);
    });

    test('5 h → validBelowTarget, 2 h deficit, no credit', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(13, 0),
      );
      expect(r.status, DayStatus.validBelowTarget);
      expect(r.workedDuration, const Duration(hours: 5));
      expect(r.creditEarned, Duration.zero);
      expect(r.deficit, const Duration(hours: 2));
      expect(r.isValid, isTrue);
      expect(r.isInsufficient, isFalse);
    });

    test('3 h → insufficient, no credit', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(11, 0),
      );
      expect(r.status, DayStatus.insufficient);
      expect(r.workedDuration, const Duration(hours: 3));
      expect(r.creditEarned, Duration.zero);
      expect(r.isValid, isFalse);
      expect(r.isInsufficient, isTrue);
    });

    test('exactly 4 h → validBelowTarget (minimum boundary)', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(12, 0),
      );
      expect(r.status, DayStatus.validBelowTarget);
      expect(r.isValid, isTrue);
    });

    test('exactly 7 h → targetMet, zero credit', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(15, 0),
      );
      expect(r.status, DayStatus.targetMet);
      expect(r.creditEarned, Duration.zero);
    });

    test('approved exception with 2 h → excused + valid', () {
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(10, 0),
        hasException: true,
      );
      expect(r.status, DayStatus.excused);
      expect(r.isValid, isTrue);
      expect(r.isInsufficient, isFalse);
    });
  });

  group('Earliest departure times', () {
    test('earliestValidDeparture = checkIn + 4 h', () {
      final ci = checkIn(8, 0);
      final r = HoursRuleEngine.analyseSession(checkIn: ci, checkOut: null);
      expect(r.earliestValidDeparture, ci.add(WorkRules.minimumValidDay));
    });

    test('earliestTargetDeparture = checkIn + 7 h', () {
      final ci = checkIn(8, 0);
      final r = HoursRuleEngine.analyseSession(checkIn: ci, checkOut: null);
      expect(r.earliestTargetDeparture, ci.add(WorkRules.standardDailyTarget));
    });

    test('2 h credit → earliestSafe = checkIn + 5 h', () {
      final ci = checkIn(8, 0);
      final r = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: null,
        availableCredit: const Duration(hours: 2),
      );
      // 7h - 2h credit = 5h required (above 4h minimum).
      expect(r.earliestSafeDeparture, ci.add(const Duration(hours: 5)));
    });

    test('credit exceeding 3 h cannot push stay below 4 h', () {
      final ci = checkIn(8, 0);
      // 10 h credit would mean 7h-10h = -3h, but must stay at least 4h.
      final r = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: null,
        availableCredit: const Duration(hours: 10),
      );
      expect(r.earliestSafeDeparture, ci.add(WorkRules.minimumValidDay));
    });

    test('3 h credit → earliestSafe = checkIn + 4 h (clamped at minimum)', () {
      final ci = checkIn(8, 0);
      // 7h - 3h = 4h exactly → exactly at minimum boundary.
      final r = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: null,
        availableCredit: const Duration(hours: 3),
      );
      expect(r.earliestSafeDeparture, ci.add(WorkRules.minimumValidDay));
    });
  });

  group('Credit and deficit accumulation', () {
    test('totalCreditFromDays sums credit across multiple days', () {
      final days = [
        (workedMinutes: 9 * 60, hasException: false), // +2h credit
        (workedMinutes: 8 * 60, hasException: false), // +1h credit
        (workedMinutes: 5 * 60, hasException: false), // no credit
      ];
      final credit = HoursRuleEngine.totalCreditFromDays(days);
      expect(credit, const Duration(hours: 3));
    });

    test('day under 4 h never becomes valid from credit alone', () {
      // Even with 10 h of accumulated credit, a 3-hour day is still insufficient
      // unless an exception is present.
      final r = HoursRuleEngine.analyseSession(
        checkIn: checkIn(8, 0),
        checkOut: checkOut(11, 0),
        availableCredit: const Duration(hours: 10),
        hasException: false,
      );
      expect(r.status, DayStatus.insufficient);
      expect(r.isValid, isFalse);
    });
  });

  group('Cycle summary', () {
    test('cycle summary aggregates correctly', () {
      final days = [
        (
          date: DateTime(2025, 1, 16),
          workedMinutes: 9 * 60,
          hasException: false
        ), // +2h
        (
          date: DateTime(2025, 1, 17),
          workedMinutes: 5 * 60,
          hasException: false
        ), // valid
        (
          date: DateTime(2025, 1, 18),
          workedMinutes: 3 * 60,
          hasException: false
        ), // insufficient
        (
          date: DateTime(2025, 1, 19),
          workedMinutes: 7 * 60,
          hasException: false
        ), // target met
      ];
      final summary = HoursRuleEngine.summariseCycle(
        days: days,
        workingDaysInCycle: 22,
        workingDaysRemaining: 18,
      );
      expect(summary.totalWorkedMinutes, (9 + 5 + 3 + 7) * 60);
      expect(summary.validDays, 3);
      expect(summary.insufficientDays, 1);
      expect(summary.totalCreditMinutes, 2 * 60); // only 9h day earns credit
    });

    test('weekly summary', () {
      final days = [
        (workedMinutes: 7 * 60, hasException: false),
        (workedMinutes: 5 * 60, hasException: false),
        (workedMinutes: 3 * 60, hasException: false), // insufficient
      ];
      final w = HoursRuleEngine.summariseWeek(
        days: days,
        workingDaysInWeek: 5,
      );
      expect(w.validDays, 2);
      expect(w.insufficientDays, 1);
      expect(w.totalWorked, const Duration(hours: 15));
      expect(w.remainingMinutes, (35 - 15) * 60);
    });

    test('cycle summary reports behind schedule when elapsed target is missed',
        () {
      final summary = HoursRuleEngine.summariseCycle(
        days: [
          (
            date: DateTime(2025, 1, 16),
            workedMinutes: 5 * 60,
            hasException: false
          ),
          (
            date: DateTime(2025, 1, 17),
            workedMinutes: 7 * 60,
            hasException: false
          ),
        ],
        workingDaysInCycle: 20,
        workingDaysRemaining: 18,
      );

      expect(summary.isOnTrack, isFalse);
    });

    test('cycle summary reports on track at or above elapsed target', () {
      final summary = HoursRuleEngine.summariseCycle(
        days: [
          (
            date: DateTime(2025, 1, 16),
            workedMinutes: 8 * 60,
            hasException: false
          ),
          (
            date: DateTime(2025, 1, 17),
            workedMinutes: 7 * 60,
            hasException: false
          ),
        ],
        workingDaysInCycle: 20,
        workingDaysRemaining: 18,
      );

      expect(summary.isOnTrack, isTrue);
    });
  });

  group('Edge cases', () {
    test('exactly 0 minutes worked → insufficient', () {
      final ci = checkIn(8, 0);
      final r = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: ci,
      );
      expect(r.status, DayStatus.insufficient);
      expect(r.workedDuration, Duration.zero);
    });

    test('recommendation text changes between states', () {
      final ci = checkIn(8, 0);
      final insufficient = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: ci.add(const Duration(hours: 3)),
      );
      expect(insufficient.recommendation, contains('Insufficient'));

      final valid = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: ci.add(const Duration(hours: 5)),
      );
      expect(valid.recommendation, contains('Valid'));

      final met = HoursRuleEngine.analyseSession(
        checkIn: ci,
        checkOut: ci.add(const Duration(hours: 7)),
      );
      expect(met.recommendation, contains('target'));
    });
  });
}
