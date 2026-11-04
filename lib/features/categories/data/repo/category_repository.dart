import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:category_manager/core/database/database_service.dart';
import 'package:category_manager/core/errors/app_exception.dart';
import 'package:category_manager/features/categories/data/models/category.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';

class CategoryRepository {
  CategoryRepository(this._database);
  final DatabaseService _database;

  Future<Category> create(String name, {int? parentId, int? userId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const AppException('Enter a category name.');
    final db = await _database.database;
    try {
      return await db.transaction((txn) async {
        if (parentId != null &&
            (await txn.query(
              'categories',
              where: userId == null
                  ? 'id = ?'
                  : 'id = ? AND (user_id = ? OR user_id IS NULL)',
              whereArgs: userId == null ? [parentId] : [parentId, userId],
              limit: 1,
            )).isEmpty) {
          throw const AppException('The parent category no longer exists.');
        }
        final createdAt = DateTime.now().toUtc();
        final id = await txn.insert('categories', {
          'name': trimmed,
          'name_key': trimmed.toLowerCase(),
          'parent_id': parentId,
          'user_id': userId,
          'created_at': createdAt.toIso8601String(),
        });
        return Category(
          id: id,
          name: trimmed,
          parentId: parentId,
          createdAt: createdAt,
        );
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw const AppException(
          'A category with this name already exists under this parent.',
        );
      }
      rethrow;
    }
  }

  Future<CategoryPage<CategoryEntry>> list(CategoryQuery query) async {
    query.validate();
    final db = await _database.database;
    return db.transaction((txn) async {
      final conditions = <String>[];
      final args = <Object?>[];

      if (query.userId != null) {
        conditions.add('(c.user_id = ? OR c.user_id IS NULL)');
        args.add(query.userId);
      }

      if (query.parentId != null) {
        conditions.add('c.parent_id = ?');
        args.add(query.parentId);
      } else if (query.rootsOnly) {
        conditions.add('c.parent_id IS NULL');
      }
      if (query.search.trim().isNotEmpty) {
        conditions.add('instr(c.name_key, ?) > 0');
        args.add(query.search.trim().toLowerCase());
      }
      final where = conditions.isEmpty
          ? ''
          : 'WHERE ${conditions.join(' AND ')}';
      final count = Sqflite.firstIntValue(
        await txn.rawQuery('SELECT COUNT(*) FROM categories c $where', args),
      )!;
      final available = query.limit == null
          ? count
          : math.min(count, query.limit!);
      final offset = query.pageSize == null
          ? 0
          : (query.page - 1) * query.pageSize!;
      final take = math.max(
        0,
        math.min(query.pageSize ?? available, available - offset),
      );
      final rows = await txn.rawQuery(
        '''SELECT c.*,
        (SELECT COUNT(*) FROM categories child
         WHERE child.parent_id = c.id
         AND (? IS NULL OR child.user_id = ? OR child.user_id IS NULL)) AS child_count
        FROM categories c $where ORDER BY c.name_key, c.id LIMIT ? OFFSET ?''',
        [query.userId, query.userId, ...args, take, offset],
      );
      final entries = <CategoryEntry>[];
      for (final row in rows) {
        final category = Category.fromMap(row);
        final ancestors = await txn.rawQuery(
          '''WITH RECURSIVE ancestors AS (
          SELECT *, 0 AS distance FROM categories WHERE id = ?
          UNION ALL
          SELECT c.*, a.distance + 1 FROM categories c
          JOIN ancestors a ON c.id = a.parent_id
        ) SELECT * FROM ancestors ORDER BY distance DESC''',
          [category.id],
        );
        entries.add(
          CategoryEntry(
            category: category,
            path: ancestors.map(Category.fromMap).toList(),
            childCount: row['child_count'] as int,
          ),
        );
      }
      return CategoryPage(
        items: entries,
        page: query.page,
        pageSize: query.pageSize,
        totalCount: count,
        limit: query.limit,
      );
    });
  }
}
