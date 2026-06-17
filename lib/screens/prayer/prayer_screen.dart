import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/prayer_time.dart';
import '../../services/notification_service.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/qibla_compass.dart';
import '../../widgets/screen_title.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _prayerService = PrayerService();
  Timer? _timer;
  Future<PrayerSchedule>? _scheduleFuture;
  PrayerSchedule? _schedule;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshStatuses();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadSchedule() {
    setState(() {
      _schedule = null;
      _scheduleFuture = _prayerService.getTodayPrayerSchedule();
    });
  }

  void _refreshStatuses() {
    final schedule = _schedule;
    if (schedule == null || !mounted) {
      return;
    }
    setState(() {
      _schedule = schedule.copyWith(
        prayers: _prayerService.updateStatuses(schedule.prayers),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return FutureBuilder<PrayerSchedule>(
      future: _scheduleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: palette.primary),
          );
        }

        if (snapshot.hasError) {
          return _PrayerError(
            message: snapshot.error.toString(),
            onRetry: _loadSchedule,
          );
        }

        final freshSchedule = snapshot.data;
        if (freshSchedule != null && _schedule == null) {
          _schedule = freshSchedule;
          NotificationService.instance.schedulePrayerNotifications(
            freshSchedule.prayers,
          );
        }
        final schedule = _schedule ?? freshSchedule;
        if (schedule == null) {
          return _PrayerError(
            message: 'Не удалось загрузить расписание',
            onRetry: _loadSchedule,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(
                title: 'Намаз',
                subtitle: 'Ваше местоположение · ${schedule.locationLabel}',
              ),
              const SizedBox(height: 20),
              QiblaCompass(
                qiblaDirection: schedule.qiblaDirection,
                locationLabel: schedule.locationLabel,
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Расписание на сегодня',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: _loadSchedule,
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: palette.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final prayer in schedule.prayers)
                      PrayerTimeRow(prayer: prayer),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerError extends StatelessWidget {
  const _PrayerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_rounded,
                color: palette.primaryDeep,
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                'Геолокация недоступна',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('Повторить'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: palette.surface,
                    backgroundColor: palette.primary,
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

class PrayerTimeRow extends StatelessWidget {
  const PrayerTimeRow({super.key, required this.prayer});

  final PrayerTime prayer;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final isNext = prayer.status == PrayerStatus.next;
    final isFaint = prayer.status == PrayerStatus.faint;
    final foreground = isNext
        ? AppTheme.inkOnLight
        : isFaint
            ? palette.inkFaint
            : palette.ink;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNext ? palette.primarySoft : palette.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppTheme.motion,
              curve: AppTheme.motionCurve,
              width: 3,
              decoration: BoxDecoration(
                color: isNext
                    ? palette.primary
                    : palette.surface.withValues(alpha: 0),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    _PrayerStatusIcon(status: prayer.status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prayer.nameRu,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: isNext
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        prayer.nameAr,
                        textAlign: TextAlign.right,
                        style: AppTheme.arabicText(
                          fontSize: 19,
                          color: foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      prayer.time,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerStatusIcon extends StatelessWidget {
  const _PrayerStatusIcon({required this.status});

  final PrayerStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    switch (status) {
      case PrayerStatus.done:
        return Icon(
          Icons.check_circle_rounded,
          color: palette.primaryDeep.withValues(alpha: 0.58),
          size: 22,
        );
      case PrayerStatus.next:
        return const _PulsingPrayerDot();
      case PrayerStatus.upcoming:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.inkFaint, width: 1.4),
          ),
        );
      case PrayerStatus.faint:
        return Icon(
          Icons.check_circle_rounded,
          color: palette.inkFaint.withValues(alpha: 0.55),
          size: 22,
        );
    }
  }
}

class _PulsingPrayerDot extends StatefulWidget {
  const _PulsingPrayerDot();

  @override
  State<_PulsingPrayerDot> createState() => _PulsingPrayerDotState();
}

class _PulsingPrayerDotState extends State<_PulsingPrayerDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.motionCurve),
    );
    _opacity = Tween<double>(begin: 0.42, end: 1).animate(
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

    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
