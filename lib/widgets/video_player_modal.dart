import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/video_lesson.dart';
import '../theme/app_theme.dart';

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
  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  VideoPlayerController? _controller;
  late int _index;
  int _speedIndex = 1;
  int _generation = 0;
  bool _repeat = false;
  bool _loading = false;
  String? _error;

  VideoLesson get _video => widget.videos[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _controller?.removeListener(_refresh);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final previous = _controller;
    _controller = null;
    previous?.removeListener(_refresh);
    await previous?.dispose();
    if (!mounted || generation != _generation) return;

    final hasSource = _video.videoUrl.isNotEmpty;
    setState(() {
      _loading = hasSource;
      _error = hasSource ? null : 'Для этого урока видео ещё не загружено';
    });
    if (!hasSource) return;

    final url = _video.videoUrl.trim();
    if (!mounted || generation != _generation) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (url.isNotEmpty) {
        setState(() => _error = 'Некорректная ссылка на видео');
      }
      setState(() => _loading = false);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      _controller = controller..addListener(_refresh);
      await controller.setLooping(_repeat);
      await controller.setPlaybackSpeed(_speeds[_speedIndex]);
      await controller.play();
      setState(() => _loading = false);
    } catch (_) {
      await controller.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error =
              'Не удалось открыть видео. Проверьте интернет и формат файла.';
        });
      }
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    final player = _controller;
    if (player == null) return;
    if (player.value.isPlaying) {
      await player.pause();
    } else {
      if (player.value.position >= player.value.duration) {
        await player.seekTo(Duration.zero);
      }
      await player.play();
    }
  }

  void _changeVideo(int offset) {
    setState(
      () => _index =
          (_index + offset + widget.videos.length) % widget.videos.length,
    );
    _load();
  }

  Future<void> _toggleRepeat() async {
    setState(() => _repeat = !_repeat);
    await _controller?.setLooping(_repeat);
  }

  Future<void> _changeSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    await _controller?.setPlaybackSpeed(_speeds[_speedIndex]);
  }

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller?.value;
    final ready = value?.isInitialized ?? false;
    final position = ready ? value!.position : Duration.zero;
    final duration = ready ? value!.duration : Duration.zero;
    final max = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final current = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Урок ${_video.number}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        _video.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: ready && value!.aspectRatio > 0
                  ? value.aspectRatio
                  : 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColoredBox(
                  color: Colors.black,
                  child: _videoArea(ready),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Slider(
              value: current,
              max: max,
              onChanged: ready
                  ? (ms) =>
                        _controller?.seekTo(Duration(milliseconds: ms.round()))
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(_time(position)), Text(_time(duration))],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: widget.videos.length > 1
                      ? () => _changeVideo(-1)
                      : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                FilledButton(
                  onPressed: ready ? _togglePlay : null,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(18),
                  ),
                  child: Icon(
                    value?.isPlaying == true
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                IconButton(
                  onPressed: widget.videos.length > 1
                      ? () => _changeVideo(1)
                      : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: ready ? _toggleRepeat : null,
                  icon: Icon(
                    _repeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  ),
                  label: const Text('Повтор'),
                ),
                TextButton.icon(
                  onPressed: ready ? _changeSpeed : null,
                  icon: const Icon(Icons.speed_rounded),
                  label: Text('${_speeds[_speedIndex]}x'),
                ),
              ],
            ),
            if (_video.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_video.description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _videoArea(bool ready) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_file_outlined,
                color: Colors.white70,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              if (_video.videoUrl.isNotEmpty)
                TextButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (!ready || _controller == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        if (_controller!.value.isBuffering)
          const Center(child: CircularProgressIndicator()),
        Material(
          color: Colors.transparent,
          child: InkWell(onTap: _togglePlay),
        ),
      ],
    );
  }
}
