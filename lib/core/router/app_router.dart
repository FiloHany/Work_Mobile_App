import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../features/onboarding/presentation/screens/schedule_wizard_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/attendance/presentation/screens/check_in_out_screen.dart';
import '../../features/attendance/presentation/screens/attendance_history_screen.dart';
import '../../features/schedule/presentation/screens/schedule_list_screen.dart';
import '../../features/schedule/presentation/screens/schedule_editor_screen.dart';
import '../../features/schedule/presentation/screens/schedule_ocr_import_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reports/presentation/screens/cycle_summary_screen.dart';
import '../../features/corrections/presentation/screens/correction_form_screen.dart';
import '../../features/corrections/presentation/screens/corrections_history_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/optimizer/presentation/screens/optimizer_screen.dart';
import '../../features/optimizer/presentation/screens/optimizer_simulator_screen.dart';
import '../../features/settings/presentation/screens/holidays_screen.dart';
import '../../shared/widgets/app_shell.dart';

// ── Route names ──────────────────────────────────────────────────────────────

abstract final class Routes {
  static const splash = '/';
  static const login = '/register';
  static const profileSetup = '/profile-setup';
  static const today = '/today';
  static const dashboard = '/dashboard';
  static const checkInOut = '/attendance/check-in-out';
  static const history = '/attendance/history';
  static const schedule = '/schedule';
  static const scheduleEditor = '/schedule/editor';
  static const reports = '/reports';
  static const cycleSummary = '/reports/cycle';
  static const correctionForm = '/corrections/new';
  static const correctionsHistory = '/corrections/history';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const optimizer = '/optimizer';
  static const optimizerSimulator = '/optimizer/simulator';
  static const scheduleWizard = '/schedule-wizard';
  static const scheduleOcrImport = '/schedule/ocr-import';
  static const holidays = '/holidays';
}

// ── Provider ─────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(
    Supabase.instance.client.auth.onAuthStateChange,
  );

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Registration (first-time users only) ──────────────────────────────
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Profile setup (optional, accessible via Settings) ─────────────────
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // ── Main shell with bottom nav ─────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Today
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.today,
              builder: (_, __) => const TodayScreen(),
              routes: [
                GoRoute(
                  path: 'check-in-out',
                  builder: (_, __) => const CheckInOutScreen(),
                ),
              ],
            ),
          ]),

          // Tab 1 — Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.dashboard,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),

          // Tab 2 — History / Reports
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.history,
              builder: (_, __) => const AttendanceHistoryScreen(),
              routes: [
                GoRoute(
                  path: 'reports',
                  builder: (_, __) => const ReportsScreen(),
                  routes: [
                    GoRoute(
                      path: 'cycle',
                      builder: (_, __) => const CycleSummaryScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ]),

          // Tab 3 — Settings
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),

      // ── Floating / modal routes (outside shell) ────────────────────────────
      GoRoute(
        path: Routes.checkInOut,
        builder: (_, __) => const CheckInOutScreen(),
      ),
      GoRoute(
        path: Routes.reports,
        builder: (_, __) => const ReportsScreen(),
        routes: [
          GoRoute(
            path: 'cycle',
            builder: (_, __) => const CycleSummaryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.schedule,
        builder: (_, __) => const ScheduleListScreen(),
        routes: [
          GoRoute(
            path: 'editor',
            builder: (context, state) {
              final entryId = state.uri.queryParameters['id'];
              return ScheduleEditorScreen(entryId: entryId);
            },
          ),
          GoRoute(
            path: 'ocr-import',
            builder: (_, __) => const ScheduleOcrImportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.correctionForm,
        builder: (_, __) => const CorrectionFormScreen(),
      ),
      GoRoute(
        path: Routes.correctionsHistory,
        builder: (_, __) => const CorrectionsHistoryScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.optimizer,
        builder: (_, __) => const OptimizerScreen(),
        routes: [
          GoRoute(
            path: 'simulator',
            builder: (_, __) => const OptimizerSimulatorScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.scheduleWizard,
        builder: (_, __) => const ScheduleWizardScreen(),
      ),
      GoRoute(
        path: Routes.holidays,
        builder: (_, __) => const HolidaysScreen(),
      ),
    ],
  );
});

// ── Global redirect ──────────────────────────────────────────────────────────

String? _globalRedirect(BuildContext context, GoRouterState state) {
  final currentPath = state.matchedLocation;

  if (currentPath == Routes.splash) return null;

  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;

  if (!isLoggedIn && currentPath != Routes.login) return Routes.login;
  if (isLoggedIn && currentPath == Routes.login) return Routes.today;

  return null;
}

// ── Auth refresh notifier ─────────────────────────────────────────────────────
// Notifies GoRouter to re-evaluate the redirect whenever the Supabase auth
// state changes (sign-in, sign-out, token refresh). Without this, GoRouter
// only re-runs the redirect on explicit navigation events, so sign-out would
// require a manual context.go() that races with the ongoing route transition.

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
