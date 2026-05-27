import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/features/attendance/domain/entities/attendance_session.dart';

void main() {
  test('timestamptz fields parse to local time and serialize as UTC', () {
    final checkInUtc = DateTime.utc(2026, 4, 28, 6);
    final checkOutUtc = DateTime.utc(2026, 4, 28, 14, 30);

    final session = AttendanceSession.fromJson({
      'id': 'session-1',
      'user_id': 'user-1',
      'session_date': '2026-04-28',
      'check_in_time': checkInUtc.toIso8601String(),
      'check_out_time': checkOutUtc.toIso8601String(),
      'total_minutes': 510,
      'status': 'completed',
    });

    expect(session.checkInTime, checkInUtc.toLocal());
    expect(session.checkOutTime, checkOutUtc.toLocal());
    expect(session.toJson()['check_in_time'], checkInUtc.toIso8601String());
    expect(session.toJson()['check_out_time'], checkOutUtc.toIso8601String());
  });
}
