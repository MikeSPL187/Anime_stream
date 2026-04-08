import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/search/search_providers.dart';
import '../../domain/models/series.dart';
import '../../shared/widgets/anime_cached_artwork.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _queryController;
  Timer? _debounce;
  String _draftQuery = '';
  String? _submittedQuery;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final nextDraft = _queryController.text;
    if (nextDraft == _draftQuery) {
      return;
    }

    setState(() {
      _draftQuery = nextDraft;
    });

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      _commitSearchFromDraft,
    );
  }

  void _commitSearchFromDraft() {
    final normalized = normalizeSearchQuery(_draftQuery);
    setState(() {
      _submittedQuery = canExecuteSearchQuery(normalized) ? normalized : null;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _queryController.clear();
    setState(() {
      _submittedQuery = null;
      _draftQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final submittedQuery = _submittedQuery;
    final searchResults = submittedQuery == null
        ? null
        : ref.watch(searchSeriesProvider(submittedQuery));

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _SearchField(
              controller: _queryController,
              hasText: _draftQuery.trim().isNotEmpty,
              onClear: _clearSearch,
            ),
          ),
          Expanded(
            child: _SearchBody(
              draftQuery: _draftQuery,
              searchResults: searchResults,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search anime titles',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear',
              )
            : null,
      ),
      style: theme.textTheme.bodyLarge,
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.draftQuery, required this.searchResults});

  final String draftQuery;
  final AsyncValue<List<Series>>? searchResults;

  @override
  Widget build(BuildContext context) {
    final normalizedDraft = normalizeSearchQuery(draftQuery);

    if (normalizedDraft.isEmpty) {
      return const _SearchState(
        icon: Icons.search_rounded,
        title: 'Search by title',
        message: 'Type a series title to move directly into a watch hub.',
      );
    }

    if (!canExecuteSearchQuery(normalizedDraft)) {
      return _SearchState(
        icon: Icons.keyboard_rounded,
        title: 'Keep typing',
        message: 'Search starts at $minimumSearchQueryLength characters.',
      );
    }

    return searchResults!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _SearchState(
        icon: Icons.error_outline_rounded,
        title: 'Search unavailable',
        message: 'The catalog could not be searched right now.\n$error',
      ),
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return _SearchState(
            icon: Icons.search_off_rounded,
            title: 'No match found',
            message: 'No anime matched "$normalizedDraft".',
            action: TextButton.icon(
              onPressed: () => context.go(AppRoutePaths.browse),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse instead'),
            ),
          );
        }

        final topMatch = seriesList.first;
        final otherResults = seriesList.skip(1).toList(growable: false);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _TopResultTile(series: topMatch),
            if (otherResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'More results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < otherResults.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _SearchResultRow(series: otherResults[index]),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _TopResultTile extends StatelessWidget {
  const _TopResultTile({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      'Top match',
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 292,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeCachedArtwork(
                  imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
                  label: series.title,
                  icon: Icons.movie_creation_outlined,
                  alignment: Alignment.topCenter,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  top: 14,
                  child: _OverlayPill(
                    label: 'Top match',
                    icon: Icons.search_rounded,
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.03,
                        ),
                      ),
                      if ((series.originalTitle ?? '').trim().isNotEmpty &&
                          series.originalTitle != series.title) ...[
                        const SizedBox(height: 5),
                        Text(
                          series.originalTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          series.synopsis!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.24,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push(
                          AppRoutePaths.seriesDetails(series.id),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Open series'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 114,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeCachedArtwork(
                  imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
                  label: series.title,
                  icon: Icons.movie_creation_outlined,
                  alignment: Alignment.topCenter,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.88),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  bottom: 14,
                  right: 46,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            series.synopsis!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 10,
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchState extends StatelessWidget {
  const _SearchState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
