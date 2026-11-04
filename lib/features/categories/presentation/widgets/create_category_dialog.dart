import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/core/widgets/feedback_widgets.dart';
import 'package:category_manager/features/categories/data/models/category.dart';
import 'package:category_manager/features/categories/data/providers/category_providers.dart';

Future<bool?> showCreateCategory(
  BuildContext context,
  WidgetRef ref, {
  Category? parent,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  ref.read(categoryCreationProvider.notifier).reset();
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CreateCategoryDialog(parent: parent),
  );
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        showCloseIcon: true,
        width: MediaQuery.sizeOf(context).width > 520 ? 480 : null,
        content: Text(
          parent == null ? 'Category created.' : 'Subcategory added.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  return saved;
}

class CreateCategoryDialog extends ConsumerStatefulWidget {
  const CreateCategoryDialog({super.key, this.parent});
  final Category? parent;
  @override
  ConsumerState<CreateCategoryDialog> createState() =>
      _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends ConsumerState<CreateCategoryDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final saved = await ref
        .read(categoryCreationProvider.notifier)
        .create(_name.text, parentId: widget.parent?.id);
    if (saved && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryCreationProvider);
    return PopScope(
      canPop: !state.isLoading,
      child: AlertDialog(
        title: Text(widget.parent == null ? 'Add Category' : 'Add Subcategory'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.parent != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Parent: ${widget.parent!.name}',
                        style: const TextStyle(
                          color: Color(0xFF5A7066),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    enabled: !state.isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a name.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!state.isLoading) _save();
                    },
                  ),
                  if (state.hasError) ErrorNotice(error: state.error!),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: state.isLoading ? null : _save,
            child: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
