import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TagWidget extends StatelessWidget {
  const TagWidget({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final background = backgroundColor ?? palette.primarySoft;
    final foreground = foregroundColor ?? AppTheme.inkOnLight;

    return AnimatedContainer(
      duration: AppTheme.motionFast,
      curve: AppTheme.motionCurve,
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 5)],
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
