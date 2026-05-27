import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

enum UserRole {
  @JsonValue('demonstrator')
  demonstrator,
  @JsonValue('teaching_assistant')
  teachingAssistant,
  @JsonValue('doctor')
  doctor;

  String get label => switch (this) {
        UserRole.demonstrator => 'Demonstrator',
        UserRole.teachingAssistant => 'Teaching Assistant',
        UserRole.doctor => 'Doctor',
      };

  // DB enum values (match PostgreSQL user_role type exactly).
  String get dbValue => switch (this) {
        UserRole.demonstrator => 'demonstrator',
        UserRole.teachingAssistant => 'teaching_assistant',
        UserRole.doctor => 'doctor',
      };
}

@Freezed(toJson: true)
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required UserRole role,
    String? departmentId,
    String? faculty,
    String? employeeId,
    String? phone,
    @Default(false) bool isOnboarded,
    // Extra rest days chosen by user (DateTime.weekday values 1–7; Friday=5 is always off).
    @Default([]) List<int> restDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: _roleFromJson(json['role']),
      departmentId: json['department_id'] as String?,
      faculty: json['faculty'] as String?,
      employeeId: json['employee_id'] as String?,
      phone: json['phone'] as String?,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      restDays: (json['rest_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }
}

UserRole _roleFromJson(dynamic value) {
  if (value == null) return UserRole.demonstrator;
  if (value is String) {
    return UserRole.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => UserRole.demonstrator,
    );
  }
  return UserRole.demonstrator;
}
