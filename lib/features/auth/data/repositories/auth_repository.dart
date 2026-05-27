import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../../core/constants/app_constants.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  static const _storage = FlutterSecureStorage();
  static const _keyEmail = 'wh_auth_email';
  static const _keyPassword = 'wh_auth_password';

  // ── Name-based registration (no email shown to user) ──────────────────────

  Future<UserProfile> registerByName({
    required String fullName,
    required UserRole role,
    List<int> restDays = const [],
  }) async {
    try {
      // Generate invisible credentials so the user only provides their name.
      // Stored in secure storage to allow silent re-login after session expiry.
      final id = const Uuid().v4();
      final email = '$id@workhours.app';
      final password = _randomPassword();

      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);

      // Try anonymous auth first (no email provider required).
      // Fall back to email+password if anonymous is disabled.
      AuthResponse res;
      try {
        res = await _client.auth.signInAnonymously(
          data: {'full_name': fullName, 'role': role.dbValue},
        );
      } catch (_) {
        res = await _client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'role': role.dbValue},
        );
        if (res.user != null && res.session == null) {
          throw const AuthException(
            'Registration failed: email confirmation is required. '
            'Disable "Confirm email" in your Supabase Auth settings.',
          );
        }
      }

      if (res.user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      // Mark onboarded and save chosen rest days.
      await _client.from(AppConstants.tableProfiles).update({
        'is_onboarded': true,
        'rest_days': restDays,
      }).eq('id', res.user!.id);

      return _fetchProfile(res.user!.id);
    } catch (e) {
      throw mapException(e);
    }
  }

  // ── Auto sign-in (restores persisted Supabase session) ───────────────────

  Future<UserProfile?> currentProfile() async {
    var user = _client.auth.currentUser;

    // If no active session, try re-signing in with stored credentials.
    if (user == null) {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      if (email != null && password != null) {
        try {
          final res = await _client.auth
              .signInWithPassword(email: email, password: password);
          user = res.user;
        } catch (_) {}
      }
    }

    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  // ── Sign-out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw mapException(e);
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final data = await _client
          .from(AppConstants.tableProfiles)
          .update({
            'full_name': profile.fullName,
            'avatar_url': profile.avatarUrl,
            'role': profile.role.dbValue,
            'department_id': profile.departmentId,
            'faculty': profile.faculty,
            'employee_id': profile.employeeId,
            'phone': profile.phone,
            'is_onboarded': profile.isOnboarded,
            'rest_days': profile.restDays,
          })
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', userId)
        .single();
    return UserProfile.fromJson(data);
  }

  String _randomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final rand = Random.secure();
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
