import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/search/search_providers.dart';
import '../../domain/models/series.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _TopResultTile(series: topMatch),
            if (otherResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'More results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < otherResults.length; index++) ...[
                if (index > 0) const Divider(height: 24),
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
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _SearchArtwork(
                        imageUrl: series.posterImageUrl,
                        label: series.title,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top match',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(series.title, style: theme.textTheme.headlineSmall),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          series.synopsis!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => context.push(
                          AppRoutePaths.seriesDetails(series.id),
                        ),
                        child: const Text('Open Series'),
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 82,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: _SearchArtwork(
                      imageUrl: series.posterImageUrl,
                      label: series.title,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(series.title, style: theme.textTheme.titleMedium),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metadata,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          series.synopsis!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
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

class _SearchArtwork extends StatelessWidget {
  const _SearchArtwork({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return _SearchArtworkFallback(label: label);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              _SearchArtworkFallback(label: label),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _SearchArtworkFallback(label: label);
        },
      ),
    );
  }
}

class _SearchArtworkFallback extends StatelessWidget {
  const _SearchArtworkFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
