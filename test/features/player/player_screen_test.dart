import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/playback_repository_provider.dart';
import 'package:anime_stream_app/app/di/watch_system_repository_provider.dart';
import 'package:anime_stream_app/app/player/player_playback_providers.dart';
import 'package:anime_stream_app/app/player/player_playback_source.dart';
import 'package:anime_stream_app/app/player/player_runtime.dart';
import 'package:anime_stream_app/domain/models/continue_watching_entry.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/playback_preferences.dart';
import 'package:anime_stream_app/domain/repositories/playback_repository.dart';
import 'package:anime_stream_app/domain/repositories/watch_system_repository.dart';
import 'package:anime_stream_app/features/player/player_screen.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  const sessionContext = PlayerScreenContext(
    seriesId: 'series-1',
    seriesTitle: 'Frieren',
    episodeId: 'episode-3',
    episodeNumberLabel: '3',
    episodeTitle: 'Killing Magic',
  );

  testWidgets(
    'PlayerScreen shows recovery state when session context is missing',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PlayerScreen())),
      );

      expect(find.text('Player unavailable'), findsOneWidget);
      expect(
        find.text(
          'Return to a series and choose an episode to enter playback.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'PlayerScreen shows the playback resolution stage while the source is loading',
    (tester) async {
      final loadingCompleter = Completer<PlayerPlaybackSource>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerPlaybackSourceProvider.overrideWith(
              (ref, context) => loadingCompleter.future,
            ),
          ],
          child: const MaterialApp(
            home: PlayerScreen(sessionContext: sessionContext),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Preparing Playback'), findsOneWidget);
      expect(
        find.text('Resolving this episode into a playable stream.'),
        findsOneWidget,
      );
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('Episode 3'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets('PlayerScreen retries playback resolution after an error', (
    tester,
  ) async {
    var requests = 0;
    final retryLoadingCompleter = Completer<PlayerPlaybackSource>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerPlaybackSourceProvider.overrideWith((ref, context) async {
            requests += 1;
            if (requests == 1) {
              throw const PlayerPlaybackResolutionException(
                'Stream resolution failed right now.',
              );
            }

            return retryLoadingCompleter.future;
          }),
        ],
        child: const MaterialApp(
          home: PlayerScreen(sessionContext: sessionContext),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Playback Unavailable'), findsOneWidget);
    expect(find.text('Stream resolution failed right now.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(requests, 2);
    expect(find.text('Preparing Playback'), findsOneWidget);
    expect(
      find.text('Resolving this episode into a playable stream.'),
      findsOneWidget,
    );
  });

  testWidgets('PlayerScreen sanitizes unexpected playback resolution errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerPlaybackSourceProvider.overrideWith((ref, context) async {
            throw StateError('SocketException: upstream transport failed');
          }),
        ],
        child: const MaterialApp(
          home: PlayerScreen(sessionContext: sessionContext),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Playback Unavailable'), findsOneWidget);
    expect(
      find.text(
        'Player could not resolve a stream for this episode right now.',
      ),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets(
    'PlayerScreen renders the resolved playback surface with runtime-backed controls',
    (tester) async {
      final runtimeFactory = _FakePlayerRuntimeFactory(
        () => _FakePlayerRuntimeHandle(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerPlaybackSourceProvider.overrideWith((ref, context) async {
              return PlayerPlaybackSource(
                variants: const [
                  PlayerPlaybackVariant(
                    sourceUri: 'https://cdn.example.com/episode-3-1080.m3u8',
                    qualityLabel: '1080p',
                    kind: PlayerPlaybackSourceKind.remoteHls,
                  ),
                  PlayerPlaybackVariant(
                    sourceUri: 'https://cdn.example.com/episode-3-720.m3u8',
                    qualityLabel: '720p',
                    kind: PlayerPlaybackSourceKind.remoteHls,
                  ),
                ],
              );
            }),
            playerRuntimeFactoryProvider.overrideWithValue(runtimeFactory),
            playbackRepositoryProvider.overrideWithValue(
              const _FakePlaybackRepository(),
            ),
            watchSystemRepositoryProvider.overrideWithValue(
              const _FakeWatchSystemRepository(),
            ),
            playerPreviousEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
            playerNextEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
          ],
          child: const MaterialApp(
            home: PlayerScreen(sessionContext: sessionContext),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake-player-view')), findsOneWidget);
      expect(find.text('Now playing'), findsOneWidget);
      expect(find.text('Speed 1x'), findsWidgets);
      expect(find.text('Quality 1080p'), findsWidgets);
      expect(find.text('Open Series'), findsWidgets);
    },
  );

  testWidgets(
    'PlayerScreen surfaces a resolved open failure from the player runtime',
    (tester) async {
      final runtimeFactory = _FakePlayerRuntimeFactory(
        () => _FakePlayerRuntimeHandle(
          openError: StateError('Offline file is missing on this device.'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerPlaybackSourceProvider.overrideWith((ref, context) async {
              return PlayerPlaybackSource(
                variants: const [
                  PlayerPlaybackVariant(
                    sourceUri: '/tmp/frieren-episode-3.mp4',
                    qualityLabel: 'Offline',
                    kind: PlayerPlaybackSourceKind.localFile,
                  ),
                ],
              );
            }),
            playerRuntimeFactoryProvider.overrideWithValue(runtimeFactory),
            playbackRepositoryProvider.overrideWithValue(
              const _FakePlaybackRepository(),
            ),
            watchSystemRepositoryProvider.overrideWithValue(
              const _FakeWatchSystemRepository(),
            ),
            playerPreviousEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
            playerNextEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
          ],
          child: const MaterialApp(
            home: PlayerScreen(sessionContext: sessionContext),
          ),
        ),
      );
      await tester.pump();
      for (var attempt = 0; attempt < 20; attempt += 1) {
        if (find.text('Playback Failed').evaluate().isNotEmpty) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Playback Failed'), findsOneWidget);
      expect(
        find.text('Offline file is missing on this device.'),
        findsOneWidget,
      );
      expect(find.text('Retry Stream'), findsOneWidget);
    },
  );

  testWidgets(
    'PlayerScreen surfaces playback recovery UI when the active stream dies and no fallback remains',
    (tester) async {
      final runtimeFactory = _FakePlayerRuntimeFactory(
        () => _FakePlayerRuntimeHandle(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerPlaybackSourceProvider.overrideWith((ref, context) async {
              return PlayerPlaybackSource(
                variants: const [
                  PlayerPlaybackVariant(
                    sourceUri: 'https://cdn.example.com/episode-3-1080.m3u8',
                    qualityLabel: '1080p',
                    kind: PlayerPlaybackSourceKind.remoteHls,
                  ),
                ],
              );
            }),
            playerRuntimeFactoryProvider.overrideWithValue(runtimeFactory),
            playbackRepositoryProvider.overrideWithValue(
              const _FakePlaybackRepository(),
            ),
            watchSystemRepositoryProvider.overrideWithValue(
              const _FakeWatchSystemRepository(),
            ),
            playerPreviousEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
            playerNextEpisodeContextProvider.overrideWith(
              (ref, context) async => null,
            ),
          ],
          child: const MaterialApp(
            home: PlayerScreen(sessionContext: sessionContext),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final runtimeHandle = runtimeFactory.createdHandles.single;
      runtimeHandle.emitError('stream died');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Playback Failed'), findsOneWidget);
      expect(
        find.text('Playback failed and no other stream remained available.'),
        findsOneWidget,
      );
      expect(find.text('Retry Stream'), findsOneWidget);
    },
  );
}

class _FakePlayerRuntimeFactory implements PlayerRuntimeFactory {
  _FakePlayerRuntimeFactory(this._createHandle);

  final _FakePlayerRuntimeHandle Function() _createHandle;
  final List<_FakePlayerRuntimeHandle> createdHandles = [];

  @override
  Future<void> ensureInitialized() async {}

  @override
  PlayerRuntimeHandle create() {
    final handle = _createHandle();
    createdHandles.add(handle);
    return handle;
  }
}

class _FakePlayerRuntimeHandle implements PlayerRuntimeHandle {
  _FakePlayerRuntimeHandle({this.openError});

  final Object? openError;
  final _errorController = StreamController<String>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _completedController = StreamController<bool>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _rateController = StreamController<double>.broadcast();
  bool _isDisposed = false;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<bool> get completedStream => _completedController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<bool> get bufferingStream => _bufferingController.stream;

  @override
  Stream<double> get rateStream => _rateController.stream;

  @override
  Widget buildView() {
    return const ColoredBox(key: Key('fake-player-view'), color: Colors.black);
  }

  @override
  Future<void> open(String sourceUri) async {
    if (openError != null) {
      throw openError!;
    }
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> setRate(double rate) async {
    _rateController.add(rate);
  }

  void emitError(String message) {
    _errorController.add(message);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    unawaited(_errorController.close());
    unawaited(_positionController.close());
    unawaited(_durationController.close());
    unawaited(_completedController.close());
    unawaited(_playingController.close());
    unawaited(_bufferingController.close());
    unawaited(_rateController.close());
  }
}

class _FakePlaybackRepository implements PlaybackRepository {
  const _FakePlaybackRepository();

  @override
  Future<PlaybackPreferences> getPlaybackPreferences() async {
    return const PlaybackPreferences();
  }

  @override
  Future<void> savePlaybackPreferences(PlaybackPreferences preferences) async {}
}

class _FakeWatchSystemRepository implements WatchSystemRepository {
  const _FakeWatchSystemRepository();

  @override
  Future<List<ContinueWatchingEntry>> getContinueWatching({
    int limit = 20,
  }) async {
    return const <ContinueWatchingEntry>[];
  }

  @override
  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  }) async {
    return null;
  }

  @override
  Future<List<HistoryEntry>> getWatchHistory({int limit = 50}) async {
    return const <HistoryEntry>[];
  }

  @override
  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  }) async {
    return const <EpisodeProgress>[];
  }

  @override
  Future<void> markEpisodeUnwatched({
    required String seriesId,
    required String episodeId,
  }) async {}

  @override
  Future<void> markEpisodeWatched({
    required String seriesId,
    required String episodeId,
  }) async {}

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {}
}
