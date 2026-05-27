import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => profile != null;

  AuthState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearProfile = false,
    bool clearError = false,
  }) =>
      AuthState(
        profile: clearProfile ? null : (profile ?? this.profile),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _loadCurrentUser();
  }

  final AuthRepository _repo;

  Future<void> _loadCurrentUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repo.currentProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> registerByName({
    required String fullName,
    required UserRole role,
    List<int> restDays = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repo.registerByName(
        fullName: fullName,
        role: role,
        restDays: restDays,
      );
      state = state.copyWith(profile: profile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateProfile(profile);
      state = state.copyWith(profile: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// Convenience: current profile (null if not registered).
final profileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).profile;
});
