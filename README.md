# WorkHours — Faculty Attendance & Hours Optimizer

A Flutter mobile app for university faculty staff (demonstrators, teaching assistants, and doctors) to track attendance, optimise working hours, and stay compliant with the 7 h/day, 4 h minimum institutional policy.

## Features

- **Smart check-in / check-out** — one-tap attendance with real-time elapsed timer
- **Work cycle tracking** — 16th of month → 15th of next month (not calendar month)
- **Early-leave optimisation** — "Earliest safe departure" calculated from credit balance
- **Credit accumulation** — hours above 7 h/day carry forward; credit never pushes a day below 4 h
- **Weekly & cycle summaries** — progress bars, valid/insufficient day counts
- **Schedule management** — add lectures, sections, labs, office hours; today view shows what's next
- **Correction requests** — submit missed check-in/out with reason for admin review
- **Push notifications** — arrival/departure reminders (local) + cycle-end warnings (FCM)
- **Offline-tolerant** — Supabase real-time with optimistic UI updates

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter 3.27, Material 3, Inter font |
| State | Riverpod 2.6, Freezed, json_serializable |
| Routing | GoRouter 14 with StatefulShellRoute |
| Backend | Supabase (PostgreSQL + Auth + RLS) |
| Push | Firebase Cloud Messaging + flutter_local_notifications |
| Environment | flutter_dotenv |

## Quick Start

```bash
# 1. Clone and install
git clone <repo-url>
cd work_app
flutter pub get

# 2. Generate Freezed / JSON code
dart run build_runner build --delete-conflicting-outputs

# 3. Configure environment
cp .env.example .env
# Edit .env — add your SUPABASE_URL and SUPABASE_ANON_KEY

# 4. Apply database schema
supabase db push   # or psql -f supabase/migrations/*.sql

# 5. (Optional) Configure Firebase
flutterfire configure --project=<your-firebase-project-id>

# 6. Run
flutter run
```

See [docs/setup.md](docs/setup.md) for the full setup guide.

## Architecture

```
lib/
├── core/
│   ├── constants/     work_rules.dart — single source of business rules
│   ├── engine/        work_cycle_calculator.dart, hours_rule_engine.dart (pure Dart, zero Flutter deps)
│   ├── router/        app_router.dart — GoRouter with auth redirect
│   └── theme/         Material 3 tokens, AppColors, AppTheme
├── features/
│   ├── auth/          sign-in, sign-up, forgot-password
│   ├── onboarding/    profile setup (role, department, faculty)
│   ├── today/         check-in card, metrics, today schedule
│   ├── dashboard/     cycle + weekly summary cards
│   ├── attendance/    history list, session detail
│   ├── schedule/      weekly schedule editor
│   ├── corrections/   correction request form + history
│   ├── reports/       cycle detail screen
│   ├── notifications/ preference toggles + reminder time pickers
│   └── settings/      profile, sign-out
└── shared/
    ├── models/        UserProfile (Freezed)
    ├── providers/     supabaseClientProvider, authStateProvider
    ├── services/      NotificationService singleton
    └── widgets/       AppShell (bottom nav)
```

## Business Rules

| Rule | Value |
|------|-------|
| Daily target | 7 hours |
| Minimum valid day | 4 hours |
| Insufficient threshold | < 4 hours (never redeemable by credit) |
| Weekly target | 35 hours (5 × 7 h) |
| Cycle start | 16th of each month |
| Cycle end | 15th of following month |
| Credit | `worked - 7h` (only when > 7h) |
| Earliest safe departure | `checkIn + max(4h, 7h - credit)` |

## Testing

```bash
flutter test test/engine/          # 34 pure-Dart unit tests, no device required
flutter analyze                    # zero issues
```

## CI/CD

- **Push / PR to main**: lint + test (`.github/workflows/ci.yml`)
- **Tag push `v*.*.*`**: Android release AAB + GitHub Release (`.github/workflows/build.yml`)

Required GitHub secrets for build workflow: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FIREBASE_PROJECT_ID`, `GOOGLE_SERVICES_JSON` (base64), `KEYSTORE_BASE64` (base64), `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.

## Documentation

- [Setup guide](docs/setup.md)
- [Deployment guide](docs/deployment.md)
- [Supabase schema & RLS](docs/supabase.md)
