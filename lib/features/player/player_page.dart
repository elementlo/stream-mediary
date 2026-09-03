import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/l10n/app_localizations.dart';
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
  VideoController? _controller;
  String? _error;
  bool _ready = false;
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<String>? _errorSub;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final store = ref.read(engineTaskStoreProvider);
    final task = await store.loadTask(widget.taskId);
    if (!mounted) return;
    // Localizations.of must not run before initState completes.
    final l10n = AppLocalizations.of(context);
    final path = task?.outputPath;

    if (path == null) {
      setState(() => _error = l10n.playerNoOutput);
      return;
    }
    if (!File(path).existsSync()) {
      setState(() => _error = l10n.playerFileMissing);
      return;
    }

    final player = ref.read(playerProvider(path));
    _playlistSub = player.stream.playlist.listen((playlist) {
      if (playlist.medias.isNotEmpty && mounted && !_ready) {
        setState(() => _ready = true);
      }
    });
    _errorSub = player.stream.error.listen((message) {
      if (mounted && !_ready) {
        setState(() => _error = '${l10n.playerOpenFailed}: $message');
      }
    });
    // Give up waiting for a playable stream after 15s.
    _timeout = Timer(const Duration(seconds: 15), () {
      if (mounted && !_ready && _error == null) {
        setState(() => _error = l10n.playerOpenFailed);
      }
    });

    setState(() {
      _controller = VideoController(player);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _playlistSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.play),
      ),
      body: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(),
        fullscreen: MaterialVideoControlsThemeData(),
        child: Video(
          controller: controller,
          controls: MaterialVideoControls,
        ),
      ),
    );
  }
}
