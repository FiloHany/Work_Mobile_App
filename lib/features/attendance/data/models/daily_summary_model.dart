import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_summary_model.freezed.dart';
part 'daily_summary_model.g.dart';

@freezed
class DailySummaryModel with _$DailySummaryModel {
  const factory DailySummaryModel({
    required String id,
    required String userId,
    required DateTime summaryDate,
    required DateTime cycleStart,
    @Default(0) int totalWorkedMinutes,
    @Default(0) int creditEarnedMinutes,
    @Default(0) int deficitMinutes,
    @Default(false) bool isValidDay,
    @Default(false) bool isInsufficientDay,
    @Default(false) bool hasApprovedException,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DailySummaryModel;

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$DailySummaryModelFromJson(json);
}
