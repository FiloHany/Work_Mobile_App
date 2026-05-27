// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttendanceSessionImpl _$$AttendanceSessionImplFromJson(
        Map<String, dynamic> json) =>
    _$AttendanceSessionImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sessionDate: DateTime.parse(json['session_date'] as String),
      checkInTime: _dateTimeFromJson(json['check_in_time'] as String),
      checkOutTime:
          _nullableDateTimeFromJson(json['check_out_time'] as String?),
      totalMinutes: (json['total_minutes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      status: $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.active,
      isApprovedException: json['is_approved_exception'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$AttendanceSessionImplToJson(
        _$AttendanceSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'session_date': instance.sessionDate.toIso8601String(),
      'check_in_time': _dateTimeToJson(instance.checkInTime),
      'check_out_time': _nullableDateTimeToJson(instance.checkOutTime),
      'total_minutes': instance.totalMinutes,
      'notes': instance.notes,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'is_approved_exception': instance.isApprovedException,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.completed: 'completed',
  SessionStatus.voided: 'voided',
  SessionStatus.correctionApplied: 'correction_applied',
};
