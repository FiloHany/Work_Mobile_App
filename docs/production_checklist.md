# Production Checklist

Work through this list top-to-bottom before releasing to users.

---

## Environment & Configuration

- [ ] `.env` has production `SUPABASE_URL` and `SUPABASE_ANON_KEY` (not development keys)
- [ ] `APP_ENV=production` in `.env`
- [ ] `.env` is in `.gitignore` — verify it is NOT committed to the repo
- [ ] `android/app/google-services.json` is present and matches the production Firebase project
- [ ] `ios/Runner/GoogleService-Info.plist` is present (if targeting iOS)
- [ ] `android/key.properties` references the release keystore (not debug)
- [ ] Keystore file exists at the path specified in `key.properties`

---

## Database (Supabase)

- [ ] All three migrations applied in order:
  - [ ] `001_initial_schema.sql`
  - [ ] `002_rls_policies.sql`
  - [ ] `003_functions.sql`
- [ ] Seed data applied (`001_seed_data.sql`) — departments and holiday calendar populated
- [ ] RLS enabled on all tables (verify in Supabase dashboard → Authentication → Policies)
- [ ] `handle_new_user` trigger is active — test by creating a new user and confirming a `profiles` row is created
- [ ] `upsert_daily_summary` RPC accessible to authenticated users
- [ ] `get_cycle_summary` RPC accessible to authenticated users
- [ ] `register_device_token` RPC accessible to authenticated users

---

## Firebase / FCM

- [ ] Firebase project created
- [ ] Android app registered in Firebase (package name: `com.example.work_app` or your custom ID)
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] FCM is enabled in Firebase console → Cloud Messaging
- [ ] Test FCM token registration: sign in, check `device_tokens` table for a row

---

## Android Build

- [ ] `versionCode` and `versionName` updated in `android/app/build.gradle`
- [ ] Release APK or AAB builds without errors:
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
  ```
- [ ] APK installs and launches on a physical device
- [ ] App is signed with the release keystore (not debug — Play Store rejects debug-signed APKs)
- [ ] `flutter analyze` returns "No issues found"
- [ ] All 34 unit tests pass: `flutter test test/engine/`

---

## Functional Smoke Test (Physical Device)

- [ ] Splash screen shows and animates
- [ ] Sign-up flow completes; profile row created in Supabase
- [ ] Email verification works (if enabled in Supabase Auth settings)
- [ ] Login with created account succeeds
- [ ] Onboarding: name, role, department, faculty, employee ID all save
- [ ] Onboarding completed flag set (`profiles.onboarding_completed = true`)
- [ ] Today screen loads; check-in button is visible
- [ ] Check-in creates `attendance_sessions` row with `status = active`
- [ ] Elapsed timer increments in real time
- [ ] Check-out: session row updated; `upsert_daily_summary` called; result card displays
- [ ] Dashboard shows correct cycle start/end dates and working-days-remaining count
- [ ] Schedule: add a lecture entry → appears in today view and schedule list
- [ ] History screen lists today's session with correct status badge
- [ ] Reports screen shows cycle hours and credit
- [ ] Correction request: submit form → row appears in `correction_requests`
- [ ] Notification preferences: toggle arrival reminder → fires at scheduled time
- [ ] Settings: profile edit saves; sign-out redirects to login

---

## Security Checks

- [ ] Attempt to read another user's profile via Supabase client → 0 rows returned (RLS working)
- [ ] Attempt to update another user's session directly → error (RLS working)
- [ ] Confirm no raw SQL is concatenated with user input in any repository file
- [ ] Confirm `.env`, `keystore.jks`, `google-services.json`, `key.properties` are all in `.gitignore`

---

## Performance

- [ ] Today screen loads in under 2 s on a mid-range Android device (cold start after login)
- [ ] Dashboard loads in under 2 s
- [ ] Check-in / check-out complete within 3 s (network call)
- [ ] No jank (dropped frames) during tab switches and scroll

---

## CI/CD (if using GitHub Actions)

- [ ] `ci.yml` runs on push to `main` — verify it passes in Actions tab
- [ ] All required secrets added to repository: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FIREBASE_PROJECT_ID`, `GOOGLE_SERVICES_JSON`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
- [ ] Tag `v1.0.0` pushed — `build.yml` produces AAB artifact
- [ ] GitHub Release created with release notes

---

## Post-Release

- [ ] Monitor Supabase logs for RLS violations or function errors (Supabase dashboard → Logs)
- [ ] Monitor Firebase Crashlytics (if integrated) for crash reports
- [ ] Verify FCM delivery via Firebase console → Cloud Messaging → Send test message
