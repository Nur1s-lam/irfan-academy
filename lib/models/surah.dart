class SurahInfo {
  const SurahInfo({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameTranslation,
    required this.versesCount,
    required this.revelationType,
  });

  final int number;
  final String nameArabic;
  final String nameTransliteration;
  final String nameTranslation;
  final int versesCount;
  final String revelationType;
}
