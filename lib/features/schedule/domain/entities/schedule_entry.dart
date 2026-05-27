import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_entry.freezed.dart';
part 'schedule_entry.g.dart';

enum ScheduleEntryType {
  @JsonValue('lecture')
  lecture,
  @JsonValue('section')
  section,
  @JsonValue('lab')
  lab,
  @JsonValue('meeting')
  meeting,
  @JsonValue('office_hours')
  officeHours,
  @JsonValue('required_presence')
  requiredPresence,
  @JsonValue('free')
  free;

  String get label => switch (this) {
        lecture => 'Lecture',
        section => 'Section',
        lab => 'Lab',
        meeting => 'Meeting',
        officeHours => 'Office Hours',
        requiredPresence => 'Required Presence',
        free => 'Free',
      };

  String get dbValue => switch (this) {
        lecture => 'lecture',
        section => 'section',
        lab => 'lab',
        meeting => 'meeting',
        officeHours => 'office_hours',
        requiredPresence => 'required_presence',
        free => 'free',
      };
}

@freezed
class ScheduleEntry with _$ScheduleEntry {
  const factory ScheduleEntry({
    required String id,
    required String scheduleId,
    required String userId,

    /// 0 = Sunday … 6 = Saturday (matching DateTime.weekday - 1).
    required int dayOfWeek,
    required String startTime, // "HH:mm:ss"
    required String endTime,
    required ScheduleEntryType entryType,
    required String title,
    String? groupName,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ScheduleEntry;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) =>
      _$ScheduleEntryFromJson(json);
}
