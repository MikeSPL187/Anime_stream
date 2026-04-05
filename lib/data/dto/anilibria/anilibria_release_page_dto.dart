import 'anilibria_release_dto.dart';

class AnilibriaReleasePageDto {
  const AnilibriaReleasePageDto({
    required this.releases,
    required this.currentPage,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
  });

  final List<AnilibriaReleaseDto> releases;
  final int currentPage;
  final int perPage;
  final int totalItems;
  final int totalPages;
}
