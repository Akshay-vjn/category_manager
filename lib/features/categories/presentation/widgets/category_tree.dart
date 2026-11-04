import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/core/widgets/feedback_widgets.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';
import 'package:category_manager/features/auth/data/providers/auth_providers.dart';
import 'package:category_manager/features/categories/data/models/category.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';
import 'package:category_manager/features/categories/data/providers/category_providers.dart';
import 'package:category_manager/features/categories/presentation/widgets/create_category_dialog.dart';

class CategoryBranch extends ConsumerStatefulWidget {
  const CategoryBranch({
    super.key,
    required this.entry,
    this.depth = 0,
    this.showContext = false,
  });
  final CategoryEntry entry;
  final int depth;
  final bool showContext;
  @override
  ConsumerState<CategoryBranch> createState() => _CategoryBranchState();
}

class _CategoryBranchState extends ConsumerState<CategoryBranch> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.showContext;
  }

  void _details() {
    final entry = widget.entry;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.folder_outlined, color: AppTheme.green),
        title: Text(entry.category.name),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FULL PATH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  entry.breadcrumb,
                  style: const TextStyle(height: 1.6),
                ),
                const Divider(height: 32),
                Text('Parent: ${entry.parent?.name ?? 'None (root)'}'),
                const SizedBox(height: 12),
                Text('Direct children: ${entry.childCount}'),
                const SizedBox(height: 12),
                Text(
                  'Created: ${MaterialLocalizations.of(context).formatMediumDate(entry.category.createdAt.toLocal())}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  CategoryEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: IconButton(
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            onPressed: entry.childCount == 0
                ? null
                : () => setState(() => _expanded = !_expanded),
            icon: Icon(
              entry.childCount == 0
                  ? Icons.folder_outlined
                  : _expanded
                  ? Icons.expand_more_rounded
                  : Icons.chevron_right_rounded,
              color: entry.childCount == 0 ? Colors.grey : AppTheme.green,
            ),
          ),
          title: Text(
            entry.category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: widget.showContext
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.breadcrumb),
                      Text('Parent: ${entry.parent?.name ?? 'None (root)'}'),
                    ],
                  ),
                )
              : null,
          onTap: entry.childCount == 0
              ? _details
              : () => setState(() => _expanded = !_expanded),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Details for ${entry.category.name}',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                onPressed: _details,
              ),
              IconButton(
                tooltip: 'Add subcategory to ${entry.category.name}',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: AppTheme.green,
                ),
                onPressed: () async {
                  final saved = await showCreateCategory(
                    context,
                    ref,
                    parent: entry.category,
                  );
                  if (saved == true && mounted) {
                    setState(() => _expanded = true);
                  }
                },
              ),
            ],
          ),
        ),
        if (_expanded && entry.childCount > 0)
          Container(
            margin: EdgeInsets.only(
              left:
                  widget.depth <
                      (MediaQuery.sizeOf(context).width < 600 ? 2 : 4)
                  ? 16
                  : 0,
            ),
            decoration: widget.depth < 4
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFFDCE5DF), width: 1.5),
                    ),
                  )
                : null,
            child: ChildCategoryList(
              parentId: entry.category.id,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}

class ChildCategoryList extends ConsumerStatefulWidget {
  const ChildCategoryList({
    super.key,
    required this.parentId,
    required this.depth,
  });
  final int parentId, depth;
  @override
  ConsumerState<ChildCategoryList> createState() => _ChildCategoryListState();
}

class _ChildCategoryListState extends ConsumerState<ChildCategoryList> {
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final activeUserId = ref.watch(currentUserIdProvider);
    final query = CategoryQuery(
      userId: activeUserId,
      parentId: widget.parentId,
      page: _page,
      pageSize: 20,
    );
    return ref
        .watch(categoryPageProvider(query))
        .when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => ErrorNotice(
            error: e,
            onRetry: () => ref.invalidate(categoryPageProvider(query)),
          ),
          data: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in result.items)
                CategoryBranch(
                  key: ValueKey(entry.category.id),
                  entry: entry,
                  depth: widget.depth,
                ),
              if (result.totalPages > 1)
                PageControls(
                  result: result,
                  onChanged: (page) => setState(() => _page = page),
                ),
            ],
          ),
        );
  }
}

class PageControls extends StatelessWidget {
  const PageControls({
    super.key,
    required this.result,
    required this.onChanged,
  });

  final CategoryPage<CategoryEntry> result;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          IconButton.outlined(
            tooltip: 'Previous page',
            onPressed: result.page > 1
                ? () => onChanged(result.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page ${result.page} of ${result.totalPages}'),
          IconButton.outlined(
            tooltip: 'Next page',
            onPressed: result.hasNext ? () => onChanged(result.page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text(
            '${result.pageSize ?? result.availableCount} per page · ${result.totalCount} total',
          ),
        ],
      ),
    ),
  );
}
