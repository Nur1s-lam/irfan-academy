import 'package:flutter/material.dart';

import '../models/ayah.dart';
import '../theme/app_theme.dart';

class TajweedText extends StatelessWidget {
  const TajweedText({
    super.key,
    required this.arabic,
    required this.segments,
    this.defaultColor,
    this.fontSize = 26,
  });

  final String arabic;
  final List<TajweedSegment> segments;
  final Color? defaultColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final words = arabic.split(' ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            for (var index = 0; index < words.length; index++)
              TextSpan(
                text: '${words[index]}${index == words.length - 1 ? '' : ' '}',
                style: AppTheme.arabicText(
                  fontSize: fontSize,
                  height: 2.2,
                  color: _colorFor(words[index], palette),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String word, AppPalette palette) {
    for (final segment in segments) {
      if (segment.word == word) {
        return segment.color;
      }
    }
    return defaultColor ?? palette.ink;
  }
}
