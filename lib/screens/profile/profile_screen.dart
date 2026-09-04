import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/achievement.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/ring_progress.dart';
import '../admin/admin_screen.dart';
import 'settings_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onGoToQuran});

  final VoidCallback onGoToQuran;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(
        child: Text(
          'Войдите в аккаунт, чтобы открыть профиль',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final uid = user.uid;

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService(uid).getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.palette(context).primary,
            ),
          );
        }

        return _ProfileContent(
          profile: profile,
          onGoToQuran: onGoToQuran,
          achievements: _achievementsFor(profile),
        );
      },
    );
  }

  List<Achievement> _achievementsFor(UserProfile profile) {
    double ratio(num value, num target) =>
        (value / target).clamp(0, 1).toDouble();
    return [
      Achievement(
        title: 'Первый урок',
        progress: ratio(profile.lessonsCount, 1),
        isUnlocked: profile.lessonsCount >= 1,
      ),
      Achievement(
        title: '7 дней подряд',
        progress: ratio(profile.streakDays, 7),
        isUnlocked: profile.streakDays >= 7,
      ),
      Achievement(
        title: '30 уроков',
        progress: ratio(profile.lessonsCount, 30),
        isUnlocked: profile.lessonsCount >= 30,
      ),
      Achievement(
        title: 'Прогресс Корана',
        progress: profile.quranProgress.clamp(0, 1),
        isUnlocked: profile.quranProgress >= 1,
      ),
    ];
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onGoToQuran,
    required this.achievements,
  });

  final UserProfile profile;
  final VoidCallback onGoToQuran;
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileBanner(profile: profile),
          if (profile.isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminScreen()),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Открыть админ-панель'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _StatsRow(profile: profile),
          const SizedBox(height: 20),
          _MemorizationCard(profile: profile, onContinue: onGoToQuran),
          const SizedBox(height: 20),
          Text('Достижения', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _AchievementsGrid(achievements: achievements),
        ],
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      constraints: const BoxConstraints(minHeight: 172),
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
              child: CustomPaint(
                painter: _BannerPatternPainter(color: onPrimary),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SettingsSheet(),
                ),
                icon: Icon(Icons.settings_rounded, color: onPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(profile.name),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: palette.primaryDeep,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${profile.group} · ${profile.role}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: onPrimary.withValues(alpha: 0.8),
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
          ],
        ),
      ),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('${profile.attendance}%', 'Посещаемость'),
      _StatData('${profile.lessonsCount}', 'Уроков'),
      _StatData('${profile.streakDays}', 'Дней подряд'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth < 340 ? 1 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _StatCard(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: palette.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.inkSoft,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemorizationCard extends StatelessWidget {
  const _MemorizationCard({required this.profile, required this.onContinue});

  final UserProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 340;
          final progress = RingProgress(
            percent: profile.quranProgress,
            color: palette.primary,
            size: isCompact ? 92 : 100,
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заучивание Корана',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Сура ${profile.currentSura} · аят ${profile.currentAyah}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              GoldButton(
                label: 'Продолжить',
                icon: Icons.menu_book_rounded,
                onPressed: onContinue,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [progress, const SizedBox(height: 16), content],
            );
          }

          return Row(
            children: [
              progress,
              const SizedBox(width: 16),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth < 360 ? 1 : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final achievement in achievements)
              SizedBox(
                width: width,
                child: _AchievementCard(achievement: achievement),
              ),
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final unlocked = achievement.isUnlocked;
    final onGold = AppTheme.inkOnLight;

    return AnimatedContainer(
      duration: AppTheme.motion,
      curve: AppTheme.motionCurve,
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? palette.primarySoft : palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unlocked ? palette.primary : palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: unlocked ? palette.primaryDeep : palette.inkFaint,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: unlocked ? onGold : palette.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (unlocked)
            Text(
              'Выполнено',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: onGold,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: achievement.progress,
                minHeight: 5,
                color: palette.primary,
                backgroundColor: palette.primarySoft,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(achievement.progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.inkFaint,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerPatternPainter extends CustomPainter {
  const _BannerPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const step = 40.0;
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
  bool shouldRepaint(covariant _BannerPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _StatData {
  const _StatData(this.value, this.label);

  final String value;
  final String label;
}
