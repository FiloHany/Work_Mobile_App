import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/extensions/datetime_extensions.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../domain/entities/schedule_entry.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.read(supabaseClientProvider));
});

class ScheduleRepository {
  ScheduleRepository(this._client);
  final SupabaseClient _client;

  /// Returns the user's active schedule id, creating one if absent.
  Future<String> _ensureActiveSchedule(String userId) async {
    final rows = await _client
        .from(AppConstants.tableSchedules)
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);

    if ((rows as List).isNotEmpty) {
      return rows.first['id'] as String;
    }

    // Create a default schedule.
    final data = await _client
        .from(AppConstants.tableSchedules)
        .insert({
          'user_id': userId,
          'name': 'My Schedule',
          'is_active': true,
          'effective_from': DateTime.now().isoDate,
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  Future<List<ScheduleEntry>> fetchAllEntries(String userId) async {
    try {
      final rows = await _client
          .from(AppConstants.tableScheduleEntries)
          .select()
          .eq('user_id', userId)
          .order('day_of_week')
          .order('start_time');
      return (rows as List)
          .map((r) => ScheduleEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  /// Entries for today's day-of-week (0=Sunday … 6=Saturday).
  Future<List<ScheduleEntry>> fetchTodayEntries(
      {required String userId}) async {
    try {
      // DateTime.weekday: Mon=1…Sun=7. DB uses 0=Sun…6=Sat.
      final today = DateTime.now();
      final dbDow = today.weekday == DateTime.sunday ? 0 : today.weekday;

      final rows = await _client
          .from(AppConstants.tableScheduleEntries)
          .select()
          .eq('user_id', userId)
          .eq('day_of_week', dbDow)
          .order('start_time');
      return (rows as List)
          .map((r) => ScheduleEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<List<ScheduleEntry>> fetchEntriesForDay({
    required String userId,
    required int dayOfWeek,
  }) async {
    try {
      final rows = await _client
          .from(AppConstants.tableScheduleEntries)
          .select()
          .eq('user_id', userId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');
      return (rows as List)
          .map((r) => ScheduleEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<ScheduleEntry> addEntry({
    required String userId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required ScheduleEntryType entryType,
    required String title,
    String? groupName,
    String? location,
  }) async {
    try {
      final scheduleId = await _ensureActiveSchedule(userId);
      final data = await _client
          .from(AppConstants.tableScheduleEntries)
          .insert({
            'schedule_id': scheduleId,
            'user_id': userId,
            'day_of_week': dayOfWeek,
            'start_time': startTime,
            'end_time': endTime,
            'entry_type': entryType.dbValue,
            'title': title,
            if (groupName != null) 'group_name': groupName,
            'location': location,
          })
          .select()
          .single();
      return ScheduleEntry.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<ScheduleEntry> updateEntry(ScheduleEntry entry) async {
    try {
      final data = await _client
          .from(AppConstants.tableScheduleEntries)
          .update({
            'day_of_week': entry.dayOfWeek,
            'start_time': entry.startTime,
            'end_time': entry.endTime,
            'entry_type': entry.entryType.dbValue,
            'title': entry.title,
            'group_name': entry.groupName,
            'location': entry.location,
          })
          .eq('id', entry.id)
          .eq('user_id', entry.userId)
          .select()
          .single();
      return ScheduleEntry.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<void> deleteEntry({
    required String entryId,
    required String userId,
  }) async {
    try {
      await _client
          .from(AppConstants.tableScheduleEntries)
          .delete()
          .eq('id', entryId)
          .eq('user_id', userId);
    } catch (e) {
      throw mapException(e);
    }
  }
}
