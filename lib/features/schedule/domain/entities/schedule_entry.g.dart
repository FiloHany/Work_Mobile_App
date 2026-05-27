// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleEntryImpl _$$ScheduleEntryImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleEntryImpl(
      id: json['id'] as String,
      scheduleId: json['schedule_id'] as String,
      userId: json['user_id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      entryType: $enumDecode(_$ScheduleEntryTypeEnumMap, json['entry_type']),
      title: json['title'] as String,
      groupName: json['group_name'] as String?,
      location: json['location'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ScheduleEntryImplToJson(_$ScheduleEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'schedule_id': instance.scheduleId,
      'user_id': instance.userId,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'entry_type': _$ScheduleEntryTypeEnumMap[instance.entryType]!,
      'title': instance.title,
      'group_name': instance.groupName,
      'location': instance.location,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ScheduleEntryTypeEnumMap = {
  ScheduleEntryType.lecture: 'lecture',
  ScheduleEntryType.section: 'section',
  ScheduleEntryType.lab: 'lab',
  ScheduleEntryType.meeting: 'meeting',
  ScheduleEntryType.officeHours: 'office_hours',
  ScheduleEntryType.requiredPresence: 'required_presence',
  ScheduleEntryType.free: 'free',
};
