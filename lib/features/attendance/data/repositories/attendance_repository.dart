import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/work_rules.dart';
import '../../../../core/engine/hours_rule_engine.dart';
import '../../../../core/engine/work_cycle_calculator.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/attendance_session.dart';
import '../models/daily_summary_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.read(supabaseClientProvider));
});

abstract interface class AttendanceRepositoryPort {
  Future<AttendanceSession?> activeSession(String userId);

  Future<AttendanceSession?> activeSessionToday(String userId);

  Future<AttendanceSession> checkIn({
    required String userId,
    String? notes,
    DateTime? checkInTime,
  });

  Future<AttendanceSession> checkOut({
    required String sessionId,
    required String userId,
    String? notes,
    DateTime? checkOutTime,
  });

  Future<List<AttendanceSession>> fetchSessions({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<DailySummaryModel>> fetchSummaries({
    required String userId,
    required DateTime cycleStart,
    required DateTime cycleEnd,
  });

  Future<Duration> fetchAvailableCredit({
    required String userId,
    required DateTime cycleStart,
  });
}

class AttendanceRepository implements AttendanceRepositoryPort {
  AttendanceRepository(
    this._client, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;

  /// Returns the newest open session, even if it started before today.
  ///
  /// A missed checkout should remain visible after midnight; otherwise the app
  /// can silently create a second open session and corrupt worked-time totals.
  @override
  Future<AttendanceSession?> activeSession(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final rows = await _client
          .from(AppConstants.tableAttendanceSessions)
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('check_in_time', ascending: false)
          .limit(1);

      if ((rows as List).isEmpty) return null;
      return AttendanceSession.fromJson(_mapRow(rows.first));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AttendanceSession?> activeSessionToday(String userId) async {
    if (userId.isEmpty) return null;

    try {
      final today = _now().toLocal().isoDate;
      final rows = await _client
          .from(AppConstants.tableAttendanceSessions)
          .select()
          .eq('user_id', userId)
          .eq('session_date', today)
          .eq('status', 'active')
          .limit(1);

      if ((rows as List).isEmpty) return null;
      return AttendanceSession.fromJson(_mapRow(rows.first));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AttendanceSession> checkIn({
    required String userId,
    String? notes,
    DateTime? checkInTime,
  }) async {
    if (userId.isEmpty) {
      throw const AuthException('You must be signed in to check in.');
    }

    try {
      final effectiveCheckIn = (checkInTime ?? _now()).toLocal();

      if (!WorkRules.isBeforeCheckInDeadline(effectiveCheckIn)) {
        throw const AttendanceException(
          'Check-in is not allowed after 11:30 AM.',
        );
      }

      final sessionDate = effectiveCheckIn.dateOnly;
      final utcCheckIn = effectiveCheckIn.toUtc();

      await _ensureCanCheckIn(userId: userId, sessionDate: sessionDate);

      final data = await _client
          .from(AppConstants.tableAttendanceSessions)
          .insert({
            'user_id': userId,
            'session_date': sessionDate.isoDate,
            'check_in_time': utcCheckIn.toIso8601String(),
            if (notes != null) 'notes': notes,
            'status': 'active',
          })
          .select()
          .single();

      return AttendanceSession.fromJson(_mapRow(data));
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<AttendanceSession> checkOut({
    required String sessionId,
    required String userId,
    String? notes,
    DateTime? checkOutTime,
  }) async {
    if (userId.isEmpty) {
      throw const AuthException('You must be signed in to check out.');
    }

    try {
      final utcCheckOut = (checkOutTime ?? _now()).toLocal().toUtc();
      final data = await _client
          .from(AppConstants.tableAttendanceSessions)
          .update({
            'check_out_time': utcCheckOut.toIso8601String(),
            'status': 'completed',
            if (notes != null) 'notes': notes,
          })
          .eq('id', sessionId)
          .eq('user_id', userId)
          .eq('status', 'active')
          .select()
          .single();

      final session = AttendanceSession.fromJson(_mapRow(data));
      await _upsertDailySummary(userId: userId, session: session);
      return session;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<AttendanceSession>> fetchSessions({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await _client
          .from(AppConstants.tableAttendanceSessions)
          .select()
          .eq('user_id', userId)
          .gte('session_date', from.isoDate)
          .lte('session_date', to.isoDate)
          .order('session_date', ascending: false);

      return (rows as List)
          .map((r) => AttendanceSession.fromJson(_mapRow(r)))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<DailySummaryModel>> fetchSummaries({
    required String userId,
    required DateTime cycleStart,
    required DateTime cycleEnd,
  }) async {
    try {
      final rows = await _client
          .from(AppConstants.tableDailySummaries)
          .select()
          .eq('user_id', userId)
          .gte('summary_date', cycleStart.isoDate)
          .lte('summary_date', cycleEnd.isoDate)
          .order('summary_date', ascending: true);

      return (rows as List)
          .map((r) => DailySummaryModel.fromJson(_mapRow(r)))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Duration> fetchAvailableCredit({
    required String userId,
    required DateTime cycleStart,
  }) async {
    try {
      final rows = await _client
          .from(AppConstants.tableDailySummaries)
          .select('credit_earned_minutes, deficit_minutes')
          .eq('user_id', userId)
          .eq('cycle_start', cycleStart.isoDate);

      int creditMinutes = 0;
      int deficitMinutes = 0;
      for (final r in (rows as List)) {
        creditMinutes +=
            (r['credit_earned_minutes'] as num?)?.toInt() ?? 0;
        deficitMinutes +=
            (r['deficit_minutes'] as num?)?.toInt() ?? 0;
      }
      // Positive = usable credit; negative = outstanding debt from short days.
      return Duration(minutes: creditMinutes - deficitMinutes);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Directly applies a user self-service correction for [targetDate].
  ///
  /// Delegates to the `apply_attendance_correction` SECURITY DEFINER RPC which
  /// bypasses the UPDATE RLS policy and the no_future_checkin constraint.
  Future<AttendanceSession> applyCorrection({
    required String userId,
    required DateTime targetDate,
    DateTime? newCheckIn,
    DateTime? newCheckOut,
  }) async {
    if (userId.isEmpty) {
      throw const AuthException('Not authenticated.');
    }
    try {
      final dateStr = targetDate.toLocal().isoDate;

      await _client.rpc('apply_attendance_correction', params: {
        'p_target_date': dateStr,
        'p_check_in_time': newCheckIn?.toUtc().toIso8601String(),
        'p_check_out_time': newCheckOut?.toUtc().toIso8601String(),
      });

      final rows = await _client
          .from(AppConstants.tableAttendanceSessions)
          .select()
          .eq('user_id', userId)
          .eq('session_date', dateStr)
          .neq('status', 'voided')
          .order('created_at', ascending: false)
          .limit(1);

      if ((rows as List).isEmpty) {
        throw const AttendanceException(
            'Correction applied but session not found.');
      }

      final session = AttendanceSession.fromJson(_mapRow(rows.first));
      if (session.checkOutTime != null) {
        await _upsertDailySummary(userId: userId, session: session);
      }
      return session;
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<void> _upsertDailySummary({
    required String userId,
    required AttendanceSession session,
  }) async {
    if (session.checkOutTime == null) return;

    final dateStr = session.sessionDate.isoDate;

    // Check if the session date falls on a public holiday.
    bool isHoliday = false;
    try {
      final rows = await _client
          .from(AppConstants.tableHolidayCalendar)
          .select('name')
          .eq('holiday_date', dateStr)
          .limit(1);
      isHoliday = (rows as List).isNotEmpty;
    } catch (_) {}

    final result = HoursRuleEngine.analyseSession(
      checkIn: session.checkInTime,
      checkOut: session.checkOutTime,
      hasException: session.isApprovedException,
      isHoliday: isHoliday,
    );
    final worked = result.workedDuration;
    final cycle = WorkCycleCalculator.currentCycle(session.checkInTime);

    await _client.rpc('upsert_daily_summary', params: {
      'p_user_id': userId,
      'p_date': dateStr,
      'p_cycle_start': cycle.start.isoDate,
      'p_worked_minutes': worked.inMinutes,
      'p_credit_minutes': result.creditEarned.inMinutes,
      'p_deficit_minutes': result.deficit.inMinutes,
      'p_is_valid': result.isValid,
      'p_is_insufficient': result.isInsufficient,
      'p_has_exception': session.isApprovedException || isHoliday,
    });
  }

  Future<void> _ensureCanCheckIn({
    required String userId,
    required DateTime sessionDate,
  }) async {
    final openSession = await activeSession(userId);
    if (openSession != null) {
      throw const AttendanceException(
        'You already have an active check-in. Check out before starting a new session.',
      );
    }

    final rows = await _client
        .from(AppConstants.tableAttendanceSessions)
        .select('id, status')
        .eq('user_id', userId)
        .eq('session_date', sessionDate.isoDate)
        .neq('status', 'voided')
        .limit(1);

    if ((rows as List).isNotEmpty) {
      throw const AttendanceException(
        'Attendance for this day is already recorded.',
      );
    }
  }

  Map<String, dynamic> _mapRow(Map<String, dynamic> row) => row;
}
