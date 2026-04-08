import 'package:dio/dio.dart';

import '../../../domain/models/episode_playback_variant.dart';
import '../../../domain/models/episode_selector.dart';
import '../../../domain/repositories/episode_playback_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../dto/anilibria/anilibria_episode_dto.dart';

class AnilibriaEpisodePlaybackRepository implements EpisodePlaybackRepository {
  AnilibriaEpisodePlaybackRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AnilibriaRemoteDataSource _remoteDataSource;

  @override
  Future<List<EpisodePlaybackVariant>> getRemotePlaybackVariants({
    required String seriesId,
    required EpisodeSelector episodeSelector,
  }) async {
    try {
      final release = await _remoteDataSource.fetchReleaseDetails(seriesId);
      final episode = _findEpisode(
        release.episodes,
        episodeSelector: episodeSelector,
      );
      if (episode == null) {
        throw EpisodePlaybackLookupException(
          '${episodeSelector.episodeDisplayLabel} could not be resolved for playback.',
        );
      }

      final variants = _buildRemoteVariants(episode);
      if (variants.isEmpty) {
        throw EpisodePlaybackLookupException(
          'No supported remote playback variants are available for ${episodeSelector.episodeDisplayLabel}.',
        );
      }

      return List.unmodifiable(variants);
    } on DioException catch (error) {
      throw EpisodePlaybackLookupException(
        'Failed to load release data for playback.'
        '${error.response?.statusCode == null ? '' : ' HTTP ${error.response!.statusCode}.'}',
      );
    } on FormatException catch (error) {
      throw EpisodePlaybackLookupException(
        'Release data for playback could not be parsed: ${error.message}',
      );
    }
  }

  AnilibriaEpisodeDto? _findEpisode(
    List<AnilibriaEpisodeDto> episodes, {
    required EpisodeSelector episodeSelector,
  }) {
    if (episodes.isEmpty) {
      return null;
    }

    for (final episode in episodes) {
      if (episodeSelector.matchesEpisode(
        id: episode.id,
        numberLabel: episode.numberLabel ?? '',
        title: episode.title ?? '',
      )) {
        return episode;
      }
    }

    return null;
  }

  List<EpisodePlaybackVariant> _buildRemoteVariants(
    AnilibriaEpisodeDto episode,
  ) {
    const streamCandidates = [
      ('1080p', 'hls1080Url'),
      ('720p', 'hls720Url'),
      ('480p', 'hls480Url'),
    ];

    final variants = <EpisodePlaybackVariant>[];
    for (final (qualityLabel, key) in streamCandidates) {
      final streamUri = switch (key) {
        'hls1080Url' => episode.hls1080Url,
        'hls720Url' => episode.hls720Url,
        'hls480Url' => episode.hls480Url,
        _ => null,
      };

      final trimmedStreamUri = streamUri?.trim();
      if (trimmedStreamUri == null || trimmedStreamUri.isEmpty) {
        continue;
      }

      variants.add(
        EpisodePlaybackVariant(
          sourceUri: trimmedStreamUri,
          qualityLabel: qualityLabel,
        ),
      );
    }

    return variants;
  }
}
