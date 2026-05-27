-- ============================================================
-- Seed 001: Reference data for local/staging environments
-- ============================================================

-- ── Departments ───────────────────────────────────────────────────────────────
insert into departments (name, code, faculty) values
  ('Computer Science',            'CS',   'Faculty of Engineering'),
  ('Mathematics',                  'MATH', 'Faculty of Science'),
  ('Physics',                      'PHYS', 'Faculty of Science'),
  ('Electrical Engineering',       'EE',   'Faculty of Engineering'),
  ('Civil Engineering',            'CE',   'Faculty of Engineering'),
  ('Business Administration',      'BA',   'Faculty of Commerce'),
  ('Arabic Language',              'AR',   'Faculty of Arts'),
  ('English Language',             'EN',   'Faculty of Arts')
on conflict do nothing;

-- ── Holiday Calendar (sample year) ────────────────────────────────────────────
insert into holiday_calendar (holiday_date, name, is_national) values
  ('2025-01-01', 'New Year Day',              true),
  ('2025-04-25', 'Sinai Liberation Day',      true),
  ('2025-05-01', 'Labour Day',                true),
  ('2025-06-30', 'June 30 Revolution Day',    true),
  ('2025-07-23', 'July 23 Revolution Day',    true),
  ('2025-10-06', 'Armed Forces Day',          true),
  ('2026-01-01', 'New Year Day',              true),
  ('2026-04-25', 'Sinai Liberation Day',      true),
  ('2026-05-01', 'Labour Day',                true),
  ('2026-06-30', 'June 30 Revolution Day',    true),
  ('2026-07-23', 'July 23 Revolution Day',    true),
  ('2026-10-06', 'Armed Forces Day',          true)
on conflict do nothing;

-- ── Demo user (run this AFTER creating the user via Supabase Auth) ─────────────
-- Replace 'DEMO_USER_UUID' with the actual UUID from auth.users after signup.
-- Example:
--   UPDATE profiles SET
--     full_name   = 'Dr. Ahmed Hassan',
--     role        = 'doctor',
--     department_id = (select id from departments where code = 'CS'),
--     faculty     = 'Faculty of Engineering',
--     employee_id = 'EMP-001',
--     is_onboarded = true
--   WHERE email = 'demo@example.com';
