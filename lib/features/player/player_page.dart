import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../providers/app_providers.dart';

/// Provides a [Player] for a given task's output file.
final playerProvider = Provider.family<Player, String>((ref, path) {
  // Load media_kit native libraries on first use so cold start stays fast.
  MediaKit.ensureInitialized();
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
  String? _title;
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

    setState(() => _title = task?.title);

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
    final profile = context.platformProfile;

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const _PlayerBackButton(),
          title: Text(_title ?? l10n.play),
        ),
        body: _PlayerError(message: _error!),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const _PlayerBackButton(),
          title: Text(_title ?? l10n.play),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        leading: const _PlayerBackButton(),
        title: Text(
          _title ?? l10n.play,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
      body: MaterialVideoControlsTheme(
        normal: MaterialVideoControlsThemeData(
          // Desktop gets a slimmer control bar; touch platforms need the
          // larger targets.
          seekBarHeight: profile.isDesktop ? 3 : 5,
          seekBarContainerHeight: profile.isDesktop ? 44 : 56,
          seekBarMargin: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
          ),
          seekBarThumbSize: profile.isDesktop ? 12 : 14,
          seekBarColor: Colors.white24,
          seekBarPositionColor: Colors.white,
          seekBarBufferColor: Colors.white38,
          buttonBarHeight: profile.isDesktop ? 46 : 56,
          buttonBarButtonSize: profile.isDesktop ? 20 : 24,
          buttonBarButtonColor: Colors.white,
          bottomButtonBarMargin: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.sm,
          ),
        ),
        fullscreen: MaterialVideoControlsThemeData(
          seekBarHeight: 5,
          seekBarContainerHeight: 56,
          seekBarThumbSize: 14,
          seekBarColor: Colors.white24,
          seekBarPositionColor: Colors.white,
          seekBarBufferColor: Colors.white38,
          buttonBarButtonSize: 24,
          buttonBarButtonColor: Colors.white,
        ),
        child: Video(
          controller: controller,
          controls: MaterialVideoControls,
        ),
      ),
    );
  }
}

/// Back affordance that returns to history when there is nothing to pop
/// (e.g. the player was opened directly as the initial route).
class _PlayerBackButton extends StatelessWidget {
  const _PlayerBackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.10),
                borderRadius: Radii.lgAll,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 30, color: scheme.error),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}