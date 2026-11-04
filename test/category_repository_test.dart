import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:category_manager/core/database/database_service.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';
import 'package:category_manager/features/categories/data/repo/category_repository.dart';

void main() {
  sqfliteFfiInit();
  late DatabaseService database;
  late CategoryRepository repository;
  setUp(() {
    database = DatabaseService(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = CategoryRepository(database);
  });
  tearDown(() => database.close());

  test(
    'new database is empty; creation stores trimmed name and UTC timestamp',
    () async {
      expect((await repository.list(const CategoryQuery())).items, isEmpty);
      final category = await repository.create('  Electronics  ');
      expect(category.id, isPositive);
      expect(category.name, 'Electronics');
      expect(category.createdAt.isUtc, isTrue);
      final stored = (await repository.list(
        const CategoryQuery(),
      )).items.single;
      expect(stored.category.createdAt, category.createdAt);
      expect(stored.parent, isNull);
      expect(stored.path.map((e) => e.name), ['Electronics']);
    },
  );

  test('rejects empty names and nonexistent parents', () async {
    await expectLater(repository.create('  '), throwsA(isA<AppException>()));
    await expectLater(
      repository.create('Child', parentId: 999),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'database enforces case-insensitive uniqueness including root NULL parents',
    () async {
      final root = await repository.create('Electronics');
      final other = await repository.create('Clothing');
      await expectLater(
        repository.create(' electronics '),
        throwsA(isA<AppException>()),
      );
      await repository.create('Mobile', parentId: root.id);
      await expectLater(
        repository.create(' MOBILE ', parentId: root.id),
        throwsA(isA<AppException>()),
      );
      await repository.create('Mobile', parentId: other.id);
      expect(
        (await repository.list(
          const CategoryQuery(search: 'mobile'),
        )).totalCount,
        2,
      );
      final db = await database.database;
      await expectLater(
        db.insert('categories', {
          'name': 'Electronics',
          'name_key': 'electronics',
          'parent_id': null,
          'created_at': DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'concurrent duplicate writes cannot create duplicate siblings',
    () async {
      final results = await Future.wait(
        List.generate(5, (_) async {
          try {
            await repository.create('Concurrent');
            return true;
          } on AppException {
            return false;
          }
        }),
      );
      expect(results.where((success) => success).length, 1);
    },
  );

  test('new categories stay with their user, including child counts', () async {
    final firstRoot = await repository.create('Projects', userId: 1);
    final secondRoot = await repository.create('Projects', userId: 2);
    await repository.create('Personal', parentId: firstRoot.id, userId: 1);
    await repository.create('Work', parentId: secondRoot.id, userId: 2);

    final first = await repository.list(
      const CategoryQuery(userId: 1, search: 'projects'),
    );
    final second = await repository.list(
      const CategoryQuery(userId: 2, search: 'projects'),
    );
    expect(first.items.single.category.id, firstRoot.id);
    expect(second.items.single.category.id, secondRoot.id);
    expect(first.items.single.childCount, 1);
    expect(second.items.single.childCount, 1);
    expect(
      (await repository.list(
        const CategoryQuery(userId: 1, search: 'work'),
      )).items,
      isEmpty,
    );
    await expectLater(
      repository.create('Wrong parent', parentId: secondRoot.id, userId: 1),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'recursive search resolves 200 levels, parent, path and direct children',
    () async {
      int? parent;
      final names = <String>[];
      for (var i = 0; i < 200; i++) {
        final name = 'Level $i';
        names.add(name);
        parent = (await repository.create(name, parentId: parent)).id;
      }
      final leaf = await repository.create(
        'Needle › literal',
        parentId: parent,
      );
      await repository.create('Direct child', parentId: leaf.id);
      final result = await repository.list(
        const CategoryQuery(search: 'NEEDLE'),
      );
      final match = result.items.single;
      expect(match.path.map((e) => e.name), [...names, 'Needle › literal']);
      expect(match.parent!.name, 'Level 199');
      expect(match.childCount, 1);
      final children = await repository.list(CategoryQuery(parentId: leaf.id));
      expect(children.items.single.category.name, 'Direct child');
    },
  );

  test(
    'literal search handles SQL wildcards, quotes and Unicode lowercase',
    () async {
      await repository.create("50%_ O'Reilly");
      await repository.create('ÉCLAIR');
      expect(
        (await repository.list(const CategoryQuery(search: '%_'))).totalCount,
        1,
      );
      expect(
        (await repository.list(
          const CategoryQuery(search: "' OR 1=1 --"),
        )).totalCount,
        0,
      );
      expect(
        (await repository.list(
          const CategoryQuery(search: 'éclair'),
        )).totalCount,
        1,
      );
    },
  );

  test(
    'no limit returns all; pagination is stable and cap applies across pages',
    () async {
      for (var i = 0; i < 25; i++) {
        await repository.create('Category ${i.toString().padLeft(2, '0')}');
      }
      final all = await repository.list(const CategoryQuery());
      expect(all.items.length, 25);
      final first = await repository.list(
        const CategoryQuery(pageSize: 10, limit: 12),
      );
      final second = await repository.list(
        const CategoryQuery(page: 2, pageSize: 10, limit: 12),
      );
      expect(first.items.length, 10);
      expect(first.hasNext, isTrue);
      expect(second.items.length, 2);
      expect(second.hasNext, isFalse);
      expect(second.metadata, {
        'page': 2,
        'page_size': 10,
        'total_count': 25,
        'limit': 12,
      });
      expect(second.items.first.category.id, all.items[10].category.id);
      expect(
        (await repository.list(const CategoryQuery(limit: 10))).items.length,
        10,
      );
      expect(
        (await repository.list(
          const CategoryQuery(page: 99, pageSize: 10),
        )).items,
        isEmpty,
      );
      expect(
        (await repository.list(
          const CategoryQuery(search: 'absent', pageSize: 10),
        )).totalPages,
        1,
      );
    },
  );

  test(
    'root and direct-child pages do not include unrelated descendants',
    () async {
      final root = await repository.create('Root');
      final child = await repository.create('Child', parentId: root.id);
      await repository.create('Grandchild', parentId: child.id);
      expect(
        (await repository.list(
          const CategoryQuery(rootsOnly: true),
        )).items.single.category.id,
        root.id,
      );
      expect(
        (await repository.list(
          CategoryQuery(parentId: root.id),
        )).items.single.category.id,
        child.id,
      );
    },
  );

  test('invalid paging arguments are rejected', () async {
    for (final query in [
      const CategoryQuery(page: 0),
      const CategoryQuery(pageSize: 0),
      const CategoryQuery(limit: -1),
      const CategoryQuery(page: 2),
    ]) {
      await expectLater(repository.list(query), throwsArgumentError);
    }
  });

  test(
    'categories survive database close and reopen from an actual file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'category_persistence_',
      );
      final path = '${directory.path}/categories.db';
      final first = DatabaseService(
        factory: databaseFactoryFfi,
        databasePath: path,
      );
      final original = CategoryRepository(first);
      final root = await original.create('Persistent root');
      final child = await original.create(
        'Persistent child',
        parentId: root.id,
      );
      await first.close();
      final reopened = DatabaseService(
        factory: databaseFactoryFfi,
        databasePath: path,
      );
      try {
        final result = await CategoryRepository(
          reopened,
        ).list(const CategoryQuery(search: 'child'));
        expect(result.items.single.category.id, child.id);
        expect(result.items.single.parent!.id, root.id);
        expect(result.items.single.category.createdAt, child.createdAt);
      } finally {
        await reopened.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
