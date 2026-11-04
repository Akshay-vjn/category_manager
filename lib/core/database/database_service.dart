import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService({DatabaseFactory? factory, this.databasePath})
    : _factory = factory ?? databaseFactory;
  final DatabaseFactory _factory;
  final String? databasePath;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open().catchError((Object e) {
    _opening = null;
    throw e;
  });

  Future<Database> _open() async {
    final path =
        databasePath ??
        p.join(await _factory.getDatabasesPath(), 'categories.db');
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          name TEXT NOT NULL CHECK(length(trim(name)) > 0),
          name_key TEXT NOT NULL,
          parent_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT,
          created_at TEXT NOT NULL
        )''');
          // Sibling uniqueness per parent per user:
          await db.execute(
            'CREATE UNIQUE INDEX category_sibling_name ON categories(COALESCE(user_id, 0), COALESCE(parent_id, 0), name_key)',
          );
          await db.execute(
            'CREATE INDEX category_parent ON categories(user_id, parent_id, name_key, id)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE categories ADD COLUMN user_id INTEGER',
            );
            await db.execute('DROP INDEX IF EXISTS category_sibling_name');
            await db.execute('DROP INDEX IF EXISTS category_parent');
            await db.execute(
              'CREATE UNIQUE INDEX category_sibling_name ON categories(COALESCE(user_id, 0), COALESCE(parent_id, 0), name_key)',
            );
            await db.execute(
              'CREATE INDEX category_parent ON categories(user_id, parent_id, name_key, id)',
            );
          }
        },
      ),
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await (await opening).close();
    _opening = null;
  }
}
