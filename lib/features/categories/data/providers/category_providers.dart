import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/core/database/database_service.dart';
import 'package:category_manager/features/auth/data/providers/auth_providers.dart';
import 'package:category_manager/features/categories/data/models/category.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';
import 'package:category_manager/features/categories/data/repo/category_repository.dart';

final databaseProvider = Provider((ref) {
  final service = DatabaseService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

final categoryRepositoryProvider = Provider(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final categoryPageProvider = FutureProvider.autoDispose
    .family<CategoryPage<CategoryEntry>, CategoryQuery>(
      (ref, query) => ref.watch(categoryRepositoryProvider).list(query),
    );

final categoryCreationProvider =
    NotifierProvider<CategoryCreationController, AsyncValue<void>>(
      CategoryCreationController.new,
    );

class CategoryCreationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  void reset() => state = const AsyncData(null);

  Future<bool> create(String name, {int? parentId}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final userId = ref.read(currentUserIdProvider);
    final result = await AsyncValue.guard(() async {
      await ref
          .read(categoryRepositoryProvider)
          .create(name, parentId: parentId, userId: userId);
    });
    if (!ref.mounted) return false;
    state = result;
    if (!result.hasError) ref.invalidate(categoryPageProvider);
    return !result.hasError;
  }
}
