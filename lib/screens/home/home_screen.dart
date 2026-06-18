import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/lesson.dart';
import '../../models/prayer_time.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/screen_title.dart';
import '../../widgets/tag_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _prayerService = PrayerService();
  Timer? _timer;
  PrayerSchedule? _prayerSchedule;
  PrayerTime? _nextPrayer;
  Duration? _timeToPrayer;
  String? _prayerError;
  bool _isPrayerLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerSchedule();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerSchedule == null || !mounted) {
        return;
      }
      setState(() {
        _refreshNextPrayer();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerSchedule() async {
    setState(() {
      _isPrayerLoading = true;
      _prayerError = null;
    });

    try {
      final schedule = await _prayerService.getTodayPrayerSchedule();
      if (!mounted) {
        return;
      }
      setState(() {
        _prayerSchedule = schedule;
        _isPrayerLoading = false;
        _refreshNextPrayer();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPrayerLoading = false;
        _prayerError = error.toString();
      });
    }
  }

  void _refreshNextPrayer() {
    final schedule = _prayerSchedule;
    if (schedule == null) {
      return;
    }

    final prayers = _prayerService.updateStatuses(schedule.prayers);
    final nextPrayer = _prayerService.getNextPrayer(prayers);
    _prayerSchedule = schedule.copyWith(prayers: prayers);
    _nextPrayer = nextPrayer;
    _timeToPrayer = _prayerService.getTimeUntilNextPrayer(nextPrayer);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final palette = AppTheme.palette(context);

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService(uid).getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return Center(
            child: CircularProgressIndicator(color: palette.primary),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(profile: profile),
              const SizedBox(height: 20),
              _NextPrayerCard(
                nextPrayer: _nextPrayer,
                countdown: _formatDuration(_timeToPrayer ?? Duration.zero),
                locationLabel: _prayerSchedule?.locationLabel ?? 'Бишкек',
                isLoading: _isPrayerLoading,
                error: _prayerError,
                onTap: () => widget.onTabSelected(1),
                onRetry: _loadPrayerSchedule,
              ),
              const SizedBox(height: 20),
              _QuickAccess(onTabSelected: widget.onTabSelected),
              const SizedBox(height: 20),
              _ProgressCard(
                profile: profile,
                onContinue: () => widget.onTabSelected(2),
              ),
              const SizedBox(height: 20),
              _TodayLessons(
                uid: uid,
                onAllLessons: () => widget.onTabSelected(2),
              ),
              const SizedBox(height: 20),
              const _RecommendedSection(),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials(profile.name),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: palette.primaryDeep,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ассаламу алейкум 👋',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.inkSoft),
              ),
              const SizedBox(height: 3),
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: IconButton(
                  onPressed: () => _showNotificationsSheet(context),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: palette.ink,
                  ),
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    final palette = AppTheme.palette(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: palette.ink.withValues(alpha: 0.42),
      builder: (context) => const _NotificationsSheet(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'IA';
    }
    return parts.take(2).map((part) => part.characters.first).join();
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final notifications = [
      _NotificationItem(
        icon: Icons.schedule_rounded,
        title: 'Напоминание о намазе',
        message: 'Аср начнётся сегодня в 17:18.',
        time: 'Сегодня',
        highlighted: true,
      ),
      _NotificationItem(
        icon: Icons.school_rounded,
        title: 'Урок таджвида',
        message: 'Повторите правила Нун сакина и танвин перед занятием.',
        time: '2 часа назад',
      ),
      _NotificationItem(
        icon: Icons.menu_book_rounded,
        title: 'Продолжите чтение',
        message: 'Вы остановились на текущем аяте в разделе Коран.',
        time: 'Вчера',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: palette.inkFaint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Уведомления',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: palette.inkSoft),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (
                    var index = 0;
                    index < notifications.length;
                    index++
                  ) ...[
                    if (index > 0)
                      Divider(
                        height: 18,
                        color: palette.inkFaint.withValues(alpha: 0.16),
                      ),
                    _NotificationTile(item: notifications[index]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool highlighted;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final iconColor = item.highlighted ? palette.primaryDeep : palette.inkSoft;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.highlighted ? palette.primarySoft : palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Icon(
            item.icon,
            color: item.highlighted ? AppTheme.inkOnLight : iconColor,
            size: 22,
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
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.time,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.inkFaint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.inkSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.nextPrayer,
    required this.countdown,
    required this.locationLabel,
    required this.isLoading,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  final PrayerTime? nextPrayer;
  final String countdown;
  final String locationLabel;
  final bool isLoading;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final prayer = nextPrayer;

    return Material(
      color: palette.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primary, palette.primaryDeep],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: palette.primaryDeep.withValues(alpha: 0.24),
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
                  child: CustomPaint(
                    painter: _PrayerPatternPainter(color: onPrimary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Следующий намаз',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: onPrimary),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_rounded,
                                      size: 15,
                                      color: onPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: onPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              prayer?.nameAr ?? '...',
                              style: AppTheme.arabicText(
                                fontSize: 34,
                                color: onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isLoading)
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: CircularProgressIndicator(color: onPrimary),
                        )
                      else if (error != null)
                        _PrayerCardError(
                          message: error!,
                          onRetry: onRetry,
                          foreground: onPrimary,
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prayer?.nameRu ?? '--',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: onPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    prayer?.time ?? '--:--',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(color: onPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'осталось',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: onPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  countdown,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: onPrimary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerCardError extends StatelessWidget {
  const _PrayerCardError({
    required this.message,
    required this.onRetry,
    required this.foreground,
  });

  final String message;
  final VoidCallback onRetry;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: foreground),
          child: const Text('Повторить'),
        ),
      ],
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem('Уроки', Icons.school_rounded, () => onTabSelected(2)),
      _QuickAccessItem('Намаз', Icons.schedule_rounded, () => onTabSelected(1)),
      _QuickAccessItem(
        'Коран',
        Icons.menu_book_rounded,
        () => onTabSelected(3),
      ),
      _QuickAccessItem('Новости', Icons.campaign_rounded, () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(title: 'Быстрый доступ'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(child: _QuickAccessButton(item: items[index])),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  const _QuickAccessButton({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    const onGold = AppTheme.inkOnLight;

    return Material(
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: onGold, size: 24),
              const SizedBox(height: 7),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: onGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.profile, required this.onContinue});

  final UserProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final percent = (profile.quranProgress * 100).round();

    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: _ProgressRingPainter(
                    progress: profile.quranProgress,
                    palette: palette,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Мой прогресс',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${profile.currentSura} · аят ${profile.currentAyah}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                GoldButton(
                  label: 'Продолжить урок',
                  icon: Icons.play_arrow_rounded,
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLessons extends StatefulWidget {
  const _TodayLessons({required this.uid, required this.onAllLessons});

  final String uid;
  final VoidCallback onAllLessons;

  @override
  State<_TodayLessons> createState() => _TodayLessonsState();
}

class _TodayLessonsState extends State<_TodayLessons> {
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService(widget.uid);
    _firestoreService.ensureDefaultLessons();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Уроки на сегодня',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: widget.onAllLessons,
                child: const Text('Все уроки →'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<Lesson>>(
            stream: _firestoreService.getLessons(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: CircularProgressIndicator(color: palette.primary),
                );
              }

              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'На сегодня уроков нет',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < lessons.length; index++) ...[
                    if (index > 0)
                      Divider(color: palette.inkFaint.withValues(alpha: 0.16)),
                    _LessonRow(lesson: lessons[index]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              lesson.time,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: palette.primaryDeep,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lesson.type,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: palette.ink),
                    ),
                    if (lesson.isSoon) ...[
                      const SizedBox(width: 8),
                      const _SoonTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.topic,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.teacher,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection();

  @override
  Widget build(BuildContext context) {
    final videos = [
      const _VideoLesson('Урок 10', 'Введение в таджвид', '12:30'),
      const _VideoLesson('Урок 11', 'Правила Изхар', '15:45'),
      const _VideoLesson('Урок 12', 'Правила Мадд', '18:24'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenTitle(title: 'Рекомендуется'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < videos.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                _VideoLessonCard(video: videos[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoLessonCard extends StatelessWidget {
  const _VideoLessonCard({required this.video});

  final _VideoLesson video;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return SizedBox(
      width: 190,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: AppTheme.inkOnLight,
              ),
            ),
            const SizedBox(height: 14),
            TagWidget(label: video.number),
            const SizedBox(height: 10),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: palette.inkFaint),
                const SizedBox(width: 5),
                Text(
                  video.duration,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoonTag extends StatefulWidget {
  const _SoonTag();

  @override
  State<_SoonTag> createState() => _SoonTagState();
}

class _SoonTagState extends State<_SoonTag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.motionCurve),
    );
    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.motionCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return TagWidget(
      label: 'скоро',
      icon: null,
      backgroundColor: palette.primarySoft,
      foregroundColor: AppTheme.inkOnLight,
      leading: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: palette.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerPatternPainter extends CustomPainter {
  const _PrayerPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const step = 42.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final center = Offset(x + step / 2, y + step / 2);
        final rect = Rect.fromCenter(center: center, width: 22, height: 22);
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
  bool shouldRepaint(covariant _PrayerPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress, required this.palette});

  final double progress;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 7;
    final trackPaint = Paint()
      ..color = palette.primarySoft
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = palette.primary
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.palette != palette;
  }
}

class _QuickAccessItem {
  const _QuickAccessItem(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _VideoLesson {
  const _VideoLesson(this.number, this.title, this.duration);

  final String number;
  final String title;
  final String duration;
}
