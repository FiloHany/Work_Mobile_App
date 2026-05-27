import 'package:freezed_annotation/freezed_annotation.dart';

part 'correction_request.freezed.dart';
part 'correction_request.g.dart';

enum CorrectionType {
  @JsonValue('missed_check_in')
  missedCheckIn,
  @JsonValue('missed_check_out')
  missedCheckOut,
  @JsonValue('full_correction')
  fullCorrection;

  String get label => switch (this) {
        missedCheckIn => 'Missed Check-In',
        missedCheckOut => 'Missed Check-Out',
        fullCorrection => 'Full Correction',
      };

  String get dbValue => switch (this) {
        missedCheckIn => 'missed_check_in',
        missedCheckOut => 'missed_check_out',
        fullCorrection => 'full_correction',
      };
}

enum CorrectionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected;

  String get label => switch (this) {
        pending => 'Pending',
        approved => 'Applied',
        rejected => 'Rejected',
      };
}

@freezed
class CorrectionRequest with _$CorrectionRequest {
  const factory CorrectionRequest({
    required String id,
    required String userId,
    required DateTime targetDate,
    required CorrectionType requestType,
    DateTime? requestedCheckIn,
    DateTime? requestedCheckOut,
    required String reason,
    @Default(CorrectionStatus.pending) CorrectionStatus status,
    String? sessionId,
    String? reviewerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CorrectionRequest;

  factory CorrectionRequest.fromJson(Map<String, dynamic> json) =>
      _$CorrectionRequestFromJson(json);
}
