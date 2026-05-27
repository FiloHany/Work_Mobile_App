import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../services/holiday_api_service.dart';
import 'supabase_provider.dart';

class HolidayInfo {
  const HolidayInfo({required this.date, required this.name});
  final DateTime date;
  final String name;
}

/// All holidays as a list (for display) and a set of dates (for fast lookup).
class HolidaysData {
  const HolidaysData({this.all = const [], this.dates = const {}});
  final List<HolidayInfo> all;
  final Set<DateTime> dates;

  bool isHoliday(DateTime date) => dates.contains(date.dateOnly);

  HolidayInfo? infoFor(DateTime date) {
    final d = date.dateOnly;
    try {
      return all.firstWhere((h) => h.date == d);
    } catch (_) {
      return null;
    }
  }
}

/// Provides all public holidays for the current and adjacent years.
///
/// On every load the provider attempts to sync from Google Calendar's public
/// iCal feed and persists new entries into [holiday_calendar] via the
/// [sync_holidays] RPC. The RPC uses ON CONFLICT DO NOTHING, so authoritative
/// data seeded by database migrations is never overwritten by the API.
/// If the network or RPC call fails, existing cached rows are used instead.
final holidaysProvider = FutureProvider<HolidaysData>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final svc = HolidayApiService();
  final now = DateTime.now();

  // ── Step 1: attempt a background sync from Google Calendar iCal ──────────
  for (final year in [now.year - 1, now.year, now.year + 1]) {
    try {
      final fetched = await svc.fetchYear(year);
      if (fetched.isEmpty) continue;

      await client.rpc('sync_holidays', params: {
        'holidays': fetched
            .map((h) => {
                  'holiday_date': h.date.isoDate,
                  'name': h.name,
                  'is_national': true,
                })
            .toList(),
      });
    } catch (_) {
      // Network or RPC failure — continue with cached data.
    }
  }

  // ── Step 2: read the complete authoritative set from Supabase ─────────────
  try {
    final rows = await client
        .from(AppConstants.tableHolidayCalendar)
        .select('holiday_date, name')
        .order('holiday_date', ascending: true);

    final all = (rows as List).map(_rowToInfo).toList();
    final dateSet = all.map((h) => h.date).toSet();
    return HolidaysData(all: all, dates: dateSet);
  } catch (_) {
    return const HolidaysData();
  }
});

HolidayInfo _rowToInfo(dynamic r) {
  final d = DateTime.parse(r['holiday_date'] as String).dateOnly;
  return HolidayInfo(date: d, name: r['name'] as String);
}
