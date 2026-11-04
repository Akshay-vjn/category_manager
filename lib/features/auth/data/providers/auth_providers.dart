import 'package:category_manager/core/api_config/api_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/features/profile/data/models/user_profile.dart';
import 'package:category_manager/features/auth/data/repo/auth_repository.dart';
import 'package:category_manager/features/profile/data/services/user_api_service.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(UserApiService(ref.watch(dioProvider))),
);
final authProvider = NotifierProvider<AuthController, AsyncValue<UserProfile?>>(
  AuthController.new,
);
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authProvider).asData?.value?.id,
);

class AuthController extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() => const AsyncData(null);

  Future<void> login(String id) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(id),
    );
    if (ref.mounted) state = result;
  }

  void logout() => state = const AsyncData(null);
}
