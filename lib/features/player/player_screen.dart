import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/player/player_playback_providers.dart';
import '../../app/player/player_playback_source.dart';
import '../../app/player/player_progress_providers.dart';
import '../../app/router/app_router.dart';
import 'player_screen_context.dart';

const _playerAccent = Color(0xFFFF7A00);
const _playerOutline = Color(0x26FFFFFF);
const _playerOverlaySurface = Color(0x7A0D0D0D);

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key, this.sessionContext});

  final PlayerScreenContext? sessionContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessionContext == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _MissingSessionContextState()),
      );
    }

    final playbackSourceAsync = ref.watch(
      playerPlaybackSourceProvider(sessionContext!),
    );

    return _PlayerRouteChrome(
      sessionContext: sessionContext!,
      playbackSourceAsync: playbackSourceAsync,
    );
  }
}

class _PlayerRouteChrome extends StatefulWidget {
  const _PlayerRouteChrome({
    required this.sessionContext,
    required this.playbackSourceAsync,
  });

  final PlayerScreenContext sessionContext;
  final AsyncValue<PlayerPlaybackSource> playbackSourceAsync;

  @override
  State<_PlayerRouteChrome> createState() => _PlayerRouteChromeState();
}

class _PlayerRouteChromeState extends State<_PlayerRouteChrome> {
  bool _didInitializeContract = false;
  bool _usesHandsetContract = false;
  bool _isFullscreen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitializeContract) {
      return;
    }

    _didInitializeContract = true;
    _usesHandsetContract = _isHandsetLayout(context);
    _isFullscreen = _usesHandsetContract;
    unawaited(_applyRouteMode(fullscreen: _isFullscreen));
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(
      SystemChrome.setPreferredOrientations(const <DeviceOrientation>[]),
    );
    super.dispose();
  }

  Future<void> _applyRouteMode({required bool fullscreen}) async {
    if (_usesHandsetContract) {
      await SystemChrome.setPreferredOrientations(
        fullscreen
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [DeviceOrientation.portraitUp],
      );
    }

    await SystemChrome.setEnabledSystemUIMode(
      fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _setFullscreen(bool fullscreen) async {
    if (!_usesHandsetContract || _isFullscreen == fullscreen) {
      return;
    }

    setState(() {
      _isFullscreen = fullscreen;
    });

    await _applyRouteMode(fullscreen: fullscreen);
  }

  Future<bool> _handleWillPop() async {
    if (_usesHandsetContract && _isFullscreen) {
      await _setFullscreen(false);
      return false;
    }

    return true;
  }

  Future<void> _handleBackRequested() async {
    final shouldPop = await _handleWillPop();
    if (!mounted || !shouldPop) {
      return;
    }

    Navigator.of(context).maybePop();
  }

  bool _isHandsetLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }

          unawaited(_handleBackRequested());
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: widget.playbackSourceAsync.when(
            loading: () => _PlayerResolutionStage(
              sessionContext: widget.sessionContext,
              title: 'Preparing Playback',
              message: 'Resolving this episode into a playable stream.',
              onBackRequested: _handleBackRequested,
              child: const CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _PlayerResolutionStage(
              sessionContext: widget.sessionContext,
              title: 'Playback Unavailable',
              message: error.toString(),
              onBackRequested: _handleBackRequested,
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            data: (playbackSource) => _ResolvedPlaybackSurface(
              sessionContext: widget.sessionContext,
              playbackSource: playbackSource,
              isFullscreen: _isFullscreen,
              canToggleFullscreen: _usesHandsetContract,
              onToggleFullscreen: () => _setFullscreen(!_isFullscreen),
              onBackRequested: _handleBackRequested,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingSessionContextState extends StatelessWidget {
  const _MissingSessionContextState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: _PlayerGlassPanel(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.96),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PlayerStateIcon(icon: Icons.play_circle_outline_rounded),
                const SizedBox(height: 20),
                Text(
                  'Player Unavailable',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'No watch session was provided. Return to a series and choose an episode to enter playback.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerResolutionStage extends StatelessWidget {
  const _PlayerResolutionStage({
    required this.sessionContext,
    required this.title,
    required this.message,
    required this.child,
    required this.onBackRequested,
  });

  final PlayerScreenContext sessionContext;
  final String title;
  final String message;
  final Widget child;
  final Future<void> Function() onBackRequested;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final showLandscapeLayout =
        media.orientation == Orientation.landscape &&
        media.size.shortestSide >= 600;

    final sessionSummary = _SessionSummaryPanel(
      sessionContext: sessionContext,
      qualityLabel: null,
      streamHost: null,
      statusText: 'Player is preparing this stream.',
      statusLabel: 'Opening',
      primaryActionLabel: 'Back',
      onPrimaryAction: onBackRequested,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Color(0xFF080808)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: showLandscapeLayout
              ? Row(
                  children: [
                    Expanded(
                      child: _StageFrame(
                        child: _StageContent(
                          title: title,
                          message: message,
                          child: child,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(width: 340, child: sessionSummary),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RouteBackButton(onPressed: onBackRequested),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _StageFrame(
                        child: _StageContent(
                          title: title,
                          message: message,
                          child: child,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    sessionSummary,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResolvedPlaybackSurface extends ConsumerStatefulWidget {
  const _ResolvedPlaybackSurface({
    required this.sessionContext,
    required this.playbackSource,
    required this.isFullscreen,
    required this.canToggleFullscreen,
    required this.onToggleFullscreen,
    required this.onBackRequested,
  });

  final PlayerScreenContext sessionContext;
  final PlayerPlaybackSource playbackSource;
  final bool isFullscreen;
  final bool canToggleFullscreen;
  final Future<void> Function() onToggleFullscreen;
  final Future<void> Function() onBackRequested;

  @override
  ConsumerState<_ResolvedPlaybackSurface> createState() =>
      _ResolvedPlaybackSurfaceState();
}

class _ResolvedPlaybackSurfaceState
    extends ConsumerState<_ResolvedPlaybackSurface> {
  static const _progressWriteStep = Duration(seconds: 15);
  static const _controlsAutoHideDelay = Duration(seconds: 3);

  Player? _player;
  VideoController? _videoController;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  Timer? _controlsHideTimer;

  String? _playbackError;
  bool _isOpening = true;
  bool _controlsVisible = true;
  bool _isPlaying = true;
  bool _isBuffering = false;
  bool _isCompleted = false;
  bool _hasOpenedPlayback = false;
  bool _isRecoveringPlaybackError = false;
  int _activeVariantIndex = 0;
  Duration _latestPosition = Duration.zero;
  Duration? _latestTotalDuration;
  Duration _lastPersistedPosition = Duration.zero;

  PlayerPlaybackVariant get _currentVariant =>
      widget.playbackSource.variantAt(_activeVariantIndex);

  String get _activeQualityLabel => _currentVariant.qualityLabel;

  @override
  void initState() {
    super.initState();
    _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
    unawaited(_openPlayback());
  }

  @override
  void didUpdateWidget(covariant _ResolvedPlaybackSurface oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.playbackSource, widget.playbackSource)) {
      _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
    }

    if (widget.isFullscreen && _isPlaying) {
      _scheduleControlsAutoHide();
    } else {
      _showControls();
    }
  }

  Future<void> _openPlayback() async {
    try {
      MediaKit.ensureInitialized();

      final player = Player();
      final videoController = VideoController(player);
      final progressController = ref.read(playerProgressControllerProvider);

      _errorSubscription = player.stream.error.listen((message) {
        if (!_hasOpenedPlayback) {
          return;
        }
        unawaited(_handlePlaybackError(message));
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
        _showControls();
        unawaited(
          _persistProgressSnapshot(progressController, isCompleted: true),
        );
      });

      _playingSubscription = player.stream.playing.listen((isPlaying) {
        if (!mounted) {
          _isPlaying = isPlaying;
          return;
        }

        setState(() {
          _isPlaying = isPlaying;
        });

        if (isPlaying) {
          _scheduleControlsAutoHide();
        } else {
          _showControls();
        }
      });

      _bufferingSubscription = player.stream.buffering.listen((isBuffering) {
        if (!mounted) {
          _isBuffering = isBuffering;
          return;
        }

        setState(() {
          _isBuffering = isBuffering;
        });

        if (isBuffering) {
          _showControls();
        } else {
          _scheduleControlsAutoHide();
        }
      });

      final didOpen = await _openResolvedSource(
        player,
        widget.playbackSource.selectedVariantIndex,
      );
      if (!didOpen) {
        throw StateError(
          'Playback could not be opened from any available stream.',
        );
      }

      _hasOpenedPlayback = true;
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
        _playbackError = null;
      });

      _scheduleControlsAutoHide();
    } catch (error) {
      if (!mounted) {
        _playbackError =
            'Playback could not be opened from any available stream.';
        return;
      }

      setState(() {
        _playbackError =
            'Playback could not be opened from any available stream.';
        _isOpening = false;
      });
      _showControls();
    }
  }

  Future<bool> _openResolvedSource(
    Player player,
    int startIndex, {
    bool restorePosition = false,
  }) async {
    var variantIndex = startIndex;

    while (true) {
      final didOpen = await _openPlaybackVariant(
        player,
        variantIndex,
        restorePosition: restorePosition,
      );
      if (didOpen) {
        return true;
      }

      final nextVariantIndex = widget.playbackSource.nextVariantIndexAfter(
        variantIndex,
      );
      if (nextVariantIndex == null) {
        return false;
      }

      variantIndex = nextVariantIndex;
    }
  }

  Future<bool> _openPlaybackVariant(
    Player player,
    int variantIndex, {
    bool restorePosition = false,
  }) async {
    final variant = widget.playbackSource.variantAt(variantIndex);

    if (mounted) {
      setState(() {
        _activeVariantIndex = variantIndex;
        _isOpening = true;
        _isCompleted = false;
        _playbackError = null;
      });
    } else {
      _activeVariantIndex = variantIndex;
      _isOpening = true;
      _isCompleted = false;
      _playbackError = null;
    }

    try {
      await player.open(Media(variant.sourceUri));

      if (restorePosition && _latestPosition > Duration.zero) {
        try {
          await player.seek(_latestPosition);
        } catch (_) {
          // Recovery seek is best-effort only.
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handlePlaybackError(String message) async {
    final recovered = await _tryRecoverFromPlaybackError();
    if (recovered) {
      return;
    }

    if (!mounted) {
      _playbackError =
          'Playback failed and no other stream remained available.';
      _isOpening = false;
      return;
    }

    setState(() {
      _playbackError =
          'Playback failed and no other stream remained available.';
      _isOpening = false;
    });
    _showControls();
  }

  Future<bool> _tryRecoverFromPlaybackError() async {
    if (_isRecoveringPlaybackError) {
      return false;
    }

    if (_currentVariant.kind != PlayerPlaybackSourceKind.remoteHls) {
      return false;
    }

    final player = _player;
    if (player == null) {
      return false;
    }

    final nextVariantIndex = widget.playbackSource.nextVariantIndexAfter(
      _activeVariantIndex,
    );
    if (nextVariantIndex == null) {
      return false;
    }

    _isRecoveringPlaybackError = true;
    if (mounted) {
      setState(() {
        _isOpening = true;
        _playbackError = null;
      });
    } else {
      _isOpening = true;
      _playbackError = null;
    }

    try {
      final didRecover = await _openResolvedSource(
        player,
        nextVariantIndex,
        restorePosition: _latestPosition > Duration.zero,
      );
      if (!didRecover) {
        return false;
      }

      if (!mounted) {
        _isOpening = false;
        _isCompleted = false;
        return true;
      }

      setState(() {
        _isOpening = false;
        _isCompleted = false;
        _playbackError = null;
      });
      _scheduleControlsAutoHide();
      return true;
    } finally {
      _isRecoveringPlaybackError = false;
    }
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
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
    await _bufferingSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _completedSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _errorSubscription?.cancel();
  }

  void _showControls() {
    _controlsHideTimer?.cancel();

    if (!mounted) {
      _controlsVisible = true;
      return;
    }

    setState(() {
      _controlsVisible = true;
    });
  }

  void _scheduleControlsAutoHide() {
    _controlsHideTimer?.cancel();

    if (!_isPlaying || _isBuffering || _isCompleted) {
      return;
    }

    _controlsHideTimer = Timer(_controlsAutoHideDelay, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _toggleControlsVisibility() {
    if (_controlsVisible) {
      if (!_isPlaying || _isBuffering || _isCompleted) {
        return;
      }

      setState(() {
        _controlsVisible = false;
      });
      return;
    }

    _showControls();
    _scheduleControlsAutoHide();
  }

  Future<void> _handlePrimaryPlaybackAction() async {
    final player = _player;
    if (player == null) {
      return;
    }

    _showControls();

    if (_isCompleted) {
      await _restartPlayback(player);
      _scheduleControlsAutoHide();
      return;
    }

    if (_isPlaying) {
      await player.pause();
      return;
    }

    await player.play();
    _scheduleControlsAutoHide();
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

  Future<void> _seekBy(Duration offset) async {
    final player = _player;
    if (player == null) {
      return;
    }

    final totalDuration = _latestTotalDuration;
    var target = _latestPosition + offset;

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (totalDuration != null && target > totalDuration) {
      target = totalDuration;
    }

    if (_isCompleted && target < (totalDuration ?? Duration.zero)) {
      setState(() {
        _isCompleted = false;
      });
    }

    _showControls();
    await player.seek(target);
    _scheduleControlsAutoHide();
  }

  void _openSeriesHub() {
    context.go(AppRoutePaths.seriesDetails(widget.sessionContext.seriesId));
  }

  bool _isHandsetLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    if (_playbackError != null) {
      return _PlayerResolutionStage(
        sessionContext: widget.sessionContext,
        title: 'Playback Failed',
        message: _playbackError!,
        onBackRequested: widget.onBackRequested,
        child: const Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: Colors.white,
        ),
      );
    }

    if (_videoController == null || _player == null || _isOpening) {
      return _PlayerResolutionStage(
        sessionContext: widget.sessionContext,
        title: 'Opening Stream',
        message: 'Opening $_activeQualityLabel playback for this episode.',
        onBackRequested: widget.onBackRequested,
        child: const CircularProgressIndicator(),
      );
    }

    final isHandset = _isHandsetLayout(context);
    final showHandsetCompanion = isHandset && !widget.isFullscreen;
    final streamHost = Uri.tryParse(_currentVariant.sourceUri)?.host;
    final stage = _PlaybackStage(
      videoController: _videoController!,
      player: _player!,
      sessionContext: widget.sessionContext,
      qualityLabel: _activeQualityLabel,
      isPlaying: _isPlaying,
      isBuffering: _isBuffering,
      isCompleted: _isCompleted,
      controlsVisible: _controlsVisible,
      canToggleFullscreen: widget.canToggleFullscreen,
      isFullscreen: widget.isFullscreen,
      onBackRequested: widget.onBackRequested,
      onOpenSeriesRequested: _openSeriesHub,
      onPrimaryAction: _handlePrimaryPlaybackAction,
      onSeekBackward: () => _seekBy(const Duration(seconds: -10)),
      onSeekForward: () => _seekBy(const Duration(seconds: 10)),
      onToggleFullscreen: widget.onToggleFullscreen,
      onStageTap: _toggleControlsVisibility,
      onTimelineInteractionStart: _showControls,
      onTimelineInteractionEnd: _scheduleControlsAutoHide,
    );

    final companionPanel = _SessionSummaryPanel(
      sessionContext: widget.sessionContext,
      qualityLabel: _activeQualityLabel,
      streamHost: streamHost,
      statusText: _statusMessage(),
      statusLabel: _statusLabel(),
      timeline: _PlaybackTimeline(
        player: _player!,
        textColor: Theme.of(context).colorScheme.onSurface,
        onInteractionStart: _showControls,
        onInteractionEnd: _scheduleControlsAutoHide,
      ),
      primaryActionLabel: widget.canToggleFullscreen && !widget.isFullscreen
          ? 'Enter Fullscreen'
          : 'Open Series',
      onPrimaryAction: widget.canToggleFullscreen && !widget.isFullscreen
          ? widget.onToggleFullscreen
          : () async {
              _openSeriesHub();
            },
      secondaryActionLabel: widget.canToggleFullscreen && !widget.isFullscreen
          ? 'Open Series'
          : null,
      onSecondaryAction: widget.canToggleFullscreen && !widget.isFullscreen
          ? _openSeriesHub
          : null,
    );

    const playerBackdrop = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Color(0xFF080808)],
      ),
    );

    if (showHandsetCompanion) {
      return DecoratedBox(
        decoration: playerBackdrop,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: stage),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  child: companionPanel,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isHandset) {
      return DecoratedBox(decoration: playerBackdrop, child: stage);
    }

    return DecoratedBox(
      decoration: playerBackdrop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _StageFrame(child: stage)),
              const SizedBox(width: 16),
              SizedBox(width: 348, child: companionPanel),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (_isCompleted) {
      return 'Complete';
    }

    if (_isBuffering) {
      return 'Buffering';
    }

    if (_isPlaying) {
      return 'Playing';
    }

    return 'Paused';
  }

  String _statusMessage() {
    if (_isCompleted) {
      return 'This episode is finished. Progress is stored as complete and you can exit to the series hub for the next episode.';
    }

    if (_isBuffering) {
      return 'Playback is active, but the stream is catching up.';
    }

    if (_isPlaying) {
      return 'Playback is active and progress continues syncing back into Continue Watching.';
    }

    return 'Playback is paused and ready to continue from the saved position.';
  }
}

class _PlaybackStage extends StatelessWidget {
  const _PlaybackStage({
    required this.videoController,
    required this.player,
    required this.sessionContext,
    required this.qualityLabel,
    required this.isPlaying,
    required this.isBuffering,
    required this.isCompleted,
    required this.controlsVisible,
    required this.canToggleFullscreen,
    required this.isFullscreen,
    required this.onBackRequested,
    required this.onOpenSeriesRequested,
    required this.onPrimaryAction,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onToggleFullscreen,
    required this.onStageTap,
    required this.onTimelineInteractionStart,
    required this.onTimelineInteractionEnd,
  });

  final VideoController videoController;
  final Player player;
  final PlayerScreenContext sessionContext;
  final String qualityLabel;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final bool controlsVisible;
  final bool canToggleFullscreen;
  final bool isFullscreen;
  final Future<void> Function() onBackRequested;
  final VoidCallback onOpenSeriesRequested;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onSeekBackward;
  final Future<void> Function() onSeekForward;
  final Future<void> Function() onToggleFullscreen;
  final VoidCallback onStageTap;
  final VoidCallback onTimelineInteractionStart;
  final VoidCallback onTimelineInteractionEnd;

  @override
  Widget build(BuildContext context) {
    final effectiveControlsVisible =
        controlsVisible || !isPlaying || isBuffering || isCompleted;
    final playbackStateLabel = isCompleted
        ? 'Complete'
        : isBuffering
        ? 'Buffering'
        : isPlaying
        ? 'Playing'
        : 'Paused';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onStageTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          Video(
            controller: videoController,
            controls: NoVideoControls,
            fill: Colors.black,
            fit: BoxFit.contain,
          ),
          if (isBuffering)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          IgnorePointer(
            ignoring: !effectiveControlsVisible,
            child: AnimatedOpacity(
              opacity: effectiveControlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x15000000),
                      Color(0xD9000000),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      children: [
                        _PlayerGlassPanel(
                          backgroundColor: const Color(0x5E111111),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _OverlayIconButton(
                                icon: Icons.arrow_back_rounded,
                                onPressed: onBackRequested,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _PlayerOverlayEyebrow(
                                      label: 'Now playing',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sessionContext.seriesTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sessionContext.episodeDisplayLabel} • ${sessionContext.episodeTitle}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white70,
                                            height: 1.25,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _OverlayIconButton(
                                icon: Icons.menu_book_rounded,
                                onPressed: () async => onOpenSeriesRequested(),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _PlayerGlassPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _OverlayTransportButton(
                                    icon: Icons.replay_10_rounded,
                                    onPressed: () async {
                                      await onSeekBackward();
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  _OverlayTransportButton(
                                    icon: isCompleted
                                        ? Icons.replay_rounded
                                        : isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    isPrimary: true,
                                    onPressed: () async {
                                      await onPrimaryAction();
                                    },
                                  ),
                                  const SizedBox(width: 20),
                                  _OverlayTransportButton(
                                    icon: Icons.forward_10_rounded,
                                    onPressed: () async {
                                      await onSeekForward();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isCompleted
                                    ? 'Playback finished'
                                    : isPlaying
                                    ? 'Tap to pause or scrub'
                                    : 'Ready to resume',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _PlayerGlassPanel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _PlaybackBadge(
                                    label: sessionContext.episodeDisplayLabel,
                                  ),
                                  _PlaybackBadge(label: qualityLabel),
                                  _PlaybackBadge(label: playbackStateLabel),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _PlaybackTimeline(
                                player: player,
                                textColor: Colors.white,
                                inactiveColor: Colors.white24,
                                onInteractionStart: onTimelineInteractionStart,
                                onInteractionEnd: onTimelineInteractionEnd,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Player controls stay minimal so playback remains dominant.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ),
                                  if (canToggleFullscreen)
                                    TextButton.icon(
                                      onPressed: () {
                                        unawaited(onToggleFullscreen());
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: Icon(
                                        isFullscreen
                                            ? Icons.fullscreen_exit_rounded
                                            : Icons.fullscreen_rounded,
                                      ),
                                      label: Text(
                                        isFullscreen
                                            ? 'Exit Fullscreen'
                                            : 'Enter Fullscreen',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSummaryPanel extends StatelessWidget {
  const _SessionSummaryPanel({
    required this.sessionContext,
    required this.qualityLabel,
    required this.streamHost,
    required this.statusText,
    required this.statusLabel,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.timeline,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final PlayerScreenContext sessionContext;
  final String? qualityLabel;
  final String? streamHost;
  final String statusText;
  final String statusLabel;
  final Widget? timeline;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PlayerGlassPanel(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.98),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PlayerOverlayEyebrow(label: 'Now watching'),
          const SizedBox(height: 8),
          Text(
            sessionContext.seriesTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionContext.episodeTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                label: sessionContext.episodeDisplayLabel,
                color: theme.colorScheme.primary,
              ),
              if (qualityLabel != null)
                _HeaderChip(
                  label: qualityLabel!,
                  color: theme.colorScheme.secondary,
                ),
              if (streamHost != null && streamHost!.isNotEmpty)
                _HeaderChip(
                  label: streamHost!,
                  color: theme.colorScheme.tertiary,
                ),
              _HeaderChip(label: statusLabel, color: theme.colorScheme.primary),
            ],
          ),
          if (timeline != null) ...[
            const SizedBox(height: 22),
            _PlayerGlassPanel(
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              padding: const EdgeInsets.all(14),
              child: timeline!,
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Playback status',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                unawaited(onPrimaryAction());
              },
              child: Text(primaryActionLabel),
            ),
          ),
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaybackTimeline extends StatefulWidget {
  const _PlaybackTimeline({
    required this.player,
    required this.textColor,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    this.inactiveColor,
  });

  final Player player;
  final Color textColor;
  final Color? inactiveColor;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  @override
  State<_PlaybackTimeline> createState() => _PlaybackTimelineState();
}

class _PlaybackTimelineState extends State<_PlaybackTimeline> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      initialData: Duration.zero,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          initialData: Duration.zero,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final hasDuration = duration > Duration.zero;
            final currentValue = hasDuration
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0;
            final displayedValue = _dragValue ?? currentValue;
            final displayedPosition = hasDuration
                ? Duration(
                    milliseconds: (duration.inMilliseconds * displayedValue)
                        .round(),
                  )
                : position;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: widget.textColor,
                    inactiveTrackColor:
                        widget.inactiveColor ??
                        widget.textColor.withValues(alpha: 0.24),
                    thumbColor: widget.textColor,
                  ),
                  child: Slider(
                    value: displayedValue,
                    onChangeStart: hasDuration
                        ? (_) => widget.onInteractionStart()
                        : null,
                    onChanged: hasDuration
                        ? (value) {
                            setState(() {
                              _dragValue = value;
                            });
                          }
                        : null,
                    onChangeEnd: hasDuration
                        ? (value) async {
                            final target = Duration(
                              milliseconds: (duration.inMilliseconds * value)
                                  .round(),
                            );
                            await widget.player.seek(target);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _dragValue = null;
                            });
                            widget.onInteractionEnd();
                          }
                        : null,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPlaybackDuration(displayedPosition),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.textColor,
                        ),
                      ),
                    ),
                    Text(
                      hasDuration
                          ? _formatPlaybackDuration(duration)
                          : 'Duration unknown',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.textColor.withValues(alpha: 0.78),
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

class _StageFrame extends StatelessWidget {
  const _StageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _playerOutline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _StageContent extends StatelessWidget {
  const _StageContent({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: _PlayerGlassPanel(
            backgroundColor: _playerOverlaySurface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PlayerOverlayEyebrow(label: 'Playback'),
                const SizedBox(height: 14),
                _PlayerStateIcon(child: child),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerGlassPanel extends StatelessWidget {
  const _PlayerGlassPanel({
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? _playerOverlaySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _playerOutline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PlayerOverlayEyebrow extends StatelessWidget {
  const _PlayerOverlayEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: _playerAccent,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PlayerStateIcon extends StatelessWidget {
  const _PlayerStateIcon({this.icon, this.child});

  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child ?? Icon(icon, color: Colors.white, size: 34),
    );
  }
}

class _RouteBackButton extends StatelessWidget {
  const _RouteBackButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _OverlayIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: onPressed,
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: IconButton(
        onPressed: () {
          unawaited(onPressed());
        },
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _OverlayTransportButton extends StatelessWidget {
  const _OverlayTransportButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFFFF8F1F), Color(0xFFFF6A00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: isPrimary
            ? const [
                BoxShadow(
                  color: Color(0x55FF7A00),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: isPrimary ? 72 : 56,
        height: isPrimary ? 72 : 56,
        child: IconButton(
          onPressed: () {
            unawaited(onPressed());
          },
          icon: Icon(
            icon,
            color: isPrimary ? Colors.black : Colors.white,
            size: isPrimary ? 34 : 24,
          ),
        ),
      ),
    );
  }
}

class _PlaybackBadge extends StatelessWidget {
  const _PlaybackBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
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
