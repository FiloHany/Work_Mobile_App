// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DailySummaryModel _$DailySummaryModelFromJson(Map<String, dynamic> json) {
  return _DailySummaryModel.fromJson(json);
}

/// @nodoc
mixin _$DailySummaryModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get summaryDate => throw _privateConstructorUsedError;
  DateTime get cycleStart => throw _privateConstructorUsedError;
  int get totalWorkedMinutes => throw _privateConstructorUsedError;
  int get creditEarnedMinutes => throw _privateConstructorUsedError;
  int get deficitMinutes => throw _privateConstructorUsedError;
  bool get isValidDay => throw _privateConstructorUsedError;
  bool get isInsufficientDay => throw _privateConstructorUsedError;
  bool get hasApprovedException => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DailySummaryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailySummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailySummaryModelCopyWith<DailySummaryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailySummaryModelCopyWith<$Res> {
  factory $DailySummaryModelCopyWith(
          DailySummaryModel value, $Res Function(DailySummaryModel) then) =
      _$DailySummaryModelCopyWithImpl<$Res, DailySummaryModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime summaryDate,
      DateTime cycleStart,
      int totalWorkedMinutes,
      int creditEarnedMinutes,
      int deficitMinutes,
      bool isValidDay,
      bool isInsufficientDay,
      bool hasApprovedException,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$DailySummaryModelCopyWithImpl<$Res, $Val extends DailySummaryModel>
    implements $DailySummaryModelCopyWith<$Res> {
  _$DailySummaryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailySummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? summaryDate = null,
    Object? cycleStart = null,
    Object? totalWorkedMinutes = null,
    Object? creditEarnedMinutes = null,
    Object? deficitMinutes = null,
    Object? isValidDay = null,
    Object? isInsufficientDay = null,
    Object? hasApprovedException = null,
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
      summaryDate: null == summaryDate
          ? _value.summaryDate
          : summaryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cycleStart: null == cycleStart
          ? _value.cycleStart
          : cycleStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalWorkedMinutes: null == totalWorkedMinutes
          ? _value.totalWorkedMinutes
          : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      creditEarnedMinutes: null == creditEarnedMinutes
          ? _value.creditEarnedMinutes
          : creditEarnedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      deficitMinutes: null == deficitMinutes
          ? _value.deficitMinutes
          : deficitMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      isValidDay: null == isValidDay
          ? _value.isValidDay
          : isValidDay // ignore: cast_nullable_to_non_nullable
              as bool,
      isInsufficientDay: null == isInsufficientDay
          ? _value.isInsufficientDay
          : isInsufficientDay // ignore: cast_nullable_to_non_nullable
              as bool,
      hasApprovedException: null == hasApprovedException
          ? _value.hasApprovedException
          : hasApprovedException // ignore: cast_nullable_to_non_nullable
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
abstract class _$$DailySummaryModelImplCopyWith<$Res>
    implements $DailySummaryModelCopyWith<$Res> {
  factory _$$DailySummaryModelImplCopyWith(_$DailySummaryModelImpl value,
          $Res Function(_$DailySummaryModelImpl) then) =
      __$$DailySummaryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime summaryDate,
      DateTime cycleStart,
      int totalWorkedMinutes,
      int creditEarnedMinutes,
      int deficitMinutes,
      bool isValidDay,
      bool isInsufficientDay,
      bool hasApprovedException,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$DailySummaryModelImplCopyWithImpl<$Res>
    extends _$DailySummaryModelCopyWithImpl<$Res, _$DailySummaryModelImpl>
    implements _$$DailySummaryModelImplCopyWith<$Res> {
  __$$DailySummaryModelImplCopyWithImpl(_$DailySummaryModelImpl _value,
      $Res Function(_$DailySummaryModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailySummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? summaryDate = null,
    Object? cycleStart = null,
    Object? totalWorkedMinutes = null,
    Object? creditEarnedMinutes = null,
    Object? deficitMinutes = null,
    Object? isValidDay = null,
    Object? isInsufficientDay = null,
    Object? hasApprovedException = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$DailySummaryModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      summaryDate: null == summaryDate
          ? _value.summaryDate
          : summaryDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      cycleStart: null == cycleStart
          ? _value.cycleStart
          : cycleStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalWorkedMinutes: null == totalWorkedMinutes
          ? _value.totalWorkedMinutes
          : totalWorkedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      creditEarnedMinutes: null == creditEarnedMinutes
          ? _value.creditEarnedMinutes
          : creditEarnedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      deficitMinutes: null == deficitMinutes
          ? _value.deficitMinutes
          : deficitMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      isValidDay: null == isValidDay
          ? _value.isValidDay
          : isValidDay // ignore: cast_nullable_to_non_nullable
              as bool,
      isInsufficientDay: null == isInsufficientDay
          ? _value.isInsufficientDay
          : isInsufficientDay // ignore: cast_nullable_to_non_nullable
              as bool,
      hasApprovedException: null == hasApprovedException
          ? _value.hasApprovedException
          : hasApprovedException // ignore: cast_nullable_to_non_nullable
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
class _$DailySummaryModelImpl implements _DailySummaryModel {
  const _$DailySummaryModelImpl(
      {required this.id,
      required this.userId,
      required this.summaryDate,
      required this.cycleStart,
      this.totalWorkedMinutes = 0,
      this.creditEarnedMinutes = 0,
      this.deficitMinutes = 0,
      this.isValidDay = false,
      this.isInsufficientDay = false,
      this.hasApprovedException = false,
      this.createdAt,
      this.updatedAt});

  factory _$DailySummaryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailySummaryModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime summaryDate;
  @override
  final DateTime cycleStart;
  @override
  @JsonKey()
  final int totalWorkedMinutes;
  @override
  @JsonKey()
  final int creditEarnedMinutes;
  @override
  @JsonKey()
  final int deficitMinutes;
  @override
  @JsonKey()
  final bool isValidDay;
  @override
  @JsonKey()
  final bool isInsufficientDay;
  @override
  @JsonKey()
  final bool hasApprovedException;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'DailySummaryModel(id: $id, userId: $userId, summaryDate: $summaryDate, cycleStart: $cycleStart, totalWorkedMinutes: $totalWorkedMinutes, creditEarnedMinutes: $creditEarnedMinutes, deficitMinutes: $deficitMinutes, isValidDay: $isValidDay, isInsufficientDay: $isInsufficientDay, hasApprovedException: $hasApprovedException, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailySummaryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.summaryDate, summaryDate) ||
                other.summaryDate == summaryDate) &&
            (identical(other.cycleStart, cycleStart) ||
                other.cycleStart == cycleStart) &&
            (identical(other.totalWorkedMinutes, totalWorkedMinutes) ||
                other.totalWorkedMinutes == totalWorkedMinutes) &&
            (identical(other.creditEarnedMinutes, creditEarnedMinutes) ||
                other.creditEarnedMinutes == creditEarnedMinutes) &&
            (identical(other.deficitMinutes, deficitMinutes) ||
                other.deficitMinutes == deficitMinutes) &&
            (identical(other.isValidDay, isValidDay) ||
                other.isValidDay == isValidDay) &&
            (identical(other.isInsufficientDay, isInsufficientDay) ||
                other.isInsufficientDay == isInsufficientDay) &&
            (identical(other.hasApprovedException, hasApprovedException) ||
                other.hasApprovedException == hasApprovedException) &&
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
      summaryDate,
      cycleStart,
      totalWorkedMinutes,
      creditEarnedMinutes,
      deficitMinutes,
      isValidDay,
      isInsufficientDay,
      hasApprovedException,
      createdAt,
      updatedAt);

  /// Create a copy of DailySummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailySummaryModelImplCopyWith<_$DailySummaryModelImpl> get copyWith =>
      __$$DailySummaryModelImplCopyWithImpl<_$DailySummaryModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailySummaryModelImplToJson(
      this,
    );
  }
}

abstract class _DailySummaryModel implements DailySummaryModel {
  const factory _DailySummaryModel(
      {required final String id,
      required final String userId,
      required final DateTime summaryDate,
      required final DateTime cycleStart,
      final int totalWorkedMinutes,
      final int creditEarnedMinutes,
      final int deficitMinutes,
      final bool isValidDay,
      final bool isInsufficientDay,
      final bool hasApprovedException,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$DailySummaryModelImpl;

  factory _DailySummaryModel.fromJson(Map<String, dynamic> json) =
      _$DailySummaryModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get summaryDate;
  @override
  DateTime get cycleStart;
  @override
  int get totalWorkedMinutes;
  @override
  int get creditEarnedMinutes;
  @override
  int get deficitMinutes;
  @override
  bool get isValidDay;
  @override
  bool get isInsufficientDay;
  @override
  bool get hasApprovedException;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of DailySummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailySummaryModelImplCopyWith<_$DailySummaryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
