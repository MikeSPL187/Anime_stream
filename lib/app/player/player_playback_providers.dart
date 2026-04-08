import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/episode_playback_variant.dart';
import '../../domain/models/download_entry.dart';
import '../../domain/models/episode.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../domain/repositories/episode_playback_repository.dart';
import '../../features/player/player_screen_context.dart';
import '../di/downloads_repository_provider.dart';
import '../di/episode_playback_repository_provider.dart';
import '../series/series_providers.dart';
import 'player_playback_source.dart';

final playerPlaybackResolverProvider = Provider<PlayerPlaybackResolver>((ref) {
  return PlayerPlaybackResolver(
    episodePlaybackRepository: ref.watch(episodePlaybackRepositoryProvider),
    downloadsRepository: ref.watch(downloadsRepositoryProvider),
  );
});

final playerPlaybackSourceProvider = FutureProvider.autoDispose
    .family<PlayerPlaybackSource, PlayerScreenContext>((ref, sessionContext) {
      final resolver = ref.watch(playerPlaybackResolverProvider);
      return resolver.resolve(sessionContext);
    });

final playerNextEpisodeContextProvider = FutureProvider.autoDispose
    .family<PlayerScreenContext?, PlayerScreenContext>((
      ref,
      sessionContext,
    ) async {
      final content = await ref.watch(
        seriesContentProvider(sessionContext.seriesId).future,
      );
      final sortedEpisodes = content.episodes.toList(growable: false)
        ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

      for (var index = 0; index < sortedEpisodes.length; index++) {
        final episode = sortedEpisodes[index];
        if (!_matchesSeriesEpisode(episode, sessionContext)) {
          continue;
        }

        final nextIndex = index + 1;
        if (nextIndex >= sortedEpisodes.length) {
          return null;
        }

        final nextEpisode = sortedEpisodes[nextIndex];
        return PlayerScreenContext(
          seriesId: content.series.id,
          seriesTitle: content.series.title,
          episodeId: nextEpisode.id,
          episodeNumberLabel: nextEpisode.numberLabel,
          episodeTitle: _playerEpisodeTitle(nextEpisode),
        );
      }

      return null;
    });

final playerPreviousEpisodeContextProvider = FutureProvider.autoDispose
    .family<PlayerScreenContext?, PlayerScreenContext>((
      ref,
      sessionContext,
    ) async {
      final content = await ref.watch(
        seriesContentProvider(sessionContext.seriesId).future,
      );
      final sortedEpisodes = content.episodes.toList(growable: false)
        ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

      for (var index = 0; index < sortedEpisodes.length; index++) {
        final episode = sortedEpisodes[index];
        if (!_matchesSeriesEpisode(episode, sessionContext)) {
          continue;
        }

        final previousIndex = index - 1;
        if (previousIndex < 0) {
          return null;
        }

        final previousEpisode = sortedEpisodes[previousIndex];
        return PlayerScreenContext(
          seriesId: content.series.id,
          seriesTitle: content.series.title,
          episodeId: previousEpisode.id,
          episodeNumberLabel: previousEpisode.numberLabel,
          episodeTitle: _playerEpisodeTitle(previousEpisode),
        );
      }

      return null;
    });

class PlayerPlaybackResolver {
  PlayerPlaybackResolver({
    required EpisodePlaybackRepository episodePlaybackRepository,
    required DownloadsRepository downloadsRepository,
  }) : _episodePlaybackRepository = episodePlaybackRepository,
       _downloadsRepository = downloadsRepository;

  final EpisodePlaybackRepository _episodePlaybackRepository;
  final DownloadsRepository _downloadsRepository;

  Future<PlayerPlaybackSource> resolve(PlayerScreenContext context) async {
    final localDownload = await _downloadsRepository.getPlayableDownload(
      seriesId: context.seriesId,
      episodeId: context.episodeId,
    );
    if (localDownload != null) {
      final localAssetUri = localDownload.localAssetUri;
      if (localAssetUri != null && localAssetUri.trim().isNotEmpty) {
        return PlayerPlaybackSource(
          variants: [
            PlayerPlaybackVariant(
              sourceUri: localAssetUri,
              qualityLabel: '${localDownload.selectedQuality} offline',
              kind: _mapDownloadSourceKind(localDownload.sourceKind),
            ),
          ],
        );
      }
    }

    try {
      final remoteVariants = await _episodePlaybackRepository
          .getRemotePlaybackVariants(
            seriesId: context.seriesId,
            episodeSelector: context.episodeSelector,
          );
      final orderedVariants = remoteVariants
          .map(_mapRemotePlaybackVariant)
          .toList(growable: false);
      return PlayerPlaybackSource(variants: orderedVariants);
    } on EpisodePlaybackLookupException catch (error) {
      throw PlayerPlaybackResolutionException(error.message);
    }
  }

  PlayerPlaybackVariant _mapRemotePlaybackVariant(
    EpisodePlaybackVariant variant,
  ) {
    return PlayerPlaybackVariant(
      sourceUri: variant.sourceUri,
      qualityLabel: variant.qualityLabel,
      kind: PlayerPlaybackSourceKind.remoteHls,
    );
  }

  PlayerPlaybackSourceKind _mapDownloadSourceKind(
    DownloadSourceKind sourceKind,
  ) {
    return switch (sourceKind) {
      DownloadSourceKind.localFile => PlayerPlaybackSourceKind.localFile,
      DownloadSourceKind.localHlsManifest =>
        PlayerPlaybackSourceKind.localHlsManifest,
    };
  }
}

class PlayerPlaybackResolutionException implements Exception {
  const PlayerPlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _matchesSeriesEpisode(Episode episode, PlayerScreenContext context) {
  return context.matchesEpisode(
    id: episode.id,
    numberLabel: episode.numberLabel,
    title: episode.title,
  );
}

String _playerEpisodeTitle(Episode episode) {
  final trimmedTitle = episode.title.trim();
  if (trimmedTitle.isNotEmpty) {
    return trimmedTitle;
  }

  return 'Episode ${episode.numberLabel}';
}
