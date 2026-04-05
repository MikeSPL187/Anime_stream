import '../../../domain/models/episode.dart';
import '../../../domain/models/series.dart';
import '../../../domain/repositories/series_details_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../mappers/anilibria/anilibria_episode_mapper.dart';
import '../../mappers/anilibria/anilibria_series_mapper.dart';

class AniLibriaSeriesDetailsRepository implements SeriesDetailsRepository {
  AniLibriaSeriesDetailsRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
    required AnilibriaSeriesMapper seriesMapper,
    required AnilibriaEpisodeMapper episodeMapper,
  })  : _remoteDataSource = remoteDataSource,
        _seriesMapper = seriesMapper,
        _episodeMapper = episodeMapper;

  final AnilibriaRemoteDataSource _remoteDataSource;
  final AnilibriaSeriesMapper _seriesMapper;
  final AnilibriaEpisodeMapper _episodeMapper;

  @override
  Future<List<Episode>> getEpisodesForSeason({
    required String seriesId,
    required String seasonId,
  }) async {
    final episodes = await _remoteDataSource.fetchReleaseEpisodes(seriesId);
    return episodes
        .map(
          (dto) => _episodeMapper.mapEpisode(
            dto: dto,
            seriesId: seriesId,
            seasonId: seasonId,
          ),
        )
        .toList();
  }

  @override
  Future<Series> getSeriesDetails(String seriesId) async {
    final release = await _remoteDataSource.fetchReleaseDetails(seriesId);
    return _seriesMapper.mapRelease(release);
  }
}
