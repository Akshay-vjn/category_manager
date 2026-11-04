import 'package:category_manager/core/navigation/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:category_manager/app.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';
import 'package:category_manager/features/profile/data/models/user_profile.dart';
import 'package:category_manager/features/profile/presentation/profile_screen.dart';
import 'package:category_manager/features/categories/data/models/category.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';
import 'package:category_manager/features/categories/data/providers/category_providers.dart';
import 'package:category_manager/features/categories/presentation/widgets/category_tree.dart';
import 'package:category_manager/features/auth/presentation/splash_screen.dart';
import 'support/test_api.dart';

void main() {
  Future<void> phone(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('splash transitions to usable login exactly once', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(const ProviderScope(child: CategoryManagerApp()));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Login'), findsNothing);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.widgetWithText(TextFormField, 'User ID'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash timer is cancelled when the app is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CategoryManagerApp()));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('category search stays usable on a small phone', (tester) async {
    await phone(tester, width: 320, height: 640);
    final queries = <CategoryQuery>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryPageProvider.overrideWith((ref, query) async {
            queries.add(query);
            return CategoryPage<CategoryEntry>(
              items: [],
              page: query.page,
              pageSize: query.pageSize,
              totalCount: 0,
              limit: query.limit,
            );
          }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: HomeScreen(user: UserProfile.fromJson(profileJson())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsNothing);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    expect(queries.last.pageSize, 20);
    expect(queries.last.limit, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search categories'),
      'Travel',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(queries.last.search, 'Travel');

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree can expand without extra row actions on a phone', (
    tester,
  ) async {
    await phone(tester);
    final root = Category(
      id: 1,
      name: 'Personal',
      parentId: null,
      createdAt: DateTime.utc(2026),
    );
    final work = Category(
      id: 3,
      name: 'Work projects',
      parentId: null,
      createdAt: DateTime.utc(2026),
    );
    final child = Category(
      id: 2,
      name: 'Travel plans',
      parentId: 1,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryPageProvider.overrideWith(
            (ref, query) async => CategoryPage(
              items: query.parentId == 1
                  ? [
                      CategoryEntry(
                        category: child,
                        path: [root, child],
                        childCount: 0,
                      ),
                    ]
                  : [
                      CategoryEntry(
                        category: root,
                        path: [root],
                        childCount: 1,
                      ),
                      CategoryEntry(
                        category: work,
                        path: [work],
                        childCount: 0,
                      ),
                    ],
              page: 1,
              pageSize: 20,
              totalCount: query.parentId == 1 ? 1 : 2,
              limit: null,
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: HomeScreen(user: UserProfile.fromJson(profileJson())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal'));
    await tester.pumpAndSettle();
    expect(find.text('Travel plans'), findsOneWidget);
    expect(find.byTooltip('Details for Personal'), findsNothing);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    expect(find.byTooltip('Add subcategory to Personal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pagination uses result ranges without a page badge', (
    tester,
  ) async {
    var selectedPage = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageControls(
            result: CategoryPage<CategoryEntry>(
              items: [],
              page: 1,
              pageSize: 10,
              totalCount: 25,
              limit: null,
            ),
            onChanged: (page) => selectedPage = page,
          ),
        ),
      ),
    );

    expect(find.text('Showing 1–10 of 25'), findsOneWidget);
    expect(find.textContaining('Page 1 of'), findsNothing);
    await tester.tap(find.byTooltip('Next page'));
    expect(selectedPage, 2);
  });

  testWidgets('profile wraps long details with large accessibility text', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileScreen(user: UserProfile.fromJson(profileJson())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
