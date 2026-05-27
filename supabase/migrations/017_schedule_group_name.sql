-- Migration 017: Add group_name to schedule_entries
-- Stores the student group (e.g. "A9", "B 2-AI") separately from
-- the course code (title) and room (location).

ALTER TABLE schedule_entries
  ADD COLUMN IF NOT EXISTS group_name text;
