import 'package:flutter/material.dart';

typedef CategoryOptions = ({int pageSize, int? limit});

class CategoryOptionsSheet extends StatefulWidget {
  const CategoryOptionsSheet({super.key, required this.initial});
  final CategoryOptions initial;
  @override
  State<CategoryOptionsSheet> createState() => _CategoryOptionsSheetState();
}

class _CategoryOptionsSheetState extends State<CategoryOptionsSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _limit;
  late int _pageSize;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initial.pageSize;
    _limit = TextEditingController(
      text: widget.initial.limit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  void _apply() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, (
        pageSize: _pageSize,
        limit: int.tryParse(_limit.text.trim()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Display Options',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: _pageSize,
                decoration: const InputDecoration(labelText: 'Page size'),
                items: [10, 20, 50]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (value) => setState(() => _pageSize = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limit,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _apply(),
                decoration: const InputDecoration(
                  labelText: 'Limit results (optional)',
                ),
                validator: (value) =>
                    value!.trim().isNotEmpty &&
                        (int.tryParse(value.trim()) ?? 0) <= 0
                    ? 'Enter a positive whole number, or leave empty.'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _apply,
                child: const Text('Apply options'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, (pageSize: 20, limit: null)),
                child: const Text('Reset to defaults'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
