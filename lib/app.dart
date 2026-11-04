import 'package:flutter/material.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';
import 'package:category_manager/core/navigation/app_router.dart';

class CategoryManagerApp extends StatelessWidget {
  const CategoryManagerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Category Manager',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const StartupGate(),
  );
}
