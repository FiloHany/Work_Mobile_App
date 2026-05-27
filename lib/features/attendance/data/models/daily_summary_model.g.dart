// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailySummaryModelImpl _$$DailySummaryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DailySummaryModelImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      summaryDate: DateTime.parse(json['summary_date'] as String),
      cycleStart: DateTime.parse(json['cycle_start'] as String),
      totalWorkedMinutes: (json['total_worked_minutes'] as num?)?.toInt() ?? 0,
      creditEarnedMinutes:
          (json['credit_earned_minutes'] as num?)?.toInt() ?? 0,
      deficitMinutes: (json['deficit_minutes'] as num?)?.toInt() ?? 0,
      isValidDay: json['is_valid_day'] as bool? ?? false,
      isInsufficientDay: json['is_insufficient_day'] as bool? ?? false,
      hasApprovedException: json['has_approved_exception'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$DailySummaryModelImplToJson(
        _$DailySummaryModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'summary_date': instance.summaryDate.toIso8601String(),
      'cycle_start': instance.cycleStart.toIso8601String(),
      'total_worked_minutes': instance.totalWorkedMinutes,
      'credit_earned_minutes': instance.creditEarnedMinutes,
      'deficit_minutes': instance.deficitMinutes,
      'is_valid_day': instance.isValidDay,
      'is_insufficient_day': instance.isInsufficientDay,
      'has_approved_exception': instance.hasApprovedException,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
