import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class OnboardingState {
  const OnboardingState({
    this.departments = const [],
    this.isLoading = false,
    this.error,
    this.isDone = false,
  });

  final List<Department> departments;
  final bool isLoading;
  final String? error;
  final bool isDone;

  OnboardingState copyWith({
    List<Department>? departments,
    bool? isLoading,
    String? error,
    bool? isDone,
    bool clearError = false,
  }) =>
      OnboardingState(
        departments: departments ?? this.departments,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isDone: isDone ?? this.isDone,
      );
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repo, this._auth) : super(const OnboardingState()) {
    _loadDepartments();
  }

  final ProfileRepository _repo;
  final AuthNotifier _auth;

  Future<void> _loadDepartments() async {
    try {
      final depts = await _repo.fetchDepartments();
      state = state.copyWith(departments: depts);
    } catch (e) {
      // Departments failed to load, but onboarding can proceed
      debugPrint('Department load failed: $e');
    }
  }

  Future<bool> complete({
    required String fullName,
    required UserRole role,
    String? departmentId,
    String? faculty,
    String? employeeId,
    String? phone,
    List<int> restDays = const [],
  }) async {
    final userId = _auth.state.profile?.id;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.completeOnboarding(
        userId: userId,
        fullName: fullName,
        role: role,
        departmentId: departmentId,
        faculty: faculty,
        employeeId: employeeId,
        phone: phone,
        restDays: restDays,
      );
      await _auth.updateProfile(updated);
      state = state.copyWith(isLoading: false, isDone: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(
    ref.read(profileRepositoryProvider),
    ref.read(authProvider.notifier),
  );
});
