import 'package:flutter/material.dart';

import '../models/ayah.dart';
import '../theme/app_theme.dart';

class TajweedText extends StatelessWidget {
  const TajweedText({super.key, required this.arabic, required this.segments});

  final String arabic;
  final List<TajweedSegment> segments;

  @override
  Widget build(BuildContext context) {
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
                  fontSize: 26,
                  height: 2.2,
                  color: _colorFor(words[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String word) {
    for (final segment in segments) {
      if (segment.word == word) {
        return segment.color;
      }
    }
    return AppTheme.ink;
  }
}
