import 'package:flutter/material.dart';

class TajweedSegment {
  const TajweedSegment({
    required this.word,
    required this.rule,
    required this.color,
  });

  final String word;
  final String rule;
  final Color color;
}

class Ayah {
  Ayah({
    required this.number,
    required this.arabic,
    required this.translation,
    required this.tajweed,
    this.isBookmarked = false,
  });

  final int number;
  final String arabic;
  final String translation;
  final List<TajweedSegment> tajweed;
  bool isBookmarked;
}
