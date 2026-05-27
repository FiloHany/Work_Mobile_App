# Supabase Schema, RLS & Functions

## Schema Overview

### Custom Types (enums)

| Type | Values |
|------|--------|
| `user_role` | `demonstrator`, `teaching_assistant`, `doctor` |
| `session_status` | `active`, `completed`, `voided`, `corrected` |
| `schedule_entry_type` | `lecture`, `section`, `lab`, `meeting`, `office_hours`, `required_presence`, `free` |
| `correction_type` | `missed_check_in`, `missed_check_out`, `full_correction` |
| `correction_status` | `pending`, `approved`, `rejected` |

---

### Tables

#### `profiles`
Auto-created by trigger on `auth.users` insert. One row per authenticated user.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | Matches `auth.users.id` |
| `full_name` | text | |
| `role` | user_role | demonstrator / teaching_assistant / doctor |
| `department_id` | uuid FK → departments | |
| `faculty` | text | |
| `employee_id` | text | Optional institutional ID |
| `phone` | text | |
| `avatar_url` | text | |
| `onboarding_completed` | boolean | Default false; set true after profile setup |
| `created_at` / `updated_at` | timestamptz | `updated_at` auto-updated by trigger |

#### `attendance_sessions`
One row per check-in event. Never deleted; voided sessions remain for audit.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `user_id` | uuid FK → profiles | |
| `checked_in_at` | timestamptz | |
| `checked_out_at` | timestamptz | Null while session is active |
| `status` | session_status | active → completed on checkout |
| `notes` | text | |
| `location` | text | Optional geo tag |

#### `daily_summaries`
One row per user per date. Upserted by the `upsert_daily_summary` RPC.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` + `date` | composite unique | |
| `worked_minutes` | integer | Total minutes across all sessions for the date |
| `status` | text | insufficient / valid_below_target / target_met / excused |
| `credit_minutes` | integer | Minutes above 7 h (0 if below) |
| `has_exception` | boolean | Approved correction exception |

#### `schedule_entries`
User's recurring weekly schedule. Each entry belongs to a `schedule_versions` row (auto-created) to support future versioning.

| Column | Type | Notes |
|--------|------|-------|
| `schedule_version_id` | uuid FK → schedule_versions | |
| `day_of_week` | integer | 0=Sunday … 6=Saturday |
| `start_time` | time | |
| `end_time` | time | |
| `entry_type` | schedule_entry_type | |
| `subject` | text | |
| `location` | text | |
| `notes` | text | |

#### `correction_requests`
Immutable after insert (users cannot update/delete their own requests — status is set server-side).

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | uuid FK → profiles | |
| `correction_type` | correction_type | |
| `target_date` | date | The day being corrected |
| `requested_check_in` | timestamptz | |
| `requested_check_out` | timestamptz | |
| `reason` | text | Required |
| `status` | correction_status | Default pending |
| `reviewer_notes` | text | Set by admin when approving/rejecting |

#### `departments`
Reference table. Read-only for end users.

#### `holiday_calendar`
Read-only for end users. Used by `WorkCycleCalculator.countWorkingDays()` when holidays are fetched from the DB.

#### `device_tokens`
FCM tokens per user per device. Managed by `register_device_token()` function.

#### `notification_preferences`
One row per user. Auto-created by `handle_new_user()` trigger.

#### `audit_log`
Append-only. Written by trigger on `attendance_sessions` insert/update.

---

## Row-Level Security Policies

RLS is **enabled on every table**. The default deny-all is the baseline; policies grant minimum required access.

### Key policies

| Table | Operation | Policy |
|-------|-----------|--------|
| `profiles` | SELECT, UPDATE | `auth.uid() = id` |
| `profiles` | INSERT | Denied for end users — created by server trigger only |
| `attendance_sessions` | ALL | `auth.uid() = user_id` |
| `daily_summaries` | ALL | `auth.uid() = user_id` |
| `schedule_entries` | ALL | Via join to `schedule_versions.user_id = auth.uid()` |
| `correction_requests` | SELECT, INSERT | `auth.uid() = user_id` (no UPDATE/DELETE) |
| `departments` | SELECT | Any authenticated user |
| `holiday_calendar` | SELECT | Any authenticated user |
| `device_tokens` | ALL | `auth.uid() = user_id` |
| `notification_preferences` | ALL | `auth.uid() = user_id` |
| `audit_log` | SELECT | `auth.uid() = user_id` (insert via trigger only) |

### Verify RLS

```sql
-- Should return only rows belonging to the current user
select * from attendance_sessions;

-- Should return nothing if called as a different user
select * from profiles where id != auth.uid();  -- 0 rows
```

---

## Database Functions

### `upsert_daily_summary(p_user_id, p_date)`
Called after every checkout. Aggregates all completed sessions for `p_date`, calculates `worked_minutes`, determines status, and upserts into `daily_summaries`.

```sql
select upsert_daily_summary('uuid-here', '2025-04-15');
```

### `get_cycle_summary(p_user_id, p_cycle_start, p_cycle_end)`
Returns a JSON object with `total_worked_minutes`, `valid_days`, `insufficient_days`, `total_credit_minutes` for the given cycle range.

```sql
select get_cycle_summary('uuid-here', '2025-03-16', '2025-04-15');
```

### `register_device_token(p_user_id, p_token, p_platform)`
Upserts an FCM token for the device. Prevents duplicate tokens across sessions.

```sql
select register_device_token('uuid-here', 'fcm-token-string', 'android');
```

### Triggers

| Trigger | Table | Event | Action |
|---------|-------|-------|--------|
| `set_updated_at` | all tables | BEFORE UPDATE | Sets `updated_at = now()` |
| `handle_new_user` | `auth.users` | AFTER INSERT | Creates `profiles` + `notification_preferences` row |
| `audit_attendance` | `attendance_sessions` | AFTER INSERT/UPDATE | Appends row to `audit_log` |

---

## Local Development with Supabase CLI

```bash
# Start local Supabase stack (Docker required)
supabase start

# Apply migrations to local instance
supabase db push

# Reset local DB and re-seed
supabase db reset

# Generate TypeScript types (optional, for Edge Functions)
supabase gen types typescript --local > supabase/functions/_types/database.ts

# Stop local stack
supabase stop
```

Local studio URL: `http://localhost:54323`
Local API URL: `http://localhost:54321`

When using local Supabase, update `.env`:
```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<local-anon-key from supabase start output>
```
