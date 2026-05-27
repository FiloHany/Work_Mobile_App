-- ============================================================
-- Migration 002: Row-Level Security Policies
-- Principle: users can only read/write their OWN data.
-- ============================================================

-- ── Enable RLS on all tables ──────────────────────────────────────────────────
alter table profiles                  enable row level security;
alter table attendance_sessions       enable row level security;
alter table daily_attendance_summaries enable row level security;
alter table work_cycles               enable row level security;
alter table schedules                 enable row level security;
alter table schedule_entries          enable row level security;
alter table schedule_exceptions       enable row level security;
alter table correction_requests       enable row level security;
alter table notification_preferences  enable row level security;
alter table device_tokens             enable row level security;
alter table audit_logs                enable row level security;
-- departments and holiday_calendar are read-only reference data for all users
alter table departments               enable row level security;
alter table holiday_calendar          enable row level security;

-- ── Helper: current authenticated user ───────────────────────────────────────
-- Using auth.uid() directly in policies; no helper needed.

-- ── profiles ─────────────────────────────────────────────────────────────────
create policy "profiles: user reads own"
  on profiles for select
  using (id = auth.uid());

create policy "profiles: user updates own"
  on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- Insert is handled by the trigger on auth.users; no direct insert policy needed.

-- ── attendance_sessions ───────────────────────────────────────────────────────
create policy "sessions: user reads own"
  on attendance_sessions for select
  using (user_id = auth.uid());

create policy "sessions: user inserts own"
  on attendance_sessions for insert
  with check (user_id = auth.uid());

create policy "sessions: user updates own"
  on attendance_sessions for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- No delete; sessions are logically voided via status update.

-- ── daily_attendance_summaries ────────────────────────────────────────────────
create policy "summaries: user reads own"
  on daily_attendance_summaries for select
  using (user_id = auth.uid());

create policy "summaries: user writes own"
  on daily_attendance_summaries for insert
  with check (user_id = auth.uid());

create policy "summaries: user updates own"
  on daily_attendance_summaries for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ── work_cycles ───────────────────────────────────────────────────────────────
create policy "cycles: user reads own"
  on work_cycles for select
  using (user_id = auth.uid());

create policy "cycles: user writes own"
  on work_cycles for insert
  with check (user_id = auth.uid());

create policy "cycles: user updates own"
  on work_cycles for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ── schedules ─────────────────────────────────────────────────────────────────
create policy "schedules: user reads own"
  on schedules for select
  using (user_id = auth.uid());

create policy "schedules: user inserts own"
  on schedules for insert
  with check (user_id = auth.uid());

create policy "schedules: user updates own"
  on schedules for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "schedules: user deletes own"
  on schedules for delete
  using (user_id = auth.uid());

-- ── schedule_entries ──────────────────────────────────────────────────────────
create policy "entries: user reads own"
  on schedule_entries for select
  using (user_id = auth.uid());

create policy "entries: user inserts own"
  on schedule_entries for insert
  with check (user_id = auth.uid());

create policy "entries: user updates own"
  on schedule_entries for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "entries: user deletes own"
  on schedule_entries for delete
  using (user_id = auth.uid());

-- ── schedule_exceptions ───────────────────────────────────────────────────────
create policy "exceptions: user reads own"
  on schedule_exceptions for select
  using (user_id = auth.uid());

create policy "exceptions: user inserts own"
  on schedule_exceptions for insert
  with check (user_id = auth.uid());

create policy "exceptions: user updates own"
  on schedule_exceptions for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "exceptions: user deletes own"
  on schedule_exceptions for delete
  using (user_id = auth.uid());

-- ── correction_requests ───────────────────────────────────────────────────────
create policy "corrections: user reads own"
  on correction_requests for select
  using (user_id = auth.uid());

create policy "corrections: user submits own"
  on correction_requests for insert
  with check (user_id = auth.uid());

-- Users cannot modify submitted requests (must be voided and resubmitted).
-- Status updates are reserved for future admin tooling via service role.

-- ── notification_preferences ──────────────────────────────────────────────────
create policy "notif_prefs: user reads own"
  on notification_preferences for select
  using (user_id = auth.uid());

create policy "notif_prefs: user updates own"
  on notification_preferences for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Row is created by trigger on signup; no user insert policy.

-- ── device_tokens ─────────────────────────────────────────────────────────────
create policy "tokens: user reads own"
  on device_tokens for select
  using (user_id = auth.uid());

create policy "tokens: user inserts own"
  on device_tokens for insert
  with check (user_id = auth.uid());

create policy "tokens: user updates own"
  on device_tokens for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ── audit_logs ────────────────────────────────────────────────────────────────
-- Users can read their own audit rows. No write access (written server-side).
create policy "audit: user reads own"
  on audit_logs for select
  using (user_id = auth.uid());

-- ── departments (reference data: read-only for authenticated users) ────────────
create policy "departments: any authenticated reads"
  on departments for select
  using (auth.role() = 'authenticated');

-- ── holiday_calendar (read-only for authenticated users) ──────────────────────
create policy "holidays: any authenticated reads"
  on holiday_calendar for select
  using (auth.role() = 'authenticated');
