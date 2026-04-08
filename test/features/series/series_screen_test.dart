import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/playback_repository_provider.dart';
import 'package:anime_stream_app/app/downloads/downloads_providers.dart';
import 'package:anime_stream_app/app/di/downloads_repository_provider.dart';
import 'package:anime_stream_app/app/di/watchlist_repository_provider.dart';
import 'package:anime_stream_app/app/series/series_details_data.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_selector.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/playback_preferences.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/watchlist_snapshot.dart';
import 'package:anime_stream_app/domain/repositories/downloads_repository.dart';
import 'package:anime_stream_app/domain/repositories/playback_repository.dart';
import 'package:anime_stream_app/domain/repositories/watchlist_repository.dart';
import 'package:anime_stream_app/features/series/series_screen.dart';

void main() {
  testWidgets(
    'SeriesScreen shows retry state and can recover from a load failure',
    (tester) async {
      var requests = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              requests += 1;
              if (requests == 1) {
                throw StateError('series load failed');
              }

              return _seriesDetailsData();
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _FakeDownloadsRepository(),
            ),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Series unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('Frieren'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Episodes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Episodes'), findsOneWidget);
    },
  );

  testWidgets(
    'SeriesScreen surfaces degraded watch-state copy without losing the hub',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              return _seriesDetailsData(
                watchStateErrorMessage: 'watch progress unavailable',
              );
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _FakeDownloadsRepository(),
            ),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch activity unavailable'), findsWidgets);
      expect(find.text('Start Watching'), findsNothing);
      expect(find.text('Play Episode 1'), findsWidgets);
      expect(
        find.textContaining(
          'Resume progress and watched markers could not be loaded right now',
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('SeriesScreen filters episodes by local finder query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesDetailsProvider.overrideWith((ref, seriesId) async {
            return _seriesDetailsData(
              episodes: const [
                Episode(
                  id: 'episode-1',
                  seriesId: 'series-1',
                  sortOrder: 1,
                  numberLabel: '1',
                  title: 'The Journey Begins',
                ),
                Episode(
                  id: 'episode-12',
                  seriesId: 'series-1',
                  sortOrder: 12,
                  numberLabel: '12',
                  title: 'First-Class Mage Exam',
                ),
                Episode(
                  id: 'episode-28',
                  seriesId: 'series-1',
                  sortOrder: 28,
                  numberLabel: '28',
                  title: 'An Old Friend',
                ),
              ],
            );
          }),
          watchlistRepositoryProvider.overrideWithValue(
            _FakeWatchlistRepository(),
          ),
          downloadsRepositoryProvider.overrideWithValue(
            const _FakeDownloadsRepository(),
          ),
        ],
        child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('First-Class Mage Exam'), findsOneWidget);
    expect(find.text('An Old Friend'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();

    expect(find.text('First-Class Mage Exam'), findsOneWidget);
    expect(find.text('The Journey Begins'), findsNothing);
    expect(find.text('An Old Friend'), findsNothing);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('Nothing in this filter'), findsOneWidget);
    expect(
      find.text('No episodes match "missing" in this view.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'SeriesScreen labels the no-activity filter honestly and keeps only untouched episodes in it',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              return _seriesDetailsData(
                episodes: const [
                  Episode(
                    id: 'episode-1',
                    seriesId: 'series-1',
                    sortOrder: 1,
                    numberLabel: '1',
                    title: 'The Journey Begins',
                  ),
                  Episode(
                    id: 'episode-2',
                    seriesId: 'series-1',
                    sortOrder: 2,
                    numberLabel: '2',
                    title: 'The Hero Party',
                  ),
                  Episode(
                    id: 'episode-3',
                    seriesId: 'series-1',
                    sortOrder: 3,
                    numberLabel: '3',
                    title: 'Northern Lands',
                  ),
                ],
                episodeProgressById: {
                  'episode-1': EpisodeProgress(
                    seriesId: 'series-1',
                    episodeId: 'episode-1',
                    position: const Duration(minutes: 24),
                    totalDuration: const Duration(minutes: 24),
                    isCompleted: true,
                    updatedAt: DateTime(2026, 4, 8, 12),
                  ),
                  'episode-2': EpisodeProgress(
                    seriesId: 'series-1',
                    episodeId: 'episode-2',
                    position: const Duration(minutes: 6),
                    totalDuration: const Duration(minutes: 24),
                    updatedAt: DateTime(2026, 4, 8, 13),
                  ),
                },
              );
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _FakeDownloadsRepository(),
            ),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Not Started'), findsOneWidget);
      expect(find.text('Unwatched'), findsNothing);

      await tester.tap(find.textContaining('Not Started'));
      await tester.pumpAndSettle();

      expect(find.text('Northern Lands'), findsOneWidget);
      expect(find.text('The Journey Begins'), findsNothing);
      expect(find.text('The Hero Party'), findsNothing);
    },
  );

  testWidgets(
    'SeriesScreen lets the viewer choose download quality before starting offline save',
    (tester) async {
      final downloadsRepository = _RecordingDownloadsRepository();
      const request = EpisodeDownloadQualityRequest(
        seriesId: 'series-1',
        episodeSelector: EpisodeSelector(
          episodeId: 'episode-1',
          episodeNumberLabel: '1',
          episodeTitle: 'The Journey Begins',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              return _seriesDetailsData();
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(downloadsRepository),
            playbackRepositoryProvider.overrideWithValue(
              _FakePlaybackRepository(
                preferences: const PlaybackPreferences(
                  defaultDownloadQuality: '720p',
                ),
              ),
            ),
            episodeDownloadQualityOptionsProvider(
              request,
            ).overrideWith((ref) async => const ['1080p', '720p']),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('The Journey Begins'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Download for offline'));
      await tester.pumpAndSettle();

      expect(find.text('Choose download quality'), findsOneWidget);
      expect(find.text('1080p'), findsOneWidget);
      expect(find.text('720p'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, '720p'),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('720p'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(downloadsRepository.lastSelectedQuality, '720p');
      expect(downloadsRepository.lastSeriesTitle, 'Frieren');
      expect(downloadsRepository.lastEpisodeNumberLabel, '1');
      expect(downloadsRepository.lastEpisodeTitle, 'The Journey Begins');
    },
  );
}

SeriesDetailsData _seriesDetailsData({
  String? watchStateErrorMessage,
  Map<String, EpisodeProgress> episodeProgressById = const {},
  List<Episode> episodes = const [
    Episode(
      id: 'episode-1',
      seriesId: 'series-1',
      sortOrder: 1,
      numberLabel: '1',
      title: 'The Journey Begins',
    ),
  ],
}) {
  return SeriesDetailsData(
    series: const Series(
      id: 'series-1',
      slug: 'frieren',
      title: 'Frieren',
      availability: AvailabilityState(),
    ),
    episodes: episodes,
    episodeProgressById: episodeProgressById,
    watchStateErrorMessage: watchStateErrorMessage,
  );
}

class _FakeWatchlistRepository implements WatchlistRepository {
  @override
  Future<void> addToWatchlist(String seriesId) async {}

  @override
  Future<WatchlistSnapshot> getWatchlist() async => const WatchlistSnapshot();

  @override
  Future<bool> isInWatchlist(String seriesId) async => false;

  @override
  Future<void> removeFromWatchlist(String seriesId) async {}
}

class _FakeDownloadsRepository implements DownloadsRepository {
  const _FakeDownloadsRepository();

  @override
  Future<List<DownloadEntry>> getDownloads() async => const [];

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async => null;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
  }) async {
    throw UnimplementedError();
  }
}

class _RecordingDownloadsRepository implements DownloadsRepository {
  String? lastSelectedQuality;
  String? lastSeriesTitle;
  String? lastEpisodeNumberLabel;
  String? lastEpisodeTitle;

  @override
  Future<List<DownloadEntry>> getDownloads() async => const [];

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async => null;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
  }) async {
    lastSelectedQuality = selectedQuality;
    lastSeriesTitle = seriesTitle;
    lastEpisodeNumberLabel = episodeNumberLabel;
    lastEpisodeTitle = episodeTitle;
    return DownloadEntry(
      id: '$seriesId::$episodeId::$selectedQuality',
      seriesId: seriesId,
      episodeId: episodeId,
      selectedQuality: selectedQuality,
      status: DownloadStatus.completed,
      seriesTitle: seriesTitle,
      episodeNumberLabel: episodeNumberLabel,
      episodeTitle: episodeTitle,
    );
  }
}

class _FakePlaybackRepository implements PlaybackRepository {
  const _FakePlaybackRepository({required this.preferences});

  final PlaybackPreferences preferences;

  @override
  Future<PlaybackPreferences> getPlaybackPreferences() async => preferences;

  @override
  Future<void> savePlaybackPreferences(PlaybackPreferences preferences) async {}
}
