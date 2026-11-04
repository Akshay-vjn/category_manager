import 'package:category_manager/core/api_config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/auth/data/providers/auth_providers.dart';
import 'package:category_manager/features/auth/data/repo/auth_repository.dart';
import 'package:category_manager/features/profile/data/services/user_api_service.dart';
import 'support/test_api.dart';

void main() {
  test(
    'login requests the entered ID and parses every profile field',
    () async {
      final dio = testDio();
      String? requested;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requested = options.path;
            handler.next(options);
          },
        ),
      );
      final user = await AuthRepository(UserApiService(dio)).login(' 7 ');
      expect(requested, '/users/7');
      expect(
        [
          user.name,
          user.username,
          user.email,
          user.phone,
          user.website,
          user.company,
        ],
        [
          'API Test Person',
          'api_person',
          'person@example.test',
          '12345678',
          'example.test',
          'API Company',
        ],
      );
      dio.close();
    },
  );
  test('invalid ID never reaches API', () {
    final dio = testDio();
    final repo = AuthRepository(UserApiService(dio));
    for (final id in ['', 'abc', '0', '-1', '1.5']) {
      expect(() => repo.login(id), throwsA(isA<AppException>()));
    }
    dio.close();
  });
  test(
    'missing, malformed and mismatched profiles have actionable errors',
    () async {
      for (final dio in [
        testDio(status: 404),
        testDio(body: <String, dynamic>{}),
        testDio(body: {'id': 7}),
        testDio(body: profileJson(id: 8)),
      ]) {
        await expectLater(
          UserApiService(dio).fetchUser(7),
          throwsA(isA<AppException>()),
        );
        dio.close();
      }
    },
  );
  test('timeouts and connection failures become safe UI messages', () async {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.connectionError,
    ]) {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(DioException(requestOptions: options, type: type));
          },
        ),
      );
      await expectLater(
        UserApiService(dio).fetchUser(7),
        throwsA(isA<AppException>()),
      );
      dio.close();
    }
  });
  test(
    'Riverpod exposes loading, success, logout and retry after error',
    () async {
      final dio = testDio();
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      addTearDown(dio.close);
      final controller = container.read(authProvider.notifier);
      final request = controller.login('7');
      expect(container.read(authProvider).isLoading, isTrue);
      await request;
      expect(container.read(authProvider).requireValue!.id, 7);
      expect(container.read(currentUserIdProvider), 7);
      controller.logout();
      expect(container.read(authProvider).requireValue, isNull);
      expect(container.read(currentUserIdProvider), isNull);
      await controller.login('bad');
      expect(container.read(authProvider).hasError, isTrue);
      await controller.login('7');
      expect(container.read(authProvider).requireValue!.id, 7);
    },
  );
}
