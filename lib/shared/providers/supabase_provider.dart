import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw Supabase client — injected everywhere via Riverpod.
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

/// Auth stream so widgets can react to login/logout events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Convenience: current user (null if logged out).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider); // rebuild when auth changes
  return Supabase.instance.client.auth.currentUser;
});
