import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/lesson.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/tag_widget.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late final FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _firestoreService = FirestoreService(uid);
    _firestoreService.ensureDefaultLessons();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Lesson>>(
      stream: _firestoreService.getLessons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.gold),
          );
        }

        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) {
          return AppCard(
            child: Text(
              'Расписание пока пустое',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        final day = lessons.first.day.isEmpty ? 'Сегодня' : lessons.first.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ScheduleLessonCard(lesson: lessons[index]);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleLessonCard extends StatelessWidget {
  const _ScheduleLessonCard({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.goldSoft,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lesson.time,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.durationMin} мин',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                        TagWidget(label: lesson.type),
                        if (lesson.isSoon) ...[
                          const SizedBox(width: 8),
                          const _SoonTag(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lesson.topic,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lesson.teacher,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.inkSoft,
                        fontSize: 12,
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
    return TagWidget(
      label: 'скоро',
      leading: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.gold,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
