import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/ayah.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/quran_player.dart';
import '../../widgets/tajweed_text.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final ScrollController _scrollController = ScrollController();
  late final List<GlobalKey> _ayahKeys;
  Timer? _timer;

  int _activeAyahIndex = 0;
  bool _isPlaying = false;
  bool _repeat = false;
  double _currentProgress = 0;
  int _speedIndex = 0;

  static const _speeds = [1.0, 1.25, 1.5, 0.75];
  static const _surahName = 'Аль-Фатиха';

  FirestoreService get _firestoreService {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirestoreService(uid);
  }

  late final List<Ayah> _ayahs = [
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
    _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_isPlaying) {
        return;
      }
      setState(() {
        _currentProgress += 0.02 * _speeds[_speedIndex];
        if (_currentProgress >= 1) {
          if (_repeat) {
            _currentProgress = 0;
          } else {
            _goNext(autoPlay: true);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _selectAyah(int index) {
    setState(() {
      _activeAyahIndex = index;
      _currentProgress = 0;
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

  void _goNext({bool autoPlay = false}) {
    final nextIndex = (_activeAyahIndex + 1).clamp(0, _ayahs.length - 1);
    if (nextIndex == _activeAyahIndex && autoPlay) {
      _isPlaying = false;
      _currentProgress = 1;
      return;
    }
    _activeAyahIndex = nextIndex;
    _currentProgress = 0;
    _isPlaying = autoPlay ? _isPlaying : false;
    _saveQuranProgress(_activeAyahIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(_activeAyahIndex);
    });
  }

  void _goPrev() {
    setState(() {
      _activeAyahIndex = (_activeAyahIndex - 1).clamp(0, _ayahs.length - 1);
      _currentProgress = 0;
      _isPlaying = false;
    });
    _saveQuranProgress(_activeAyahIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(_activeAyahIndex);
    });
  }

  Future<void> _toggleBookmark(int number, Set<int> bookmarks) async {
    if (bookmarks.contains(number)) {
      await _firestoreService.removeBookmark(number);
    } else {
      await _firestoreService.addBookmark(number, _surahName);
    }
  }

  void _saveQuranProgress(int index) {
    final ayahNumber = _ayahs[index].number;
    final progress = ayahNumber / _ayahs.length;
    _firestoreService.updateQuranProgress(progress, _surahName, ayahNumber);
  }

  void _showSurahSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      barrierColor: AppTheme.ink.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выбор суры',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                ListTile(
                  minTileHeight: 52,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Аль-Фатиха'),
                  subtitle: const Text('7 аятов · мекканская'),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.goldDeep,
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<int>>(
      stream: _firestoreService.getBookmarks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
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
                    onSurahTap: _showSurahSheet,
                    onSearch: () {},
                    onList: () {},
                  ),
                  const SizedBox(height: 20),
                  const _SurahHero(),
                  const SizedBox(height: 16),
                  const _TajweedLegend(),
                  const SizedBox(height: 18),
                  const _BismillahOrnament(),
                  const SizedBox(height: 16),
                  for (var index = 0; index < _ayahs.length; index++) ...[
                    _AyahCard(
                      key: _ayahKeys[index],
                      ayah: _ayahs[index],
                      active: _activeAyahIndex == index,
                      bookmarked: bookmarks.contains(_ayahs[index].number),
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
                progress: _currentProgress,
                isPlaying: _isPlaying,
                repeat: _repeat,
                speed: _speeds[_speedIndex],
                onNext: () => setState(_goNext),
                onPrev: _goPrev,
                onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                onRepeat: () => setState(() => _repeat = !_repeat),
                onSpeed: () {
                  setState(
                    () => _speedIndex = (_speedIndex + 1) % _speeds.length,
                  );
                },
                onSeek: (value) => setState(() => _currentProgress = value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuranHeader extends StatelessWidget {
  const _QuranHeader({
    required this.onSurahTap,
    required this.onSearch,
    required this.onList,
  });

  final VoidCallback onSurahTap;
  final VoidCallback onSearch;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onSurahTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Text(
                'Аль-Фатиха ▾',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded, color: AppTheme.ink),
        ),
        IconButton(
          onPressed: onList,
          icon: const Icon(Icons.format_list_bulleted_rounded),
          color: AppTheme.ink,
        ),
      ],
    );
  }
}

class _SurahHero extends StatelessWidget {
  const _SurahHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.gold, AppTheme.goldDeep],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldDeep.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _HeroPatternPainter())),
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
                        'الفاتحة',
                        style: AppTheme.arabicText(
                          fontSize: 36,
                          color: AppTheme.surface,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Аль-Фатиха · Открывающая',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '7 АЯТОВ · МЕККАНСКАЯ',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.surface,
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
                    color: AppTheme.inkSoft,
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
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.gold)),
        const SizedBox(width: 12),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textAlign: TextAlign.center,
          style: AppTheme.arabicText(fontSize: 20, color: AppTheme.goldDeep),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: AppTheme.gold)),
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
    required this.onTap,
    required this.onBookmark,
  });

  final Ayah ayah;
  final bool active;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppTheme.goldSoft : AppTheme.surface,
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
                      ? AppTheme.gold
                      : AppTheme.surface.withValues(alpha: 0),
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
                            decoration: const BoxDecoration(
                              color: AppTheme.gold,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${ayah.number}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppTheme.surface,
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
                                  ? AppTheme.goldDeep
                                  : AppTheme.inkFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TajweedText(arabic: ayah.arabic, segments: ayah.tajweed),
                      const SizedBox(height: 12),
                      Text(
                        ayah.translation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.inkSoft,
                          fontSize: 13,
                        ),
                      ),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.surface.withValues(alpha: 0.08)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendItem {
  const _LegendItem(this.label, this.color);

  final String label;
  final Color color;
}
