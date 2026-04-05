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
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final nextDraftQuery = _queryController.text;
    if (nextDraftQuery == _draftQuery) {
      return;
    }

    setState(() {
      _draftQuery = nextDraftQuery;
    });
  }

  void _submitSearch() {
    final query = normalizeSearchQuery(_queryController.text);
    setState(() {
      _submittedQuery = query.isEmpty ? null : query;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _queryController.clear();
    setState(() {
      _submittedQuery = null;
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchIntroCard(
              hasActiveQuery: submittedQuery != null,
              draftQuery: _draftQuery,
            ),
            const SizedBox(height: 16),
            _SearchBar(
              controller: _queryController,
              hasText: _draftQuery.trim().isNotEmpty,
              onSubmitted: _submitSearch,
              onClear: _clearSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _SearchBody(
                submittedQuery: submittedQuery,
                searchResults: searchResults,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hasText,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search by title', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Submit an exact title or a partial title to search the catalog.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSubmitted(),
                    decoration: InputDecoration(
                      hintText: 'Search anime titles',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: !hasText
                          ? null
                          : IconButton(
                              onPressed: onClear,
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Clear search',
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onSubmitted,
                  child: const Text('Search'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.submittedQuery,
    required this.searchResults,
  });

  final String? submittedQuery;
  final AsyncValue<List<Series>>? searchResults;

  @override
  Widget build(BuildContext context) {
    final submittedQuery = this.submittedQuery;
    final theme = Theme.of(context);

    if (submittedQuery == null) {
      return _SearchMessageCard(
        title: 'Start a Search',
        message:
            'Use the search field above to find a title and jump straight into its series page.',
        footer: Text(
          'Search works best with a title or partial title.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        child: Icon(
          Icons.search_rounded,
          size: 32,
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (!canExecuteSearchQuery(submittedQuery)) {
      return _SearchMessageCard(
        title: 'Query Too Short',
        message:
            'Use at least $minimumSearchQueryLength characters so the app can run a real title search.',
        footer: Text(
          'Current query: "$submittedQuery"',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return searchResults!.when(
      loading: () => _SearchMessageCard(
        title: 'Searching',
        message: 'Looking up anime that match "$submittedQuery"...',
        footer: Text(
          'Searching for "$submittedQuery"',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => _SearchMessageCard(
        title: 'Search Failed',
        message:
            'The search request for "$submittedQuery" could not be completed.\n$error',
        child: Icon(
          Icons.error_outline_rounded,
          size: 28,
          color: theme.colorScheme.error,
        ),
      ),
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return _SearchMessageCard(
            title: 'No Results',
            message:
                'No anime matched "$submittedQuery". Try a different spelling or a shorter title fragment.',
            child: Icon(
              Icons.travel_explore_rounded,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Results', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${seriesList.length} result${seriesList.length == 1 ? '' : 's'} for "$submittedQuery"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: seriesList.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _SearchResultRow(series: seriesList[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(AppRoutePaths.seriesDetails(series.id));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchPoster(
                imageUrl: series.posterImageUrl,
                label: series.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series.title, style: theme.textTheme.titleMedium),
                    if ((series.originalTitle ?? '').trim().isNotEmpty &&
                        series.originalTitle != series.title) ...[
                      const SizedBox(height: 4),
                      Text(
                        series.originalTitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                      const SizedBox(height: 8),
                      Text(
                        series.synopsis!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Open series',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
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

class _SearchPoster extends StatelessWidget {
  const _SearchPoster({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: trimmedUrl == null || trimmedUrl.isEmpty
              ? _SearchPosterFallback(label: label)
              : Image.network(
                  trimmedUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _SearchPosterFallback(label: label),
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _SearchPosterFallback(label: label);
                  },
                ),
        ),
      ),
    );
  }
}

class _SearchPosterFallback extends StatelessWidget {
  const _SearchPosterFallback({required this.label});

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
        padding: const EdgeInsets.all(8),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMessageCard extends StatelessWidget {
  const _SearchMessageCard({
    required this.title,
    required this.message,
    this.child,
    this.footer,
  });

  final String title;
  final String message;
  final Widget? child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (child != null) ...[child!, const SizedBox(height: 16)],
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 16), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchIntroCard extends StatelessWidget {
  const _SearchIntroCard({
    required this.hasActiveQuery,
    required this.draftQuery,
  });

  final bool hasActiveQuery;
  final String draftQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedDraftQuery = draftQuery.trim();
    final helperText = hasActiveQuery
        ? 'Update the query and submit again to refine the results.'
        : trimmedDraftQuery.isNotEmpty
        ? 'Your query is ready. Submit to search the catalog.'
        : 'Find anime by title and move directly into the series flow.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Anime', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              helperText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SearchHintChip(
                  label: 'Title or partial title',
                  color: theme.colorScheme.primary,
                ),
                _SearchHintChip(
                  label: 'Opens into series pages',
                  color: theme.colorScheme.secondary,
                ),
                _SearchHintChip(
                  label: 'Minimum $minimumSearchQueryLength characters',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push(AppRoutePaths.browse),
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Browse catalog instead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHintChip extends StatelessWidget {
  const _SearchHintChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
