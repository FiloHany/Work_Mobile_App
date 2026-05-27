-- ============================================================
-- Migration 004: Attendance and RPC hardening
-- ============================================================

-- One non-voided attendance record per user per local session date.
-- This protects daily summaries from duplicate check-in/check-out cycles.
create unique index if not exists idx_one_attendance_session_per_day
  on attendance_sessions (user_id, session_date)
  where status in ('active', 'completed', 'correction_applied');

-- Users may only complete their own currently active session. They cannot
-- repeatedly update a completed session's checkout time from the client.
drop policy if exists "sessions: user updates own" on attendance_sessions;

create policy "sessions: user completes active own"
  on attendance_sessions for update
  using (
    user_id = auth.uid()
    and status = 'active'
    and check_out_time is null
  )
  with check (
    user_id = auth.uid()
    and status = 'completed'
    and check_out_time is not null
  );

-- Keep the old RPC signature for app compatibility, but enforce ownership and
-- aggregate from attendance_sessions so duplicated legacy rows cannot overwrite
-- a summary with only the last session's duration.
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
set search_path = public
as $$
declare
  v_worked_minutes int;
  v_has_exception boolean;
  v_credit_minutes int;
  v_deficit_minutes int;
  v_is_valid boolean;
  v_is_insufficient boolean;
begin
  if auth.uid() is null or p_user_id <> auth.uid() then
    raise exception 'Not allowed to update another user''s summary'
      using errcode = '42501';
  end if;

  select
    coalesce(sum(total_minutes), 0)::int,
    coalesce(bool_or(is_approved_exception), false)
  into v_worked_minutes, v_has_exception
  from attendance_sessions
  where user_id = p_user_id
    and session_date = p_date
    and status in ('completed', 'correction_applied')
    and total_minutes is not null;

  if v_worked_minutes = 0 and p_worked_minutes > 0 then
    -- Compatibility fallback for older clients/data while the completed row is
    -- still becoming visible to the transaction.
    v_worked_minutes := p_worked_minutes;
    v_has_exception := p_has_exception;
  end if;

  v_credit_minutes := greatest(v_worked_minutes - 420, 0);
  v_deficit_minutes := greatest(420 - v_worked_minutes, 0);
  v_is_valid := v_has_exception or v_worked_minutes >= 240;
  v_is_insufficient := not v_has_exception and v_worked_minutes < 240;

  insert into daily_attendance_summaries (
    user_id, summary_date, cycle_start,
    total_worked_minutes, credit_earned_minutes, deficit_minutes,
    is_valid_day, is_insufficient_day, has_approved_exception
  ) values (
    p_user_id, p_date, p_cycle_start,
    v_worked_minutes, v_credit_minutes, v_deficit_minutes,
    v_is_valid, v_is_insufficient, v_has_exception
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
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or p_user_id <> auth.uid() then
    raise exception 'Not allowed to read another user''s cycle summary'
      using errcode = '42501';
  end if;

  return query
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
end;
$$;

revoke execute on function log_audit(text, text, uuid, jsonb, jsonb)
  from public, anon, authenticated;
