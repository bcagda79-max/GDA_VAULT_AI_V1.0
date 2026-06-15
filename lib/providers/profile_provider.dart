import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gda_vault_ai/core/services/auth_service.dart';

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await AuthService.instance.getCurrentProfile();
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

final dummyProfileProvider = NotifierProvider<DummyProfileNotifier, Map<String, dynamic>?>(
  DummyProfileNotifier.new,
);

final isAdminProvider = Provider<bool>((ref) {
  final dummyProfile = ref.watch(dummyProfileProvider);
  if (dummyProfile != null) {
    return dummyProfile['role'] == 'admin';
  }

  final profileAsync = ref.watch(profileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?['role'] == 'admin',
    orElse: () => false,
  );
});
