import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../shared/providers/holidays_provider.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../../attendance/domain/entities/attendance_session.dart';
import '../../../schedule/data/repositories/schedule_repository.dart';
import '../../../schedule/domain/entities/schedule_entry.dart';

class TodayState {
  const TodayState({
    this.session,
    this.result,
    this.availableCredit = Duration.zero,
    this.todayEntries = const [],
    this.isLoading = false,
    this.isHoliday = false,
    this.holidayName,
  });

  final AttendanceSession? session;
  final DailyCalculationResult? result;
  final Duration availableCredit;
  final List<ScheduleEntry> todayEntries;
  final bool isLoading;
  final bool isHoliday;
  final String? holidayName;

  bool get isCheckedIn => session?.isActive == true;
}

final todayProvider = FutureProvider<TodayState>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const TodayState();

  final holidaysAsync = ref.watch(holidaysProvider);
  final holidays =
      holidaysAsync.maybeWhen(data: (h) => h, orElse: () => const HolidaysData());

  final attendanceRepo = ref.read(attendanceRepositoryProvider);
  final scheduleRepo = ref.read(scheduleRepositoryProvider);
  final cycle = WorkCycleCalculator.currentCycle();

  // Sequential awaits avoid Future.wait generic inference issues.
  final session = await attendanceRepo.activeSession(userId);
  final credit = await attendanceRepo.fetchAvailableCredit(
    userId: userId,
    cycleStart: cycle.start,
  );
  final entries = await scheduleRepo.fetchTodayEntries(userId: userId);

  final today = DateTime.now();
  final isHoliday = holidays.isHoliday(today);
  final holidayName = holidays.infoFor(today)?.name;

  DailyCalculationResult? result;
  if (session != null) {
    result = HoursRuleEngine.analyseSession(
      checkIn: session.checkInTime,
      checkOut: session.checkOutTime,
      availableCredit: credit,
      hasException: session.isApprovedException,
      isHoliday: isHoliday,
    );
  }

  return TodayState(
    session: session,
    result: result,
    availableCredit: credit,
    todayEntries: entries,
    isHoliday: isHoliday,
    holidayName: holidayName,
  );
});
