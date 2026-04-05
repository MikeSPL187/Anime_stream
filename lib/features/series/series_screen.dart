import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/series/series_details_data.dart';
import '../../app/series/series_providers.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/series.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesDetails = ref.watch(seriesDetailsProvider(seriesId));

    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: seriesDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load series $seriesId.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (details) => _SeriesPage(details: details),
      ),
    );
  }
}

class _SeriesPage extends StatelessWidget {
  const _SeriesPage({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final series = details.series;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _IdentitySection(series: series),
        const SizedBox(height: 16),
        _MetadataSection(series: series, episodeCount: details.episodes.length),
        if ((series.synopsis ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _SynopsisSection(synopsis: series.synopsis!.trim()),
        ],
        const SizedBox(height: 24),
        _EpisodesSection(episodes: details.episodes),
      ],
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({required this.series});

  final Series series;

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
            'Series',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(series.title, style: theme.textTheme.headlineSmall),
          if ((series.originalTitle ?? '').trim().isNotEmpty &&
              series.originalTitle != series.title) ...[
            const SizedBox(height: 6),
            Text(
              series.originalTitle!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.series, required this.episodeCount});

  final Series series;
  final int episodeCount;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (series.releaseYear != null) 'Year ${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(3).join(' • '),
      'Episodes $episodeCount',
    ];

    return _SectionCard(
      title: 'Metadata',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metadata
            .map(
              (item) =>
                  Chip(label: Text(item), visualDensity: VisualDensity.compact),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.synopsis});

  final String synopsis;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(title: 'Synopsis', child: Text(synopsis));
  }
}

class _EpisodesSection extends StatelessWidget {
  const _EpisodesSection({required this.episodes});

  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Episodes',
      trailing: Text('${episodes.length}', style: theme.textTheme.titleMedium),
      child: episodes.isEmpty
          ? const Text('Episodes are not available yet.')
          : Column(
              children: [
                for (var index = 0; index < episodes.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _EpisodeRow(episode: episodes[index]),
                ],
              ],
            ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode});

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      if (episode.duration != null) '${episode.duration!.inMinutes} min',
      if (episode.isRecap) 'Recap',
      if (episode.isFiller) 'Filler',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              'Ep ${episode.numberLabel}',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(episode.title, style: theme.textTheme.titleMedium),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join('  •  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if ((episode.synopsis ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    episode.synopsis!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
