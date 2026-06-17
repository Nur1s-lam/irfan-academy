import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuranPlayer extends StatelessWidget {
  const QuranPlayer({
    super.key,
    required this.activeAyah,
    required this.totalAyahs,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.repeat,
    required this.speed,
    required this.onNext,
    required this.onPrev,
    required this.onPlayPause,
    required this.onRepeat,
    required this.onSpeed,
    required this.onSeek,
  });

  final int activeAyah;
  final int totalAyahs;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool repeat;
  final double speed;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onRepeat;
  final VoidCallback onSpeed;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.palette(context);
    final totalMs = duration.inMilliseconds;
    final currentMs = position.inMilliseconds.clamp(0, totalMs);
    final progress = totalMs == 0 ? 0.0 : currentMs / totalMs;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: palette.primary,
                  inactiveTrackColor: palette.primarySoft,
                  thumbColor: palette.primaryDeep,
                  overlayColor: palette.primary.withValues(alpha: 0.12),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: 0,
                  max: 1,
                  value: progress.clamp(0, 1),
                  onChanged: onSeek,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Аят $activeAyah из $totalAyahs',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: palette.inkSoft,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${_format(position)} / ${_format(duration)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.inkSoft,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundIconButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'Предыдущий',
                    onTap: onPrev,
                  ),
                  _PlayButton(isPlaying: isPlaying, onTap: onPlayPause),
                  _RoundIconButton(
                    icon: Icons.skip_next_rounded,
                    label: 'Следующий',
                    onTap: onNext,
                  ),
                  _RoundIconButton(
                    icon: Icons.repeat_rounded,
                    label: 'Повтор',
                    active: repeat,
                    onTap: onRepeat,
                  ),
                  TextButton(
                    onPressed: onSpeed,
                    child: Text('×${speed.toString().replaceAll('.0', '')}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final rest = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
          customBorder: const CircleBorder(),
          onTap: onTap,
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
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
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
