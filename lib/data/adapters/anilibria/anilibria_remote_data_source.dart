import '../../dto/anilibria/anilibria_episode_dto.dart';
import '../../dto/anilibria/anilibria_release_dto.dart';

abstract interface class AnilibriaRemoteDataSource {
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20});

  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({int limit = 20});

  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20});

  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId);

  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(String releaseId);

  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  });

  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({int limit = 20});
}
