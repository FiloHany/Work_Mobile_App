# Local Development Setup

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter | 3.27.x stable | `flutter doctor` must show no errors |
| Dart | 3.6.x (bundled) | |
| Supabase CLI | latest | `brew install supabase/tap/supabase` or see supabase.com/docs/guides/cli |
| Node.js | 20+ | Required by Supabase CLI |
| Git | any | |

---

## 1. Clone & Install

```bash
git clone <repo-url>
cd work_app
flutter pub get
```

---

## 2. Generate Code (Freezed + JSON)

All models are generated. Run this once after clone, and again any time you add or modify a `@freezed` class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected output: a list of generated `.freezed.dart` and `.g.dart` files, then `Succeeded after...`.

To watch and regenerate on file save during development:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 3. Environment Variables

```bash
cp .env.example .env
```

Open `.env` and fill in:

```
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
APP_ENV=development
FIREBASE_PROJECT_ID=<your-firebase-project-id>
```

Your Supabase URL and anon key are on the Supabase dashboard under **Project Settings → API**.

> **Never commit `.env`** — it is in `.gitignore`. The `.env.example` file is the committed template.

---

## 4. Supabase Setup

### 4a. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Copy the Project URL and `anon` public key into your `.env`.

### 4b. Apply migrations

Using Supabase CLI (recommended — keeps migration history):

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

Or apply manually via the Supabase SQL editor:

```bash
# Run in order:
supabase/migrations/001_initial_schema.sql
supabase/migrations/002_rls_policies.sql
supabase/migrations/003_functions.sql
supabase/seed/001_seed_data.sql   # optional sample data
```

### 4c. Verify

In the Supabase dashboard → **Table Editor**, you should see tables: `profiles`, `attendance_sessions`, `daily_summaries`, `schedule_entries`, `correction_requests`, `departments`, `holiday_calendar`, `device_tokens`, `notification_preferences`, `audit_log`.

---

## 5. Firebase Setup (optional — for push notifications)

FCM push notifications are optional. The app will run without them; local (on-device) notifications always work.

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (creates google-services.json and GoogleService-Info.plist)
flutterfire configure --project=<your-firebase-project-id>
```

This command places:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Both files are in `.gitignore`. Do not commit them to the public repo.

---

## 6. Run the App

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Run in debug mode (hot reload enabled)
flutter run

# Run in release mode (closer to production performance)
flutter run --release
```

---

## 7. Run Tests

```bash
# Unit tests (no device required — pure Dart engine tests)
flutter test test/engine/

# All tests
flutter test

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 8. Lint

```bash
flutter analyze
```

The project is configured with `package:flutter_lints` in `analysis_options.yaml`. CI enforces `--fatal-infos`.

---

## Common Issues

**`build_runner` fails with "Already exists" errors**
```bash
dart run build_runner build --delete-conflicting-outputs
```
The `--delete-conflicting-outputs` flag resolves stale generated files.

**`_$ModelName` not a type / `_$ModelFromJson` undefined**
Generated files are missing. Run `build_runner build` (step 2).

**`SUPABASE_URL must not be empty`**
The `.env` file is missing or not loaded. Ensure it exists at the project root (same level as `pubspec.yaml`).

**Firebase initialisation skipped**
Expected when `google-services.json` is absent. The app prints `"Firebase initialisation skipped (not configured)."` and continues without FCM. Local notifications still work.
