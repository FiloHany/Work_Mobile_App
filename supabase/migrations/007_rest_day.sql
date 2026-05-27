-- Migration 007: Add user-defined second rest day to profiles
-- rest_day stores a weekday integer (1=Mon … 7=Sun); NULL = no second rest day.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS rest_day integer;
