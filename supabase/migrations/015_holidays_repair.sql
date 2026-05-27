-- Migration 015: Repair Egyptian public holiday calendar
--
-- Previous Nager.Date syncs added incorrect and duplicate Islamic holiday
-- entries alongside the correct migration-009 data. This migration removes
-- all entries for 2025-2028 and re-seeds from the authoritative list below.
--
-- Islamic holiday dates follow official Egyptian government declarations
-- (Majlis al-Buhuth al-Islamiyyah / Umm Al-Qura alignment).
-- National holidays are fixed Gregorian dates and never change.

-- Step 1: Remove all existing entries so the clean set can be inserted.
DELETE FROM holiday_calendar
WHERE holiday_date BETWEEN '2025-01-01' AND '2028-12-31';

-- Step 2: Insert verified authoritative data.
INSERT INTO holiday_calendar (holiday_date, name, is_national) VALUES

-- ── 2025 ──────────────────────────────────────────────────────────────────────
('2025-01-07',  'Coptic Christmas Day',           true),
('2025-01-25',  'National Police Day',             true),
('2025-03-30',  'Eid Al-Fitr – Day 1',            true),
('2025-03-31',  'Eid Al-Fitr – Day 2',            true),
('2025-04-01',  'Eid Al-Fitr – Day 3',            true),
('2025-04-25',  'Sinai Liberation Day',            true),
('2025-05-01',  'International Labour Day',        true),
('2025-06-05',  'Arafat (Eid Al-Adha Eve)',        true),
('2025-06-06',  'Eid Al-Adha – Day 1',            true),
('2025-06-07',  'Eid Al-Adha – Day 2',            true),
('2025-06-08',  'Eid Al-Adha – Day 3',            true),
('2025-06-09',  'Eid Al-Adha – Day 4',            true),
('2025-06-26',  'Islamic New Year (1447 AH)',      true),
('2025-06-30',  'June 30 Revolution Day',          true),
('2025-07-23',  'July 23 Revolution Day',          true),
('2025-09-04',  'Prophet''s Birthday (Mawlid)',    true),
('2025-10-06',  'Armed Forces Day',                true),

-- ── 2026 ──────────────────────────────────────────────────────────────────────
('2026-01-07',  'Coptic Christmas Day',            true),
('2026-01-25',  'National Police Day',             true),
('2026-03-19',  'Eid Al-Fitr – Day 1',            true),
('2026-03-20',  'Eid Al-Fitr – Day 2',            true),
('2026-03-21',  'Eid Al-Fitr – Day 3',            true),
('2026-04-25',  'Sinai Liberation Day',            true),
('2026-05-01',  'International Labour Day',        true),
('2026-05-26',  'Arafat (Eid Al-Adha Eve)',        true),
('2026-05-27',  'Eid Al-Adha – Day 1',            true),
('2026-05-28',  'Eid Al-Adha – Day 2',            true),
('2026-05-29',  'Eid Al-Adha – Day 3',            true),
('2026-05-30',  'Eid Al-Adha – Day 4',            true),
('2026-06-15',  'Islamic New Year (1448 AH)',      true),
('2026-06-30',  'June 30 Revolution Day',          true),
('2026-07-23',  'July 23 Revolution Day',          true),
('2026-08-25',  'Prophet''s Birthday (Mawlid)',    true),
('2026-10-06',  'Armed Forces Day',                true),

-- ── 2027 ──────────────────────────────────────────────────────────────────────
('2027-01-07',  'Coptic Christmas Day',            true),
('2027-01-25',  'National Police Day',             true),
('2027-03-08',  'Eid Al-Fitr – Day 1',            true),
('2027-03-09',  'Eid Al-Fitr – Day 2',            true),
('2027-03-10',  'Eid Al-Fitr – Day 3',            true),
('2027-04-25',  'Sinai Liberation Day',            true),
('2027-05-01',  'International Labour Day',        true),
('2027-05-15',  'Arafat (Eid Al-Adha Eve)',        true),
('2027-05-16',  'Eid Al-Adha – Day 1',            true),
('2027-05-17',  'Eid Al-Adha – Day 2',            true),
('2027-05-18',  'Eid Al-Adha – Day 3',            true),
('2027-05-19',  'Eid Al-Adha – Day 4',            true),
('2027-06-04',  'Islamic New Year (1449 AH)',      true),
('2027-06-30',  'June 30 Revolution Day',          true),
('2027-07-23',  'July 23 Revolution Day',          true),
('2027-08-14',  'Prophet''s Birthday (Mawlid)',    true),
('2027-10-06',  'Armed Forces Day',                true),

-- ── 2028 ──────────────────────────────────────────────────────────────────────
('2028-01-07',  'Coptic Christmas Day',            true),
('2028-01-25',  'National Police Day',             true),
('2028-02-25',  'Eid Al-Fitr – Day 1',            true),
('2028-02-26',  'Eid Al-Fitr – Day 2',            true),
('2028-02-27',  'Eid Al-Fitr – Day 3',            true),
('2028-04-25',  'Sinai Liberation Day',            true),
('2028-05-01',  'International Labour Day',        true),
('2028-05-04',  'Arafat (Eid Al-Adha Eve)',        true),
('2028-05-05',  'Eid Al-Adha – Day 1',            true),
('2028-05-06',  'Eid Al-Adha – Day 2',            true),
('2028-05-07',  'Eid Al-Adha – Day 3',            true),
('2028-05-08',  'Eid Al-Adha – Day 4',            true),
('2028-05-24',  'Islamic New Year (1450 AH)',      true),
('2028-06-30',  'June 30 Revolution Day',          true),
('2028-07-23',  'July 23 Revolution Day',          true),
('2028-08-02',  'Prophet''s Birthday (Mawlid)',    true),
('2028-10-06',  'Armed Forces Day',                true)

ON CONFLICT (holiday_date) DO UPDATE SET
    name        = EXCLUDED.name,
    is_national = EXCLUDED.is_national;
