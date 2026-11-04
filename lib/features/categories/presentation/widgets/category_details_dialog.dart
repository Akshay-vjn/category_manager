import 'package:flutter/material.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';
import 'package:category_manager/features/categories/data/models/category.dart';

class CategoryDetailsDialog extends StatelessWidget {
  const CategoryDetailsDialog({super.key, required this.entry});

  final CategoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final count = entry.childCount;
    final childDescription = count == 0
        ? 'No subcategories yet'
        : '$count direct ${count == 1 ? 'subcategory' : 'subcategories'}';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_rounded, color: AppTheme.green),
          const SizedBox(width: 12),
          Expanded(child: Text(entry.category.name)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location in your categories',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: AppTheme.forest),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(entry.breadcrumb),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.account_tree_outlined,
                label: 'Parent category',
                value: entry.parent?.name ?? 'Top-level category',
              ),
              _DetailRow(
                icon: Icons.folder_copy_outlined,
                label: 'Subcategories',
                value: childDescription,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: MaterialLocalizations.of(
                  context,
                ).formatMediumDate(entry.category.createdAt.toLocal()),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    ),
  );
}
