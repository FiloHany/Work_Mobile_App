// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_session.freezed.dart';
part 'attendance_session.g.dart';

enum SessionStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('voided')
  voided,
  @JsonValue('correction_applied')
  correctionApplied;
}

@freezed
class AttendanceSession with _$AttendanceSession {
  const factory AttendanceSession({
    required String id,
    required String userId,
    required DateTime sessionDate,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime checkInTime,
    @JsonKey(
        fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
    DateTime? checkOutTime,
    int? totalMinutes,
    String? notes,
    @Default(SessionStatus.active) SessionStatus status,
    @Default(false) bool isApprovedException,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AttendanceSession;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      _$AttendanceSessionFromJson(json);

  const AttendanceSession._();

  bool get isActive => status == SessionStatus.active;
  bool get isCompleted => status == SessionStatus.completed;
  Duration? get duration =>
      totalMinutes != null ? Duration(minutes: totalMinutes!) : null;
}

DateTime _dateTimeFromJson(String value) => DateTime.parse(value).toLocal();

DateTime? _nullableDateTimeFromJson(String? value) =>
    value == null ? null : _dateTimeFromJson(value);

String _dateTimeToJson(DateTime value) => value.toUtc().toIso8601String();

String? _nullableDateTimeToJson(DateTime? value) =>
    value == null ? null : _dateTimeToJson(value);
