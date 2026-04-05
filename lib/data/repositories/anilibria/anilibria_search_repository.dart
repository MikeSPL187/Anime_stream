import '../../../domain/models/series.dart';
import '../../../domain/repositories/search_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../mappers/anilibria/anilibria_series_mapper.dart';

class AniLibriaSearchRepository implements SearchRepository {
  AniLibriaSearchRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
    required AnilibriaSeriesMapper seriesMapper,
  })  : _remoteDataSource = remoteDataSource,
        _seriesMapper = seriesMapper;

  final AnilibriaRemoteDataSource _remoteDataSource;
  final AnilibriaSeriesMapper _seriesMapper;

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 20}) async {
    final releases = await _remoteDataSource.searchReleases(
      query,
      limit: limit,
    );
    return releases.map(_seriesMapper.mapRelease).toList();
  }
}
