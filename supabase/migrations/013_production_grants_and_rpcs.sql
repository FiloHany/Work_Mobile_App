-- Migration 013: Production security hardening
--
-- Two problems this migration solves:
--
-- 1. Missing table-level GRANTs.
--    PostgreSQL requires BOTH a table-level privilege AND a matching RLS policy.
--    Without the GRANT the operation fails with 42501 even when the RLS policy
--    exists. Supabase sets these automatically for tables created in the Studio,
--    but tables created via migrations may not have them.
--
-- 2. holiday_calendar has no INSERT policy by design (reference data), but the
--    Flutter app needs to sync new years from the Nager.Date API.
--    A SECURITY DEFINER function lets the app write safely.

-- ── Table-level privileges for the authenticated role ──────────────────────────
GRANT USAGE ON SCHEMA public TO authenticated;

GRANT SELECT, INSERT, UPDATE          ON profiles                    TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON attendance_sessions          TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON daily_attendance_summaries   TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON work_cycles                  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE  ON schedules                    TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE  ON schedule_entries             TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE  ON schedule_exceptions          TO authenticated;
GRANT SELECT, INSERT                  ON correction_requests          TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON notification_preferences     TO authenticated;
GRANT SELECT, INSERT, UPDATE          ON device_tokens                TO authenticated;
GRANT SELECT                          ON departments                  TO authenticated;
GRANT SELECT                          ON holiday_calendar             TO authenticated;

-- ── RPC: upsert_notification_prefs ─────────────────────────────────────────────
-- Accepts the full preferences object as a single JSONB argument so the Dart
-- _toMap() output can be forwarded directly. SECURITY DEFINER bypasses RLS,
-- but the function validates auth.uid() itself so no user can write another's row.
CREATE OR REPLACE FUNCTION upsert_notification_prefs(prefs jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    INSERT INTO notification_preferences (
        user_id,
        arrival_reminder,     arrival_reminder_time,
        departure_reminder,   departure_reminder_time,
        missed_checkin_alert, missed_checkout_alert,
        tomorrow_preview,     weekly_summary,
        cycle_end_warning,    early_leave_recommendation
    )
    VALUES (
        v_uid,
        (prefs->>'arrival_reminder')::boolean,
        (prefs->>'arrival_reminder_time')::time,
        (prefs->>'departure_reminder')::boolean,
        (prefs->>'departure_reminder_time')::time,
        (prefs->>'missed_checkin_alert')::boolean,
        (prefs->>'missed_checkout_alert')::boolean,
        (prefs->>'tomorrow_preview')::boolean,
        (prefs->>'weekly_summary')::boolean,
        (prefs->>'cycle_end_warning')::boolean,
        (prefs->>'early_leave_recommendation')::boolean
    )
    ON CONFLICT (user_id) DO UPDATE SET
        arrival_reminder          = EXCLUDED.arrival_reminder,
        arrival_reminder_time     = EXCLUDED.arrival_reminder_time,
        departure_reminder        = EXCLUDED.departure_reminder,
        departure_reminder_time   = EXCLUDED.departure_reminder_time,
        missed_checkin_alert      = EXCLUDED.missed_checkin_alert,
        missed_checkout_alert     = EXCLUDED.missed_checkout_alert,
        tomorrow_preview          = EXCLUDED.tomorrow_preview,
        weekly_summary            = EXCLUDED.weekly_summary,
        cycle_end_warning         = EXCLUDED.cycle_end_warning,
        early_leave_recommendation = EXCLUDED.early_leave_recommendation;
END;
$$;

GRANT EXECUTE ON FUNCTION upsert_notification_prefs(jsonb) TO authenticated;

-- ── RPC: sync_holidays ─────────────────────────────────────────────────────────
-- Allows the Flutter app to push holidays fetched from the Nager.Date API.
-- holiday_calendar has no user-INSERT policy by design, so the app routes
-- writes through this SECURITY DEFINER function instead.
CREATE OR REPLACE FUNCTION sync_holidays(holidays jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    INSERT INTO holiday_calendar (holiday_date, name, is_national)
    SELECT
        (h->>'holiday_date')::date,
        h->>'name',
        COALESCE((h->>'is_national')::boolean, true)
    FROM jsonb_array_elements(holidays) AS h
    ON CONFLICT (holiday_date) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION sync_holidays(jsonb) TO authenticated;
