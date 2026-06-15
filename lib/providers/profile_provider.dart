import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// StreamProvider that listens to the user authentication state and fetches
/// the corresponding profile from Supabase Database.
final profileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final controller = StreamController<Map<String, dynamic>?>();

  Future<void> fetchProfile(User? user) async {
    if (user == null) {
      controller.add(null);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      controller.add(data);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      controller.add(null);
    }
  }

  // Fetch initially for current session user
  fetchProfile(Supabase.instance.client.auth.currentUser);

  // Re-fetch dynamically when authentication state changes (login, logout, sign up)
  final subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    fetchProfile(data.session?.user);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

class DummyProfileNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() {
    return null;
  }

  @override
  set state(Map<String, dynamic>? newValue) {
    super.state = newValue;
  }
}

/// Provider to store dummy/mock profile data when bypass/offline mode is active.
final dummyProfileProvider = NotifierProvider<DummyProfileNotifier, Map<String, dynamic>?>(
  DummyProfileNotifier.new,
);


/// Evaluates if the current logged-in user is an administrator.
final isAdminProvider = Provider<bool>((ref) {
  final dummyProfile = ref.watch(dummyProfileProvider);
  if (dummyProfile != null) {
    return dummyProfile['role'] == 'admin';
  }

  final profileAsync = ref.watch(profileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?['role'] == 'admin',
    orElse: () => false, // Fallback to false if still loading or fails
  );
});

