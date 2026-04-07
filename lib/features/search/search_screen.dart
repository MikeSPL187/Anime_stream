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
    _debounce = Timer(const Duration(milliseconds: 350), _commitSearchFromDraft);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const _SearchLead(),
          const SizedBox(height: 20),
          _SearchFieldCard(
            controller: _queryController,
            hasText: _draftQuery.trim().isNotEmpty,
            submittedQuery: submittedQuery,
            onClear: _clearSearch,
          ),
          const SizedBox(height: 16),
          _SearchStatusBanner(
            draftQuery: _draftQuery,
            submittedQuery: submittedQuery,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.62,
            child: _SearchBody(
              submittedQuery: submittedQuery,
              searchResults: searchResults,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchLead extends StatelessWidget {
  const _SearchLead();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find anime'.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text('Search by title', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Type a title and let search resolve into a real series result without the old form-only feel.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SearchFieldCard extends StatelessWidget {
  const _SearchFieldCard({
    required this.controller,
    required this.hasText,
    required this.submittedQuery,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final String? submittedQuery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live title intent', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              submittedQuery == null
                  ? 'Search activates once the title is long enough to run a real query.'
                  : 'Search is actively matching "$submittedQuery".',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search anime titles',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: !hasText
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Clear',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchStatusBanner extends StatelessWidget {
  const _SearchStatusBanner({
    required this.draftQuery,
    required this.submittedQuery,
  });

  final String draftQuery;
  final String? submittedQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = normalizeSearchQuery(draftQuery);

    if (normalized.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Start typing a title to search the anime catalog.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (!canExecuteSearchQuery(normalized)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'Keep typing. Search starts at $minimumSearchQueryLength characters.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SearchChip(
              label: 'Live search active',
              color: theme.colorScheme.primary,
            ),
            _SearchChip(
              label: submittedQuery ?? normalized,
              color: theme.colorScheme.secondary,
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
    final theme = Theme.of(context);

    if (submittedQuery == null) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_rounded, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Search is waiting', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Type a title to move directly into a series page.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.go(AppRoutePaths.browse),
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Browse instead'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return searchResults!.when(
      loading: () => const Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Search failed.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No anime matched "$submittedQuery".',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }

        final topMatch = seriesList.first;
        final otherResults = seriesList.length <= 1
            ? const <Series>[]
            : seriesList.sublist(1);

        return ListView(
          children: [
            _TopMatchCard(series: topMatch),
            if (otherResults.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('More results', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              for (var i = 0; i < otherResults.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _SearchResultCard(series: otherResults[i]),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _TopMatchCard extends StatelessWidget {
  const _TopMatchCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchChip(
              label: 'Top match',
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 116,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
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
                      Text(series.title, style: theme.textTheme.headlineSmall),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(metadata, style: theme.textTheme.bodySmall),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          series.synopsis!,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push(AppRoutePaths.seriesDetails(series.id)),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Open series'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(series.title, style: theme.textTheme.titleMedium),
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          series.synopsis!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _SearchArtwork extends StatelessWidget {
  const _SearchArtwork({
    required this.imageUrl,
    required this.label,
  });

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
          if (loadingProgress == null) return child;
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
            Icon(Icons.movie_creation_outlined, color: theme.colorScheme.onSurfaceVariant),
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