-- ============================================================
-- Migration 016: Correction sets status='active' for open sessions
-- ============================================================
--
-- When a missed check-in correction has no checkout time, the resulting
-- session gets status='active' so activeSession() can find it, the live
-- timer starts from the corrected time, and the user can check out normally.
--
-- When a checkout is included (fullCorrection or missedCheckOut), the
-- session keeps status='correction_applied' as before.

CREATE OR REPLACE FUNCTION apply_attendance_correction(
    p_target_date    date,
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
    v_new_status session_status;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not_authenticated';
    END IF;

    -- Open session (no checkout) → 'active' so the timer and check-out button work.
    -- Completed session (has checkout) → 'correction_applied' so normal guards still apply.
    v_new_status := CASE WHEN p_check_out_time IS NULL THEN 'active'::session_status ELSE 'correction_applied'::session_status END;

    -- Locate the newest non-voided session for this user / date.
    SELECT id INTO v_existing
    FROM attendance_sessions
    WHERE user_id     = v_uid
      AND session_date = p_target_date
      AND status      != 'voided'
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_existing IS NOT NULL THEN
        UPDATE attendance_sessions
        SET
            status         = v_new_status,
            check_in_time  = COALESCE(p_check_in_time,  check_in_time),
            check_out_time = COALESCE(p_check_out_time, check_out_time),
            updated_at     = now()
        WHERE id      = v_existing
          AND user_id = v_uid;
    ELSE
        IF p_check_in_time IS NULL THEN
            RAISE EXCEPTION 'check_in_time is required when no session exists for this date';
        END IF;

        INSERT INTO attendance_sessions
            (user_id, session_date, check_in_time, check_out_time, status)
        VALUES
            (v_uid, p_target_date, p_check_in_time, p_check_out_time, v_new_status);
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION apply_attendance_correction(date, timestamptz, timestamptz)
  TO authenticated;
