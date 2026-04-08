part of 'player_screen.dart';

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
    required this.onRefreshPlaybackSourceRequested,
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
  final Future<void> Function() onRefreshPlaybackSourceRequested;
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

  late final PlayerProgressController _progressController;
  PlayerRuntimeHandle? _player;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<double>? _rateSubscription;
  Timer? _controlsHideTimer;
  Timer? _autoplayNextEpisodeTimer;

  Object? _lastVariantOpenError;
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
    _progressController = ref.read(playerProgressControllerProvider);
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

    PlayerRuntimeHandle? player;
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

      final playerRuntimeFactory = ref.read(playerRuntimeFactoryProvider);
      await playerRuntimeFactory.ensureInitialized();
      final requestedQualityLabel =
          widget.playbackSource.activeVariant.qualityLabel;

      player = playerRuntimeFactory.create();
      _errorSubscription = player.errorStream.listen((message) {
        if (!_hasOpenedPlayback) {
          return;
        }
        unawaited(_handlePlaybackError(message));
      });

      _positionSubscription = player.positionStream.listen((position) {
        _latestPosition = position;

        if (_isCompleted || !_shouldPersistProgress(position)) {
          return;
        }

        unawaited(
          _persistProgressSnapshot(_progressController, position: position),
        );
      });

      _durationSubscription = player.durationStream.listen((duration) {
        if (duration <= Duration.zero) {
          return;
        }

        _latestTotalDuration = duration;
      });

      _completedSubscription = player.completedStream.listen((isCompleted) {
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
          _persistProgressSnapshot(_progressController, isCompleted: true),
        );
        unawaited(_prepareAutoplayNextEpisode());
      });

      _playingSubscription = player.playingStream.listen((isPlaying) {
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

      _bufferingSubscription = player.bufferingStream.listen((isBuffering) {
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
        throw _lastVariantOpenError ??
            StateError(
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
      await _restoreSavedProgress(_progressController, player);

      _rateSubscription = player.rateStream.listen((playbackRate) {
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
      final resolvedError = _resolvePlaybackOpenError(error);

      if (!mounted) {
        _playbackError = resolvedError;
        _isOpening = false;
      } else {
        setState(() {
          _playbackError = resolvedError;
          _isOpening = false;
        });
        _showControls();
      }

      await _cancelSubscriptions();
      await player?.dispose();
    }
  }

  Future<bool> _openResolvedSource(
    PlayerRuntimeHandle player,
    int startIndex, {
    bool restorePosition = false,
  }) async {
    _lastVariantOpenError = null;
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

  String _resolvePlaybackOpenError(Object error) {
    if (error is StateError) {
      final message = error.message.toString().trim();
      if (message.isNotEmpty) {
        return message;
      }
    }

    return 'Playback could not be opened from any available stream.';
  }

  Future<bool> _openPlaybackVariant(
    PlayerRuntimeHandle player,
    int variantIndex, {
    bool restorePosition = false,
  }) async {
    final variant = widget.playbackSource.variantAt(variantIndex);
    _setOpeningState(_openingPhase, variantIndex: variantIndex);

    try {
      await player.open(variant.sourceUri);

      if (restorePosition && _latestPosition > Duration.zero) {
        try {
          await player.seek(_latestPosition);
        } catch (_) {
          // Recovery seek is best-effort only.
        }
      }

      _lastVariantOpenError = null;
      return true;
    } catch (error) {
      _lastVariantOpenError = error;
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
    PlayerRuntimeHandle player,
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
      _progressController,
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

  Future<void> _restartPlayback(PlayerRuntimeHandle player) async {
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
        _progressController,
        position: _latestPosition,
      );
    }

    await _disposePlaybackResources();

    if (widget.playbackSource.shouldRefreshSourceOnRetry) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _isPlaying = true;
          _hasOpenedPlayback = false;
          _isCompleted = false;
          _playbackError = null;
        });
      } else {
        _isBuffering = false;
        _isPlaying = true;
        _hasOpenedPlayback = false;
        _isCompleted = false;
        _playbackError = null;
      }

      await widget.onRefreshPlaybackSourceRequested();
      return;
    }

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
    _showControls();
    await _persistProgressSnapshot(
      _progressController,
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

    if (_player == null || _isOpening) {
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
      videoView: _player!.buildView(),
      positionStream: _player!.positionStream,
      durationStream: _player!.durationStream,
      onSeekRequested: _player!.seek,
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
        positionStream: _player!.positionStream,
        durationStream: _player!.durationStream,
        onSeekRequested: _player!.seek,
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
