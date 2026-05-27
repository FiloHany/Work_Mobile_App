abstract final class AppConstants {
  static const String appName = 'WorkHours';
  static const String appVersion = '1.0.0';

  // Storage keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationToken = 'fcm_token';
  static const String keyLastSyncAt = 'last_sync_at';

  // Supabase table names
  static const String tableProfiles = 'profiles';
  static const String tableDepartments = 'departments';
  static const String tableAttendanceSessions = 'attendance_sessions';
  static const String tableDailySummaries = 'daily_attendance_summaries';
  static const String tableSchedules = 'schedules';
  static const String tableScheduleEntries = 'schedule_entries';
  static const String tableScheduleExceptions = 'schedule_exceptions';
  static const String tableWorkCycles = 'work_cycles';
  static const String tableCorrectionRequests = 'correction_requests';
  static const String tableHolidayCalendar = 'holiday_calendar';
  static const String tableNotificationPreferences = 'notification_preferences';
  static const String tableDeviceTokens = 'device_tokens';

  // UI
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double pagePadding = 20.0;
}
