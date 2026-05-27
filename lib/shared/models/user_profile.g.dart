// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'role': _$UserRoleEnumMap[instance.role]!,
      'department_id': instance.departmentId,
      'faculty': instance.faculty,
      'employee_id': instance.employeeId,
      'phone': instance.phone,
      'is_onboarded': instance.isOnboarded,
      'rest_days': instance.restDays,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.demonstrator: 'demonstrator',
  UserRole.teachingAssistant: 'teaching_assistant',
  UserRole.doctor: 'doctor',
};
