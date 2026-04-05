import 'anilibria_episode_dto.dart';

class AnilibriaNamesDto {
  const AnilibriaNamesDto({
    this.main,
    this.english,
    this.alternative = const [],
  });

  final String? main;
  final String? english;
  final List<String> alternative;
}

class AnilibriaImageSetDto {
  const AnilibriaImageSetDto({
    this.posterUrl,
    this.bannerUrl,
  });

  final String? posterUrl;
  final String? bannerUrl;
}

class AnilibriaReleaseDto {
  const AnilibriaReleaseDto({
    required this.id,
    this.code,
    this.names = const AnilibriaNamesDto(),
    this.description,
    this.genres = const [],
    this.images,
    this.releaseYear,
    this.updatedAt,
    this.episodes = const [],
    this.raw = const {},
  });

  final String id;
  final String? code;
  final AnilibriaNamesDto names;
  final String? description;
  final List<String> genres;
  final AnilibriaImageSetDto? images;
  final int? releaseYear;
  final DateTime? updatedAt;
  final List<AnilibriaEpisodeDto> episodes;
  final Map<String, Object?> raw;
}
