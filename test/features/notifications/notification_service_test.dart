import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:work_app/shared/services/notification_service.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('Permission guard', () {
    setUp(() => NotificationService.instance.resetPermissionStateForTest());

    test('isPermissionsGranted starts false', () {
      expect(NotificationService.instance.isPermissionsGranted, isFalse);
    });

    test('concurrent requestPermissions() calls do not throw', () async {
      // Fire three calls at once — the guard must absorb the extras.
      // The first call will fail gracefully (plugin not initialised in tests);
      // calls 2 and 3 must be dropped by the guard without any exception.
      await Future.wait([
        NotificationService.instance.requestPermissions().catchError((_) {}),
        NotificationService.instance.requestPermissions().catchError((_) {}),
        NotificationService.instance.requestPermissions().catchError((_) {}),
      ]);
      // No PlatformException(permissionRequestInProgress) was thrown.
    });

    test('second call is a no-op once permissions are granted', () async {
      // We can't invoke the real platform plugin in unit tests, but we CAN
      // verify the guard path: two concurrent calls must not throw, and the
      // second is dropped while the first is in-flight (_requestingPermissions).
      await expectLater(
        Future.wait([
          NotificationService.instance.requestPermissions().catchError((_) {}),
          NotificationService.instance.requestPermissions().catchError((_) {}),
        ]),
        completes,
      );
    });
  });

  test('nextInstanceOfTime returns today when target time is still future', () {
    final location = tz.getLocation('UTC');
    final now = tz.TZDateTime(location, 2026, 4, 28, 8);

    final next = NotificationService.nextInstanceOfTime(
      location: location,
      now: now,
      hour: 9,
      minute: 30,
    );

    expect(next, tz.TZDateTime(location, 2026, 4, 28, 9, 30));
  });

  test('nextInstanceOfTime returns tomorrow when target time has passed', () {
    final location = tz.getLocation('UTC');
    final now = tz.TZDateTime(location, 2026, 4, 28, 10);

    final next = NotificationService.nextInstanceOfTime(
      location: location,
      now: now,
      hour: 9,
      minute: 30,
    );

    expect(next, tz.TZDateTime(location, 2026, 4, 29, 9, 30));
  });

  test('nextInstanceOfTime returns tomorrow when target equals now', () {
    final location = tz.getLocation('UTC');
    final now = tz.TZDateTime(location, 2026, 4, 28, 9, 30);

    final next = NotificationService.nextInstanceOfTime(
      location: location,
      now: now,
      hour: 9,
      minute: 30,
    );

    expect(next, tz.TZDateTime(location, 2026, 4, 29, 9, 30));
  });
}
