import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/errors/app_exception.dart';
import 'package:work_app/features/notifications/presentation/providers/notification_preferences_provider.dart';

void main() {
  test('normalizes database time values to HH:mm', () {
    final prefs = NotificationPrefs.fromJson({
      'arrival_reminder_time': '8:05:00',
      'departure_reminder_time': '17:45:00',
    });

    expect(prefs.arrivalReminderTime, '08:05');
    expect(prefs.departureReminderTime, '17:45');
  });

  test('falls back when database time values are invalid', () {
    final prefs = NotificationPrefs.fromJson({
      'arrival_reminder_time': 'not-a-time',
      'departure_reminder_time': '25:00:00',
    });

    expect(prefs.arrivalReminderTime, '08:00');
    expect(prefs.departureReminderTime, '14:30');
  });

  test('parseReminderTime validates HH:mm values', () {
    expect(parseReminderTime('09:30'), (hour: 9, minute: 30));
    expect(
      () => parseReminderTime('9:30'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => parseReminderTime('24:00'),
      throwsA(isA<ValidationException>()),
    );
  });
}
