import 'package:flutter/material.dart';
import 'package:category_manager/core/app_theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64, this.inverse = false});
  final double size;
  final bool inverse;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverse ? const Color(0xFFDAEFDA) : AppTheme.mint,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Icon(
        Icons.account_tree_rounded,
        size: size * .52,
        color: AppTheme.forest,
      ),
    ),
  );
}
