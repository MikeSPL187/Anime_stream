import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/player/player_autoplay_next.dart';
import '../../app/player/player_playback_providers.dart';
import '../../app/player/player_playback_source.dart';
import '../../app/player/player_playback_speed.dart';
import '../../app/player/player_progress_providers.dart';
import '../../app/player/player_runtime.dart';
import '../../app/player/player_stage_copy.dart';
import '../../app/router/app_router.dart';
import '../../app/settings/playback_preferences_providers.dart';
import '../../shared/user_facing_async_error.dart';
import 'player_screen_context.dart';

part 'player_screen_states.dart';
part 'player_screen_widgets.dart';

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
            skipLoadingOnRefresh: false,
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
              message: userFacingAsyncErrorMessage(
                error,
                fallbackMessage:
                    'Player could not resolve a stream for this episode right now.',
                preferredMessage: switch (error) {
                  PlayerPlaybackResolutionException(:final message) => message,
                  _ => null,
                },
              ),
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
              onRefreshPlaybackSourceRequested: _retryPlaybackSourceResolution,
              initialPlaybackRate: _playbackRate,
              onPlaybackRateChanged: _handlePlaybackRateChanged,
            ),
          ),
        ),
      ),
    );
  }
}
