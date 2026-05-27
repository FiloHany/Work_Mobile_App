-- ============================================================
-- Migration 001: Initial Schema
-- Work Hours Faculty Attendance App
-- Cycle: 16th of month → 15th of next month
-- ============================================================

-- ── Custom types ──────────────────────────────────────────────────────────────
create type user_role as enum ('demonstrator', 'teaching_assistant', 'doctor');
create type session_status as enum ('active', 'completed', 'voided', 'correction_applied');
create type schedule_entry_type as enum (
  'lecture', 'section', 'lab', 'meeting', 'office_hours', 'required_presence', 'free'
);
create type correction_type as enum ('missed_check_in', 'missed_check_out', 'full_correction');
create type correction_status as enum ('pending', 'approved', 'rejected');

-- ── departments ───────────────────────────────────────────────────────────────
create table departments (
  id          uuid    default gen_random_uuid() primary key,
  name        text    not null,
  code        text    unique,
  faculty     text,
  created_at  timestamptz default now()
);

-- ── profiles ──────────────────────────────────────────────────────────────────
-- Extends auth.users 1-to-1
create table profiles (
  id           uuid        references auth.users(id) on delete cascade primary key,
  email        text        not null,
  full_name    text        not null,
  avatar_url   text,
  role         user_role   not null,
  department_id uuid       references departments(id) on delete set null,
  faculty      text,
  employee_id  text,
  phone        text,
  is_onboarded boolean     default false,
  created_at   timestamptz default now(),
  updated_at   timestamptz default now()
);

-- ── attendance_sessions ───────────────────────────────────────────────────────
create table attendance_sessions (
  id                 uuid          default gen_random_uuid() primary key,
  user_id            uuid          not null references profiles(id) on delete cascade,
  session_date       date          not null,
  check_in_time      timestamptz   not null,
  check_out_time     timestamptz,
  total_minutes      int           generated always as (
                       case
                         when check_out_time is not null
                         then extract(epoch from (check_out_time - check_in_time)) / 60
                         else null
                       end
                     ) stored,
  notes              text,
  status             session_status not null default 'active',
  is_approved_exception boolean    default false,
  location_check_in  jsonb,
  location_check_out jsonb,
  created_at         timestamptz   default now(),
  updated_at         timestamptz   default now(),

  constraint no_future_checkin check (check_in_time <= now() + interval '5 minutes'),
  constraint checkout_after_checkin check (
    check_out_time is null or check_out_time > check_in_time
  )
);

create index idx_sessions_user_date on attendance_sessions (user_id, session_date desc);
create index idx_sessions_status    on attendance_sessions (user_id, status);

-- Prevent duplicate active sessions per user per day
create unique index idx_one_active_session
  on attendance_sessions (user_id, session_date)
  where status = 'active';

-- ── daily_attendance_summaries ────────────────────────────────────────────────
-- Materialised per-day summary; recomputed whenever a session is saved.
create table daily_attendance_summaries (
  id                     uuid  default gen_random_uuid() primary key,
  user_id                uuid  not null references profiles(id) on delete cascade,
  summary_date           date  not null,
  cycle_start            date  not null,
  total_worked_minutes   int   not null default 0,
  credit_earned_minutes  int   not null default 0,
  deficit_minutes        int   not null default 0,
  is_valid_day           boolean not null default false,
  is_insufficient_day    boolean not null default false,
  has_approved_exception boolean default false,
  created_at             timestamptz default now(),
  updated_at             timestamptz default now(),

  unique (user_id, summary_date)
);

create index idx_summaries_user_cycle on daily_attendance_summaries (user_id, cycle_start);

-- ── work_cycles ───────────────────────────────────────────────────────────────
create table work_cycles (
  id                    uuid  default gen_random_uuid() primary key,
  user_id               uuid  not null references profiles(id) on delete cascade,
  cycle_start           date  not null,
  cycle_end             date  not null,
  working_days_total    int   not null default 0,
  total_worked_minutes  int   not null default 0,
  total_required_minutes int  not null default 0,
  total_credit_minutes  int   not null default 0,
  total_deficit_minutes int   not null default 0,
  valid_days            int   not null default 0,
  insufficient_days     int   not null default 0,
  is_complete           boolean default false,
  created_at            timestamptz default now(),
  updated_at            timestamptz default now(),

  unique (user_id, cycle_start)
);

-- ── schedules ─────────────────────────────────────────────────────────────────
create table schedules (
  id             uuid  default gen_random_uuid() primary key,
  user_id        uuid  not null references profiles(id) on delete cascade,
  name           text  not null default 'My Schedule',
  is_active      boolean default true,
  effective_from date  not null,
  effective_to   date,
  created_at     timestamptz default now(),
  updated_at     timestamptz default now()
);

-- ── schedule_entries ──────────────────────────────────────────────────────────
create table schedule_entries (
  id           uuid               default gen_random_uuid() primary key,
  schedule_id  uuid               not null references schedules(id) on delete cascade,
  user_id      uuid               not null references profiles(id) on delete cascade,
  day_of_week  int                not null check (day_of_week between 0 and 6),
  start_time   time               not null,
  end_time     time               not null,
  entry_type   schedule_entry_type not null,
  title        text               not null,
  location     text,
  created_at   timestamptz        default now(),
  updated_at   timestamptz        default now(),

  constraint end_after_start check (end_time > start_time)
);

create index idx_schedule_entries_user on schedule_entries (user_id, day_of_week);

-- ── schedule_exceptions ───────────────────────────────────────────────────────
create table schedule_exceptions (
  id              uuid  default gen_random_uuid() primary key,
  user_id         uuid  not null references profiles(id) on delete cascade,
  exception_date  date  not null,
  exception_type  text  not null default 'off_day',
  notes           text,
  created_at      timestamptz default now(),

  unique (user_id, exception_date)
);

-- ── correction_requests ───────────────────────────────────────────────────────
create table correction_requests (
  id                    uuid              default gen_random_uuid() primary key,
  user_id               uuid              not null references profiles(id) on delete cascade,
  target_date           date              not null,
  request_type          correction_type   not null,
  requested_check_in    timestamptz,
  requested_check_out   timestamptz,
  reason                text              not null,
  status                correction_status not null default 'pending',
  session_id            uuid              references attendance_sessions(id),
  reviewer_notes        text,
  created_at            timestamptz       default now(),
  updated_at            timestamptz       default now()
);

create index idx_corrections_user on correction_requests (user_id, created_at desc);

-- ── holiday_calendar ──────────────────────────────────────────────────────────
create table holiday_calendar (
  id            uuid  default gen_random_uuid() primary key,
  holiday_date  date  not null unique,
  name          text  not null,
  is_national   boolean default true,
  created_at    timestamptz default now()
);

-- ── notification_preferences ──────────────────────────────────────────────────
create table notification_preferences (
  id                          uuid  default gen_random_uuid() primary key,
  user_id                     uuid  not null references profiles(id) on delete cascade unique,
  arrival_reminder            boolean default true,
  arrival_reminder_time       time    default '08:00:00',
  departure_reminder          boolean default true,
  departure_reminder_time     time    default '14:30:00',
  missed_checkin_alert        boolean default true,
  missed_checkout_alert       boolean default true,
  tomorrow_preview            boolean default true,
  weekly_summary              boolean default true,
  cycle_end_warning           boolean default true,
  early_leave_recommendation  boolean default true,
  created_at                  timestamptz default now(),
  updated_at                  timestamptz default now()
);

-- ── device_tokens ─────────────────────────────────────────────────────────────
create table device_tokens (
  id          uuid  default gen_random_uuid() primary key,
  user_id     uuid  not null references profiles(id) on delete cascade,
  token       text  not null,
  platform    text  not null check (platform in ('android', 'ios', 'web')),
  is_active   boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),

  unique (user_id, token)
);

-- ── audit_logs ────────────────────────────────────────────────────────────────
create table audit_logs (
  id          uuid  default gen_random_uuid() primary key,
  user_id     uuid  references profiles(id) on delete set null,
  action      text  not null,
  table_name  text,
  record_id   uuid,
  old_values  jsonb,
  new_values  jsonb,
  created_at  timestamptz default now()
);

-- ── updated_at trigger ────────────────────────────────────────────────────────
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_profiles_updated_at
  before update on profiles for each row execute function set_updated_at();

create trigger trg_sessions_updated_at
  before update on attendance_sessions for each row execute function set_updated_at();

create trigger trg_summaries_updated_at
  before update on daily_attendance_summaries for each row execute function set_updated_at();

create trigger trg_cycles_updated_at
  before update on work_cycles for each row execute function set_updated_at();

create trigger trg_schedules_updated_at
  before update on schedules for each row execute function set_updated_at();

create trigger trg_corrections_updated_at
  before update on correction_requests for each row execute function set_updated_at();

create trigger trg_notif_prefs_updated_at
  before update on notification_preferences for each row execute function set_updated_at();

create trigger trg_device_tokens_updated_at
  before update on device_tokens for each row execute function set_updated_at();

-- ── Auto-create profile after signup ─────────────────────────────────────────
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'demonstrator')::public.user_role
  );
  insert into public.notification_preferences (user_id)
  values (new.id);
  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
