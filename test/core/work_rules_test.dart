import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/constants/work_rules.dart';

void main() {
  // All times are local.
  DateTime localTime(int hour, int minute) {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  group('WorkRules.isBeforeCheckInDeadline', () {
    test('08:00 is before deadline', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(8, 0)), isTrue);
    });

    test('11:29 is before deadline', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(11, 29)), isTrue);
    });

    test('11:30 is exactly at deadline — still allowed', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(11, 30)), isTrue);
    });

    test('11:31 is past deadline — not allowed', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(11, 31)), isFalse);
    });

    test('12:00 is past deadline', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(12, 0)), isFalse);
    });

    test('23:59 is past deadline', () {
      expect(WorkRules.isBeforeCheckInDeadline(localTime(23, 59)), isFalse);
    });
  });

  group('WorkRules.checkInDeadlineFor', () {
    test('returns 11:30 on the given date', () {
      final date = DateTime(2026, 3, 20);
      final deadline = WorkRules.checkInDeadlineFor(date);
      expect(deadline.hour, WorkRules.maxCheckInHour);
      expect(deadline.minute, WorkRules.maxCheckInMinute);
      expect(deadline.second, 0);
      expect(deadline.year, 2026);
      expect(deadline.month, 3);
      expect(deadline.day, 20);
    });
  });
}
