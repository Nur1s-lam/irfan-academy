import 'dart:async';

import 'package:flutter/material.dart';

import '../models/video_lesson.dart';
import '../theme/app_theme.dart';
import 'gold_button.dart';

Future<void> showVideoPlayerModal({
  required BuildContext context,
  required List<VideoLesson> videos,
  required int initialIndex,
}) {
  final palette = AppTheme.palette(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.surface,
    barrierColor: palette.ink.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _VideoPlayerModal(videos: videos, initialIndex: initialIndex),
  );
}

class _VideoPlayerModal extends StatefulWidget {
  const _VideoPlayerModal({required this.videos, required this.initialIndex});

  final List<VideoLesson> videos;
  final int initialIndex;

  @override
  State<_VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<_VideoPlayerModal> {
  Timer? _timer;
  late int _index;
  int _currentSeconds = 154;
  bool _isPlaying = true;
  bool _repeat = false;
  int _speedIndex = 0;

  static const _speeds = [1.0, 1.25, 1.5, 0.75];

  VideoLesson get _video => widget.videos[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _currentSeconds = _video.totalSeconds > 154 ? 154 : 0;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPlaying) {
        return;
      }
      setState(() {
        _currentSeconds += _speeds[_speedIndex].round();
        if (_currentSeconds >= _video.totalSeconds) {
          if (_repeat) {
            _currentSeconds = 0;
          } else {
            _nextVideo();
          }
        }
      });
    });
  }

  void _previousVideo() {
    setState(() {
      _index = (_index - 1 + widget.videos.length) % widget.videos.length;
      _currentSeconds = 0;
      _isPlaying = true;
    });
  }

  void _nextVideo() {
    _index = (_index + 1) % widget.videos.length;
    _currentSeconds = 0;
    _isPlaying = true;
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _toggleRepeat() {
    setState(() => _repeat = !_repeat);
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final clampedSeconds = _currentSeconds.clamp(0, _video.totalSeconds);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.inkFaint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Урок ${_video.number} · ${_video.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: onPrimary,
                  size: 72,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: palette.primary,
                inactiveTrackColor: palette.primarySoft,
                thumbColor: palette.primaryDeep,
                overlayColor: palette.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: 0,
                max: _video.totalSeconds.toDouble(),
                value: clampedSeconds.toDouble(),
                onChanged: (value) {
                  setState(() => _currentSeconds = value.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatTime(clampedSeconds)} / ${_video.duration}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.inkSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _isPlaying ? 'Воспроизведение' : 'Пауза',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.primaryDeep,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  label: 'Предыдущий',
                  onTap: _previousVideo,
                ),
                const SizedBox(width: 8),
                _PlayButton(isPlaying: _isPlaying, onTap: _togglePlay),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  label: 'Следующий',
                  onTap: () => setState(_nextVideo),
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.repeat_rounded,
                  label: 'Повтор',
                  active: _repeat,
                  onTap: _toggleRepeat,
                ),
                const SizedBox(width: 8),
                _SpeedButton(
                  label:
                      '×${_speeds[_speedIndex].toString().replaceAll('.0', '')}',
                  onTap: _cycleSpeed,
                ),
              ],
            ),
            const SizedBox(height: 18),
            GoldButton(
              label: 'Продолжить просмотр',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                if (!_isPlaying) {
                  _togglePlay();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Tooltip(
      message: label,
      child: Material(
        color: active ? palette.primarySoft : palette.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: active ? AppTheme.inkOnLight : palette.inkSoft,
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.isPlaying, required this.onTap});

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Tooltip(
      message: isPlaying ? 'Пауза' : 'Плей',
      child: Material(
        color: palette.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: onPrimary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);

    return Material(
      color: palette.primarySoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 50,
          height: 44,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.inkOnLight,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
