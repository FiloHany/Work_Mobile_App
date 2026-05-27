-- Migration 008: Support anonymous auth (no email provider required)
--
-- Problem: handle_new_user trigger inserts `new.email` into profiles.email (NOT NULL).
-- Anonymous auth users have null email → trigger fails → registration broken.
-- Fix: fall back to a synthetic "{uuid}@workhours.app" when email is null.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id,
    COALESCE(new.email, new.id::text || '@workhours.app'),
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'role', 'demonstrator')::public.user_role
  );
  INSERT INTO public.notification_preferences (user_id)
  VALUES (new.id);
  RETURN new;
END;
$$;
