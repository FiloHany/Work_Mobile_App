import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../data/repositories/correction_repository.dart';
import '../../domain/entities/correction_request.dart';

class CorrectionsState {
  const CorrectionsState({
    this.requests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<CorrectionRequest> requests;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  CorrectionsState copyWith({
    List<CorrectionRequest>? requests,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) =>
      CorrectionsState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
      );
}

class CorrectionsNotifier extends StateNotifier<CorrectionsState> {
  CorrectionsNotifier(this._corrRepo, this._attendRepo, this._userId)
      : super(const CorrectionsState()) {
    load();
  }

  final CorrectionRepository _corrRepo;
  final AttendanceRepository _attendRepo;
  final String _userId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final requests = await _corrRepo.fetchAll(_userId);
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Applies the correction directly to the attendance session, then logs it.
  Future<bool> apply({
    required DateTime targetDate,
    required CorrectionType requestType,
    required String reason,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      // 1. Apply the change to the attendance session.
      await _attendRepo.applyCorrection(
        userId: _userId,
        targetDate: targetDate,
        newCheckIn: requestedCheckIn,
        newCheckOut: requestedCheckOut,
      );

      // 2. Log as an approved history record.
      final record = await _corrRepo.logApplied(
        userId: _userId,
        targetDate: targetDate,
        requestType: requestType,
        reason: reason,
        requestedCheckIn: requestedCheckIn,
        requestedCheckOut: requestedCheckOut,
      );

      state = state.copyWith(
        requests: [record, ...state.requests],
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final correctionsProvider =
    StateNotifierProvider<CorrectionsNotifier, CorrectionsState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return CorrectionsNotifier(
    ref.read(correctionRepositoryProvider),
    ref.read(attendanceRepositoryProvider),
    userId,
  );
});
