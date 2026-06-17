class QuranAudioService {
  static const String baseUrl = 'https://everyayah.com/data';

  static String reciter = 'Abdul_Basit_Murattal_192kbps';

  static const Map<String, String> reciters = {
    'Abdul_Basit_Murattal_192kbps': 'Абдул Басит',
    'Alafasy_128kbps': 'Мишари Рашид',
    'Husary_128kbps': 'Махмуд Хусари',
  };

  static String getAyahAudioUrl(int surahNumber, int ayahNumber) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return '$baseUrl/$reciter/$surah$ayah.mp3';
  }
}
