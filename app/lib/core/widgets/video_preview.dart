import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../theme/app_theme.dart';

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.path, this.height = 220});

  final String path;
  final double height;

  static bool _available = true;

  static bool get _platformSupported =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get isSupported => _platformSupported && _available;

  static void initialize() {
    if (!_platformSupported) return;
    try {
      MediaKit.ensureInitialized();
    } catch (_) {
      _available = false;
    }
  }

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  Player? _player;
  VideoController? _controller;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _open();
  }

  void _open() {
    final generation = ++_generation;
    _player?.dispose();
    final player = Player();
    final controller = VideoController(player);
    _player = player;
    _controller = controller;
    player
        .open(Media(widget.path), play: false)
        .then((_) {
          if (!mounted || generation != _generation) {
            player.dispose();
          }
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _generation++;
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Video(
        controller: controller,
        fit: BoxFit.contain,
        controls: AdaptiveVideoControls,
      ),
    );
  }
}
