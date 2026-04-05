import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/player/player_playback_providers.dart';
import '../../app/player/player_progress_providers.dart';
import '../../app/player/player_playback_source.dart';
import '../../app/router/app_router.dart';
import 'player_screen_context.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, this.sessionContext});

  final PlayerScreenContext? sessionContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionContext == null) {
      return const Scaffold(
        appBar: _PlayerAppBar(),
        body: SafeArea(child: _MissingSessionContextState()),
      );
    }

    final playbackSourceAsync = ref.watch(
      playerPlaybackSourceProvider(sessionContext!),
    );

    return Scaffold(
      appBar: const _PlayerAppBar(),
      body: SafeArea(
        child: playbackSourceAsync.when(
          loading: () =>
              _PlayerResolutionLoadingState(sessionContext: sessionContext!),
          error: (error, stackTrace) => _PlayerResolutionErrorState(
            sessionContext: sessionContext!,
            error: error,
          ),
          data: (playbackSource) => _ResolvedPlaybackSurface(
            sessionContext: sessionContext!,
            playbackSource: playbackSource,
          ),
        ),
      ),
    );
  }
}

class _PlayerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PlayerAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Player'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MissingSessionContextState extends StatelessWidget {
  const _MissingSessionContextState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No watch session was provided.\nReturn to a series and choose an episode to enter the player.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PlayerResolutionLoadingState extends StatelessWidget {
  const _PlayerResolutionLoadingState({required this.sessionContext});

  final PlayerScreenContext sessionContext;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SessionHeader(sessionContext: sessionContext),
        const SizedBox(height: 16),
        const _VideoStageCard(
          title: 'Preparing Playback',
          message: 'Resolving this episode into a playable stream.',
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        const _InfoCard(
          title: 'What Happens Next',
          child: Text(
            'Once the stream is ready, playback starts in the dedicated watch surface.',
          ),
        ),
      ],
    );
  }
}

class _PlayerResolutionErrorState extends StatelessWidget {
  const _PlayerResolutionErrorState({
    required this.sessionContext,
    required this.error,
  });

  final PlayerScreenContext sessionContext;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SessionHeader(sessionContext: sessionContext),
        const SizedBox(height: 16),
        const _VideoStageCard(
          title: 'Playback Unavailable',
          message: 'The selected episode could not be prepared for playback.',
          child: Icon(Icons.error_outline_rounded, size: 36),
        ),
        const SizedBox(height: 16),
        _InfoCard(
          title: 'Playback Resolution Failed',
          child: Text(error.toString()),
        ),
      ],
    );
  }
}

class _ResolvedPlaybackSurface extends ConsumerStatefulWidget {
  const _ResolvedPlaybackSurface({
    required this.sessionContext,
    required this.playbackSource,
  });

  final PlayerScreenContext sessionContext;
  final PlayerPlaybackSource playbackSource;

  @override
  ConsumerState<_ResolvedPlaybackSurface> createState() =>
      _ResolvedPlaybackSurfaceState();
}

class _ResolvedPlaybackSurfaceState
    extends ConsumerState<_ResolvedPlaybackSurface> {
  static const _progressWriteStep = Duration(seconds: 15);

  Player? _player;
  VideoController? _videoController;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _completedSubscription;
  String? _playbackError;
  bool _isOpening = true;
  Duration _latestPosition = Duration.zero;
  Duration? _latestTotalDuration;
  Duration _lastPersistedPosition = Duration.zero;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_openPlayback());
  }

  Future<void> _openPlayback() async {
    try {
      MediaKit.ensureInitialized();

      final player = Player();
      final videoController = VideoController(player);
      final progressController = ref.read(playerProgressControllerProvider);

      _errorSubscription = player.stream.error.listen((message) {
        if (!mounted) {
          return;
        }

        setState(() {
          _playbackError = message;
        });
      });

      _positionSubscription = player.stream.position.listen((position) {
        _latestPosition = position;

        if (_isCompleted || !_shouldPersistProgress(position)) {
          return;
        }

        unawaited(
          _persistProgressSnapshot(progressController, position: position),
        );
      });

      _durationSubscription = player.stream.duration.listen((duration) {
        if (duration <= Duration.zero) {
          return;
        }

        _latestTotalDuration = duration;
      });

      _completedSubscription = player.stream.completed.listen((isCompleted) {
        if (!isCompleted) {
          return;
        }

        if (mounted) {
          setState(() {
            _isCompleted = true;
          });
        } else {
          _isCompleted = true;
        }
        unawaited(
          _persistProgressSnapshot(progressController, isCompleted: true),
        );
      });

      await player.open(Media(widget.playbackSource.streamUri));
      await _restoreSavedProgress(progressController, player);

      if (!mounted) {
        await _cancelSubscriptions();
        await player.dispose();
        return;
      }

      setState(() {
        _player = player;
        _videoController = videoController;
        _isOpening = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playbackError = error.toString();
        _isOpening = false;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_persistProgressOnExit());
    unawaited(_cancelSubscriptions());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _restoreSavedProgress(
    PlayerProgressController progressController,
    Player player,
  ) async {
    try {
      final savedProgress = await progressController.loadEpisodeProgress(
        widget.sessionContext,
      );
      if (savedProgress == null || savedProgress.isCompleted) {
        return;
      }

      if (savedProgress.position <= Duration.zero) {
        return;
      }

      _latestPosition = savedProgress.position;
      _lastPersistedPosition = savedProgress.position;
      _latestTotalDuration ??= savedProgress.totalDuration;
      await player.seek(savedProgress.position);
    } catch (_) {
      return;
    }
  }

  bool _shouldPersistProgress(Duration position) {
    if (position < PlayerProgressController.minimumPersistedPosition) {
      return false;
    }

    return position - _lastPersistedPosition >= _progressWriteStep;
  }

  Future<void> _persistProgressOnExit() async {
    if (_player == null || _playbackError != null || _isCompleted) {
      return;
    }

    await _persistProgressSnapshot(
      ref.read(playerProgressControllerProvider),
      position: _latestPosition,
    );
  }

  Future<void> _persistProgressSnapshot(
    PlayerProgressController progressController, {
    Duration? position,
    bool isCompleted = false,
  }) async {
    final snapshotPosition = position ?? _latestPosition;
    try {
      await progressController.savePlaybackSnapshot(
        widget.sessionContext,
        position: snapshotPosition,
        totalDuration: _latestTotalDuration,
        isCompleted: isCompleted,
      );
      _lastPersistedPosition = snapshotPosition;
    } catch (_) {
      return;
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _completedSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _errorSubscription?.cancel();
  }

  Future<void> _handlePrimaryPlaybackAction(bool isPlaying) async {
    final player = _player;
    if (player == null) {
      return;
    }

    if (_isCompleted) {
      await _restartPlayback(player);
      return;
    }

    if (isPlaying) {
      await player.pause();
      return;
    }

    await player.play();
  }

  Future<void> _restartPlayback(Player player) async {
    await player.seek(Duration.zero);
    _latestPosition = Duration.zero;
    _lastPersistedPosition = Duration.zero;
    if (mounted) {
      setState(() {
        _isCompleted = false;
      });
    } else {
      _isCompleted = false;
    }
    await player.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_playbackError != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SessionHeader(sessionContext: widget.sessionContext),
          const SizedBox(height: 16),
          const _VideoStageCard(
            title: 'Playback Failed',
            message: 'The stream started to open but could not continue.',
            child: Icon(Icons.error_outline_rounded, size: 36),
          ),
          const SizedBox(height: 16),
          _InfoCard(title: 'Playback Details', child: Text(_playbackError!)),
        ],
      );
    }

    if (_videoController == null || _player == null || _isOpening) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SessionHeader(sessionContext: widget.sessionContext),
          const SizedBox(height: 16),
          _VideoStageCard(
            title: 'Opening Stream',
            message:
                'Opening ${widget.playbackSource.qualityLabel} playback for this episode.',
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Playback Startup',
            child: Text(
              'Saved progress will be restored automatically when available, and new playback progress will sync back to Continue Watching and this series.',
            ),
          ),
        ],
      );
    }

    final streamHost = Uri.tryParse(widget.playbackSource.streamUri)?.host;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SessionHeader(sessionContext: widget.sessionContext),
        const SizedBox(height: 16),
        _PlaybackVideoCard(
          videoController: _videoController!,
          player: _player!,
          isCompleted: _isCompleted,
        ),
        const SizedBox(height: 16),
        _PlaybackControlPanel(
          player: _player!,
          qualityLabel: widget.playbackSource.qualityLabel,
          streamHost: streamHost,
          isCompleted: _isCompleted,
          onPrimaryAction: _handlePrimaryPlaybackAction,
        ),
        const SizedBox(height: 16),
        _WatchFlowContextCard(
          sessionContext: widget.sessionContext,
          isCompleted: _isCompleted,
        ),
        const SizedBox(height: 16),
        StreamBuilder<bool>(
          stream: _player!.stream.playing,
          initialData: true,
          builder: (context, playingSnapshot) {
            final isPlaying = playingSnapshot.data ?? false;
            return StreamBuilder<bool>(
              stream: _player!.stream.buffering,
              initialData: false,
              builder: (context, bufferingSnapshot) {
                final isBuffering = bufferingSnapshot.data ?? false;
                return _InfoCard(
                  title: 'Playback Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlaybackStateBadgeRow(
                        isPlaying: isPlaying,
                        isBuffering: isBuffering,
                        isCompleted: _isCompleted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage(
                          isPlaying: isPlaying,
                          isBuffering: isBuffering,
                          isCompleted: _isCompleted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        if (_isCompleted) ...[
          const SizedBox(height: 16),
          _EpisodeCompletionCard(sessionContext: widget.sessionContext),
        ],
      ],
    );
  }

  String _statusMessage({
    required bool isPlaying,
    required bool isBuffering,
    required bool isCompleted,
  }) {
    if (isCompleted) {
      return 'Playback reached the end of the episode.';
    }

    if (isBuffering) {
      return 'Playback is buffering while the stream catches up.';
    }

    if (isPlaying) {
      return 'Playback is active.';
    }

    return 'Playback is paused and ready to continue.';
  }
}

class _WatchFlowContextCard extends StatelessWidget {
  const _WatchFlowContextCard({
    required this.sessionContext,
    required this.isCompleted,
  });

  final PlayerScreenContext sessionContext;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journeyText = isCompleted
        ? 'This episode is complete. Go back to your previous screen or open the series page to choose what to watch next.'
        : 'Progress saves while you watch. Leaving now returns to your previous screen, and this episode can reappear in Continue Watching until it is finished.';

    return _InfoCard(
      title: 'Watch Journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            journeyText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    AppRoutePaths.seriesDetails(sessionContext.seriesId),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Open Series'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeCompletionCard extends StatelessWidget {
  const _EpisodeCompletionCard({required this.sessionContext});

  final PlayerScreenContext sessionContext;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Episode Finished',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This episode is complete. Return to your previous screen or open the series page to continue with the next available episode.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  AppRoutePaths.seriesDetails(sessionContext.seriesId),
                ),
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Open Series'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.sessionContext});

  final PlayerScreenContext sessionContext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now Watching',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionContext.seriesTitle,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                label: sessionContext.episodeDisplayLabel,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sessionContext.episodeTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackVideoCard extends StatelessWidget {
  const _PlaybackVideoCard({
    required this.videoController,
    required this.player,
    required this.isCompleted,
  });

  final VideoController videoController;
  final Player player;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.black),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(
                controller: videoController,
                controls: NoVideoControls,
                fill: Colors.black,
                fit: BoxFit.contain,
              ),
              StreamBuilder<bool>(
                stream: player.stream.buffering,
                initialData: false,
                builder: (context, snapshot) {
                  if (snapshot.data != true) {
                    return const SizedBox.shrink();
                  }

                  return const ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              StreamBuilder<bool>(
                stream: player.stream.playing,
                initialData: true,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  if (isCompleted) {
                    return const _VideoOverlayMessage(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Episode complete',
                    );
                  }

                  if (isPlaying) {
                    return const SizedBox.shrink();
                  }

                  return const _VideoOverlayMessage(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'Paused',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackControlPanel extends StatelessWidget {
  const _PlaybackControlPanel({
    required this.player,
    required this.qualityLabel,
    required this.streamHost,
    required this.isCompleted,
    required this.onPrimaryAction,
  });

  final Player player;
  final String qualityLabel;
  final String? streamHost;
  final bool isCompleted;
  final Future<void> Function(bool isPlaying) onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<bool>(
      stream: player.stream.playing,
      initialData: true,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;
        final primaryIcon = isCompleted
            ? Icons.replay_rounded
            : isPlaying
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;
        final primaryLabel = isCompleted
            ? 'Replay Episode'
            : isPlaying
            ? 'Pause'
            : 'Play';

        return _InfoCard(
          title: 'Controls',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onPrimaryAction(isPlaying),
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(height: 16),
              _PlaybackProgressSummary(player: player),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderChip(
                    label: qualityLabel,
                    color: theme.colorScheme.primary,
                  ),
                  if (streamHost != null && streamHost!.isNotEmpty)
                    _HeaderChip(
                      label: streamHost!,
                      color: theme.colorScheme.secondary,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaybackProgressSummary extends StatelessWidget {
  const _PlaybackProgressSummary({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<Duration>(
      stream: player.stream.position,
      initialData: Duration.zero,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          initialData: Duration.zero,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final hasDuration = duration > Duration.zero;
            final progressValue = hasDuration
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPlaybackDuration(position),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      hasDuration
                          ? _formatPlaybackDuration(duration)
                          : 'Live duration unknown',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VideoStageCard extends StatelessWidget {
  const _VideoStageCard({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  child,
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackStateBadgeRow extends StatelessWidget {
  const _PlaybackStateBadgeRow({
    required this.isPlaying,
    required this.isBuffering,
    required this.isCompleted,
  });

  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = <Widget>[
      if (isCompleted)
        _HeaderChip(label: 'Complete', color: theme.colorScheme.tertiary)
      else if (isBuffering)
        _HeaderChip(label: 'Buffering', color: theme.colorScheme.secondary)
      else if (isPlaying)
        _HeaderChip(label: 'Playing', color: theme.colorScheme.primary)
      else
        _HeaderChip(label: 'Paused', color: theme.colorScheme.secondary),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _VideoOverlayMessage extends StatelessWidget {
  const _VideoOverlayMessage({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x33000000),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xB2000000),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPlaybackDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
