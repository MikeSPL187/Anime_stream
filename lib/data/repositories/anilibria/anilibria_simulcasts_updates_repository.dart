import '../../../domain/models/episode.dart';
import '../../../domain/models/series.dart';
import '../../../domain/repositories/simulcasts_updates_repository.dart';
import '../../adapters/anilibria/anilibria_remote_data_source.dart';
import '../../mappers/anilibria/anilibria_series_mapper.dart';

class AniLibriaSimulcastsUpdatesRepository
    implements SimulcastsUpdatesRepository {
  AniLibriaSimulcastsUpdatesRepository({
    required AnilibriaRemoteDataSource remoteDataSource,
    required AnilibriaSeriesMapper seriesMapper,
  })  : _remoteDataSource = remoteDataSource,
        _seriesMapper = seriesMapper;

  final AnilibriaRemoteDataSource _remoteDataSource;
  final AnilibriaSeriesMapper _seriesMapper;

  @override
  Future<List<Episode>> getLatestEpisodeUpdates({int limit = 20}) {
    throw UnimplementedError(
      'Episode update mapping requires canonical season assignment.',
    );
  }

  @override
  Future<List<Series>> getSimulcasts({int limit = 20}) async {
    final releases = await _remoteDataSource.fetchSimulcastReleases(
      limit: limit,
    );
    return releases.map(_seriesMapper.mapRelease).toList();
  }
}
