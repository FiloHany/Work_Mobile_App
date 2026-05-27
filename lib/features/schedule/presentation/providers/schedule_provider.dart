import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/supabase_provider.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../domain/entities/schedule_entry.dart';

class ScheduleState {
  const ScheduleState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ScheduleEntry> entries;
  final bool isLoading;
  final String? error;

  ScheduleState copyWith({
    List<ScheduleEntry>? entries,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ScheduleState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  Map<int, List<ScheduleEntry>> get byDay {
    final map = <int, List<ScheduleEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.dayOfWeek, () => []).add(e);
    }
    return map;
  }
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier(this._repo, this._userId) : super(const ScheduleState()) {
    load();
  }

  final ScheduleRepository _repo;
  final String _userId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _repo.fetchAllEntries(_userId);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addEntry({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required ScheduleEntryType entryType,
    required String title,
    String? groupName,
    String? location,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entry = await _repo.addEntry(
        userId: _userId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        entryType: entryType,
        title: title,
        groupName: groupName,
        location: location,
      );
      state = state.copyWith(
        entries: [...state.entries, entry],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateEntry(ScheduleEntry entry) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repo.updateEntry(entry);
      state = state.copyWith(
        entries:
            state.entries.map((e) => e.id == updated.id ? updated : e).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEntry(String entryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.deleteEntry(entryId: entryId, userId: _userId);
      state = state.copyWith(
        entries: state.entries.where((e) => e.id != entryId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return ScheduleNotifier(ref.read(scheduleRepositoryProvider), userId);
});
