-- Migration 010: Replace single rest_day with rest_days array
-- Allows users to select multiple additional rest days.

-- Add the new array column (default empty array).
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS rest_days integer[] NOT NULL DEFAULT '{}';

-- Migrate existing single rest_day values into the new array.
UPDATE public.profiles
  SET rest_days = ARRAY[rest_day]
  WHERE rest_day IS NOT NULL;

-- Drop the old column.
ALTER TABLE public.profiles
  DROP COLUMN IF EXISTS rest_day;
