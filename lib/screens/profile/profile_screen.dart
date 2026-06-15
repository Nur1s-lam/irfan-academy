import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/achievement.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gold_button.dart';
import '../../widgets/ring_progress.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onGoToQuran});

  final VoidCallback onGoToQuran;

  static const List<Achievement> _achievements = [
    Achievement(title: 'Хафиз Аль-Фатиха', progress: 1, isUnlocked: true),
    Achievement(title: '7 дней подряд', progress: 1, isUnlocked: true),
    Achievement(title: '30 уроков', progress: 1, isUnlocked: true),
    Achievement(title: 'Мастер таджвида', progress: 0.6, isUnlocked: false),
    Achievement(title: 'Первый джуз', progress: 0.4, isUnlocked: false),
    Achievement(title: '100 аятов', progress: 0.25, isUnlocked: false),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService(uid).getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          );
        }

        return _ProfileContent(
          profile: profile,
          onGoToQuran: onGoToQuran,
          achievements: _achievements,
        );
      },
    );
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
            Positioned.fill(
              child: CustomPaint(painter: _BannerPatternPainter()),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppTheme.surface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(profile.name),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.goldDeep,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.surface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${profile.group} · ${profile.role}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.surface.withValues(
                                    alpha: 0.8,
                                  ),
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

    return Row(
      children: [
        for (var index = 0; index < stats.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(child: _StatCard(stat: stats[index])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.gold,
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
              color: AppTheme.inkSoft,
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
    return AppCard(
      child: Row(
        children: [
          RingProgress(
            percent: profile.quranProgress,
            color: AppTheme.gold,
            size: 100,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
            ),
          ),
        ],
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
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final achievement in achievements)
              SizedBox(
                width: width,
                height: 142,
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
    final unlocked = achievement.isUnlocked;

    return AnimatedContainer(
      duration: AppTheme.motion,
      curve: AppTheme.motionCurve,
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? AppTheme.goldSoft : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unlocked ? AppTheme.gold : AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.04),
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
            color: unlocked ? AppTheme.goldDeep : AppTheme.inkFaint,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: unlocked ? AppTheme.ink : AppTheme.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          if (unlocked)
            Text(
              'Выполнено',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.goldDeep,
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
                color: AppTheme.gold,
                backgroundColor: AppTheme.goldSoft,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(achievement.progress * 100).round()}%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.inkFaint,
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.surface.withValues(alpha: 0.08)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatData {
  const _StatData(this.value, this.label);

  final String value;
  final String label;
}
