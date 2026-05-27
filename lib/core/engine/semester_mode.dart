import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SemesterMode {
  semester,
  finals,
  summer;

  static const _prefKey = 'semester_mode';

  String get label => switch (this) {
        SemesterMode.semester => 'Regular Semester',
        SemesterMode.finals => 'Final Exams',
        SemesterMode.summer => 'Summer / Off Season',
      };

  String get subtitle => switch (this) {
        SemesterMode.semester => 'Schedule-based optimization',
        SemesterMode.finals => 'Optimize by check-in hours only',
        SemesterMode.summer => 'Optimize by check-in hours only',
      };

  IconData get icon => switch (this) {
        SemesterMode.semester => Icons.school_outlined,
        SemesterMode.finals => Icons.menu_book_outlined,
        SemesterMode.summer => Icons.wb_sunny_outlined,
      };

  static SemesterMode _from(String? v) => switch (v) {
        'finals' => SemesterMode.finals,
        'summer' => SemesterMode.summer,
        _ => SemesterMode.semester,
      };
}

class SemesterModeNotifier extends AsyncNotifier<SemesterMode> {
  @override
  Future<SemesterMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SemesterMode._from(prefs.getString(SemesterMode._prefKey));
  }

  Future<void> setMode(SemesterMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SemesterMode._prefKey, mode.name);
    state = AsyncData(mode);
  }
}

final semesterModeProvider =
    AsyncNotifierProvider<SemesterModeNotifier, SemesterMode>(
  SemesterModeNotifier.new,
);
