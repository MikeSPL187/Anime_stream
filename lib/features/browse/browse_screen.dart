import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  BrowseDiscoveryMode _selectedMode = BrowseDiscoveryMode.all;

  @override
  Widget build(BuildContext context) {
    final browseCatalog = ref.watch(browseCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.catalog),
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Catalog',
          ),
        ],
      ),
      body: browseCatalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _BrowseMessageState(
          title: 'Browse unavailable',
          message: 'Catalog browse data could not be loaded.\n$error',
        ),
        data: (catalog) => _BrowseContent(
          catalog: catalog,
          selectedMode: _selectedMode,
          onSelectMode: (mode) => setState(() => _selectedMode = mode),
        ),
      ),
    );
  }
}

enum BrowseDiscoveryMode { all, latest, trending, popular }

class _BrowseContent extends StatelessWidget {
  const _BrowseContent({
    required this.catalog,
    required this.selectedMode,
    required this.onSelectMode,
  });

  final BrowseCatalogData catalog;
  final BrowseDiscoveryMode selectedMode;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final sections = _sections(catalog);
    final selectedSection = selectedMode == BrowseDiscoveryMode.all
        ? null
        : sections.firstWhere((section) => section.mode == selectedMode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const _LeadHeader(
          eyebrow: 'Explore anime',
          title: 'Browse discovery',
          description:
              'Move across the real discovery slices already backed by the repository.',
        ),
        const SizedBox(height: 20),
        _ModeSelector(
          selectedMode: selectedMode,
          onSelectMode: onSelectMode,
        ),
        const SizedBox(height: 24),
        if (!catalog.hasAnyContent)
          const _BrowseMessageState(
            title: 'Nothing surfaced yet',
            message: 'No browse slices are available right now.',
          )
        else if (selectedSection == null)
          _BrowseAllBody(sections: sections, onSelectMode: onSelectMode)
        else
          _BrowseFocusedBody(
            section: selectedSection,
            onSelectMode: onSelectMode,
          ),
      ],
    );
  }

  List<_BrowseSection> _sections(BrowseCatalogData catalog) => [
        _BrowseSection(
          mode: BrowseDiscoveryMode.latest,
          title: 'Latest Releases',
          description: 'Freshly surfaced anime from the current feed.',
          seriesList: catalog.latestReleases,
        ),
        _BrowseSection(
          mode: BrowseDiscoveryMode.trending,
          title: 'Trending Ongoing',
          description: 'Ongoing anime ordered by fresh release activity.',
          seriesList: catalog.trendingSeries,
        ),
        _BrowseSection(
          mode: BrowseDiscoveryMode.popular,
          title: 'Popular Catalog',
          description: 'Stronger general catalog picks from rating-sorted discovery.',
          seriesList: catalog.popularSeries,
        ),
      ];
}

class _BrowseAllBody extends StatelessWidget {
  const _BrowseAllBody({
    required this.sections,
    required this.onSelectMode,
  });

  final List<_BrowseSection> sections;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final spotlight = sections.firstWhere(
      (section) => section.seriesList.isNotEmpty,
      orElse: () => sections.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spotlight.seriesList.isNotEmpty) ...[
          _BrowseHero(section: spotlight, series: spotlight.seriesList.first),
          const SizedBox(height: 28),
        ],
        for (final section in sections)
          if (section.seriesList.isNotEmpty) ...[
            _BrowseRail(
              section: section,
              onFocus: () => onSelectMode(section.mode),
            ),
            const SizedBox(height: 28),
          ],
      ],
    );
  }
}

class _BrowseFocusedBody extends StatelessWidget {
  const _BrowseFocusedBody({
    required this.section,
    required this.onSelectMode,
  });

  final _BrowseSection section;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final spotlight = section.seriesList.isEmpty ? null : section.seriesList.first;
    final gridItems = section.seriesList.length <= 1
        ? section.seriesList
        : section.seriesList.sublist(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FocusHeader(
          section: section,
          onBack: () => onSelectMode(BrowseDiscoveryMode.all),
        ),
        const SizedBox(height: 20),
        if (spotlight != null) ...[
          _BrowseHero(section: section, series: spotlight),
          const SizedBox(height: 24),
        ],
        _BrowseGrid(seriesList: gridItems),
      ],
    );
  }
}

class _LeadHeader extends StatelessWidget {
  const _LeadHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.onSelectMode,
  });

  final BrowseDiscoveryMode selectedMode;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in BrowseDiscoveryMode.values)
          ChoiceChip(
            selected: mode == selectedMode,
            label: Text(_label(mode)),
            onSelected: (_) => onSelectMode(mode),
          ),
      ],
    );
  }

  String _label(BrowseDiscoveryMode mode) {
    return switch (mode) {
      BrowseDiscoveryMode.all => 'All',
      BrowseDiscoveryMode.latest => 'Latest',
      BrowseDiscoveryMode.trending => 'Trending',
      BrowseDiscoveryMode.popular => 'Popular',
    };
  }
}

class _BrowseHero extends StatelessWidget {
  const _BrowseHero({required this.section, required this.series});

  final _BrowseSection section;
  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: _Artwork(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              label: series.title,
              icon: Icons.live_tv_rounded,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ColorChip(
                  label: section.title,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(series.title, style: theme.textTheme.headlineSmall),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    metadata,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    series.synopsis!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
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
    );
  }
}

class _BrowseRail extends StatelessWidget {
  const _BrowseRail({
    required this.section,
    required this.onFocus,
  });

  final _BrowseSection section;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    section.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onFocus, child: const Text('Focus')),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.seriesList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _PosterCard(series: section.seriesList[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FocusHeader extends StatelessWidget {
  const _FocusHeader({
    required this.section,
    required this.onBack,
  });

  final _BrowseSection section;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              section.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Back to all discovery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 176,
      child: Material(
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 152,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: _Artwork(
                          imageUrl: series.posterImageUrl,
                          label: series.title,
                          icon: Icons.movie_creation_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Open series',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseGrid extends StatelessWidget {
  const _BrowseGrid({required this.seriesList});

  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seriesList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.35 : 0.76,
          ),
          itemBuilder: (context, index) {
            return _GridCard(series: seriesList[index]);
          },
        );
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.series});

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
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 106,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _Artwork(
                        imageUrl: series.posterImageUrl,
                        label: series.title,
                        icon: Icons.movie_creation_outlined,
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
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          series.synopsis!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
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

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.imageUrl,
    required this.label,
    required this.icon,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final String label;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return _ArtworkFallback(label: label, icon: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        alignment: alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _ArtworkFallback(label: label, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ArtworkFallback(label: label, icon: icon);
        },
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.label, required this.icon});

  final String label;
  final IconData icon;

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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
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

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

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

class _BrowseMessageState extends StatelessWidget {
  const _BrowseMessageState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseSection {
  const _BrowseSection({
    required this.mode,
    required this.title,
    required this.description,
    required this.seriesList,
  });

  final BrowseDiscoveryMode mode;
  final String title;
  final String description;
  final List<Series> seriesList;
}