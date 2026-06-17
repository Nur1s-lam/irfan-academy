import 'package:quran/quran.dart' as quran_lib;

import '../models/ayah.dart';
import '../models/surah.dart';

class QuranDataService {
  static List<SurahInfo> getAllSurahs() {
    return List.generate(114, (index) {
      final number = index + 1;
      return getSurahInfo(number);
    });
  }

  static SurahInfo getSurahInfo(int surahNumber) {
    return SurahInfo(
      number: surahNumber,
      nameArabic: quran_lib.getSurahNameArabic(surahNumber),
      nameTransliteration: quran_lib.getSurahName(surahNumber),
      nameTranslation: quran_lib.getSurahNameRussian(surahNumber),
      versesCount: quran_lib.getVerseCount(surahNumber),
      revelationType: quran_lib.getPlaceOfRevelation(surahNumber) == 'Makkah'
          ? 'Мекканская'
          : 'Мединская',
    );
  }

  static SurahInfo? findSurahByTransliteration(String name) {
    final normalized = name.trim().toLowerCase();
    for (final surah in getAllSurahs()) {
      if (surah.nameTransliteration.toLowerCase() == normalized) {
        return surah;
      }
    }
    return null;
  }

  static List<String> getSurahVerses(int surahNumber) {
    final count = quran_lib.getVerseCount(surahNumber);
    return List.generate(
      count,
      (index) => quran_lib.getVerse(
        surahNumber,
        index + 1,
        verseEndSymbol: true,
      ),
    );
  }

  static List<Ayah> getPlainAyahs(int surahNumber) {
    final verses = getSurahVerses(surahNumber);
    return List.generate(verses.length, (index) {
      final verseNumber = index + 1;
      final translation = getVerseTranslation(surahNumber, verseNumber);
      return Ayah.fromPlainText(verseNumber, verses[index], translation);
    });
  }

  static String getVerseTranslation(int surahNumber, int verseNumber) {
    return quran_lib.getVerseTranslation(
      surahNumber,
      verseNumber,
      translation: quran_lib.Translation.ruKuliev,
    );
  }

  static String getSurahNameArabic(int surahNumber) {
    return quran_lib.getSurahNameArabic(surahNumber);
  }

  static String getSurahNameTransliteration(int surahNumber) {
    return quran_lib.getSurahName(surahNumber);
  }

  static int getVerseCount(int surahNumber) {
    return quran_lib.getVerseCount(surahNumber);
  }
}
