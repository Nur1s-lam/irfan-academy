import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: palette.surface,
        elevation: 2,
        shadowColor: palette.ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
