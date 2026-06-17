import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/ayah.dart';
import '../../models/surah.dart';
import '../../services/firestore_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/quran_player.dart';
import '../../widgets/tajweed_text.dart';
import 'quran_menu_sheet.dart';
import 'quran_search_sheet.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<GlobalKey> _ayahKeys;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  late List<Ayah> _ayahs;
  final List<SurahInfo> _surahs = QuranDataService.getAllSurahs();
  int _currentSurahNumber = 1;
  int _activeAyahIndex = 0;
  bool _isPlaying = false;
  bool _repeat = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _speedIndex = 0;
  double _arabicFontSize = 26;
  bool _showTranslation = true;
  bool _showTajweed = true;
  String _reciter = QuranAudioService.reciter;
  int? _loadedSurahNumber;
  int? _loadedAyahNumber;
  bool _handlingCompletion = false;

  static const _speeds = [1.0, 1.25, 1.5, 0.75];
  SurahInfo get _currentSurah => _surahs[_currentSurahNumber - 1];

  String get _currentSurahName => _currentSurah.nameTransliteration;

  FirestoreService get _firestoreService {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirestoreService(uid);
  }

  static final List<Ayah> _fatihaAyahs = [
    Ayah(
      number: 1,
      arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'Во имя Аллаха, Милостивого, Милосердного.',
      tajweed: const [
        TajweedSegment(
          word: 'الرَّحْمَٰنِ',
          rule: 'gunna',
          color: AppTheme.tajweedGunna,
        ),
        TajweedSegment(
          word: 'الرَّحِيمِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
      ],
    ),
    Ayah(
      number: 2,
      arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      translation: 'Хвала Аллаху, Господу миров,',
      tajweed: const [
        TajweedSegment(
          word: 'الْعَالَمِينَ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'رَبِّ',
          rule: 'gunna',
          color: AppTheme.tajweedGunna,
        ),
      ],
    ),
    Ayah(
      number: 3,
      arabic: 'الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'Милостивому, Милосердному,',
      tajweed: const [
        TajweedSegment(
          word: 'الرَّحْمَٰنِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'الرَّحِيمِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
      ],
    ),
    Ayah(
      number: 4,
      arabic: 'مَالِكِ يَوْمِ الدِّينِ',
      translation: 'Властелину Дня воздаяния!',
      tajweed: const [
        TajweedSegment(
          word: 'مَالِكِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'الدِّينِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
      ],
    ),
    Ayah(
      number: 5,
      arabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      translation: 'Тебе одному мы поклоняемся и Тебя одного молим о помощи.',
      tajweed: const [
        TajweedSegment(
          word: 'إِيَّاكَ',
          rule: 'idgham',
          color: AppTheme.tajweedIdgham,
        ),
        TajweedSegment(
          word: 'نَعْبُدُ',
          rule: 'qalqala',
          color: AppTheme.tajweedQalqala,
        ),
        TajweedSegment(
          word: 'نَسْتَعِينُ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
      ],
    ),
    Ayah(
      number: 6,
      arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      translation: 'Веди нас прямым путём,',
      tajweed: const [
        TajweedSegment(
          word: 'الصِّرَاطَ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'الْمُسْتَقِيمَ',
          rule: 'qalqala',
          color: AppTheme.tajweedQalqala,
        ),
      ],
    ),
    Ayah(
      number: 7,
      arabic:
          'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      translation:
          'Путём тех, кого Ты облагодетельствовал, не тех, на кого пал гнев, и не заблудших.',
      tajweed: const [
        TajweedSegment(
          word: 'الَّذِينَ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'أَنْعَمْتَ',
          rule: 'gunna',
          color: AppTheme.tajweedGunna,
        ),
        TajweedSegment(
          word: 'الْمَغْضُوبِ',
          rule: 'madd',
          color: AppTheme.tajweedMadd,
        ),
        TajweedSegment(
          word: 'الضَّالِّينَ',
          rule: 'qalqala',
          color: AppTheme.tajweedQalqala,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ayahs = _loadAyahsForSurah(_currentSurahNumber);
    _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration ?? Duration.zero);
      }
    });
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }

      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _handleAudioCompleted();
      }
    });
  }

  List<Ayah> _loadAyahsForSurah(int surahNumber) {
    if (surahNumber == 1) {
      return List<Ayah>.of(_fatihaAyahs);
    }

    return QuranDataService.getPlainAyahs(surahNumber);
  }

  void _selectSurah(SurahInfo surah) {
    _audioPlayer.stop();
    _clearLoadedAudio();
    setState(() {
      _currentSurahNumber = surah.number;
      _ayahs = _loadAyahsForSurah(surah.number);
      _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
      _activeAyahIndex = 0;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });

    _saveQuranProgress(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 180),
          curve: AppTheme.motionCurve,
        );
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectAyah(int index) {
    _audioPlayer.stop();
    _clearLoadedAudio();
    setState(() {
      _activeAyahIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });
    _saveQuranProgress(index);
    _scrollToAyah(index);
  }

  void _scrollToAyah(int index) {
    final context = _ayahKeys[index].currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 180),
      curve: AppTheme.motionCurve,
      alignment: 0.18,
    );
  }

  Future<void> _goNext({bool autoPlay = false}) async {
    final wasPlaying = _audioPlayer.playing || autoPlay;
    final nextIndex = (_activeAyahIndex + 1).clamp(0, _ayahs.length - 1);
    if (nextIndex == _activeAyahIndex && autoPlay) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() {
      _activeAyahIndex = nextIndex;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = wasPlaying;
    });
    _clearLoadedAudio();
    _saveQuranProgress(_activeAyahIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(_activeAyahIndex);
    });
    if (wasPlaying) {
      await _playAyahAt(nextIndex);
    } else {
      await _audioPlayer.stop();
    }
  }

  Future<void> _goPrev() async {
    final wasPlaying = _audioPlayer.playing;
    await _audioPlayer.stop();
    _clearLoadedAudio();
    setState(() {
      _activeAyahIndex = (_activeAyahIndex - 1).clamp(0, _ayahs.length - 1);
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = wasPlaying;
    });
    _saveQuranProgress(_activeAyahIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(_activeAyahIndex);
    });
    if (wasPlaying) {
      await _playAyahAt(_activeAyahIndex);
    }
  }

  Future<void> _playCurrentAyah() async {
    await _playAyahAt(_activeAyahIndex);
  }

  Future<void> _playAyahAt(int index) async {
    final ayahNumber = _ayahs[index].number;
    final surahNumber = _currentSurahNumber;
    final url = QuranAudioService.getAyahAudioUrl(surahNumber, ayahNumber);

    try {
      await _audioPlayer.stop();
      _clearLoadedAudio();
      await _audioPlayer.setUrl(url);
      _loadedSurahNumber = surahNumber;
      _loadedAyahNumber = ayahNumber;
      await _audioPlayer.setSpeed(_speeds[_speedIndex]);
      await _audioPlayer.play();
    } catch (error, stackTrace) {
      // On web, everyayah.com can fail if the browser blocks remote audio/CORS.
      debugPrint('Quran audio error for $url: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось загрузить аудио. Попробуйте позже.'),
        ),
      );
    }
  }

  void _clearLoadedAudio() {
    _loadedSurahNumber = null;
    _loadedAyahNumber = null;
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    final activeAyah = _ayahs[_activeAyahIndex].number;
    final needsNewSource =
        _loadedSurahNumber != _currentSurahNumber ||
        _loadedAyahNumber != activeAyah ||
        _audioPlayer.processingState == ProcessingState.idle ||
        _audioPlayer.processingState == ProcessingState.completed;

    if (needsNewSource) {
      await _playCurrentAyah();
      return;
    }

    await _audioPlayer.play();
  }

  Future<void> _seekAudio(double value) async {
    if (_duration == Duration.zero) {
      return;
    }

    final target = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    await _audioPlayer.seek(target);
  }

  Future<void> _changeSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    await _audioPlayer.setSpeed(_speeds[_speedIndex]);
  }

  Future<void> _handleAudioCompleted() async {
    if (_handlingCompletion) {
      return;
    }

    _handlingCompletion = true;
    try {
      if (_repeat) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
        return;
      }

      await _goNext(autoPlay: true);
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> _selectSurahAndAyah(int surahNumber, int ayahNumber) async {
    final surah = _surahs[surahNumber - 1];
    await _audioPlayer.stop();
    _clearLoadedAudio();
    setState(() {
      _currentSurahNumber = surah.number;
      _ayahs = _loadAyahsForSurah(surah.number);
      _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
      _activeAyahIndex = (ayahNumber - 1).clamp(0, _ayahs.length - 1);
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
    });
    _saveQuranProgress(_activeAyahIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(_activeAyahIndex);
    });
  }

  Future<void> _toggleBookmark(int number, Set<int> bookmarks) async {
    if (bookmarks.contains(number)) {
      await _firestoreService.removeBookmarkFromSurah(number, _currentSurahName);
    } else {
      await _firestoreService.addBookmark(number, _currentSurahName);
    }
  }

  void _saveQuranProgress(int index) {
    final ayahNumber = _ayahs[index].number;
    final progress = ayahNumber / _ayahs.length;
    _firestoreService.updateQuranProgress(
      progress,
      _currentSurahName,
      ayahNumber,
    );
  }

  void _showSurahSheet() {
    final palette = AppTheme.palette(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: palette.ink.withValues(alpha: 0.42),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _SurahPickerSheet(
          surahs: _surahs,
          currentSurahNumber: _currentSurahNumber,
          onSelected: (surah) {
            Navigator.of(context).pop();
            _selectSurah(surah);
          },
        );
      },
    );
  }

  void _showSearchSheet() {
    final palette = AppTheme.palette(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: palette.ink.withValues(alpha: 0.42),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return QuranSearchSheet(
          surahs: _surahs,
          onSelected: (result) {
            Navigator.of(context).pop();
            _selectSurahAndAyah(result.surah.number, result.ayahNumber);
          },
        );
      },
    );
  }

  void _showMenuSheet() {
    final palette = AppTheme.palette(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      barrierColor: palette.ink.withValues(alpha: 0.42),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return QuranMenuSheet(
          bookmarksStream: _firestoreService.getQuranBookmarks(),
          settings: QuranReadingSettings(
            arabicFontSize: _arabicFontSize,
            showTranslation: _showTranslation,
            showTajweed: _showTajweed,
            reciter: _reciter,
          ),
          onSettingsChanged: (settings) async {
            final reciterChanged = settings.reciter != _reciter;
            final wasPlaying = _audioPlayer.playing;
            if (reciterChanged) {
              await _audioPlayer.stop();
              _clearLoadedAudio();
              QuranAudioService.reciter = settings.reciter;
            }

            setState(() {
              _arabicFontSize = settings.arabicFontSize;
              _showTranslation = settings.showTranslation;
              _showTajweed = settings.showTajweed;
              _reciter = settings.reciter;
            });

            if (reciterChanged && wasPlaying) {
              await _playCurrentAyah();
            }
          },
          onBookmarkSelected: (selection) {
            Navigator.of(context).pop();
            _selectSurahAndAyah(selection.surahNumber, selection.ayahNumber);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return StreamBuilder<Set<int>>(
      stream: _firestoreService.getBookmarksForSurah(_currentSurahName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: palette.primary),
          );
        }

        final bookmarks = snapshot.data ?? {};

        return Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 174),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuranHeader(
                    surah: _currentSurah,
                    onSurahTap: _showSurahSheet,
                    onSearch: _showSearchSheet,
                    onList: _showMenuSheet,
                  ),
                  const SizedBox(height: 20),
                  _SurahHero(surah: _currentSurah),
                  const SizedBox(height: 16),
                  if (_currentSurahNumber == 1) ...[
                    const _TajweedLegend(),
                    const SizedBox(height: 18),
                  ],
                  if (_currentSurahNumber != 9) ...[
                    const _BismillahOrnament(),
                    const SizedBox(height: 16),
                  ],
                  for (var index = 0; index < _ayahs.length; index++) ...[
                    _AyahCard(
                      key: _ayahKeys[index],
                      ayah: _ayahs[index],
                      active: _activeAyahIndex == index,
                      bookmarked: bookmarks.contains(_ayahs[index].number),
                      arabicFontSize: _arabicFontSize,
                      showTranslation: _showTranslation,
                      showTajweed: _showTajweed,
                      onTap: () => _selectAyah(index),
                      onBookmark: () {
                        _toggleBookmark(_ayahs[index].number, bookmarks);
                      },
                    ),
                    if (index != _ayahs.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QuranPlayer(
                activeAyah: _activeAyahIndex + 1,
                totalAyahs: _ayahs.length,
                position: _position,
                duration: _duration,
                isPlaying: _isPlaying,
                repeat: _repeat,
                speed: _speeds[_speedIndex],
                onNext: _goNext,
                onPrev: _goPrev,
                onPlayPause: _togglePlayPause,
                onRepeat: () => setState(() => _repeat = !_repeat),
                onSpeed: _changeSpeed,
                onSeek: _seekAudio,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SurahPickerSheet extends StatefulWidget {
  const _SurahPickerSheet({
    required this.surahs,
    required this.currentSurahNumber,
    required this.onSelected,
  });

  final List<SurahInfo> surahs;
  final int currentSurahNumber;
  final ValueChanged<SurahInfo> onSelected;

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final filtered = widget.surahs.where((surah) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }

      return surah.number.toString().contains(query) ||
          surah.nameArabic.contains(query) ||
          surah.nameTransliteration.toLowerCase().contains(query) ||
          surah.nameTranslation.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Выбор суры',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: palette.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Поиск суры',
                  prefixIcon: Icon(Icons.search_rounded, color: palette.inkSoft),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final selected =
                        surah.number == widget.currentSurahNumber;

                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onTap: () => widget.onSelected(surah),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? palette.primary
                                  : palette.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${surah.number}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: selected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : AppTheme.inkOnLight,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        surah.nameTransliteration,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        surah.nameArabic,
                                        style: AppTheme.arabicText(
                                          fontSize: 20,
                                          color: palette.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${surah.nameTranslation} · ${surah.versesCount} аятов · ${surah.revelationType}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: palette.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle_rounded,
                              color: palette.primaryDeep,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuranHeader extends StatelessWidget {
  const _QuranHeader({
    required this.surah,
    required this.onSurahTap,
    required this.onSearch,
    required this.onList,
  });

  final SurahInfo surah;
  final VoidCallback onSurahTap;
  final VoidCallback onSearch;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Row(
      children: [
        Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onSurahTap,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 210),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Text(
                  '${surah.nameTransliteration} ▾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSearch,
          icon: Icon(Icons.search_rounded, color: palette.ink),
        ),
        IconButton(
          onPressed: onList,
          icon: const Icon(Icons.format_list_bulleted_rounded),
          color: palette.ink,
        ),
      ],
    );
  }
}

class _SurahHero extends StatelessWidget {
  const _SurahHero({required this.surah});

  final SurahInfo surah;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      height: 172,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.primary, palette.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: palette.primaryDeep.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeroPatternPainter(color: onPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        surah.nameArabic,
                        style: AppTheme.arabicText(
                          fontSize: 36,
                          color: onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${surah.nameTransliteration} · ${surah.nameTranslation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${surah.versesCount} АЯТОВ · ${surah.revelationType.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TajweedLegend extends StatelessWidget {
  const _TajweedLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    const items = [
      _LegendItem('Мадд', AppTheme.tajweedMadd),
      _LegendItem('Калькаля', AppTheme.tajweedQalqala),
      _LegendItem('Гунна', AppTheme.tajweedGunna),
      _LegendItem('Идгам', AppTheme.tajweedIdgham),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: items[index].color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  items[index].label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BismillahOrnament extends StatelessWidget {
  const _BismillahOrnament();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Row(
      children: [
        Expanded(child: Divider(color: palette.primary)),
        const SizedBox(width: 12),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          style: AppTheme.arabicText(fontSize: 20, color: palette.primaryDeep),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: palette.primary)),
      ],
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({
    super.key,
    required this.ayah,
    required this.active,
    required this.bookmarked,
    required this.arabicFontSize,
    required this.showTranslation,
    required this.showTajweed,
    required this.onTap,
    required this.onBookmark,
  });

  final Ayah ayah;
  final bool active;
  final bool bookmarked;
  final double arabicFontSize;
  final bool showTranslation;
  final bool showTajweed;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final activeForeground = active ? AppTheme.inkOnLight : palette.ink;
    final activeSoftForeground = active ? AppTheme.inkOnLight : palette.inkSoft;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? palette.primarySoft : palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppTheme.motion,
                curve: AppTheme.motionCurve,
                width: 3,
                decoration: BoxDecoration(
                  color: active
                      ? palette.primary
                      : palette.surface.withValues(alpha: 0),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${ayah.number}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: onBookmark,
                            icon: Icon(
                              bookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: bookmarked
                                  ? palette.primaryDeep
                                  : palette.inkFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TajweedText(
                        arabic: ayah.arabic,
                        segments: showTajweed ? ayah.tajweed : const [],
                        defaultColor: activeForeground,
                        fontSize: arabicFontSize,
                      ),
                      if (showTranslation && ayah.translation.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          ayah.translation,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: activeSoftForeground,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  const _HeroPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const step = 38.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final center = Offset(x + step / 2, y + step / 2);
        final rect = Rect.fromCenter(center: center, width: 20, height: 20);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.translate(-center.dx, -center.dy);
        canvas.drawRect(rect, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _LegendItem {
  const _LegendItem(this.label, this.color);

  final String label;
  final Color color;
}
