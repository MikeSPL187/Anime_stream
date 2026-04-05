class AnilibriaEpisodeDto {
  const AnilibriaEpisodeDto({
    required this.id,
    required this.releaseId,
    required this.ordinal,
    this.numberLabel,
    this.title,
    this.description,
    this.durationSeconds,
    this.thumbnailUrl,
    this.hls480Url,
    this.hls720Url,
    this.hls1080Url,
    this.airedAt,
    this.isFiller = false,
    this.isRecap = false,
    this.raw = const {},
  });

  final String id;
  final String releaseId;
  final int ordinal;
  final String? numberLabel;
  final String? title;
  final String? description;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String? hls480Url;
  final String? hls720Url;
  final String? hls1080Url;
  final DateTime? airedAt;
  final bool isFiller;
  final bool isRecap;
  final Map<String, Object?> raw;
}
