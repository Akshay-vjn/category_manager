import 'dart:math' as math;

class CategoryQuery {
  const CategoryQuery({
    this.userId,
    this.search = '',
    this.parentId,
    this.rootsOnly = false,
    this.page = 1,
    this.pageSize,
    this.limit,
  });
  final int? userId;
  final String search;
  final int? parentId;
  final bool rootsOnly;
  final int page;
  final int? pageSize, limit;

  void validate() {
    if (page < 1 ||
        (pageSize != null && pageSize! < 1) ||
        (limit != null && limit! < 1) ||
        (pageSize == null && page != 1)) {
      throw ArgumentError(
        'Page, page size and limit must be positive; paging needs a page size.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryQuery &&
      userId == other.userId &&
      search == other.search &&
      parentId == other.parentId &&
      rootsOnly == other.rootsOnly &&
      page == other.page &&
      pageSize == other.pageSize &&
      limit == other.limit;
  @override
  int get hashCode =>
      Object.hash(userId, search, parentId, rootsOnly, page, pageSize, limit);
}

class CategoryPage<T> {
  CategoryPage({
    required List<T> items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.limit,
  }) : items = List.unmodifiable(items);
  final List<T> items;
  final int page;
  final int? pageSize, limit;

  final int totalCount;
  int get availableCount =>
      limit == null ? totalCount : math.min(totalCount, limit!);
  int get totalPages =>
      pageSize == null ? 1 : math.max(1, (availableCount / pageSize!).ceil());
  bool get hasNext => page < totalPages;
  Map<String, Object?> get metadata => {
    'page': page,
    'page_size': pageSize,
    'total_count': totalCount,
    'limit': limit,
  };
}
