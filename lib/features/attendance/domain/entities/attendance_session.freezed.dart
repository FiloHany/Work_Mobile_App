// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttendanceSession _$AttendanceSessionFromJson(Map<String, dynamic> json) {
  return _AttendanceSession.fromJson(json);
}

/// @nodoc
mixin _$AttendanceSession {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get sessionDate => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get checkInTime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  DateTime? get checkOutTime => throw _privateConstructorUsedError;
  int? get totalMinutes => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  SessionStatus get status => throw _privateConstructorUsedError;
  bool get isApprovedException => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this AttendanceSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttendanceSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttendanceSessionCopyWith<AttendanceSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttendanceSessionCopyWith<$Res> {
  factory $AttendanceSessionCopyWith(
          AttendanceSession value, $Res Function(AttendanceSession) then) =
      _$AttendanceSessionCopyWithImpl<$Res, AttendanceSession>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime sessionDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime checkInTime,
      @JsonKey(
          fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
      DateTime? checkOutTime,
      int? totalMinutes,
      String? notes,
      SessionStatus status,
      bool isApprovedException,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$AttendanceSessionCopyWithImpl<$Res, $Val extends AttendanceSession>
    implements $AttendanceSessionCopyWith<$Res> {
  _$AttendanceSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttendanceSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? sessionDate = null,
    Object? checkInTime = null,
    Object? checkOutTime = freezed,
    Object? totalMinutes = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? isApprovedException = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionDate: null == sessionDate
          ? _value.sessionDate
          : sessionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkInTime: null == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalMinutes: freezed == totalMinutes
          ? _value.totalMinutes
          : totalMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SessionStatus,
      isApprovedException: null == isApprovedException
          ? _value.isApprovedException
          : isApprovedException // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttendanceSessionImplCopyWith<$Res>
    implements $AttendanceSessionCopyWith<$Res> {
  factory _$$AttendanceSessionImplCopyWith(_$AttendanceSessionImpl value,
          $Res Function(_$AttendanceSessionImpl) then) =
      __$$AttendanceSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime sessionDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime checkInTime,
      @JsonKey(
          fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
      DateTime? checkOutTime,
      int? totalMinutes,
      String? notes,
      SessionStatus status,
      bool isApprovedException,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$AttendanceSessionImplCopyWithImpl<$Res>
    extends _$AttendanceSessionCopyWithImpl<$Res, _$AttendanceSessionImpl>
    implements _$$AttendanceSessionImplCopyWith<$Res> {
  __$$AttendanceSessionImplCopyWithImpl(_$AttendanceSessionImpl _value,
      $Res Function(_$AttendanceSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttendanceSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? sessionDate = null,
    Object? checkInTime = null,
    Object? checkOutTime = freezed,
    Object? totalMinutes = freezed,
    Object? notes = freezed,
    Object? status = null,
    Object? isApprovedException = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$AttendanceSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionDate: null == sessionDate
          ? _value.sessionDate
          : sessionDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkInTime: null == checkInTime
          ? _value.checkInTime
          : checkInTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      checkOutTime: freezed == checkOutTime
          ? _value.checkOutTime
          : checkOutTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalMinutes: freezed == totalMinutes
          ? _value.totalMinutes
          : totalMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as SessionStatus,
      isApprovedException: null == isApprovedException
          ? _value.isApprovedException
          : isApprovedException // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttendanceSessionImpl extends _AttendanceSession {
  const _$AttendanceSessionImpl(
      {required this.id,
      required this.userId,
      required this.sessionDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.checkInTime,
      @JsonKey(
          fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
      this.checkOutTime,
      this.totalMinutes,
      this.notes,
      this.status = SessionStatus.active,
      this.isApprovedException = false,
      this.createdAt,
      this.updatedAt})
      : super._();

  factory _$AttendanceSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttendanceSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime sessionDate;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime checkInTime;
  @override
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  final DateTime? checkOutTime;
  @override
  final int? totalMinutes;
  @override
  final String? notes;
  @override
  @JsonKey()
  final SessionStatus status;
  @override
  @JsonKey()
  final bool isApprovedException;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'AttendanceSession(id: $id, userId: $userId, sessionDate: $sessionDate, checkInTime: $checkInTime, checkOutTime: $checkOutTime, totalMinutes: $totalMinutes, notes: $notes, status: $status, isApprovedException: $isApprovedException, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttendanceSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.sessionDate, sessionDate) ||
                other.sessionDate == sessionDate) &&
            (identical(other.checkInTime, checkInTime) ||
                other.checkInTime == checkInTime) &&
            (identical(other.checkOutTime, checkOutTime) ||
                other.checkOutTime == checkOutTime) &&
            (identical(other.totalMinutes, totalMinutes) ||
                other.totalMinutes == totalMinutes) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isApprovedException, isApprovedException) ||
                other.isApprovedException == isApprovedException) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      sessionDate,
      checkInTime,
      checkOutTime,
      totalMinutes,
      notes,
      status,
      isApprovedException,
      createdAt,
      updatedAt);

  /// Create a copy of AttendanceSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttendanceSessionImplCopyWith<_$AttendanceSessionImpl> get copyWith =>
      __$$AttendanceSessionImplCopyWithImpl<_$AttendanceSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttendanceSessionImplToJson(
      this,
    );
  }
}

abstract class _AttendanceSession extends AttendanceSession {
  const factory _AttendanceSession(
      {required final String id,
      required final String userId,
      required final DateTime sessionDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required final DateTime checkInTime,
      @JsonKey(
          fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
      final DateTime? checkOutTime,
      final int? totalMinutes,
      final String? notes,
      final SessionStatus status,
      final bool isApprovedException,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$AttendanceSessionImpl;
  const _AttendanceSession._() : super._();

  factory _AttendanceSession.fromJson(Map<String, dynamic> json) =
      _$AttendanceSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get sessionDate;
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get checkInTime;
  @override
  @JsonKey(fromJson: _nullableDateTimeFromJson, toJson: _nullableDateTimeToJson)
  DateTime? get checkOutTime;
  @override
  int? get totalMinutes;
  @override
  String? get notes;
  @override
  SessionStatus get status;
  @override
  bool get isApprovedException;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of AttendanceSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttendanceSessionImplCopyWith<_$AttendanceSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
