// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduleEntry _$ScheduleEntryFromJson(Map<String, dynamic> json) {
  return _ScheduleEntry.fromJson(json);
}

/// @nodoc
mixin _$ScheduleEntry {
  String get id => throw _privateConstructorUsedError;
  String get scheduleId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;

  /// 0 = Sunday … 6 = Saturday (matching DateTime.weekday - 1).
  int get dayOfWeek => throw _privateConstructorUsedError;
  String get startTime => throw _privateConstructorUsedError; // "HH:mm:ss"
  String get endTime => throw _privateConstructorUsedError;
  ScheduleEntryType get entryType => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get groupName => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ScheduleEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScheduleEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleEntryCopyWith<ScheduleEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleEntryCopyWith<$Res> {
  factory $ScheduleEntryCopyWith(
          ScheduleEntry value, $Res Function(ScheduleEntry) then) =
      _$ScheduleEntryCopyWithImpl<$Res, ScheduleEntry>;
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      int dayOfWeek,
      String startTime,
      String endTime,
      ScheduleEntryType entryType,
      String title,
      String? groupName,
      String? location,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ScheduleEntryCopyWithImpl<$Res, $Val extends ScheduleEntry>
    implements $ScheduleEntryCopyWith<$Res> {
  _$ScheduleEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduleEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? dayOfWeek = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? entryType = null,
    Object? title = null,
    Object? groupName = freezed,
    Object? location = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: null == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as ScheduleEntryType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: freezed == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$ScheduleEntryImplCopyWith<$Res>
    implements $ScheduleEntryCopyWith<$Res> {
  factory _$$ScheduleEntryImplCopyWith(
          _$ScheduleEntryImpl value, $Res Function(_$ScheduleEntryImpl) then) =
      __$$ScheduleEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      int dayOfWeek,
      String startTime,
      String endTime,
      ScheduleEntryType entryType,
      String title,
      String? groupName,
      String? location,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ScheduleEntryImplCopyWithImpl<$Res>
    extends _$ScheduleEntryCopyWithImpl<$Res, _$ScheduleEntryImpl>
    implements _$$ScheduleEntryImplCopyWith<$Res> {
  __$$ScheduleEntryImplCopyWithImpl(
      _$ScheduleEntryImpl _value, $Res Function(_$ScheduleEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScheduleEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? dayOfWeek = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? entryType = null,
    Object? title = null,
    Object? groupName = freezed,
    Object? location = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ScheduleEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: null == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      dayOfWeek: null == dayOfWeek
          ? _value.dayOfWeek
          : dayOfWeek // ignore: cast_nullable_to_non_nullable
              as int,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as String,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as String,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as ScheduleEntryType,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      groupName: freezed == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$ScheduleEntryImpl implements _ScheduleEntry {
  const _$ScheduleEntryImpl(
      {required this.id,
      required this.scheduleId,
      required this.userId,
      required this.dayOfWeek,
      required this.startTime,
      required this.endTime,
      required this.entryType,
      required this.title,
      this.groupName,
      this.location,
      this.createdAt,
      this.updatedAt});

  factory _$ScheduleEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String scheduleId;
  @override
  final String userId;

  /// 0 = Sunday … 6 = Saturday (matching DateTime.weekday - 1).
  @override
  final int dayOfWeek;
  @override
  final String startTime;
// "HH:mm:ss"
  @override
  final String endTime;
  @override
  final ScheduleEntryType entryType;
  @override
  final String title;
  @override
  final String? groupName;
  @override
  final String? location;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ScheduleEntry(id: $id, scheduleId: $scheduleId, userId: $userId, dayOfWeek: $dayOfWeek, startTime: $startTime, endTime: $endTime, entryType: $entryType, title: $title, groupName: $groupName, location: $location, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.entryType, entryType) ||
                other.entryType == entryType) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.location, location) ||
                other.location == location) &&
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
      scheduleId,
      userId,
      dayOfWeek,
      startTime,
      endTime,
      entryType,
      title,
      groupName,
      location,
      createdAt,
      updatedAt);

  /// Create a copy of ScheduleEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleEntryImplCopyWith<_$ScheduleEntryImpl> get copyWith =>
      __$$ScheduleEntryImplCopyWithImpl<_$ScheduleEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleEntryImplToJson(
      this,
    );
  }
}

abstract class _ScheduleEntry implements ScheduleEntry {
  const factory _ScheduleEntry(
      {required final String id,
      required final String scheduleId,
      required final String userId,
      required final int dayOfWeek,
      required final String startTime,
      required final String endTime,
      required final ScheduleEntryType entryType,
      required final String title,
      final String? groupName,
      final String? location,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ScheduleEntryImpl;

  factory _ScheduleEntry.fromJson(Map<String, dynamic> json) =
      _$ScheduleEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get scheduleId;
  @override
  String get userId;

  /// 0 = Sunday … 6 = Saturday (matching DateTime.weekday - 1).
  @override
  int get dayOfWeek;
  @override
  String get startTime; // "HH:mm:ss"
  @override
  String get endTime;
  @override
  ScheduleEntryType get entryType;
  @override
  String get title;
  @override
  String? get groupName;
  @override
  String? get location;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ScheduleEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleEntryImplCopyWith<_$ScheduleEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
