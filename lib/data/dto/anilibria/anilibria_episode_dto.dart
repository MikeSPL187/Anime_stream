class AnilibriaEpisodeDto {
  const AnilibriaEpisodeDto({
    required this.id,
    required this.releaseId,
    required this.ordinal,
    this.title,
    this.description,
    this.durationSeconds,
    this.thumbnailUrl,
    this.airedAt,
    this.isFiller = false,
    this.isRecap = false,
    this.raw = const {},
  });

  final String id;
  final String releaseId;
  final int ordinal;
  final String? title;
  final String? description;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final DateTime? airedAt;
  final bool isFiller;
  final bool isRecap;
  final Map<String, Object?> raw;
}
