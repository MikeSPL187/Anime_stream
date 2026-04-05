import '../../../domain/models/availability_state.dart';
import '../../../domain/models/series.dart';
import '../../dto/anilibria/anilibria_release_dto.dart';

class AnilibriaSeriesMapper {
  const AnilibriaSeriesMapper();

  Series mapRelease(AnilibriaReleaseDto dto) {
    return Series(
      id: dto.id,
      slug: dto.code ?? dto.id,
      title: dto.names.main ?? dto.names.english ?? dto.id,
      originalTitle: dto.names.english,
      synopsis: dto.description,
      posterImageUrl: dto.images?.posterUrl,
      bannerImageUrl: dto.images?.bannerUrl,
      genres: dto.genres,
      releaseYear: dto.releaseYear,
      availability: const AvailabilityState.available(),
      lastUpdatedAt: dto.updatedAt,
    );
  }
}
