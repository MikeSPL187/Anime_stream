import '../../../domain/models/availability_state.dart';
import '../../../domain/models/episode.dart';
import '../../dto/anilibria/anilibria_episode_dto.dart';

class AnilibriaEpisodeMapper {
  const AnilibriaEpisodeMapper();

  Episode mapEpisode({
    required AnilibriaEpisodeDto dto,
    required String seriesId,
    String? seasonId,
  }) {
    return Episode(
      id: dto.id,
      seriesId: seriesId,
      sortOrder: dto.ordinal,
      numberLabel: dto.numberLabel ?? dto.ordinal.toString(),
      title: dto.title ?? 'Episode ${dto.ordinal}',
      synopsis: dto.description,
      duration: dto.durationSeconds == null
          ? null
          : Duration(seconds: dto.durationSeconds!),
      thumbnailImageUrl: dto.thumbnailUrl,
      airDate: dto.airedAt,
      isFiller: dto.isFiller,
      isRecap: dto.isRecap,
      availability: const AvailabilityState(),
    );
  }
}
