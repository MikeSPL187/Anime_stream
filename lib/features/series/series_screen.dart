import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/series/series_details_data.dart';
import '../../app/series/series_providers.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/episode_progress.dart';
import '../../domain/models/series.dart';
import '../player/player_screen_context.dart';

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
        _SaveIntentSection(series: series),
        const SizedBox(height: 16),
        _PrimaryWatchActionSection(details: details),
        const SizedBox(height: 24),
        _EpisodesSection(details: details),
        const SizedBox(height: 24),
        _MetadataSection(series: series, episodeCount: details.episodes.length),
        if ((series.synopsis ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _SynopsisSection(synopsis: series.synopsis!.trim()),
        ],
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
    final summary = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

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
          _IdentityArtworkHero(
            imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
            fallbackLabel: series.title,
          ),
          const SizedBox(height: 16),
          Text(
            'Series',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IdentityPoster(
                imageUrl: series.posterImageUrl,
                fallbackLabel: series.title,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryWatchActionSection extends StatelessWidget {
  const _PrimaryWatchActionSection({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    final latestProgress = details.latestProgress;
    final latestProgressEpisode = latestProgress == null
        ? null
        : details.episodeForProgress(latestProgress);
    final supportingText = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode when targetEpisode != null =>
        'Continue from Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.continueEpisode when targetEpisode != null =>
        'Up next: Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.startWatching when targetEpisode != null =>
        'Begin with Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'You have completed all currently available episodes for this series.',
      SeriesPrimaryWatchActionKind.unavailable =>
        'Episodes are not available yet.',
      _ => 'A playable episode is not available yet.',
    };
    final actionBadge = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode => (
        label: 'Resume',
        color: theme.colorScheme.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => (
        label: 'Up Next',
        color: theme.colorScheme.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => (
        label: 'Start',
        color: theme.colorScheme.primary,
      ),
      SeriesPrimaryWatchActionKind.endOfAvailableContent => (
        label: 'Up to Date',
        color: theme.colorScheme.tertiary,
      ),
      SeriesPrimaryWatchActionKind.unavailable => (
        label: 'Unavailable',
        color: theme.colorScheme.error,
      ),
    };
    final summaryChips = <Widget>[
      _WatchSummaryChip(
        label: '${details.episodes.length} episodes',
        color: theme.colorScheme.primary,
      ),
      if (details.inProgressEpisodeCount > 0)
        _WatchSummaryChip(
          label: '${details.inProgressEpisodeCount} in progress',
          color: theme.colorScheme.primary,
        ),
      if (details.completedEpisodeCount > 0)
        _WatchSummaryChip(
          label: '${details.completedEpisodeCount} completed',
          color: theme.colorScheme.tertiary,
        ),
    ];
    final latestActivityText = switch ((
      latestProgress,
      latestProgressEpisode,
    )) {
      (final progress?, final episode?) when progress.isCompleted =>
        'Latest activity: completed Episode ${episode.numberLabel}',
      (final progress?, final episode?) =>
        'Latest activity: Episode ${episode.numberLabel} at ${_formatPlaybackPosition(progress.position)}',
      _ => 'Choose an episode below or start from the main action.',
    };
    final transitionText = switch (action.kind) {
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'Return here after playback to pick the next available episode or revisit earlier episodes.',
      SeriesPrimaryWatchActionKind.unavailable =>
        'This watch action stays unavailable until a playable episode exists.',
      _ =>
        'This action opens the player directly. Progress syncs back to this series and Continue Watching.',
    };

    return _SectionCard(
      title: 'Watch Now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WatchStateBadge(label: actionBadge.label, color: actionBadge.color),
          const SizedBox(height: 12),
          Text(action.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            supportingText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            latestActivityText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (summaryChips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: summaryChips),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: targetEpisode == null
                  ? null
                  : () => _openEpisodeInPlayer(
                      context,
                      series: details.series,
                      episode: targetEpisode,
                    ),
              icon: Icon(switch (action.kind) {
                SeriesPrimaryWatchActionKind.resumeEpisode =>
                  Icons.play_circle_fill_rounded,
                SeriesPrimaryWatchActionKind.continueEpisode =>
                  Icons.skip_next_rounded,
                SeriesPrimaryWatchActionKind.endOfAvailableContent =>
                  Icons.check_circle_outline_rounded,
                _ => Icons.play_arrow_rounded,
              }),
              label: Text(action.label),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transitionText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveIntentSection extends ConsumerWidget {
  const _SaveIntentSection({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedState = ref.watch(
      watchlistMembershipControllerProvider(series.id),
    );

    return _SectionCard(
      title: 'Save for Later',
      child: savedState.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checking whether this series is already saved in your Watchlist.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Checking Watchlist'),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The saved-for-later state could not be loaded right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(
                  watchlistMembershipControllerProvider(series.id),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Watchlist'),
            ),
          ],
        ),
        data: (isSaved) {
          if (isSaved) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WatchStateBadge(
                  label: 'Saved for Later',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'This series is saved in Watchlist so you can return later outside active playback progress.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => ref
                          .read(
                            watchlistMembershipControllerProvider(
                              series.id,
                            ).notifier,
                          )
                          .removeFromWatchlist(),
                      icon: const Icon(Icons.bookmark_remove_rounded),
                      label: const Text('Remove from Watchlist'),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutePaths.watchlist),
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: const Text('Open Watchlist'),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Save this series to Watchlist when you want to come back later without starting or continuing playback right now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(
                      watchlistMembershipControllerProvider(series.id).notifier,
                    )
                    .addToWatchlist(),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Save to Watchlist'),
              ),
              const SizedBox(height: 10),
              Text(
                'Watchlist is separate from Continue Watching and only tracks saved intent.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
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
      title: 'About This Series',
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
    return _SectionCard(title: 'Story', child: Text(synopsis));
  }
}

class _EpisodesSection extends StatelessWidget {
  const _EpisodesSection({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = details.series;
    final episodes = details.episodes;
    final action = details.primaryWatchAction;
    final actionTargetEpisode = action.targetEpisode;
    final sectionSubtitle = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode
          when actionTargetEpisode != null =>
        'Resume from Episode ${actionTargetEpisode.numberLabel} or pick another episode.',
      SeriesPrimaryWatchActionKind.continueEpisode
          when actionTargetEpisode != null =>
        'Episode ${actionTargetEpisode.numberLabel} is next, or jump anywhere in the list.',
      SeriesPrimaryWatchActionKind.startWatching
          when actionTargetEpisode != null =>
        'Start with Episode ${actionTargetEpisode.numberLabel} or browse the full list.',
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'You are caught up. Revisit any episode below.',
      _ => 'Choose an episode from the list below.',
    };

    return _SectionCard(
      title: 'Episodes',
      trailing: _WatchSummaryChip(
        label: '${episodes.length} available',
        color: theme.colorScheme.primary,
      ),
      child: episodes.isEmpty
          ? const Text('Episodes are not available yet.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EpisodesSectionLead(
                  message: sectionSubtitle,
                  actionLabel:
                      'Tap any episode to open playback. Progress comes back here and to Home.',
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < episodes.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _EpisodeRow(
                    series: series,
                    episode: episodes[index],
                    savedProgress: details.progressForEpisode(
                      episodes[index].id,
                    ),
                    actionHint: _episodeActionHint(details, episodes[index]),
                  ),
                ],
              ],
            ),
    );
  }

  _EpisodeActionHint? _episodeActionHint(
    SeriesDetailsData details,
    Episode episode,
  ) {
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    if (targetEpisode == null || targetEpisode.id != episode.id) {
      return null;
    }

    return switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode => _EpisodeActionHint(
        label: 'Resume here',
        tone: _EpisodeActionHintTone.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => _EpisodeActionHint(
        label: 'Up next',
        tone: _EpisodeActionHintTone.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => _EpisodeActionHint(
        label: 'Start here',
        tone: _EpisodeActionHintTone.primary,
      ),
      _ => null,
    };
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.series,
    required this.episode,
    this.savedProgress,
    this.actionHint,
  });

  final Series series;
  final Episode episode;
  final EpisodeProgress? savedProgress;
  final _EpisodeActionHint? actionHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodeLabel = 'Episode ${episode.numberLabel}';
    final resolvedTitle = episode.title.trim().isEmpty
        ? episodeLabel
        : episode.title;
    final subtitleParts = <String>[
      if (episode.duration != null) '${episode.duration!.inMinutes} min',
      if (episode.isRecap) 'Recap',
      if (episode.isFiller) 'Filler',
    ];
    final watchStatus = switch (savedProgress) {
      final progress? when progress.isCompleted == true => (
        label: 'Completed',
        color: theme.colorScheme.tertiary,
      ),
      _? => (label: 'In progress', color: theme.colorScheme.primary),
      _ => null,
    };
    final progressLabel = switch (savedProgress) {
      final progress? when progress.isCompleted => 'Watched',
      final progress? when progress.totalDuration != null =>
        '${_formatPlaybackPosition(progress.position)} / ${_formatPlaybackPosition(progress.totalDuration!)} watched',
      final progress? =>
        '${_formatPlaybackPosition(progress.position)} watched',
      _ => null,
    };
    final progressFraction = switch (savedProgress) {
      final progress? when progress.isCompleted => 1.0,
      final progress?
          when progress.totalDuration != null &&
              progress.totalDuration! > Duration.zero =>
        (progress.position.inMilliseconds /
                progress.totalDuration!.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble(),
      _ => null,
    };
    final actionHintColor = switch (actionHint?.tone) {
      _EpisodeActionHintTone.secondary => theme.colorScheme.secondary,
      _EpisodeActionHintTone.primary => theme.colorScheme.primary,
      null => null,
    };
    final rowBackgroundColor = actionHint != null
        ? actionHintColor!.withValues(alpha: 0.06)
        : savedProgress != null
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
        : null;
    final rowBorderColor = actionHint != null
        ? actionHintColor!.withValues(alpha: 0.24)
        : savedProgress != null
        ? theme.colorScheme.outlineVariant
        : null;
    final rowDecoration = rowBackgroundColor == null
        ? null
        : BoxDecoration(
            color: rowBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: rowBorderColor == null
                ? null
                : Border.all(color: rowBorderColor),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openEpisodeInPlayer(context, series: series, episode: episode);
        },
        child: Container(
          decoration: rowDecoration,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EpisodeNumberTile(
                numberLabel: episode.numberLabel,
                color: actionHintColor ?? theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EpisodeWatchStatus(
                          label: episodeLabel,
                          color: theme.colorScheme.secondary,
                        ),
                        if (actionHint != null)
                          _EpisodeWatchStatus(
                            label: actionHint!.label,
                            color: actionHintColor!,
                          ),
                        if (watchStatus != null)
                          _EpisodeWatchStatus(
                            label: watchStatus.label,
                            color: watchStatus.color,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(resolvedTitle, style: theme.textTheme.titleMedium),
                    if (progressLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        progressLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (progressFraction != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 6,
                        ),
                      ),
                    ],
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitleParts.join('  •  '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if ((episode.synopsis ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        episode.synopsis!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Open in player',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
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

void _openEpisodeInPlayer(
  BuildContext context, {
  required Series series,
  required Episode episode,
}) {
  context.push(
    AppRoutePaths.player,
    extra: PlayerScreenContext(
      seriesId: series.id,
      seriesTitle: series.title,
      episodeId: episode.id,
      episodeNumberLabel: episode.numberLabel,
      episodeTitle: episode.title,
    ),
  );
}

class _WatchSummaryChip extends StatelessWidget {
  const _WatchSummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _WatchStateBadge extends StatelessWidget {
  const _WatchStateBadge({required this.label, required this.color});

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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _EpisodeActionHint {
  const _EpisodeActionHint({required this.label, required this.tone});

  final String label;
  final _EpisodeActionHintTone tone;
}

enum _EpisodeActionHintTone { primary, secondary }

class _EpisodesSectionLead extends StatelessWidget {
  const _EpisodesSectionLead({
    required this.message,
    required this.actionLabel,
  });

  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.32,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            actionLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeNumberTile extends StatelessWidget {
  const _EpisodeNumberTile({required this.numberLabel, required this.color});

  final String numberLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            'EP',
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            numberLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _EpisodeWatchStatus extends StatelessWidget {
  const _EpisodeWatchStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _IdentityArtworkHero extends StatelessWidget {
  const _IdentityArtworkHero({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _SeriesArtworkImage(
          imageUrl: imageUrl,
          fallbackLabel: fallbackLabel,
          icon: Icons.live_tv_rounded,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _IdentityPoster extends StatelessWidget {
  const _IdentityPoster({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 104,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: _SeriesArtworkImage(
            imageUrl: imageUrl,
            fallbackLabel: fallbackLabel,
            icon: Icons.movie_creation_outlined,
          ),
        ),
      ),
    );
  }
}

class _SeriesArtworkImage extends StatelessWidget {
  const _SeriesArtworkImage({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.icon,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return _SeriesArtworkFallback(fallbackLabel: fallbackLabel, icon: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        alignment: alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              _SeriesArtworkFallback(fallbackLabel: fallbackLabel, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _SeriesArtworkFallback(
            fallbackLabel: fallbackLabel,
            icon: icon,
          );
        },
      ),
    );
  }
}

class _SeriesArtworkFallback extends StatelessWidget {
  const _SeriesArtworkFallback({
    required this.fallbackLabel,
    required this.icon,
  });

  final String fallbackLabel;
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
              fallbackLabel,
              maxLines: 2,
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

String _formatPlaybackPosition(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  }

  return '${duration.inSeconds}s';
}
