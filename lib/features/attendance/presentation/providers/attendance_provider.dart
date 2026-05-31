import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/work_rules.dart';
import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../shared/services/notification_service.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/entities/attendance_session.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AttendanceState {
  const AttendanceState({
    this.activeSession,
    this.todayResult,
    this.availableCredit = Duration.zero,
    this.isLoading = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.error,
  });

  final AttendanceSession? activeSession;
  final DailyCalculationResult? todayResult;
  final Duration availableCredit;
  final bool isLoading;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final String? error;

  bool get isCheckedIn => activeSession != null;

  AttendanceState copyWith({
    AttendanceSession? activeSession,
    DailyCalculationResult? todayResult,
    Duration? availableCredit,
    bool? isLoading,
    bool? isCheckingIn,
    bool? isCheckingOut,
    String? error,
    bool clearSession = false,
    bool clearError = false,
  }) =>
      AttendanceState(
        activeSession:
            clearSession ? null : (activeSession ?? this.activeSession),
        todayResult: todayResult ?? this.todayResult,
        availableCredit: availableCredit ?? this.availableCredit,
        isLoading: isLoading ?? this.isLoading,
        isCheckingIn: isCheckingIn ?? this.isCheckingIn,
        isCheckingOut: isCheckingOut ?? this.isCheckingOut,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier(this._repo, this._userId)
      : super(const AttendanceState()) {
    if (_userId.isNotEmpty) {
      _init();
    }
  }

  final AttendanceRepositoryPort _repo;
  final String _userId;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final cycle = WorkCycleCalculator.currentCycle();
      final credit = await _repo.fetchAvailableCredit(
          userId: _userId, cycleStart: cycle.start);
      final session = await _repo.activeSession(_userId);
      state = state.copyWith(
        activeSession: session,
        availableCredit: credit,
        isLoading: false,
      );
      if (session != null) _refreshTodayResult(session);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _init();

  Future<bool> checkIn({String? notes}) async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'You must be signed in to check in.');
      return false;
    }
    if (state.isCheckingIn) return false;
    if (state.activeSession != null) {
      state = state.copyWith(
        error:
            'You are already checked in. Check out before checking in again.',
      );
      return false;
    }

    state = state.copyWith(isCheckingIn: true, clearError: true);
    try {
      final session = await _repo.checkIn(userId: _userId, notes: notes);
      state = state.copyWith(activeSession: session, isCheckingIn: false);
      _refreshTodayResult(session);
      // Cancel "haven't checked in" reminders now that the user has.
      NotificationService.instance.cancelCheckInReminders().ignore();
      // Confirm check-in via notification.
      NotificationService.instance
          .showCheckInConfirmation(session.checkInTime)
          .ignore();
      // Schedule "you can leave" alert at effectiveCheckIn + standard target.
      final effectiveIn = HoursRuleEngine.roundCheckIn(session.checkInTime);
      final leaveAt = effectiveIn.add(WorkRules.standardDailyTarget);
      NotificationService.instance.scheduleEarlyLeaveAlert(
        hour: leaveAt.hour,
        minute: leaveAt.minute,
      ).ignore();
      return true;
    } catch (e) {
      state = state.copyWith(isCheckingIn: false, error: e.toString());
      return false;
    }
  }

  Future<bool> checkOut({String? notes}) async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'You must be signed in to check out.');
      return false;
    }
    if (state.isCheckingOut) return false;

    final session = state.activeSession;
    if (session == null) {
      state =
          state.copyWith(error: 'No active attendance session to check out.');
      return false;
    }

    state = state.copyWith(isCheckingOut: true, clearError: true);
    try {
      final completed = await _repo.checkOut(
        sessionId: session.id,
        userId: _userId,
        notes: notes,
      );
      final cycle = WorkCycleCalculator.currentCycle();
      final credit = await _repo.fetchAvailableCredit(
          userId: _userId, cycleStart: cycle.start);
      state = state.copyWith(
        isCheckingOut: false,
        availableCredit: credit,
        clearSession: true,
      );
      _refreshTodayResult(completed);
      // User has left — cancel the early-leave alert and departure reminder.
      NotificationService.instance.cancelEarlyLeaveAlert().ignore();
      NotificationService.instance.cancelDepartureReminder().ignore();
      // Send check-out summary notification.
      if (completed.checkOutTime != null) {
        final workedRaw = HoursRuleEngine.roundCheckOut(completed.checkOutTime!)
            .difference(HoursRuleEngine.roundCheckIn(session.checkInTime));
        final worked = workedRaw.isNegative ? Duration.zero : workedRaw;
        NotificationService.instance.showCheckOutSummary(
          worked: worked,
          credit: credit,
        ).ignore();
      }
      return true;
    } catch (e) {
      state = state.copyWith(isCheckingOut: false, error: e.toString());
      return false;
    }
  }

  void _refreshTodayResult(AttendanceSession session) {
    final result = HoursRuleEngine.analyseSession(
      checkIn: session.checkInTime,
      checkOut: session.checkOutTime,
      availableCredit: state.availableCredit,
      hasException: session.isApprovedException,
    );
    state = state.copyWith(todayResult: result);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return AttendanceNotifier(
    ref.read(attendanceRepositoryProvider),
    userId,
  );
});
