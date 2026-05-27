// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'correction_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CorrectionRequest _$CorrectionRequestFromJson(Map<String, dynamic> json) {
  return _CorrectionRequest.fromJson(json);
}

/// @nodoc
mixin _$CorrectionRequest {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get targetDate => throw _privateConstructorUsedError;
  CorrectionType get requestType => throw _privateConstructorUsedError;
  DateTime? get requestedCheckIn => throw _privateConstructorUsedError;
  DateTime? get requestedCheckOut => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  CorrectionStatus get status => throw _privateConstructorUsedError;
  String? get sessionId => throw _privateConstructorUsedError;
  String? get reviewerNotes => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CorrectionRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CorrectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CorrectionRequestCopyWith<CorrectionRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CorrectionRequestCopyWith<$Res> {
  factory $CorrectionRequestCopyWith(
          CorrectionRequest value, $Res Function(CorrectionRequest) then) =
      _$CorrectionRequestCopyWithImpl<$Res, CorrectionRequest>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime targetDate,
      CorrectionType requestType,
      DateTime? requestedCheckIn,
      DateTime? requestedCheckOut,
      String reason,
      CorrectionStatus status,
      String? sessionId,
      String? reviewerNotes,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$CorrectionRequestCopyWithImpl<$Res, $Val extends CorrectionRequest>
    implements $CorrectionRequestCopyWith<$Res> {
  _$CorrectionRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CorrectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? targetDate = null,
    Object? requestType = null,
    Object? requestedCheckIn = freezed,
    Object? requestedCheckOut = freezed,
    Object? reason = null,
    Object? status = null,
    Object? sessionId = freezed,
    Object? reviewerNotes = freezed,
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
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requestType: null == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as CorrectionType,
      requestedCheckIn: freezed == requestedCheckIn
          ? _value.requestedCheckIn
          : requestedCheckIn // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      requestedCheckOut: freezed == requestedCheckOut
          ? _value.requestedCheckOut
          : requestedCheckOut // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CorrectionStatus,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewerNotes: freezed == reviewerNotes
          ? _value.reviewerNotes
          : reviewerNotes // ignore: cast_nullable_to_non_nullable
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
abstract class _$$CorrectionRequestImplCopyWith<$Res>
    implements $CorrectionRequestCopyWith<$Res> {
  factory _$$CorrectionRequestImplCopyWith(_$CorrectionRequestImpl value,
          $Res Function(_$CorrectionRequestImpl) then) =
      __$$CorrectionRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime targetDate,
      CorrectionType requestType,
      DateTime? requestedCheckIn,
      DateTime? requestedCheckOut,
      String reason,
      CorrectionStatus status,
      String? sessionId,
      String? reviewerNotes,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$CorrectionRequestImplCopyWithImpl<$Res>
    extends _$CorrectionRequestCopyWithImpl<$Res, _$CorrectionRequestImpl>
    implements _$$CorrectionRequestImplCopyWith<$Res> {
  __$$CorrectionRequestImplCopyWithImpl(_$CorrectionRequestImpl _value,
      $Res Function(_$CorrectionRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of CorrectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? targetDate = null,
    Object? requestType = null,
    Object? requestedCheckIn = freezed,
    Object? requestedCheckOut = freezed,
    Object? reason = null,
    Object? status = null,
    Object? sessionId = freezed,
    Object? reviewerNotes = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CorrectionRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      targetDate: null == targetDate
          ? _value.targetDate
          : targetDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requestType: null == requestType
          ? _value.requestType
          : requestType // ignore: cast_nullable_to_non_nullable
              as CorrectionType,
      requestedCheckIn: freezed == requestedCheckIn
          ? _value.requestedCheckIn
          : requestedCheckIn // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      requestedCheckOut: freezed == requestedCheckOut
          ? _value.requestedCheckOut
          : requestedCheckOut // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CorrectionStatus,
      sessionId: freezed == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewerNotes: freezed == reviewerNotes
          ? _value.reviewerNotes
          : reviewerNotes // ignore: cast_nullable_to_non_nullable
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
class _$CorrectionRequestImpl implements _CorrectionRequest {
  const _$CorrectionRequestImpl(
      {required this.id,
      required this.userId,
      required this.targetDate,
      required this.requestType,
      this.requestedCheckIn,
      this.requestedCheckOut,
      required this.reason,
      this.status = CorrectionStatus.pending,
      this.sessionId,
      this.reviewerNotes,
      this.createdAt,
      this.updatedAt});

  factory _$CorrectionRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CorrectionRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime targetDate;
  @override
  final CorrectionType requestType;
  @override
  final DateTime? requestedCheckIn;
  @override
  final DateTime? requestedCheckOut;
  @override
  final String reason;
  @override
  @JsonKey()
  final CorrectionStatus status;
  @override
  final String? sessionId;
  @override
  final String? reviewerNotes;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CorrectionRequest(id: $id, userId: $userId, targetDate: $targetDate, requestType: $requestType, requestedCheckIn: $requestedCheckIn, requestedCheckOut: $requestedCheckOut, reason: $reason, status: $status, sessionId: $sessionId, reviewerNotes: $reviewerNotes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CorrectionRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.requestType, requestType) ||
                other.requestType == requestType) &&
            (identical(other.requestedCheckIn, requestedCheckIn) ||
                other.requestedCheckIn == requestedCheckIn) &&
            (identical(other.requestedCheckOut, requestedCheckOut) ||
                other.requestedCheckOut == requestedCheckOut) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.reviewerNotes, reviewerNotes) ||
                other.reviewerNotes == reviewerNotes) &&
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
      targetDate,
      requestType,
      requestedCheckIn,
      requestedCheckOut,
      reason,
      status,
      sessionId,
      reviewerNotes,
      createdAt,
      updatedAt);

  /// Create a copy of CorrectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CorrectionRequestImplCopyWith<_$CorrectionRequestImpl> get copyWith =>
      __$$CorrectionRequestImplCopyWithImpl<_$CorrectionRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CorrectionRequestImplToJson(
      this,
    );
  }
}

abstract class _CorrectionRequest implements CorrectionRequest {
  const factory _CorrectionRequest(
      {required final String id,
      required final String userId,
      required final DateTime targetDate,
      required final CorrectionType requestType,
      final DateTime? requestedCheckIn,
      final DateTime? requestedCheckOut,
      required final String reason,
      final CorrectionStatus status,
      final String? sessionId,
      final String? reviewerNotes,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$CorrectionRequestImpl;

  factory _CorrectionRequest.fromJson(Map<String, dynamic> json) =
      _$CorrectionRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get targetDate;
  @override
  CorrectionType get requestType;
  @override
  DateTime? get requestedCheckIn;
  @override
  DateTime? get requestedCheckOut;
  @override
  String get reason;
  @override
  CorrectionStatus get status;
  @override
  String? get sessionId;
  @override
  String? get reviewerNotes;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of CorrectionRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CorrectionRequestImplCopyWith<_$CorrectionRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
