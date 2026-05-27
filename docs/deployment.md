# Deployment Guide

## Android Release Build

### Prerequisites

- Java 17 installed and `JAVA_HOME` set
- Flutter 3.27 stable
- A signing keystore (see below)
- Production `.env` with real Supabase credentials
- `android/app/google-services.json` from Firebase console

---

### 1. Create a Signing Keystore (first time only)

```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias work_app_key
```

Store the keystore and its passwords securely (password manager / CI secrets). **Do not commit `keystore.jks`** — it is in `.gitignore`.

---

### 2. Configure Signing in Gradle

Create `android/key.properties` (also gitignored):

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=work_app_key
storeFile=keystore.jks
```

Ensure `android/app/build.gradle` references this file (already configured in this project):

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

### 3. Set Production Environment

```bash
# .env must have production values
APP_ENV=production
SUPABASE_URL=https://<prod-project-ref>.supabase.co
SUPABASE_ANON_KEY=<prod-anon-key>
FIREBASE_PROJECT_ID=<prod-firebase-project>
```

---

### 4. Run Supabase Migrations on Production

```bash
supabase link --project-ref <prod-project-ref>
supabase db push
```

Verify all three migrations are applied:
```
001_initial_schema.sql
002_rls_policies.sql
003_functions.sql
```

---

### 5. Build

**APK (direct install / testing):**
```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**App Bundle (Play Store):**
```bash
flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/debug-info
```
Output: `build/app/outputs/bundle/release/app-release.aab`

> The `--obfuscate` flag plus `--split-debug-info` is required for Play Store upload to pass code protection checks and allow crash symbolication.

---

### 6. Pre-Release Smoke Test Checklist

Run through this on a physical device with the release APK before publishing:

- [ ] App launches, splash animation plays
- [ ] Sign-up creates a profile (check Supabase → profiles table)
- [ ] Login with created credentials works
- [ ] Onboarding: role, department, faculty ID saves correctly
- [ ] Check-in creates a row in `attendance_sessions`
- [ ] Elapsed timer counts up in real time
- [ ] Check-out updates `checked_out_at`, triggers `upsert_daily_summary`
- [ ] Daily result card shows correct status (sufficient / target met / insufficient)
- [ ] Credit from a 9 h day appears on next day's "Earliest safe departure"
- [ ] Dashboard cycle progress bar and working days remaining are correct
- [ ] Schedule: add entry → appears in Today view and Schedule list
- [ ] Correction request submits (row appears in `correction_requests`)
- [ ] Notification preferences save and local reminder fires at scheduled time
- [ ] Sign-out returns to login screen; protected routes redirect unauthenticated users

---

### 7. GitHub CI/CD Release

Tag a commit to trigger the automated build:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The `build.yml` workflow will:
1. Build the signed AAB
2. Upload it as a GitHub Release artifact
3. Create a GitHub Release with auto-generated notes

Required repository secrets (Settings → Secrets and variables → Actions):

| Secret | Description |
|--------|-------------|
| `SUPABASE_URL` | Production Supabase URL |
| `SUPABASE_ANON_KEY` | Production anon key |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `GOOGLE_SERVICES_JSON` | Base64-encoded `google-services.json` |
| `KEYSTORE_BASE64` | Base64-encoded `keystore.jks` |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias (e.g. `work_app_key`) |

Encode files to base64:
```bash
base64 -i android/app/google-services.json | tr -d '\n'
base64 -i android/app/keystore.jks | tr -d '\n'
```

---

### 8. Play Store Upload

1. In Google Play Console, create a new app.
2. Under **Release → Production (or Internal testing)**, upload `app-release.aab`.
3. Set version name and code in `android/app/build.gradle` before building:
   ```groovy
   versionCode 1
   versionName "1.0.0"
   ```
4. Complete the store listing, content rating questionnaire, and data safety form.
5. Submit for review.
