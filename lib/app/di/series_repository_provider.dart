import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/adapters/anilibria/anilibria_remote_data_source.dart';
import '../../data/adapters/anilibria/dio_anilibria_remote_data_source.dart';
import '../../data/mappers/anilibria/anilibria_episode_mapper.dart';
import '../../data/mappers/anilibria/anilibria_series_mapper.dart';
import '../../data/repositories/anilibria/anilibria_series_repository.dart';
import '../../domain/repositories/series_repository.dart';

final anilibriaDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: DioAnilibriaRemoteDataSource.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

final anilibriaRemoteDataSourceProvider = Provider<AnilibriaRemoteDataSource>((
  ref,
) {
  return DioAnilibriaRemoteDataSource(dio: ref.watch(anilibriaDioProvider));
});

final anilibriaSeriesMapperProvider = Provider<AnilibriaSeriesMapper>((ref) {
  return const AnilibriaSeriesMapper();
});

final anilibriaEpisodeMapperProvider = Provider<AnilibriaEpisodeMapper>((ref) {
  return const AnilibriaEpisodeMapper();
});

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return AniLibriaSeriesRepository(
    remoteDataSource: ref.watch(anilibriaRemoteDataSourceProvider),
    seriesMapper: ref.watch(anilibriaSeriesMapperProvider),
    episodeMapper: ref.watch(anilibriaEpisodeMapperProvider),
  );
});
