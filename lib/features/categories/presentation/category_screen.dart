import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/features/auth/data/providers/auth_providers.dart';
import 'package:category_manager/core/widgets/feedback_widgets.dart';
import 'package:category_manager/features/categories/data/models/category_query.dart';
import 'package:category_manager/features/categories/data/providers/category_providers.dart';
import 'package:category_manager/features/categories/presentation/widgets/category_tree.dart';
import 'package:category_manager/features/categories/presentation/widgets/create_category_dialog.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  String _search = '';
  int _page = 1;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _search = value.trim();
          _page = 1;
        });
      }
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _search = '';
      _page = 1;
    });
  }

  void _changePage(int page) {
    setState(() => _page = page);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final activeUserId = ref.watch(currentUserIdProvider);
    final query = CategoryQuery(
      userId: activeUserId,
      search: _search,
      rootsOnly: _search.isEmpty,
      page: _page,
      pageSize: 20,
    );
    final results = ref.watch(categoryPageProvider(query));
    return CustomScrollView(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _searchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search categories',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => showCreateCategory(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add category'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ...results.when(
          loading: () => <Widget>[
            const SliverToBoxAdapter(child: LoadingIndicator()),
          ],
          error: (error, _) => <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorNotice(
                  error: error,
                  onRetry: () => ref.invalidate(categoryPageProvider(query)),
                ),
              ),
            ),
          ],
          data: (result) => <Widget>[
            if (result.items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: EmptyNotice(
                      title: _search.isEmpty
                          ? 'Start your category tree'
                          : 'No matches found',
                      message: _search.isEmpty
                          ? 'Add a category to get started.'
                          : 'No categories match your search.',
                      actionLabel: _search.isEmpty ? null : 'Clear search',
                      onAction: _search.isEmpty ? null : _clearSearch,
                    ),
                  ),
                ),
              ),
            if (result.items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final entry = result.items[index];
                    return Padding(
                      key: ValueKey('${_search}_${entry.category.id}'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: CategoryBranch(
                          entry: entry,
                          showContext: _search.isNotEmpty,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (result.totalPages > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PageControls(result: result, onChanged: _changePage),
                ),
              ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
