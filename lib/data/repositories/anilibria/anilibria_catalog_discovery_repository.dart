import '../../../domain/models/series.dart';
import '../../../domain/repositories/catalog_discovery_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../mappers/anilibria/anilibria_series_mapper.dart';

class AniLibriaCatalogDiscoveryRepository
    implements CatalogDiscoveryRepository {
  AniLibriaCatalogDiscoveryRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
    required AnilibriaSeriesMapper seriesMapper,
  })  : _remoteDataSource = remoteDataSource,
        _seriesMapper = seriesMapper;

  final AnilibriaRemoteDataSource _remoteDataSource;
  final AnilibriaSeriesMapper _seriesMapper;

  @override
  Future<List<Series>> getFeaturedSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchFeaturedReleases(limit: limit);
    return releases.map(_seriesMapper.mapRelease).toList();
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchPopularReleases(limit: limit);
    return releases.map(_seriesMapper.mapRelease).toList();
  }

  @override
  Future<List<Series>> getTrendingSeries({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchTrendingReleases(limit: limit);
    return releases.map(_seriesMapper.mapRelease).toList();
  }
}
