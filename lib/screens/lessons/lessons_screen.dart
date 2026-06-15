import 'package:flutter/material.dart';

import '../../models/video_lesson.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_title.dart';
import 'homework_tab.dart';
import 'schedule_tab.dart';
import 'video_tab.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _selectedTab = 0;

  final List<VideoLesson> _videos = const [
    VideoLesson(
      number: 10,
      title: 'Введение в таджвид',
      duration: '12:30',
      totalSeconds: 12 * 60 + 30,
    ),
    VideoLesson(
      number: 11,
      title: 'Правила Изхар',
      duration: '15:45',
      totalSeconds: 15 * 60 + 45,
    ),
    VideoLesson(
      number: 12,
      title: 'Правила Мадд',
      duration: '18:24',
      totalSeconds: 18 * 60 + 24,
    ),
    VideoLesson(
      number: 13,
      title: 'Правила Идгам',
      duration: '20:10',
      totalSeconds: 20 * 60 + 10,
    ),
    VideoLesson(
      number: 14,
      title: 'Правила Ихфа',
      duration: '16:55',
      totalSeconds: 16 * 60 + 55,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitle(
            title: 'Мои уроки',
            subtitle: 'Группа Хифз-2 · устаз Ибрагим',
          ),
          const SizedBox(height: 20),
          _LessonsSegmentedControl(
            selectedIndex: _selectedTab,
            onSelected: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 20),
          IndexedStack(
            index: _selectedTab,
            children: [
              const ScheduleTab(),
              const HomeworkTab(),
              VideoTab(videos: _videos),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonsSegmentedControl extends StatelessWidget {
  const _LessonsSegmentedControl({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Расписание', 'Задания', 'Видео'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++)
            Expanded(
              child: _SegmentButton(
                label: tabs[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface.withValues(alpha: 0),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: AppTheme.motion,
          curve: AppTheme.motionCurve,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.gold
                : AppTheme.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppTheme.surface : AppTheme.inkSoft,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
