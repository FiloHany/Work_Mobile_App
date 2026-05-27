import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/semester_mode.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../schedule/domain/entities/schedule_entry.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';

const _arrivalBufferMinutes = 30;

/// Per-weekday arrival alarm times derived from the user's semester schedule.
/// Returns null when in finals/summer mode (manual times apply instead).
final smartAlarmTimesProvider =
    Provider<Map<int, ({int hour, int minute})>?>((ref) {
  final semesterMode = ref.watch(semesterModeProvider).maybeWhen(
        data: (m) => m,
        orElse: () => SemesterMode.semester,
      );

  if (semesterMode != SemesterMode.semester) return null;

  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  final entries = ref.watch(scheduleProvider).entries;
  return _computePerDayArrivalTimes(entries);
});

Map<int, ({int hour, int minute})> _computePerDayArrivalTimes(
    List<ScheduleEntry> entries) {
  // Group non-free entries by dayOfWeek (0=Sun … 6=Sat).
  final byDay = <int, List<ScheduleEntry>>{};
  for (final e in entries) {
    if (e.entryType == ScheduleEntryType.free) continue;
    byDay.putIfAbsent(e.dayOfWeek, () => []).add(e);
  }

  final result = <int, ({int hour, int minute})>{};
  for (final day in byDay.entries) {
    final sorted = [...day.value]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final parts = sorted.first.startTime.split(':');
    if (parts.length < 2) continue;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) continue;

    final alarmMinutes = h * 60 + m - _arrivalBufferMinutes;
    if (alarmMinutes < 0) continue;

    result[day.key] = (
      hour: alarmMinutes ~/ 60,
      minute: alarmMinutes % 60,
    );
  }
  return result;
}
