import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuranPlayer extends StatelessWidget {
  const QuranPlayer({
    super.key,
    required this.activeAyah,
    required this.totalAyahs,
    required this.progress,
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
  final double progress;
  final bool isPlaying;
  final bool repeat;
  final double speed;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onPlayPause;
  final VoidCallback onRepeat;
  final VoidCallback onSpeed;
  final ValueChanged<double> onSeek;

  static const int _totalSeconds = 45;

  @override
  Widget build(BuildContext context) {
    final currentSeconds = (_totalSeconds * progress).round().clamp(
      0,
      _totalSeconds,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
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
                  activeTrackColor: AppTheme.gold,
                  inactiveTrackColor: AppTheme.goldSoft,
                  thumbColor: AppTheme.goldDeep,
                  overlayColor: AppTheme.gold.withValues(alpha: 0.12),
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
                              color: AppTheme.inkSoft,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${_format(currentSeconds)} / 00:45',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.inkSoft,
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

  String _format(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
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
    return Tooltip(
      message: label,
      child: Material(
        color: active ? AppTheme.goldSoft : AppTheme.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: active ? AppTheme.goldDeep : AppTheme.inkSoft,
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
    return Tooltip(
      message: isPlaying ? 'Пауза' : 'Плей',
      child: Material(
        color: AppTheme.gold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.surface,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
