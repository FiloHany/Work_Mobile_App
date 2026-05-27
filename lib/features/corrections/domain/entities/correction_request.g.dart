// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correction_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CorrectionRequestImpl _$$CorrectionRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CorrectionRequestImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetDate: DateTime.parse(json['target_date'] as String),
      requestType: $enumDecode(_$CorrectionTypeEnumMap, json['request_type']),
      requestedCheckIn: json['requested_check_in'] == null
          ? null
          : DateTime.parse(json['requested_check_in'] as String),
      requestedCheckOut: json['requested_check_out'] == null
          ? null
          : DateTime.parse(json['requested_check_out'] as String),
      reason: json['reason'] as String,
      status: $enumDecodeNullable(_$CorrectionStatusEnumMap, json['status']) ??
          CorrectionStatus.pending,
      sessionId: json['session_id'] as String?,
      reviewerNotes: json['reviewer_notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CorrectionRequestImplToJson(
        _$CorrectionRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'target_date': instance.targetDate.toIso8601String(),
      'request_type': _$CorrectionTypeEnumMap[instance.requestType]!,
      'requested_check_in': instance.requestedCheckIn?.toIso8601String(),
      'requested_check_out': instance.requestedCheckOut?.toIso8601String(),
      'reason': instance.reason,
      'status': _$CorrectionStatusEnumMap[instance.status]!,
      'session_id': instance.sessionId,
      'reviewer_notes': instance.reviewerNotes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$CorrectionTypeEnumMap = {
  CorrectionType.missedCheckIn: 'missed_check_in',
  CorrectionType.missedCheckOut: 'missed_check_out',
  CorrectionType.fullCorrection: 'full_correction',
};

const _$CorrectionStatusEnumMap = {
  CorrectionStatus.pending: 'pending',
  CorrectionStatus.approved: 'approved',
  CorrectionStatus.rejected: 'rejected',
};
