import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/semester_mode.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../core/engine/work_optimizer.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/providers/holidays_provider.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/data/repositories/schedule_repository.dart';
import '../../../schedule/domain/entities/schedule_entry.dart';

class OptimizerData {
  const OptimizerData({
    required this.plan,
    required this.generatedAt,
    required this.ignoredScheduleEntries,
  });

  final WorkOptimizationPlan plan;
  final DateTime generatedAt;
  final int ignoredScheduleEntries;

  bool get hasIgnoredScheduleEntries => ignoredScheduleEntries > 0;
}

final optimizerProvider =
    FutureProvider.autoDispose<OptimizerData>((ref) async {
  final profile = ref.watch(profileProvider);
  final userId = profile?.id;
  if (userId == null) throw const AuthException('Not authenticated');

  final extraRest = profile?.restDays.toSet() ?? <int>{};
  final holidaysAsync = ref.watch(holidaysProvider);
  final holidays =
      holidaysAsync.maybeWhen(data: (h) => h.dates, orElse: () => <DateTime>{});
  final attendanceRepo = ref.read(attendanceRepositoryProvider);
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final now = DateTime.now();
  final cycle = WorkCycleCalculator.currentCycle(now);

  final summariesFuture = attendanceRepo.fetchSummaries(
    userId: userId,
    cycleStart: cycle.start,
    cycleEnd: cycle.end,
  );
  final activeFuture = attendanceRepo.activeSession(userId);
  final scheduleFuture = scheduleRepo.fetchAllEntries(userId);

  final summaries = await summariesFuture;
  final active = await activeFuture;
  final entries = await scheduleFuture;

  final semesterMode = ref.watch(semesterModeProvider).maybeWhen(
        data: (m) => m,
        orElse: () => SemesterMode.semester,
      );

  var ignoredScheduleEntries = 0;
  final scheduleBlocks = <OptimizerScheduleBlock>[];

  // In finals/summer mode the schedule is irrelevant — optimize by hours only.
  if (semesterMode == SemesterMode.semester) {
    for (final entry in entries) {
      if (entry.entryType == ScheduleEntryType.free) continue;

      final start = _minutesFromDbTime(entry.startTime);
      final end = _minutesFromDbTime(entry.endTime);
      final validDay = entry.dayOfWeek >= 0 && entry.dayOfWeek <= 6;
      if (!validDay || start == null || end == null || end <= start) {
        ignoredScheduleEntries++;
        continue;
      }

      scheduleBlocks.add(OptimizerScheduleBlock(
        dayOfWeek: entry.dayOfWeek,
        startMinute: start,
        endMinute: end,
      ));
    }
  }

  final plan = WorkOptimizer.buildPlan(
    cycle: cycle,
    now: now,
    workedDays: summaries
        .map((summary) => OptimizerWorkedDay(
              date: summary.summaryDate,
              workedMinutes: summary.totalWorkedMinutes,
            ))
        .toList(),
    scheduleBlocks: scheduleBlocks,
    activeCheckIn: active?.checkInTime,
    extraRestWeekdays: extraRest,
    holidays: holidays,
  );

  return OptimizerData(
    plan: plan,
    generatedAt: now,
    ignoredScheduleEntries: ignoredScheduleEntries,
  );
});

int? _minutesFromDbTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  return (hour * 60) + minute;
}
