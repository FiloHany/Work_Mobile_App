import 'dart:convert';
import 'dart:io';

import '../../core/extensions/datetime_extensions.dart';

/// Fetches Egyptian public holidays from Google Calendar's public iCal feed.
///
/// Uses the official Egyptian holidays calendar published by Google:
///   https://calendar.google.com/calendar/ical/
///   en.eg%23holiday%40group.v.calendar.google.com/public/basic.ics
///
/// No API key required. Multi-day holidays (e.g. Eid Al-Adha over 4 days)
/// are expanded into individual per-day entries. Falls back to an empty list
/// on any network or parse error so callers can use cached DB data.
class HolidayApiService {
  static const _icalUrl =
      'https://calendar.google.com/calendar/ical/'
      'en.eg%23holiday%40group.v.calendar.google.com/public/basic.ics';

  Future<List<({DateTime date, String name})>> fetchYear(int year) async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse(_icalUrl))
          .timeout(const Duration(seconds: 15));
      request.headers.set('Accept-Charset', 'utf-8');

      final response = await request.close();
      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      return _parseIcal(body, year);
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  // ── iCal parser ────────────────────────────────────────────────────────────

  static List<({DateTime date, String name})> _parseIcal(
      String ical, int year) {
    // Unfold RFC 5545 line continuations (CRLF/LF followed by whitespace).
    final unfolded = ical
        .replaceAll('\r\n ', '')
        .replaceAll('\r\n\t', '')
        .replaceAll('\n ', '')
        .replaceAll('\n\t', '');

    final lines = unfolded.split(RegExp(r'\r?\n'));
    final result = <({DateTime date, String name})>[];

    bool inEvent = false;
    String? summary;
    DateTime? startDate;
    DateTime? endDate;

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        summary = null;
        startDate = null;
        endDate = null;
        continue;
      }

      if (line == 'END:VEVENT') {
        if (inEvent && summary != null && startDate != null) {
          // DTEND is exclusive — last day = endDate - 1.
          final lastDay = endDate != null
              ? endDate.subtract(const Duration(days: 1))
              : startDate;

          // Expand multi-day holiday into one entry per day.
          DateTime cursor = startDate;
          while (!cursor.isAfter(lastDay)) {
            if (cursor.year == year) {
              result.add((date: cursor.dateOnly, name: summary));
            }
            cursor = cursor.add(const Duration(days: 1));
          }
        }
        inEvent = false;
        continue;
      }

      if (!inEvent) continue;

      if (line.startsWith('SUMMARY:')) {
        summary = line.substring(8).trim();
      } else if (line.startsWith('DTSTART;VALUE=DATE:')) {
        startDate = _parseIsoDate(line.substring(19));
      } else if (line.startsWith('DTSTART;TZID=')) {
        final colon = line.indexOf(':');
        if (colon != -1) startDate = _parseIsoDate(line.substring(colon + 1));
      } else if (line.startsWith('DTSTART:')) {
        startDate = _parseIsoDate(line.substring(8));
      } else if (line.startsWith('DTEND;VALUE=DATE:')) {
        endDate = _parseIsoDate(line.substring(17));
      } else if (line.startsWith('DTEND;TZID=')) {
        final colon = line.indexOf(':');
        if (colon != -1) endDate = _parseIsoDate(line.substring(colon + 1));
      } else if (line.startsWith('DTEND:')) {
        endDate = _parseIsoDate(line.substring(6));
      }
    }

    return result;
  }

  /// Parses the first 8 characters of an iCal date string (YYYYMMDD).
  static DateTime? _parseIsoDate(String s) {
    try {
      if (s.length < 8) return null;
      final y = int.parse(s.substring(0, 4));
      final m = int.parse(s.substring(4, 6));
      final d = int.parse(s.substring(6, 8));
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }
}
