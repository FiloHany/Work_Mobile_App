-- ============================================================
-- Migration 003: Database Functions & Triggers
-- ============================================================

-- ── upsert_daily_summary ──────────────────────────────────────────────────────
-- Called from the app after checkout to materialise the daily summary row.
-- Uses security definer so it can update summaries for authenticated callers.
create or replace function upsert_daily_summary(
  p_user_id              uuid,
  p_date                 date,
  p_cycle_start          date,
  p_worked_minutes       int,
  p_credit_minutes       int,
  p_deficit_minutes      int,
  p_is_valid             boolean,
  p_is_insufficient      boolean,
  p_has_exception        boolean default false
)
returns void
language plpgsql
security definer
as $$
begin
  insert into daily_attendance_summaries (
    user_id, summary_date, cycle_start,
    total_worked_minutes, credit_earned_minutes, deficit_minutes,
    is_valid_day, is_insufficient_day, has_approved_exception
  ) values (
    p_user_id, p_date, p_cycle_start,
    p_worked_minutes, p_credit_minutes, p_deficit_minutes,
    p_is_valid, p_is_insufficient, p_has_exception
  )
  on conflict (user_id, summary_date) do update set
    total_worked_minutes   = excluded.total_worked_minutes,
    credit_earned_minutes  = excluded.credit_earned_minutes,
    deficit_minutes        = excluded.deficit_minutes,
    is_valid_day           = excluded.is_valid_day,
    is_insufficient_day    = excluded.is_insufficient_day,
    has_approved_exception = excluded.has_approved_exception,
    updated_at             = now();
end;
$$;

-- ── get_cycle_summary ─────────────────────────────────────────────────────────
-- Returns aggregated cycle data for a user + cycle start date.
create or replace function get_cycle_summary(
  p_user_id     uuid,
  p_cycle_start date
)
returns table (
  total_worked_minutes   bigint,
  total_credit_minutes   bigint,
  total_deficit_minutes  bigint,
  valid_days             bigint,
  insufficient_days      bigint,
  days_with_data         bigint
)
language sql
security definer
as $$
  select
    coalesce(sum(total_worked_minutes), 0),
    coalesce(sum(credit_earned_minutes), 0),
    coalesce(sum(deficit_minutes), 0),
    count(*) filter (where is_valid_day),
    count(*) filter (where is_insufficient_day),
    count(*)
  from daily_attendance_summaries
  where user_id = p_user_id
    and cycle_start = p_cycle_start;
$$;

-- ── register_device_token ─────────────────────────────────────────────────────
-- Upsert a FCM device token for the authenticated user.
create or replace function register_device_token(
  p_token    text,
  p_platform text
)
returns void
language plpgsql
security definer
as $$
begin
  insert into device_tokens (user_id, token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (user_id, token) do update set
    is_active  = true,
    platform   = excluded.platform,
    updated_at = now();

  -- Deactivate old tokens from the same user on the same platform
  -- (keeps at most the most recent one active per platform).
  update device_tokens
  set is_active = false
  where user_id  = auth.uid()
    and platform  = p_platform
    and token    != p_token;
end;
$$;

-- ── log_audit ─────────────────────────────────────────────────────────────────
create or replace function log_audit(
  p_action     text,
  p_table_name text,
  p_record_id  uuid,
  p_old_values jsonb default null,
  p_new_values jsonb default null
)
returns void
language plpgsql
security definer
as $$
begin
  insert into audit_logs (user_id, action, table_name, record_id, old_values, new_values)
  values (auth.uid(), p_action, p_table_name, p_record_id, p_old_values, p_new_values);
end;
$$;

-- ── Audit trigger for attendance_sessions ─────────────────────────────────────
create or replace function audit_session_changes()
returns trigger language plpgsql security definer as $$
begin
  if tg_op = 'INSERT' then
    perform log_audit('check_in', 'attendance_sessions', new.id, null, to_jsonb(new));
  elsif tg_op = 'UPDATE' then
    if old.check_out_time is null and new.check_out_time is not null then
      perform log_audit('check_out', 'attendance_sessions', new.id, to_jsonb(old), to_jsonb(new));
    else
      perform log_audit('session_update', 'attendance_sessions', new.id, to_jsonb(old), to_jsonb(new));
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_audit_sessions
  after insert or update on attendance_sessions
  for each row execute function audit_session_changes();
