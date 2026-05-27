import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/providers/supabase_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(supabaseClientProvider));
});

class Department {
  const Department({required this.id, required this.name, this.faculty});
  final String id;
  final String name;
  final String? faculty;
}

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<List<Department>> fetchDepartments() async {
    try {
      final rows = await _client
          .from(AppConstants.tableDepartments)
          .select('id, name, faculty')
          .order('name');
      return (rows as List)
          .map((r) => Department(
                id: r['id'] as String,
                name: r['name'] as String,
                faculty: r['faculty'] as String?,
              ))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<UserProfile> completeOnboarding({
    required String userId,
    required String fullName,
    required UserRole role,
    required String? departmentId,
    required String? faculty,
    required String? employeeId,
    required String? phone,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.tableProfiles)
          .update({
            'full_name': fullName,
            'role': role.dbValue,
            'department_id': departmentId,
            'faculty': faculty,
            'employee_id': employeeId,
            'phone': phone,
            'is_onboarded': true,
          })
          .eq('id', userId)
          .select()
          .single();
      return UserProfile.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }
}
