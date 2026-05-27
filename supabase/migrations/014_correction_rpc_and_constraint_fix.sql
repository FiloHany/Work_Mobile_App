-- ============================================================
-- Migration 014: Correction RPC + constraint fix
-- ============================================================

-- ── 1. Relax the no_future_checkin constraint for corrections ─────────────────
--
-- The constraint currently blocks any INSERT with check_in_time > now()+5min.
-- Corrections are always for past sessions, but they bypass normal INSERT RLS
-- via a SECURITY DEFINER function.  We exempt 'correction_applied' status so
-- the function can write corrected sessions without fighting the constraint.

ALTER TABLE attendance_sessions DROP CONSTRAINT no_future_checkin;

ALTER TABLE attendance_sessions
  ADD CONSTRAINT no_future_checkin CHECK (
    status = 'correction_applied'
    OR check_in_time <= now() + interval '5 minutes'
  );

-- ── 2. apply_attendance_correction — SECURITY DEFINER RPC ─────────────────────
--
-- Bypasses the UPDATE RLS policy (which only allows active→completed) and the
-- no_future_checkin constraint (correction_applied is now exempt above).
-- Always writes status = 'correction_applied' so normal session guards don't
-- interfere. The caller fetches the resulting row after the call.

CREATE OR REPLACE FUNCTION apply_attendance_correction(
    p_target_date   date,
    p_check_in_time  timestamptz DEFAULT NULL,
    p_check_out_time timestamptz DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid        uuid := auth.uid();
    v_existing   uuid;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    -- Locate the newest non-voided session for this user / date.
    SELECT id INTO v_existing
    FROM attendance_sessions
    WHERE user_id    = v_uid
      AND session_date = p_target_date
      AND status      != 'voided'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_existing IS NOT NULL THEN
        -- Update existing session, preserving any field not supplied.
        UPDATE attendance_sessions
        SET
            status         = 'correction_applied',
            check_in_time  = COALESCE(p_check_in_time,  check_in_time),
            check_out_time = COALESCE(p_check_out_time, check_out_time),
            updated_at     = now()
        WHERE id      = v_existing
          AND user_id = v_uid;
    ELSE
        -- No existing session — require a check-in time.
        IF p_check_in_time IS NULL THEN
            RAISE EXCEPTION 'check_in_time is required when no session exists for this date';
        END IF;

        INSERT INTO attendance_sessions
            (user_id, session_date, check_in_time, check_out_time, status)
        VALUES
            (v_uid, p_target_date, p_check_in_time, p_check_out_time, 'correction_applied');
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION apply_attendance_correction(date, timestamptz, timestamptz)
  TO authenticated;
