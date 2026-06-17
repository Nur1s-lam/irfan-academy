import 'package:flutter/material.dart';

import '../../models/video_lesson.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/video_player_modal.dart';

class VideoTab extends StatelessWidget {
  const VideoTab({super.key, required this.videos});

  final List<VideoLesson> videos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < videos.length; index++) ...[
          _VideoLessonCard(
            video: videos[index],
            onTap: () => showVideoPlayerModal(
              context: context,
              videos: videos,
              initialIndex: index,
            ),
          ),
          if (index != videos.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _VideoLessonCard extends StatelessWidget {
  const _VideoLessonCard({required this.video, required this.onTap});

  final VideoLesson video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.play_circle_outline_rounded,
              color: AppTheme.inkOnLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'УРОК ${video.number}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkFaint,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  video.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  video.duration,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkSoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: palette.inkFaint,
            size: 18,
          ),
        ],
      ),
    );
  }
}
