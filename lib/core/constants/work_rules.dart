/// Central source of truth for all business rules.
/// Change here to affect the entire app.
abstract final class WorkRules {
  /// Minimum hours for a day to count as valid attendance.
  static const Duration minimumValidDay = Duration(hours: 4);

  /// Standard daily target hours.
  static const Duration standardDailyTarget = Duration(hours: 7);

  /// Latest allowed check-in time (hour component, 24-h).
  static const int maxCheckInHour = 11;

  /// Latest allowed check-in time (minute component).
  static const int maxCheckInMinute = 30;

  /// Returns true if [time] is at or before the 11:30 check-in deadline.
  static bool isBeforeCheckInDeadline(DateTime time) {
    final local = time.toLocal();
    return local.hour < maxCheckInHour ||
        (local.hour == maxCheckInHour && local.minute <= maxCheckInMinute);
  }

  /// The check-in deadline on [date] as a local DateTime (11:30:00).
  static DateTime checkInDeadlineFor(DateTime date) {
    final d = date.toLocal();
    return DateTime(d.year, d.month, d.day, maxCheckInHour, maxCheckInMinute);
  }

  /// Standard weekly target (5 days × 7 h).
  static const Duration standardWeeklyTarget = Duration(hours: 35);

  /// Work cycle: starts on this day of month.
  static const int cycleStartDay = 16;

  /// Work cycle: ends on this day of month.
  static const int cycleEndDay = 15;

  /// Standard work week days (Sun–Thu + Sat; only Friday is the fixed rest day).
  static const Set<int> workWeekDays = {
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.saturday,
  };

  /// Minutes per hour — used to convert between representations.
  static const int minutesPerHour = 60;

  /// Cycle warning threshold: days before cycle end to warn user.
  static const int cycleEndWarningDays = 3;
}
