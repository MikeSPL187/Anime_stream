import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/series/series_providers.dart';
import '../../domain/models/series.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredSeries = ref.watch(featuredSeriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: featuredSeries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load featured series.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (seriesList) => _HomeDiscoveryView(seriesList: seriesList),
      ),
    );
  }
}

class _HomeDiscoveryView extends StatelessWidget {
  const _HomeDiscoveryView({required this.seriesList});

  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _DiscoveryHeader(itemCount: seriesList.length),
        const SizedBox(height: 16),
        if (seriesList.isEmpty)
          const _EmptyDiscoveryState()
        else ...[
          _FeaturedSpotlight(series: seriesList.first),
          const SizedBox(height: 24),
          _FeaturedCatalog(seriesList: seriesList),
        ],
      ],
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text('Featured anime picks', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Currently loaded: $itemCount series',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSpotlight extends StatelessWidget {
  const _FeaturedSpotlight({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return _SectionCard(
      title: 'Featured Now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(series.title, style: theme.textTheme.titleLarge),
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
            const SizedBox(height: 8),
            Text(
              metadata,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if ((series.synopsis ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              series.synopsis!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeaturedCatalog extends StatelessWidget {
  const _FeaturedCatalog({required this.seriesList});

  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Browse Featured',
      trailing: Text(
        '${seriesList.length}',
        style: theme.textTheme.titleMedium,
      ),
      child: Column(
        children: [
          for (var index = 0; index < seriesList.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            _SeriesRow(series: seriesList[index]),
          ],
        ],
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join('  •  ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(series.title, style: theme.textTheme.titleMedium),
          if ((series.originalTitle ?? '').trim().isNotEmpty &&
              series.originalTitle != series.title) ...[
            const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}

class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Featured',
      child: Text('No featured series are available right now.'),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ...?trailing == null ? null : [trailing!],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
