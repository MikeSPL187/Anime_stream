import '../../../domain/models/episode.dart';
import '../../../domain/models/series_catalog_page.dart';
import '../../../domain/models/series.dart';
import '../../../domain/repositories/series_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../mappers/anilibria/anilibria_episode_mapper.dart';
import '../../mappers/anilibria/anilibria_series_mapper.dart';

class AniLibriaSeriesRepository implements SeriesRepository {
  AniLibriaSeriesRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
    required AnilibriaSeriesMapper seriesMapper,
    required AnilibriaEpisodeMapper episodeMapper,
  }) : _remoteDataSource = remoteDataSource,
       _seriesMapper = seriesMapper,
       _episodeMapper = episodeMapper;

  final AnilibriaRemoteDataSource _remoteDataSource;
  final AnilibriaSeriesMapper _seriesMapper;
  final AnilibriaEpisodeMapper _episodeMapper;

  @override
  Future<List<Series>> getFeaturedSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchFeaturedReleases(
      limit: limit,
    );
    return releases.map(_seriesMapper.mapRelease).toList(growable: false);
  }

  @override
  Future<List<Series>> getTrendingSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchTrendingReleases(
      limit: limit,
    );
    return releases.map(_seriesMapper.mapRelease).toList(growable: false);
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchPopularReleases(limit: limit);
    return releases.map(_seriesMapper.mapRelease).toList(growable: false);
  }

  @override
  Future<SeriesCatalogPage> getCatalogPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (page < 1) {
      throw ArgumentError.value(
        page,
        'page',
        'Catalog page index must be 1 or greater.',
      );
    }
    if (pageSize < 1) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Catalog page size must be 1 or greater.',
      );
    }

    final releasePage = await _remoteDataSource.fetchCatalogPage(
      page: page,
      limit: pageSize,
    );

    return SeriesCatalogPage(
      items: releasePage.releases
          .map(_seriesMapper.mapRelease)
          .toList(growable: false),
      page: releasePage.currentPage,
      pageSize: releasePage.perPage,
      totalItems: releasePage.totalItems,
      totalPages: releasePage.totalPages,
    );
  }

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 20}) async {
    final releases = await _remoteDataSource.searchReleases(
      query,
      limit: limit,
    );
    return releases.map(_seriesMapper.mapRelease).toList(growable: false);
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    final release = await _remoteDataSource.fetchReleaseDetails(seriesId);
    return _seriesMapper.mapRelease(release);
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
    final episodes = await _remoteDataSource.fetchReleaseEpisodes(seriesId);
    return episodes
        .map(
          (episode) =>
              _episodeMapper.mapEpisode(dto: episode, seriesId: seriesId),
        )
        .toList(growable: false);
  }
}
