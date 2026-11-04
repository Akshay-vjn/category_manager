import 'package:category_manager/core/api_config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:category_manager/app.dart';
import 'package:category_manager/core/database/database_service.dart';
import 'package:category_manager/features/categories/data/providers/category_providers.dart';
import 'support/test_api.dart';

void main() {
  sqfliteFfiInit();
  testWidgets('login validation and server errors remain on login screen', (
    tester,
  ) async {
    final dio = testDio(status: 404);
    addTearDown(dio.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const CategoryManagerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Enter a valid positive User ID.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '100');
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('No user found for this ID.'), findsOneWidget);
  });

  testWidgets(
    'login, profile, persistent category creation, duplicate error and recursive search',
    (tester) async {
      Future<void> settleDatabase() async {
        // Allow real SQLite I/O and the widget fake clock to make progress.
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pumpAndSettle();
      }

      final dio = testDio();
      final database = DatabaseService(
        factory: databaseFactoryFfiNoIsolate,
        databasePath: inMemoryDatabasePath,
      );
      await tester.runAsync(() => database.database);
      addTearDown(dio.close);
      addTearDown(database.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            databaseProvider.overrideWithValue(database),
          ],
          child: const CategoryManagerApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '7');
      await tester.ensureVisible(find.text('Login'));
      await tester.tap(find.text('Login'));
      await settleDatabase();
      await settleDatabase();
      expect(find.text('Start your category tree'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await settleDatabase();
      await tester.scrollUntilVisible(
        find.text('API Company'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('API Company'), findsOneWidget);
      expect(find.text('person@example.test'), findsOneWidget);
      await tester.tap(find.text('Categories').last);
      await settleDatabase();
      Future<void> save(String name) async {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Category name'),
          name,
        );
        await tester.tap(find.text('Save'));
        await settleDatabase();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Add category'));
      await settleDatabase();
      await save('Electronics');
      expect(find.text('Electronics'), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip('Add subcategory to Electronics'),
      );
      await tester.tap(find.byTooltip('Add subcategory to Electronics'));
      await settleDatabase();
      await save('Mobile');
      await settleDatabase();
      expect(find.text('Mobile'), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip('Add subcategory to Electronics'),
      );
      await tester.tap(find.byTooltip('Add subcategory to Electronics'));
      await settleDatabase();
      await save(' mobile ');
      expect(
        find.text(
          'A category with this name already exists under this parent.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await settleDatabase();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search categories'),
        'Mobile',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await settleDatabase();
      expect(find.textContaining('Electronics › Mobile'), findsOneWidget);
      expect(find.textContaining('Parent: Electronics'), findsOneWidget);
      await tester.tap(find.byTooltip('Logout'));
      await settleDatabase();
      await tester.tap(find.text('Sign out').last);
      await settleDatabase();
      expect(find.text('Login'), findsOneWidget);
    },
  );
}
