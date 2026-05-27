-- The upsert in NotificationPrefsNotifier falls back to INSERT when no row
-- exists yet (trigger may not have run for older accounts or anon users).
-- Without this policy the upsert throws PermissionException.
create policy "notif_prefs: user inserts own"
  on notification_preferences for insert
  with check (user_id = auth.uid());
