-- ============================================================
-- Migration 005: Development simulation helpers
-- ============================================================

-- Clears the authenticated user's current-cycle simulation target data before
-- inserting a new simulated month. This preserves active sessions so a real
-- in-progress check-in cannot be erased by the simulation tool.
create or replace function reset_simulation_cycle_data(
  p_cycle_start date,
  p_cycle_end   date
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required to reset simulation data'
      using errcode = '42501';
  end if;

  delete from daily_attendance_summaries
  where user_id = auth.uid()
    and summary_date between p_cycle_start and p_cycle_end;

  delete from attendance_sessions
  where user_id = auth.uid()
    and session_date between p_cycle_start and p_cycle_end
    and status <> 'active';
end;
$$;

revoke execute on function reset_simulation_cycle_data(date, date)
  from public, anon;
grant execute on function reset_simulation_cycle_data(date, date)
  to authenticated;
