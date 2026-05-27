-- ============================================================
-- Migration 006: Unique display name constraint
-- ============================================================
-- Names are the sole identifier visible to users (no email/password shown).
-- Enforce case-insensitive uniqueness so 'Ahmed Ali' and 'ahmed ali' can't coexist.

CREATE UNIQUE INDEX profiles_full_name_unique
  ON profiles (lower(full_name));
