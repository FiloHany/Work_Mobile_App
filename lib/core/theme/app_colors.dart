import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A3A6B);
  static const Color primaryLight = Color(0xFF2E5FA3);
  static const Color primaryDark = Color(0xFF0F2347);

  static const Color accent = Color(0xFF00C7B1);
  static const Color accentLight = Color(0xFF33D4C1);
  static const Color accentDark = Color(0xFF009E8E);

  // ── Backgrounds ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1F8);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF5A6A7E);
  static const Color textHint = Color(0xFFADB5C5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9E6B);
  static const Color successLight = Color(0xFFE6F5EF);
  static const Color warning = Color(0xFFD4820A);
  static const Color warningLight = Color(0xFFFFF3DC);
  static const Color error = Color(0xFFD63031);
  static const Color errorLight = Color(0xFFFDECEC);
  static const Color info = Color(0xFF2979FF);
  static const Color infoLight = Color(0xFFE8F0FF);

  // ── Attendance status ────────────────────────────────────────────────────
  static const Color statusValid = success;
  static const Color statusValidBg = successLight;
  static const Color statusInsufficient = error;
  static const Color statusInsufficientBg = errorLight;
  static const Color statusInProgress = Color(0xFF0C7BB3);
  static const Color statusInProgressBg = Color(0xFFE1F3FC);
  static const Color statusAbsent = textHint;
  static const Color statusAbsentBg = surfaceVariant;

  // ── UI chrome ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE4E8F0);
  static const Color border = Color(0xFFD0D7E3);
  static const Color shadow = Color(0x14000000);
  static const Color overlay = Color(0x80000000);

  // ── Progress / Charts ────────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFE4E8F0);
  static const Color progressFill = primary;
  static const Color progressCredit = accent;
  static const Color progressDeficit = error;
}
