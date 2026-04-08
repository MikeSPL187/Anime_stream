import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/player/player_autoplay_next.dart';
import '../../app/player/player_playback_providers.dart';
import '../../app/player/player_playback_speed.dart';
import '../../app/player/player_playback_source.dart';
import '../../app/player/player_stage_copy.dart';
import '../../app/player/player_progress_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/settings/playback_preferences_providers.dart';
import 'player_screen_context.dart';

const _playerAccent = Color(0xFFFF7A00);
const _playerOutline = Color(0x14FFFFFF);
const _playerOverlaySurface = Color(0x520B0B0B);
const _playerBackdrop = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black, Color(0xFF080808)],
  ),
);

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, this.sessionContext});

  final PlayerScreenContext? sessionContext;

  @override
  Widget build(BuildContext context) {
    if (sessionContext == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: _MissingSessionContextState()),
      );
    }

    return _PlayerRouteChrome(sessionContext: sessionContext!);
  }
}

class _PlayerRouteChrome extends ConsumerStatefulWidget {
  const _PlayerRouteChrome({required this.sessionContext});

  final PlayerScreenContext sessionContext;

  @override
  ConsumerState<_PlayerRouteChrome> createState() => _PlayerRouteChromeState();
}

class _PlayerRouteChromeState extends ConsumerState<_PlayerRouteChrome> {
  bool _didInitializeContract = false;
  bool _usesHandsetContract = false;
  bool _isFullscreen = false;
  double _playbackRate = 1.0;
  late PlayerScreenContext _activeSessionContext;

  @override
  void initState() {
    super.initState();
    _activeSessionContext = widget.sessionContext;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitializeContract) {
      return;
    }

    _didInitializeContract = true;
    _usesHandsetContract = _isHandsetLayout(context);

    // Handsets should open into a portrait watch surface first, then let the
    // viewer opt into immersive fullscreen playback.
    _isFullscreen = false;
    unawaited(_applyRouteMode(fullscreen: _isFullscreen));
  }

  @override
  void didUpdateWidget(covariant _PlayerRouteChrome oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sessionContext != widget.sessionContext) {
      _activeSessionContext = widget.sessionContext;
    }
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

  Future<void> _switchEpisode(PlayerScreenContext nextContext) async {
    if (_activeSessionContext == nextContext) {
      return;
    }

    setState(() {
      _activeSessionContext = nextContext;
    });
  }

  void _handlePlaybackRateChanged(double playbackRate) {
    final normalizedRate = normalizePlayerPlaybackRate(playbackRate);
    if ((_playbackRate - normalizedRate).abs() < 0.001) {
      return;
    }

    setState(() {
      _playbackRate = normalizedRate;
    });
  }

  Future<void> _retryPlaybackSourceResolution() async {
    ref.invalidate(playerPlaybackSourceProvider(_activeSessionContext));
  }

  bool _isHandsetLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  @override
  Widget build(BuildContext context) {
    final playbackSourceAsync = ref.watch(
      playerPlaybackSourceProvider(_activeSessionContext),
    );

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
          body: playbackSourceAsync.when(
            loading: () => _PlayerResolutionStage(
              sessionContext: _activeSessionContext,
              title: 'Preparing Playback',
              message: 'Resolving this episode into a playable stream.',
              onBackRequested: _handleBackRequested,
              child: const CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _PlayerResolutionStage(
              sessionContext: _activeSessionContext,
              title: 'Playback Unavailable',
              message: error.toString(),
              onBackRequested: _handleBackRequested,
              statusLabel: 'Unavailable',
              statusText:
                  'Player could not resolve a stream for this episode right now.',
              primaryActionIcon: Icons.refresh_rounded,
              primaryActionLabel: 'Retry',
              onPrimaryAction: _retryPlaybackSourceResolution,
              secondaryActionIcon: Icons.arrow_back_rounded,
              secondaryActionLabel: 'Back',
              onSecondaryAction: _handleBackRequested,
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            data: (playbackSource) => _ResolvedPlaybackSurface(
              key: ValueKey(
                '${_activeSessionContext.seriesId}:${_activeSessionContext.episodeId}',
              ),
              sessionContext: _activeSessionContext,
              playbackSource: playbackSource,
              isFullscreen: _isFullscreen,
              canToggleFullscreen: _usesHandsetContract,
              onToggleFullscreen: () => _setFullscreen(!_isFullscreen),
              onBackRequested: _handleBackRequested,
              onPlayNextEpisodeRequested: _switchEpisode,
              initialPlaybackRate: _playbackRate,
              onPlaybackRateChanged: _handlePlaybackRateChanged,
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
      padding: const EdgeInsets.all(20),
      child: _PlayerGlassPanel(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.96),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PlayerStateIcon(icon: Icons.play_circle_outline_rounded),
                const SizedBox(height: 18),
                Text(
                  'Player unavailable',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Return to a series and choose an episode to enter playback.',
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
    this.statusLabel = 'Opening',
    this.statusText = 'Player is preparing this stream.',
    this.primaryActionIcon = Icons.arrow_back_rounded,
    this.primaryActionLabel = 'Back',
    this.onPrimaryAction,
    this.secondaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final PlayerScreenContext sessionContext;
  final String title;
  final String message;
  final Widget child;
  final Future<void> Function() onBackRequested;
  final String statusLabel;
  final String statusText;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function()? onPrimaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionLabel;
  final Future<void> Function()? onSecondaryAction;

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
      statusText: statusText,
      statusLabel: statusLabel,
      primaryActionIcon: primaryActionIcon,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction ?? onBackRequested,
      secondaryActionIcon: secondaryActionIcon,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction == null
          ? null
          : () {
              unawaited(onSecondaryAction!());
            },
    );

    return DecoratedBox(
      decoration: _playerBackdrop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                    const SizedBox(width: 14),
                    SizedBox(width: 320, child: sessionSummary),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RouteBackButton(onPressed: onBackRequested),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _StageFrame(
                        child: _StageContent(
                          title: title,
                          message: message,
                          child: child,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CompactSessionSummary(
                      sessionContext: sessionContext,
                      qualityLabel: null,
                      statusLabel: statusLabel,
                      statusText: statusText,
                      primaryActionIcon: primaryActionIcon,
                      primaryActionLabel: primaryActionLabel,
                      onPrimaryAction: onPrimaryAction ?? onBackRequested,
                      secondaryActionIcon: secondaryActionIcon,
                      secondaryActionLabel: secondaryActionLabel,
                      onSecondaryAction: onSecondaryAction == null
                          ? null
                          : () {
                              unawaited(onSecondaryAction!());
                            },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResolvedPlaybackSurface extends ConsumerStatefulWidget {
  const _ResolvedPlaybackSurface({
    super.key,
    required this.sessionContext,
    required this.playbackSource,
    required this.isFullscreen,
    required this.canToggleFullscreen,
    required this.onToggleFullscreen,
    required this.onBackRequested,
    required this.onPlayNextEpisodeRequested,
    required this.initialPlaybackRate,
    required this.onPlaybackRateChanged,
  });

  final PlayerScreenContext sessionContext;
  final PlayerPlaybackSource playbackSource;
  final bool isFullscreen;
  final bool canToggleFullscreen;
  final Future<void> Function() onToggleFullscreen;
  final Future<void> Function() onBackRequested;
  final Future<void> Function(PlayerScreenContext nextContext)
  onPlayNextEpisodeRequested;
  final double initialPlaybackRate;
  final ValueChanged<double> onPlaybackRateChanged;

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
  StreamSubscription<double>? _rateSubscription;
  Timer? _controlsHideTimer;
  Timer? _autoplayNextEpisodeTimer;

  String? _playbackError;
  bool _isOpening = true;
  PlayerPlaybackOpeningPhase _openingPhase =
      PlayerPlaybackOpeningPhase.openingStream;
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
  double _playbackRate = 1.0;
  PlayerScreenContext? _autoplayNextEpisodeContext;
  int _autoplayNextEpisodeSecondsRemaining = 0;
  String? _autoplaySuppressedEpisodeId;

  PlayerPlaybackVariant get _currentVariant =>
      widget.playbackSource.variantAt(_activeVariantIndex);

  String get _activeQualityLabel => _currentVariant.qualityLabel;

  List<PlayerPlaybackQualityOption> get _qualityOptions => widget.playbackSource
      .qualityOptions(activeVariantIndex: _activeVariantIndex);

  bool get _supportsManualQualitySelection =>
      widget.playbackSource.supportsManualQualitySelection;

  List<PlayerPlaybackSpeedOption> get _speedOptions =>
      buildPlayerPlaybackSpeedOptions(activeRate: _playbackRate);

  void _showPlaybackNotice(String message) {
    if (!mounted || message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setOpeningState(
    PlayerPlaybackOpeningPhase openingPhase, {
    int? variantIndex,
  }) {
    if (!mounted) {
      _openingPhase = openingPhase;
      _isOpening = true;
      _isCompleted = false;
      _playbackError = null;
      if (variantIndex != null) {
        _activeVariantIndex = variantIndex;
      }
      return;
    }

    setState(() {
      _openingPhase = openingPhase;
      _isOpening = true;
      _isCompleted = false;
      _playbackError = null;
      if (variantIndex != null) {
        _activeVariantIndex = variantIndex;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
    _playbackRate = normalizePlayerPlaybackRate(widget.initialPlaybackRate);
    unawaited(_openPlayback());
  }

  @override
  void didUpdateWidget(covariant _ResolvedPlaybackSurface oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.sessionContext != widget.sessionContext) {
      _cancelAutoplayNextEpisode();
      _autoplaySuppressedEpisodeId = null;
    }

    if (!identical(oldWidget.playbackSource, widget.playbackSource)) {
      _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
    }

    if (widget.isFullscreen && _isPlaying) {
      _scheduleControlsAutoHide();
    } else {
      _showControls();
    }
  }

  Future<void> _openPlayback({
    PlayerPlaybackOpeningPhase openingPhase =
        PlayerPlaybackOpeningPhase.openingStream,
  }) async {
    _setOpeningState(openingPhase);

    Player? player;
    try {
      try {
        final preferences = await ref.read(
          playbackPreferencesControllerProvider.future,
        );
        if ((_playbackRate - 1.0).abs() < 0.001) {
          _playbackRate = normalizePlayerPlaybackRate(
            preferences.defaultPlaybackSpeed,
          );
        }
      } catch (_) {
        // Player should still open on default settings when preference restore fails.
      }

      MediaKit.ensureInitialized();
      final requestedQualityLabel =
          widget.playbackSource.activeVariant.qualityLabel;

      player = Player();
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
        unawaited(_prepareAutoplayNextEpisode());
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
      if ((_playbackRate - 1.0).abs() >= 0.001) {
        try {
          await player.setRate(_playbackRate);
          widget.onPlaybackRateChanged(_playbackRate);
        } catch (_) {
          _playbackRate = 1.0;
          widget.onPlaybackRateChanged(_playbackRate);
        }
      }
      await _restoreSavedProgress(progressController, player);

      _rateSubscription = player.stream.rate.listen((playbackRate) {
        final normalizedRate = normalizePlayerPlaybackRate(playbackRate);

        widget.onPlaybackRateChanged(normalizedRate);

        if (!mounted) {
          _playbackRate = normalizedRate;
          return;
        }

        setState(() {
          _playbackRate = normalizedRate;
        });
      });

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

      if (_activeQualityLabel != requestedQualityLabel) {
        _showPlaybackNotice(
          'Opened $_activeQualityLabel because $requestedQualityLabel was unavailable.',
        );
      }
      _scheduleControlsAutoHide();
    } catch (error) {
      await _cancelSubscriptions();
      await player?.dispose();

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
    _setOpeningState(_openingPhase, variantIndex: variantIndex);

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
    final previousQualityLabel = _activeQualityLabel;

    final nextVariantIndex = widget.playbackSource.nextVariantIndexAfter(
      _activeVariantIndex,
    );
    if (nextVariantIndex == null) {
      return false;
    }

    _isRecoveringPlaybackError = true;
    _setOpeningState(
      PlayerPlaybackOpeningPhase.recoveringPlayback,
      variantIndex: nextVariantIndex,
    );

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
      if (_activeQualityLabel != previousQualityLabel) {
        _showPlaybackNotice(
          'Playback recovered on $_activeQualityLabel to keep the stream running.',
        );
      }
      _scheduleControlsAutoHide();
      return true;
    } finally {
      _isRecoveringPlaybackError = false;
    }
  }

  @override
  void dispose() {
    _cancelAutoplayNextEpisode(updateState: false);
    _controlsHideTimer?.cancel();
    unawaited(_persistProgressOnExit());
    unawaited(_cancelSubscriptions());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _prepareAutoplayNextEpisode() async {
    final completedSessionContext = widget.sessionContext;
    if (_autoplaySuppressedEpisodeId == completedSessionContext.episodeId) {
      return;
    }

    try {
      final preferences = await ref.read(
        playbackPreferencesControllerProvider.future,
      );
      if (!preferences.autoplayNextEpisode) {
        return;
      }

      final nextEpisodeContext = await ref.read(
        playerNextEpisodeContextProvider(completedSessionContext).future,
      );
      if (nextEpisodeContext == null ||
          !mounted ||
          !_isCompleted ||
          widget.sessionContext != completedSessionContext ||
          _autoplaySuppressedEpisodeId == completedSessionContext.episodeId) {
        return;
      }

      _startAutoplayNextEpisodeCountdown(nextEpisodeContext);
    } catch (_) {
      return;
    }
  }

  void _startAutoplayNextEpisodeCountdown(PlayerScreenContext nextEpisode) {
    final sessionEpisodeId = widget.sessionContext.episodeId;
    if (_autoplayNextEpisodeContext == nextEpisode &&
        _autoplayNextEpisodeTimer != null) {
      return;
    }

    _autoplayNextEpisodeTimer?.cancel();
    if (mounted) {
      setState(() {
        _autoplayNextEpisodeContext = nextEpisode;
        _autoplayNextEpisodeSecondsRemaining =
            playerAutoplayNextEpisodeDelay.inSeconds;
      });
    } else {
      _autoplayNextEpisodeContext = nextEpisode;
      _autoplayNextEpisodeSecondsRemaining =
          playerAutoplayNextEpisodeDelay.inSeconds;
    }

    _autoplayNextEpisodeTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      if (!mounted ||
          !_isCompleted ||
          widget.sessionContext.episodeId != sessionEpisodeId ||
          _autoplaySuppressedEpisodeId == sessionEpisodeId) {
        timer.cancel();
        return;
      }

      if (_autoplayNextEpisodeSecondsRemaining <= 1) {
        timer.cancel();
        final autoplayTarget = _autoplayNextEpisodeContext;
        _cancelAutoplayNextEpisode();
        if (autoplayTarget != null) {
          unawaited(_playNextEpisode(autoplayTarget));
        }
        return;
      }

      setState(() {
        _autoplayNextEpisodeSecondsRemaining -= 1;
      });
    });
  }

  void _cancelAutoplayNextEpisode({
    bool suppressCurrentEpisode = false,
    bool updateState = true,
  }) {
    _autoplayNextEpisodeTimer?.cancel();
    _autoplayNextEpisodeTimer = null;

    if (!mounted || !updateState) {
      _autoplayNextEpisodeContext = null;
      _autoplayNextEpisodeSecondsRemaining = 0;
      if (suppressCurrentEpisode) {
        _autoplaySuppressedEpisodeId = widget.sessionContext.episodeId;
      }
      return;
    }

    setState(() {
      _autoplayNextEpisodeContext = null;
      _autoplayNextEpisodeSecondsRemaining = 0;
      if (suppressCurrentEpisode) {
        _autoplaySuppressedEpisodeId = widget.sessionContext.episodeId;
      }
    });
  }

  void _clearAutoplaySuppression() {
    if (_autoplaySuppressedEpisodeId == null) {
      return;
    }
    _autoplaySuppressedEpisodeId = null;
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
    final rateSubscription = _rateSubscription;
    final bufferingSubscription = _bufferingSubscription;
    final playingSubscription = _playingSubscription;
    final completedSubscription = _completedSubscription;
    final durationSubscription = _durationSubscription;
    final positionSubscription = _positionSubscription;
    final errorSubscription = _errorSubscription;

    _rateSubscription = null;
    _bufferingSubscription = null;
    _playingSubscription = null;
    _completedSubscription = null;
    _durationSubscription = null;
    _positionSubscription = null;
    _errorSubscription = null;

    await rateSubscription?.cancel();
    await bufferingSubscription?.cancel();
    await playingSubscription?.cancel();
    await completedSubscription?.cancel();
    await durationSubscription?.cancel();
    await positionSubscription?.cancel();
    await errorSubscription?.cancel();
  }

  Future<void> _disposePlaybackResources() async {
    final player = _player;
    _player = null;
    _videoController = null;
    await _cancelSubscriptions();
    await player?.dispose();
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

    if (widget.canToggleFullscreen && !widget.isFullscreen) {
      return;
    }

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
    if (widget.canToggleFullscreen && !widget.isFullscreen) {
      _showControls();
      return;
    }

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
    _cancelAutoplayNextEpisode();
    _clearAutoplaySuppression();
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
      _cancelAutoplayNextEpisode();
      _clearAutoplaySuppression();
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

  Future<void> _playNextEpisode(PlayerScreenContext nextContext) async {
    _cancelAutoplayNextEpisode();
    _clearAutoplaySuppression();
    _showControls();
    await widget.onPlayNextEpisodeRequested(nextContext);
  }

  Future<void> _retryPlayback() async {
    if (_isOpening) {
      return;
    }

    _cancelAutoplayNextEpisode();
    _clearAutoplaySuppression();

    if (_latestPosition > Duration.zero && !_isCompleted) {
      await _persistProgressSnapshot(
        ref.read(playerProgressControllerProvider),
        position: _latestPosition,
      );
    }

    await _disposePlaybackResources();

    if (mounted) {
      setState(() {
        _isBuffering = false;
        _isPlaying = true;
        _hasOpenedPlayback = false;
        _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
      });
    } else {
      _isBuffering = false;
      _isPlaying = true;
      _hasOpenedPlayback = false;
      _activeVariantIndex = widget.playbackSource.selectedVariantIndex;
    }

    await _openPlayback(
      openingPhase: PlayerPlaybackOpeningPhase.retryingPlayback,
    );
  }

  Future<void> _openQualitySelector() async {
    if (!_supportsManualQualitySelection ||
        _isOpening ||
        _isCompleted ||
        _player == null) {
      return;
    }

    final selectedVariantIndex = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return _PlaybackQualitySheet(
          activeQualityLabel: _activeQualityLabel,
          options: _qualityOptions,
        );
      },
    );

    if (!mounted || selectedVariantIndex == null) {
      return;
    }

    await _switchPlaybackQuality(selectedVariantIndex);
  }

  Future<void> _openPlaybackSpeedSelector() async {
    final player = _player;
    if (_isOpening || _isCompleted || player == null) {
      return;
    }

    final selectedRate = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return _PlaybackSpeedSheet(
          activeRateLabel: formatPlayerPlaybackRateLabel(_playbackRate),
          options: _speedOptions,
        );
      },
    );

    if (!mounted || selectedRate == null) {
      return;
    }

    await _switchPlaybackSpeed(selectedRate);
  }

  Future<void> _switchPlaybackQuality(int variantIndex) async {
    final player = _player;
    if (player == null ||
        _isOpening ||
        _isRecoveringPlaybackError ||
        variantIndex == _activeVariantIndex) {
      return;
    }

    final previousVariantIndex = _activeVariantIndex;
    final previousQualityLabel = _activeQualityLabel;
    final selectedQualityLabel = widget.playbackSource
        .variantAt(variantIndex)
        .qualityLabel;
    final resumePosition = _latestPosition;
    final shouldRestorePosition = resumePosition > Duration.zero;
    final wasPlaying = _isPlaying && !_isCompleted;
    final progressController = ref.read(playerProgressControllerProvider);

    _showControls();
    await _persistProgressSnapshot(
      progressController,
      position: resumePosition,
    );

    _setOpeningState(
      PlayerPlaybackOpeningPhase.switchingQuality,
      variantIndex: variantIndex,
    );

    final didSwitch = await _openPlaybackVariant(
      player,
      variantIndex,
      restorePosition: shouldRestorePosition,
    );
    if (!didSwitch) {
      final reverted = await _openPlaybackVariant(
        player,
        previousVariantIndex,
        restorePosition: shouldRestorePosition,
      );
      if (!reverted) {
        if (!mounted) {
          _playbackError =
              'Playback could not switch quality and no working stream remained available.';
          _isOpening = false;
          return;
        }

        setState(() {
          _playbackError =
              'Playback could not switch quality and no working stream remained available.';
          _isOpening = false;
        });
        _showControls();
        return;
      }

      if (!wasPlaying) {
        await player.pause();
      }

      if (!mounted) {
        _isOpening = false;
        _playbackError = null;
        return;
      }

      setState(() {
        _isOpening = false;
        _playbackError = null;
        _isCompleted = false;
      });
      _showControls();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$selectedQualityLabel is unavailable right now. '
              'Playback stayed on $previousQualityLabel.',
            ),
          ),
        );
      return;
    }

    if (!wasPlaying) {
      await player.pause();
    }

    if (!mounted) {
      _isOpening = false;
      _playbackError = null;
      _isCompleted = false;
      return;
    }

    setState(() {
      _isOpening = false;
      _playbackError = null;
      _isCompleted = false;
    });

    if (wasPlaying) {
      _scheduleControlsAutoHide();
    } else {
      _showControls();
    }
  }

  Future<void> _switchPlaybackSpeed(double playbackRate) async {
    final player = _player;
    if (player == null || _isOpening) {
      return;
    }

    final normalizedRate = normalizePlayerPlaybackRate(playbackRate);
    if ((_playbackRate - normalizedRate).abs() < 0.001) {
      return;
    }

    _showControls();

    try {
      await player.setRate(normalizedRate);
      if (!mounted) {
        _playbackRate = normalizedRate;
        widget.onPlaybackRateChanged(normalizedRate);
        return;
      }

      setState(() {
        _playbackRate = normalizedRate;
      });
      widget.onPlaybackRateChanged(normalizedRate);

      if (_isPlaying) {
        _scheduleControlsAutoHide();
      }
    } catch (_) {
      _showPlaybackNotice('Playback speed could not be changed right now.');
    }
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
        statusLabel: 'Retry ready',
        statusText: 'Playback stopped and is waiting for another attempt.',
        primaryActionIcon: Icons.refresh_rounded,
        primaryActionLabel: 'Retry Stream',
        onPrimaryAction: _retryPlayback,
        secondaryActionIcon: Icons.arrow_back_rounded,
        secondaryActionLabel: 'Back',
        onSecondaryAction: widget.onBackRequested,
        child: const Icon(
          Icons.error_outline_rounded,
          size: 36,
          color: Colors.white,
        ),
      );
    }

    if (_videoController == null || _player == null || _isOpening) {
      final openingStage = buildPlayerOpeningStageCopy(
        phase: _openingPhase,
        qualityLabel: _activeQualityLabel,
      );
      return _PlayerResolutionStage(
        sessionContext: widget.sessionContext,
        title: openingStage.title,
        message: openingStage.message,
        onBackRequested: widget.onBackRequested,
        statusLabel: openingStage.statusLabel,
        statusText: openingStage.statusText,
        child: const CircularProgressIndicator(),
      );
    }

    final isHandset = _isHandsetLayout(context);
    final showHandsetCompanion = isHandset && !widget.isFullscreen;
    final streamHost = Uri.tryParse(_currentVariant.sourceUri)?.host;
    final previousEpisodeContext = ref
        .watch(playerPreviousEpisodeContextProvider(widget.sessionContext))
        .asData
        ?.value;
    final nextEpisodeAsync = _isCompleted
        ? ref.watch(playerNextEpisodeContextProvider(widget.sessionContext))
        : null;
    final nextEpisodeContext =
        nextEpisodeAsync?.asData?.value ?? _autoplayNextEpisodeContext;
    final previousEpisodeActionLabel = previousEpisodeContext == null
        ? null
        : 'Previous Episode ${previousEpisodeContext.episodeNumberLabel}';
    final autoplayNextEpisodeActive =
        _autoplayNextEpisodeContext != null &&
        _autoplayNextEpisodeSecondsRemaining > 0;
    final nextEpisodeActionLabel = nextEpisodeContext == null
        ? null
        : autoplayNextEpisodeActive
        ? formatPlayerAutoplayNextEpisodeLabel(
            episodeNumberLabel: nextEpisodeContext.episodeNumberLabel,
            secondsRemaining: _autoplayNextEpisodeSecondsRemaining,
          )
        : 'Next Episode ${nextEpisodeContext.episodeNumberLabel}';
    final cancelAutoplayActionLabel = autoplayNextEpisodeActive
        ? 'Stay Here'
        : null;
    final speedActionLabel = !_isCompleted
        ? 'Speed ${formatPlayerPlaybackRateLabel(_playbackRate)}'
        : null;
    final qualityActionLabel = _supportsManualQualitySelection && !_isCompleted
        ? 'Quality $_activeQualityLabel'
        : null;
    final summaryPrimaryActionIcon = nextEpisodeContext != null
        ? Icons.skip_next_rounded
        : widget.canToggleFullscreen && !widget.isFullscreen
        ? Icons.fullscreen_rounded
        : Icons.menu_book_rounded;
    final summaryPrimaryActionLabel =
        nextEpisodeActionLabel ??
        (widget.canToggleFullscreen && !widget.isFullscreen
            ? 'Enter Fullscreen'
            : 'Open Series');
    final summaryPrimaryAction = nextEpisodeContext != null
        ? () => _playNextEpisode(nextEpisodeContext)
        : widget.canToggleFullscreen && !widget.isFullscreen
        ? widget.onToggleFullscreen
        : () async {
            _openSeriesHub();
          };
    final summarySecondaryActionIcon = autoplayNextEpisodeActive
        ? Icons.close_rounded
        : nextEpisodeContext != null
        ? Icons.menu_book_rounded
        : widget.canToggleFullscreen && !widget.isFullscreen
        ? Icons.menu_book_rounded
        : null;
    final summarySecondaryActionLabel = autoplayNextEpisodeActive
        ? cancelAutoplayActionLabel
        : nextEpisodeContext != null
        ? 'Open Series'
        : widget.canToggleFullscreen && !widget.isFullscreen
        ? 'Open Series'
        : null;
    final summarySecondaryAction = autoplayNextEpisodeActive
        ? () => _cancelAutoplayNextEpisode(suppressCurrentEpisode: true)
        : nextEpisodeContext != null
        ? _openSeriesHub
        : widget.canToggleFullscreen && !widget.isFullscreen
        ? _openSeriesHub
        : null;
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
      previousEpisodeActionLabel: previousEpisodeActionLabel,
      onPlayPreviousEpisodeRequested: previousEpisodeContext == null
          ? null
          : () => _playNextEpisode(previousEpisodeContext),
      nextEpisodeActionLabel: nextEpisodeActionLabel,
      onPlayNextEpisodeRequested: nextEpisodeContext == null
          ? null
          : () => _playNextEpisode(nextEpisodeContext),
      cancelAutoplayActionLabel: cancelAutoplayActionLabel,
      onCancelAutoplayRequested: cancelAutoplayActionLabel == null
          ? null
          : () async {
              _cancelAutoplayNextEpisode(suppressCurrentEpisode: true);
            },
      speedActionLabel: speedActionLabel,
      onSpeedRequested: speedActionLabel == null
          ? null
          : _openPlaybackSpeedSelector,
      qualityActionLabel: qualityActionLabel,
      onQualityRequested: qualityActionLabel == null
          ? null
          : _openQualitySelector,
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
      primaryActionIcon: summaryPrimaryActionIcon,
      primaryActionLabel: summaryPrimaryActionLabel,
      onPrimaryAction: summaryPrimaryAction,
      secondaryActionIcon: summarySecondaryActionIcon,
      secondaryActionLabel: summarySecondaryActionLabel,
      onSecondaryAction: summarySecondaryAction,
      speedActionLabel: speedActionLabel,
      onSpeedAction: speedActionLabel == null
          ? null
          : _openPlaybackSpeedSelector,
      qualityActionLabel: qualityActionLabel,
      onQualityAction: qualityActionLabel == null ? null : _openQualitySelector,
    );

    if (showHandsetCompanion) {
      return DecoratedBox(
        decoration: _playerBackdrop,
        child: Column(
          children: [
            Expanded(child: stage),
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.paddingOf(context).bottom + 12,
              ),
              child: _CompactSessionSummary(
                sessionContext: widget.sessionContext,
                qualityLabel: _activeQualityLabel,
                statusLabel: _statusLabel(),
                statusText: _statusMessage(),
                primaryActionIcon: summaryPrimaryActionIcon,
                primaryActionLabel: summaryPrimaryActionLabel,
                onPrimaryAction: summaryPrimaryAction,
                secondaryActionIcon: summarySecondaryActionIcon,
                secondaryActionLabel: summarySecondaryActionLabel,
                onSecondaryAction: summarySecondaryAction,
                speedActionLabel: speedActionLabel,
                onSpeedAction: speedActionLabel == null
                    ? null
                    : _openPlaybackSpeedSelector,
                qualityActionLabel: qualityActionLabel,
                onQualityAction: qualityActionLabel == null
                    ? null
                    : _openQualitySelector,
              ),
            ),
          ],
        ),
      );
    }

    if (isHandset) {
      return DecoratedBox(decoration: _playerBackdrop, child: stage);
    }

    return DecoratedBox(
      decoration: _playerBackdrop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(child: _StageFrame(child: stage)),
              const SizedBox(width: 14),
              SizedBox(width: 332, child: companionPanel),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (_autoplayNextEpisodeContext != null &&
        _autoplayNextEpisodeSecondsRemaining > 0) {
      return 'Up next';
    }

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
    if (_autoplayNextEpisodeContext != null &&
        _autoplayNextEpisodeSecondsRemaining > 0) {
      return formatPlayerAutoplayNextEpisodeStatus(
        _autoplayNextEpisodeSecondsRemaining,
      );
    }

    if (_isCompleted) {
      return 'Episode finished. Progress is stored as complete.';
    }

    if (_isBuffering) {
      return 'Playback is active, but the stream is catching up.';
    }

    if (_isPlaying) {
      return 'Playback is active and progress is syncing.';
    }

    return 'Playback is paused and ready to resume.';
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
    this.previousEpisodeActionLabel,
    this.onPlayPreviousEpisodeRequested,
    this.nextEpisodeActionLabel,
    this.onPlayNextEpisodeRequested,
    this.cancelAutoplayActionLabel,
    this.onCancelAutoplayRequested,
    this.speedActionLabel,
    this.onSpeedRequested,
    this.qualityActionLabel,
    this.onQualityRequested,
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
  final String? previousEpisodeActionLabel;
  final Future<void> Function()? onPlayPreviousEpisodeRequested;
  final String? nextEpisodeActionLabel;
  final Future<void> Function()? onPlayNextEpisodeRequested;
  final String? cancelAutoplayActionLabel;
  final Future<void> Function()? onCancelAutoplayRequested;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedRequested;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityRequested;

  @override
  Widget build(BuildContext context) {
    final isHandset = MediaQuery.sizeOf(context).shortestSide < 600;
    final isHandsetFullscreen = isHandset && isFullscreen;
    final effectiveControlsVisible =
        controlsVisible || !isPlaying || isBuffering || isCompleted;
    final theme = Theme.of(context);
    final playbackStateLabel = isCompleted
        ? 'Complete'
        : isBuffering
        ? 'Buffering'
        : isPlaying
        ? 'Playing'
        : 'Paused';
    final stageLabel = '$qualityLabel • ${sessionContext.episodeDisplayLabel}';
    final titleStyle = isHandsetFullscreen
        ? theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          )
        : theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          );
    final dockBackground = isHandsetFullscreen
        ? const Color(0x2E101010)
        : const Color(0x40101010);
    final dockPadding = isHandsetFullscreen
        ? const EdgeInsets.fromLTRB(12, 8, 12, 10)
        : const EdgeInsets.fromLTRB(14, 10, 14, 12);

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
                      Color(0xB8000000),
                      Color(0x05000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: isHandsetFullscreen
                        ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
                        : const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverlayIconButton(
                              icon: Icons.arrow_back_rounded,
                              onPressed: onBackRequested,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _OverlayPill(
                                    label: playbackStateLabel,
                                    color: _playerAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sessionContext.seriesTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                  SizedBox(height: isHandsetFullscreen ? 2 : 3),
                                  Text(
                                    sessionContext.episodeTitle,
                                    maxLines: isHandsetFullscreen ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _OverlayIconButton(
                              icon: Icons.menu_book_rounded,
                              onPressed: () async => onOpenSeriesRequested(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isHandsetFullscreen ? 420 : 760,
                          ),
                          child: _PlayerGlassPanel(
                            backgroundColor: dockBackground,
                            padding: dockPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isHandsetFullscreen) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stageLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ),
                                      if (canToggleFullscreen) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            unawaited(onToggleFullscreen());
                                          },
                                          icon: Icon(
                                            isFullscreen
                                                ? Icons.fullscreen_exit_rounded
                                                : Icons.fullscreen_rounded,
                                            color: Colors.white,
                                          ),
                                          tooltip: isFullscreen
                                              ? 'Exit Fullscreen'
                                              : 'Enter Fullscreen',
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _OverlayTransportButton(
                                      icon: Icons.replay_10_rounded,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onSeekBackward();
                                      },
                                    ),
                                    SizedBox(
                                      width: isHandsetFullscreen ? 14 : 18,
                                    ),
                                    _OverlayTransportButton(
                                      icon: isCompleted
                                          ? Icons.replay_rounded
                                          : isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      isPrimary: true,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onPrimaryAction();
                                      },
                                    ),
                                    SizedBox(
                                      width: isHandsetFullscreen ? 14 : 18,
                                    ),
                                    _OverlayTransportButton(
                                      icon: Icons.forward_10_rounded,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onSeekForward();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: isHandsetFullscreen ? 6 : 10),
                                _PlaybackTimeline(
                                  player: player,
                                  textColor: Colors.white,
                                  inactiveColor: isHandsetFullscreen
                                      ? Colors.white10
                                      : Colors.white24,
                                  compact: isHandsetFullscreen,
                                  onInteractionStart:
                                      onTimelineInteractionStart,
                                  onInteractionEnd: onTimelineInteractionEnd,
                                ),
                                if ((previousEpisodeActionLabel != null &&
                                        onPlayPreviousEpisodeRequested !=
                                            null) ||
                                    (speedActionLabel != null &&
                                        onSpeedRequested != null) ||
                                    (qualityActionLabel != null &&
                                        onQualityRequested != null) ||
                                    (nextEpisodeActionLabel != null &&
                                        onPlayNextEpisodeRequested != null) ||
                                    (cancelAutoplayActionLabel != null &&
                                        onCancelAutoplayRequested != null)) ...[
                                  SizedBox(
                                    height: isHandsetFullscreen ? 6 : 10,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        if (previousEpisodeActionLabel !=
                                                null &&
                                            onPlayPreviousEpisodeRequested !=
                                                null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onPlayPreviousEpisodeRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.skip_previous_rounded,
                                            ),
                                            label: Text(
                                              previousEpisodeActionLabel!,
                                            ),
                                          ),
                                        if (speedActionLabel != null &&
                                            onSpeedRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onSpeedRequested!.call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.speed_rounded,
                                            ),
                                            label: Text(speedActionLabel!),
                                          ),
                                        if (qualityActionLabel != null &&
                                            onQualityRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onQualityRequested!.call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.high_quality_rounded,
                                            ),
                                            label: Text(qualityActionLabel!),
                                          ),
                                        if (nextEpisodeActionLabel != null &&
                                            onPlayNextEpisodeRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onPlayNextEpisodeRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.skip_next_rounded,
                                            ),
                                            label: Text(
                                              nextEpisodeActionLabel!,
                                            ),
                                          ),
                                        if (cancelAutoplayActionLabel != null &&
                                            onCancelAutoplayRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onCancelAutoplayRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                            label: Text(
                                              cancelAutoplayActionLabel!,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (isHandsetFullscreen) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stageLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: Colors.white54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (canToggleFullscreen)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            unawaited(onToggleFullscreen());
                                          },
                                          icon: const Icon(
                                            Icons.fullscreen_exit_rounded,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          tooltip: 'Exit Fullscreen',
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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
    required this.primaryActionIcon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.timeline,
    this.secondaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.speedActionLabel,
    this.onSpeedAction,
    this.qualityActionLabel,
    this.onQualityAction,
  });

  final PlayerScreenContext sessionContext;
  final String? qualityLabel;
  final String? streamHost;
  final String statusText;
  final String statusLabel;
  final Widget? timeline;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedAction;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PlayerGlassPanel(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now playing',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionContext.seriesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionContext.episodeTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
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
          if (statusText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              statusText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          if (timeline != null) ...[const SizedBox(height: 14), timeline!],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  unawaited(onPrimaryAction());
                },
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel),
              ),
              if (speedActionLabel != null && onSpeedAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onSpeedAction!());
                  },
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(speedActionLabel!),
                ),
              if (qualityActionLabel != null && onQualityAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onQualityAction!());
                  },
                  icon: const Icon(Icons.high_quality_rounded),
                  label: Text(qualityActionLabel!),
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton.icon(
                  onPressed: onSecondaryAction,
                  icon: Icon(
                    secondaryActionIcon ?? Icons.arrow_forward_rounded,
                  ),
                  label: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSessionSummary extends StatelessWidget {
  const _CompactSessionSummary({
    required this.sessionContext,
    required this.qualityLabel,
    required this.statusLabel,
    required this.statusText,
    required this.primaryActionIcon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.speedActionLabel,
    this.onSpeedAction,
    this.qualityActionLabel,
    this.onQualityAction,
  });

  final PlayerScreenContext sessionContext;
  final String? qualityLabel;
  final String statusLabel;
  final String statusText;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedAction;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryLine = <String>[
      sessionContext.episodeDisplayLabel,
      if (qualityLabel case final value? when value.trim().isNotEmpty)
        value.trim(),
      _compactStatusCopy(statusLabel, statusText),
    ].join(' • ');

    return _PlayerGlassPanel(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.94),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sessionContext.seriesTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sessionContext.episodeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            summaryLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                onPressed: () {
                  unawaited(onPrimaryAction());
                },
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel),
              ),
              if (speedActionLabel != null && onSpeedAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onSpeedAction!());
                  },
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(speedActionLabel!),
                ),
              if (qualityActionLabel != null && onQualityAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onQualityAction!());
                  },
                  icon: const Icon(Icons.high_quality_rounded),
                  label: Text(qualityActionLabel!),
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton.icon(
                  onPressed: onSecondaryAction,
                  icon: Icon(
                    secondaryActionIcon ?? Icons.arrow_forward_rounded,
                  ),
                  label: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _compactStatusCopy(String statusLabel, String statusText) {
  final normalizedStatus = statusText.trim();
  if (normalizedStatus.startsWith('Episode finished')) {
    return 'Marked complete';
  }
  if (normalizedStatus.startsWith('Playback is active, but the stream')) {
    return 'Stream catching up';
  }
  if (normalizedStatus.startsWith('Playback is active')) {
    return 'Progress syncing';
  }
  if (normalizedStatus.startsWith('Playback is paused')) {
    return 'Ready to resume';
  }
  if (normalizedStatus.startsWith('Player is preparing')) {
    return 'Preparing stream';
  }
  if (normalizedStatus.isNotEmpty) {
    return normalizedStatus;
  }
  return statusLabel.trim();
}

class _PlaybackQualitySheet extends StatelessWidget {
  const _PlaybackQualitySheet({
    required this.activeQualityLabel,
    required this.options,
  });

  final String activeQualityLabel;
  final List<PlayerPlaybackQualityOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback quality',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current stream: $activeQualityLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(option.label),
                subtitle: option.isOffline
                    ? const Text('Offline source')
                    : const Text('Remote stream'),
                trailing: option.isSelected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(option.variantIndex),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackSpeedSheet extends StatelessWidget {
  const _PlaybackSpeedSheet({
    required this.activeRateLabel,
    required this.options,
  });

  final String activeRateLabel;
  final List<PlayerPlaybackSpeedOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback speed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Now using $activeRateLabel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? Icons.check_circle_rounded
                      : Icons.speed_rounded,
                  color: option.isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(option.label),
                trailing: option.isSelected
                    ? Text(
                        'Current',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option.rate),
              ),
          ],
        ),
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
    this.compact = false,
    this.inactiveColor,
  });

  final Player player;
  final Color textColor;
  final Color? inactiveColor;
  final bool compact;
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
                    trackHeight: widget.compact ? 2 : null,
                    activeTrackColor: widget.textColor,
                    inactiveTrackColor:
                        widget.inactiveColor ??
                        widget.textColor.withValues(alpha: 0.24),
                    thumbColor: widget.textColor,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: widget.compact ? 5 : 6,
                    ),
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
                      hasDuration ? _formatPlaybackDuration(duration) : '',
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
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _playerOutline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3A000000),
              blurRadius: 30,
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
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _PlayerGlassPanel(
            backgroundColor: const Color(0x46101010),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerStateIcon(child: child),
                const SizedBox(height: 16),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _playerOutline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
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
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child ?? Icon(icon, color: Colors.white, size: 30),
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
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(onPressed());
          },
          icon: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _OverlayTransportButton extends StatelessWidget {
  const _OverlayTransportButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.compact = false,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isPrimary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimension = switch ((isPrimary, compact)) {
      (true, true) => 58.0,
      (true, false) => 64.0,
      (false, true) => 46.0,
      (false, false) => 52.0,
    };
    final iconSize = switch ((isPrimary, compact)) {
      (true, true) => 28.0,
      (true, false) => 30.0,
      (false, true) => 20.0,
      (false, false) => 22.0,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFFFF8F1F), Color(0xFFFF6A00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: isPrimary
            ? const [
                BoxShadow(
                  color: Color(0x45FF7A00),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(onPressed());
          },
          icon: Icon(
            icon,
            color: isPrimary ? Colors.black : Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
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
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
