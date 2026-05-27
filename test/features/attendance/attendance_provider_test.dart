import 'package:flutter_test/flutter_test.dart';
import 'package:work_app/core/engine/work_cycle_calculator.dart';
import 'package:work_app/core/errors/app_exception.dart';
import 'package:work_app/features/attendance/data/models/daily_summary_model.dart';
import 'package:work_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:work_app/features/attendance/domain/entities/attendance_session.dart';
import 'package:work_app/features/attendance/presentation/providers/attendance_provider.dart';

void main() {
  const userId = 'user-1';

  test('initial load restores active session and available credit', () async {
    final active = _session();
    final repo = _FakeAttendanceRepository(
      activeSessionResult: active,
      credit: const Duration(hours: 2),
    );

    final notifier = AttendanceNotifier(repo, userId);
    await pumpEventQueue();

    expect(notifier.state.activeSession, active);
    expect(notifier.state.availableCredit, const Duration(hours: 2));
    expect(notifier.state.todayResult, isNotNull);
  });

  test('check-in is blocked when state already has an active session',
      () async {
    final repo = _FakeAttendanceRepository(activeSessionResult: _session());
    final notifier = AttendanceNotifier(repo, userId);
    await pumpEventQueue();

    final ok = await notifier.checkIn();

    expect(ok, isFalse);
    expect(repo.checkInCalls, 0);
    expect(notifier.state.error, contains('already checked in'));
  });

  test('check-out without an active session fails visibly', () async {
    final repo = _FakeAttendanceRepository();
    final notifier = AttendanceNotifier(repo, userId);
    await pumpEventQueue();

    final ok = await notifier.checkOut();

    expect(ok, isFalse);
    expect(repo.checkOutCalls, 0);
    expect(notifier.state.error, contains('No active attendance session'));
  });

  test('successful check-out clears active session and refreshes credit',
      () async {
    final active = _session();
    final completed = active.copyWith(
      status: SessionStatus.completed,
      checkOutTime: active.checkInTime.add(const Duration(hours: 8)),
      totalMinutes: 8 * 60,
    );
    final repo = _FakeAttendanceRepository(
      activeSessionResult: active,
      checkOutResult: completed,
      credit: Duration.zero,
    );
    final notifier = AttendanceNotifier(repo, userId);
    await pumpEventQueue();

    repo.credit = const Duration(hours: 1);
    final ok = await notifier.checkOut();

    expect(ok, isTrue);
    expect(notifier.state.activeSession, isNull);
    expect(notifier.state.availableCredit, const Duration(hours: 1));
    expect(
        notifier.state.todayResult?.workedDuration, const Duration(hours: 8));
  });

  test('empty user id does not call repository during initialization',
      () async {
    final repo = _FakeAttendanceRepository();

    AttendanceNotifier(repo, '');
    await pumpEventQueue();

    expect(repo.fetchCreditCalls, 0);
    expect(repo.activeSessionCalls, 0);
  });

  test('check-in blocked after 11:30 AM surfaces the deadline error', () async {
    final repo = _FakeAttendanceRepository(
      checkInError: const AttendanceException(
          'Check-in is not allowed after 11:30 AM.'),
    );
    final notifier = AttendanceNotifier(repo, userId);
    await pumpEventQueue();

    final ok = await notifier.checkIn();

    expect(ok, isFalse);
    expect(notifier.state.error, contains('11:30'));
  });
}

AttendanceSession _session() {
  final checkIn = DateTime(2026, 4, 28, 8);
  return AttendanceSession(
    id: 'session-1',
    userId: 'user-1',
    sessionDate: DateTime(2026, 4, 28),
    checkInTime: checkIn,
  );
}

class _FakeAttendanceRepository implements AttendanceRepositoryPort {
  _FakeAttendanceRepository({
    this.activeSessionResult,
    this.checkOutResult,
    this.credit = Duration.zero,
    this.checkInError,
  });

  AttendanceSession? activeSessionResult;
  AttendanceSession? checkOutResult;
  Duration credit;
  Exception? checkInError;

  int activeSessionCalls = 0;
  int checkInCalls = 0;
  int checkOutCalls = 0;
  int fetchCreditCalls = 0;

  @override
  Future<AttendanceSession?> activeSession(String userId) async {
    activeSessionCalls++;
    return activeSessionResult;
  }

  @override
  Future<AttendanceSession?> activeSessionToday(String userId) async {
    return activeSession(userId);
  }

  @override
  Future<AttendanceSession> checkIn({
    required String userId,
    String? notes,
    DateTime? checkInTime,
  }) async {
    checkInCalls++;
    if (checkInError != null) throw checkInError!;
    final result = _session();
    activeSessionResult = result;
    return result;
  }

  @override
  Future<AttendanceSession> checkOut({
    required String sessionId,
    required String userId,
    String? notes,
    DateTime? checkOutTime,
  }) async {
    checkOutCalls++;
    final result = checkOutResult ??
        _session().copyWith(
          status: SessionStatus.completed,
          checkOutTime: _session().checkInTime.add(const Duration(hours: 7)),
          totalMinutes: 7 * 60,
        );
    activeSessionResult = null;
    return result;
  }

  @override
  Future<Duration> fetchAvailableCredit({
    required String userId,
    required DateTime cycleStart,
  }) async {
    fetchCreditCalls++;
    expect(cycleStart, WorkCycleCalculator.currentCycle().start);
    return credit;
  }

  @override
  Future<List<AttendanceSession>> fetchSessions({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    return [];
  }

  @override
  Future<List<DailySummaryModel>> fetchSummaries({
    required String userId,
    required DateTime cycleStart,
    required DateTime cycleEnd,
  }) async {
    return [];
  }
}
