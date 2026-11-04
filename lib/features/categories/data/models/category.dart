class Category {
  const Category({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
  });
  final int id;
  final String name;
  final int? parentId;
  final DateTime createdAt;

  factory Category.fromMap(Map<String, Object?> row) => Category(
    id: row['id'] as int,
    name: row['name'] as String,
    parentId: row['parent_id'] as int?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

class CategoryEntry {
  CategoryEntry({
    required this.category,
    required List<Category> path,
    required this.childCount,
  }) : path = List.unmodifiable(path);
  final Category category;

  final List<Category> path;
  final int childCount;
  Category? get parent => path.length > 1 ? path[path.length - 2] : null;
  String get breadcrumb => path.map((c) => c.name).join(' › ');
}
