import 'package:flutter/material.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Icon(icon, size: 20, color: AppTheme.green),
    title: Text(label, style: Theme.of(context).textTheme.bodySmall),
    subtitle: SelectableText(
      value,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    ),
  );
}
