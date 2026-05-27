-- Migration 011: Holiday calendar data is now fetched at runtime
-- from the Nager.Date public holidays API (https://date.nager.at/api/v3/PublicHolidays/{year}/EG).
--
-- The Flutter app automatically syncs the current and next calendar year
-- into the holiday_calendar table on startup.
-- No manual seeding is required — this migration is intentionally a no-op.
SELECT 1;
