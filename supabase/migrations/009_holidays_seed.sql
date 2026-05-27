-- Migration 009: Egyptian National & Islamic Public Holidays (2025-2027)
--
-- Fixed national holidays repeat on the same Gregorian date every year.
-- Islamic holidays are ESTIMATES based on the ~11-day annual shift; actual
-- dates depend on official moon sighting and government declarations.
-- Admins can INSERT/UPDATE rows directly in the Supabase dashboard.
--
-- Egypt observes: National Police Day, Coptic Christmas, Sinai Liberation,
-- Labour Day, Eid Al-Fitr (3d), Eid Al-Adha (4d), Islamic New Year,
-- June-30 Revolution, July-23 Revolution, Mawlid, Armed Forces Day.

INSERT INTO holiday_calendar (holiday_date, name, is_national) VALUES

-- ── 2025 ──────────────────────────────────────────────────────────────────────
('2025-01-07',  'Coptic Christmas Day',          true),
('2025-01-25',  'National Police Day',            true),
('2025-03-30',  'Eid Al-Fitr – Day 1',           true),
('2025-03-31',  'Eid Al-Fitr – Day 2',           true),
('2025-04-01',  'Eid Al-Fitr – Day 3',           true),
('2025-04-25',  'Sinai Liberation Day',           true),
('2025-05-01',  'International Labour Day',       true),
('2025-06-05',  'Arafat (Eid Al-Adha eve)',       true),
('2025-06-06',  'Eid Al-Adha – Day 1',           true),
('2025-06-07',  'Eid Al-Adha – Day 2',           true),
('2025-06-08',  'Eid Al-Adha – Day 3',           true),
('2025-06-09',  'Eid Al-Adha – Day 4',           true),
('2025-06-26',  'Islamic New Year (1447 AH)',     true),
('2025-06-30',  'June 30 Revolution Day',         true),
('2025-07-23',  'July 23 Revolution Day',         true),
('2025-09-04',  'Prophet's Birthday (Mawlid)',    true),
('2025-10-06',  'Armed Forces Day',               true),

-- ── 2026 ──────────────────────────────────────────────────────────────────────
('2026-01-07',  'Coptic Christmas Day',           true),
('2026-01-25',  'National Police Day',            true),
('2026-03-19',  'Eid Al-Fitr – Day 1',           true),
('2026-03-20',  'Eid Al-Fitr – Day 2',           true),
('2026-03-21',  'Eid Al-Fitr – Day 3',           true),
('2026-04-25',  'Sinai Liberation Day',           true),
('2026-05-01',  'International Labour Day',       true),
('2026-05-26',  'Arafat (Eid Al-Adha eve)',       true),
('2026-05-27',  'Eid Al-Adha – Day 1',           true),
('2026-05-28',  'Eid Al-Adha – Day 2',           true),
('2026-05-29',  'Eid Al-Adha – Day 3',           true),
('2026-05-30',  'Eid Al-Adha – Day 4',           true),
('2026-06-15',  'Islamic New Year (1448 AH)',     true),
('2026-06-30',  'June 30 Revolution Day',         true),
('2026-07-23',  'July 23 Revolution Day',         true),
('2026-08-25',  'Prophet's Birthday (Mawlid)',    true),
('2026-10-06',  'Armed Forces Day',               true),

-- ── 2027 ──────────────────────────────────────────────────────────────────────
('2027-01-07',  'Coptic Christmas Day',           true),
('2027-01-25',  'National Police Day',            true),
('2027-03-09',  'Eid Al-Fitr – Day 1',           true),
('2027-03-10',  'Eid Al-Fitr – Day 2',           true),
('2027-03-11',  'Eid Al-Fitr – Day 3',           true),
('2027-04-25',  'Sinai Liberation Day',           true),
('2027-05-01',  'International Labour Day',       true),
('2027-05-16',  'Arafat (Eid Al-Adha eve)',       true),
('2027-05-17',  'Eid Al-Adha – Day 1',           true),
('2027-05-18',  'Eid Al-Adha – Day 2',           true),
('2027-05-19',  'Eid Al-Adha – Day 3',           true),
('2027-05-20',  'Eid Al-Adha – Day 4',           true),
('2027-06-05',  'Islamic New Year (1449 AH)',     true),
('2027-06-30',  'June 30 Revolution Day',         true),
('2027-07-23',  'July 23 Revolution Day',         true),
('2027-08-15',  'Prophet's Birthday (Mawlid)',    true),
('2027-10-06',  'Armed Forces Day',               true)

ON CONFLICT (holiday_date) DO NOTHING;
