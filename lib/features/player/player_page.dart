import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../providers/app_providers.dart';

/// Provides a [Player] for a given task's output file.
final playerProvider = Provider.family<Player, String>((ref, path) {
  final player = Player();
  ref.onDispose(player.dispose);
  player.open(Media(path), play: true);
  return player;
});

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  late final VideoController _controller;
  Player? _player;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final store = ref.read(engineTaskStoreProvider);
    final task = await store.loadTask(widget.taskId);
    final path = task?.outputPath;

    if (path == null) {
      setState(() => _error = 'No playable output for this task.');
      return;
    }

    final player = ref.read(playerProvider(path));
    _controller = VideoController(player);
    if (mounted) {
      setState(() => _player = player);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final player = _player;
    if (player == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(),
        fullscreen: MaterialVideoControlsThemeData(),
        child: Video(
          controller: _controller,
          controls: MaterialVideoControls,
        ),
      ),
    );
  }
}
