import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// Returns date-only (no time component).
  DateTime get dateOnly => DateTime(year, month, day);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isWeekend =>
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  bool get isWorkday => !isWeekend;

  String get formattedDate => DateFormat('EEE, d MMM yyyy').format(this);

  String get formattedDateShort => DateFormat('d MMM yyyy').format(this);

  String get formattedTime => DateFormat('HH:mm').format(this);

  String get formattedDateTime => DateFormat('d MMM, HH:mm').format(this);

  String get dayName => DateFormat('EEEE').format(this);

  String get monthName => DateFormat('MMMM yyyy').format(this);

  /// ISO-8601 date string without time (YYYY-MM-DD).
  String get isoDate => DateFormat('yyyy-MM-dd').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Monday of the week this date falls in.
  DateTime get weekStart {
    final diff = weekday - DateTime.monday;
    return dateOnly.subtract(Duration(days: diff));
  }

  /// Friday of the week this date falls in.
  DateTime get weekEnd => weekStart.add(const Duration(days: 4));

  /// Whether this date is within [start] and [end] inclusive.
  bool isBetween(DateTime start, DateTime end) =>
      !isBefore(start) && !isAfter(end);
}
