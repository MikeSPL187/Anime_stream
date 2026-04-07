import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_details_data.dart';
import '../../app/series/series_providers.dart';
import '../../app/watch/watch_state_operation_providers.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/download_entry.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _SeriesHero(details: details),
        const SizedBox(height: 16),
        _PrimaryWatchPanel(details: details),
        const SizedBox(height: 24),
        _EpisodesSection(details: details),
        const SizedBox(height: 24),
        _SaveIntentSection(series: series),
        const SizedBox(height: 24),
        _SeriesDetailsSection(
          series: series,
          episodeCount: details.episodes.length,
        ),
      ],
    );
  }
}

class _SeriesHero extends StatelessWidget {
  const _SeriesHero({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = details.series;
    final facts = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
      '${details.episodes.length} episodes',
    ].join('  •  ');
    final progressSummary = switch ((
      details.inProgressEpisodeCount,
      details.completedEpisodeCount,
    )) {
      (0, 0) => 'No watch activity yet',
      (final inProgress, final completed)
          when inProgress > 0 && completed > 0 =>
        '$inProgress in progress • $completed completed',
      (final inProgress, 0) when inProgress > 0 =>
        '$inProgress episode in progress',
      (0, final completed) when completed > 0 => '$completed completed',
      _ => 'Watch state available',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 236,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _SeriesArtwork(
                  imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
                  fallbackLabel: series.title,
                  icon: Icons.live_tv_rounded,
                  alignment: Alignment.topCenter,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
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
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      if ((series.originalTitle ?? '').trim().isNotEmpty &&
                          series.originalTitle != series.title) ...[
                        const SizedBox(height: 6),
                        Text(
                          series.originalTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                      if (facts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          facts,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          progressSummary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PrimaryWatchPanel extends StatelessWidget {
  const _PrimaryWatchPanel({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    final supportingText = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode when targetEpisode != null =>
        'Continue from Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.continueEpisode when targetEpisode != null =>
        'Up next: Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.startWatching when targetEpisode != null =>
        'Begin with Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'You have completed every currently available episode.',
      SeriesPrimaryWatchActionKind.unavailable =>
        'Episodes are not available yet.',
      _ => 'A playable episode is not available yet.',
    };
    final activityText = switch ((
      details.latestProgress,
      details.latestProgress == null
          ? null
          : details.episodeForProgress(details.latestProgress!),
    )) {
      (final progress?, final episode?) when progress.isCompleted =>
        'Latest activity: completed Episode ${episode.numberLabel}',
      (final progress?, final episode?) =>
        'Latest activity: Episode ${episode.numberLabel} at ${_formatPlaybackPosition(progress.position)}',
      _ => 'Choose a specific episode below or start from the main action.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Watch now', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(action.label, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              supportingText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              activityText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
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
                TextButton(
                  onPressed: () => context.push(AppRoutePaths.watchlist),
                  child: const Text('Open Watchlist'),
                ),
              ],
            ),
          ],
        ),
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

    return savedState.when(
      loading: () => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Checking Watchlist status...')),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'The saved-for-later state could not be loaded right now.\n$error',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (isSaved) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isSaved
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved for later',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This series is already in Watchlist and stays separate from active Continue Watching progress.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                            label: const Text('Remove'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(AppRoutePaths.watchlist),
                            child: const Text('Open Watchlist'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save for later',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use Watchlist for intent to return later without starting playback right now.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => ref
                            .read(
                              watchlistMembershipControllerProvider(
                                series.id,
                              ).notifier,
                            )
                            .addToWatchlist(),
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: const Text('Save to Watchlist'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SeriesDetailsSection extends StatelessWidget {
  const _SeriesDetailsSection({
    required this.series,
    required this.episodeCount,
  });

  final Series series;
  final int episodeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = <String>[
      if (series.releaseYear != null) 'Year ${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(3).join(' • '),
      'Episodes $episodeCount',
    ].where((entry) => entry.trim().isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this series', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        if (facts.isNotEmpty)
          Text(
            facts.join('  •  '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if ((series.synopsis ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            series.synopsis!.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _EpisodesSection extends StatefulWidget {
  const _EpisodesSection({required this.details});

  final SeriesDetailsData details;

  @override
  State<_EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends State<_EpisodesSection> {
  _EpisodeListFilter _selectedFilter = _EpisodeListFilter.all;
  _EpisodeSortOrder _selectedSortOrder = _EpisodeSortOrder.oldestFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = widget.details;
    final series = details.series;
    final episodes = details.episodes;
    final sortedEpisodes = episodes.toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final orderedEpisodes = _selectedSortOrder == _EpisodeSortOrder.oldestFirst
        ? sortedEpisodes
        : sortedEpisodes.reversed.toList(growable: false);
    final inProgressCount = details.inProgressEpisodeCount;
    final watchedCount = details.completedEpisodeCount;
    final unwatchedCount =
        sortedEpisodes.length - inProgressCount - watchedCount;
    final visibleEpisodes = orderedEpisodes
        .where((episode) => _matchesFilter(details, episode))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Episodes', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSortOrder =
                      _selectedSortOrder == _EpisodeSortOrder.oldestFirst
                      ? _EpisodeSortOrder.newestFirst
                      : _EpisodeSortOrder.oldestFirst;
                });
              },
              icon: const Icon(Icons.swap_vert_rounded),
              label: Text(_selectedSortOrder.label),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your next watch decision directly from the episode list. Tap any row to open playback.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _EpisodeFilterButton(
                label: 'All',
                count: sortedEpisodes.length,
                isSelected: _selectedFilter == _EpisodeListFilter.all,
                onTap: () =>
                    setState(() => _selectedFilter = _EpisodeListFilter.all),
              ),
              const SizedBox(width: 8),
              _EpisodeFilterButton(
                label: 'Continue',
                count: inProgressCount,
                isSelected:
                    _selectedFilter == _EpisodeListFilter.continueWatching,
                onTap: () => setState(
                  () => _selectedFilter = _EpisodeListFilter.continueWatching,
                ),
              ),
              const SizedBox(width: 8),
              _EpisodeFilterButton(
                label: 'Unwatched',
                count: unwatchedCount,
                isSelected: _selectedFilter == _EpisodeListFilter.unwatched,
                onTap: () => setState(
                  () => _selectedFilter = _EpisodeListFilter.unwatched,
                ),
              ),
              const SizedBox(width: 8),
              _EpisodeFilterButton(
                label: 'Watched',
                count: watchedCount,
                isSelected: _selectedFilter == _EpisodeListFilter.watched,
                onTap: () => setState(
                  () => _selectedFilter = _EpisodeListFilter.watched,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (episodes.isEmpty)
          const _InlineEpisodesState(
            title: 'Episodes unavailable',
            message: 'Episodes are not available for this series yet.',
          )
        else if (visibleEpisodes.isEmpty)
          _InlineEpisodesState(
            title: 'Nothing in this filter',
            message: switch (_selectedFilter) {
              _EpisodeListFilter.all => 'No episodes are available right now.',
              _EpisodeListFilter.continueWatching =>
                'No episodes are currently in progress for this series.',
              _EpisodeListFilter.unwatched =>
                'Every available episode already has watch-state activity.',
              _EpisodeListFilter.watched =>
                'No episodes have been marked watched yet.',
            },
          )
        else
          Column(
            children: [
              for (var index = 0; index < visibleEpisodes.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _EpisodeRow(
                  series: series,
                  episode: visibleEpisodes[index],
                  savedProgress: details.progressForEpisode(
                    visibleEpisodes[index].id,
                  ),
                  actionHint: _episodeActionHint(
                    details,
                    visibleEpisodes[index],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  bool _matchesFilter(SeriesDetailsData details, Episode episode) {
    return switch (_selectedFilter) {
      _EpisodeListFilter.all => true,
      _EpisodeListFilter.continueWatching => details.isEpisodeInProgress(
        episode.id,
      ),
      _EpisodeListFilter.unwatched => !details.hasSavedProgress(episode.id),
      _EpisodeListFilter.watched => details.isEpisodeCompleted(episode.id),
    };
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
      SeriesPrimaryWatchActionKind.resumeEpisode => const _EpisodeActionHint(
        label: 'Resume here',
        tone: _EpisodeActionHintTone.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => const _EpisodeActionHint(
        label: 'Up next',
        tone: _EpisodeActionHintTone.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => const _EpisodeActionHint(
        label: 'Start here',
        tone: _EpisodeActionHintTone.primary,
      ),
      _ => null,
    };
  }
}

class _EpisodeFilterButton extends StatelessWidget {
  const _EpisodeFilterButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? Colors.black
            : theme.colorScheme.onSurface,
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text('$label ($count)'),
    );
  }
}

class _InlineEpisodesState extends StatelessWidget {
  const _InlineEpisodesState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final downloadKey = EpisodeDownloadKey(
      seriesId: series.id,
      episodeId: episode.id,
    );
    final downloadEntryAsync = ref.watch(
      episodeDownloadEntryProvider(downloadKey),
    );
    final downloadActionState = ref.watch(
      episodeDownloadActionControllerProvider(downloadKey),
    );
    final downloadEntry = downloadEntryAsync.asData?.value;
    final watchStateOperation = ref.watch(
      seriesWatchStateOperationsControllerProvider(series.id),
    );
    final isBusy =
        downloadActionState.isLoading || watchStateOperation.isLoading;

    final statusParts = <String>[
      'Episode ${episode.numberLabel}',
      if (episode.duration != null) '${episode.duration!.inMinutes} min',
      if (episode.isRecap) 'Recap',
      if (episode.isFiller) 'Filler',
      if (savedProgress?.isCompleted == true) 'Completed',
      if (savedProgress != null && savedProgress?.isCompleted != true)
        'In progress',
      if (downloadEntry?.isPlayableOffline == true) 'Available offline',
      if (downloadEntry?.status == DownloadStatus.downloading) 'Downloading',
      if (downloadEntry?.status == DownloadStatus.queued) 'Queued',
      if (downloadEntry?.status == DownloadStatus.failed) 'Download failed',
    ];

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

    final backgroundColor = switch (actionHint?.tone) {
      _EpisodeActionHintTone.primary => theme.colorScheme.primary.withValues(
        alpha: 0.08,
      ),
      _EpisodeActionHintTone.secondary =>
        theme.colorScheme.secondary.withValues(alpha: 0.08),
      null when savedProgress != null => theme.colorScheme.surfaceContainerLow,
      _ => Colors.transparent,
    };

    final watchedMenuAction = savedProgress?.isCompleted == true
        ? _EpisodeRowMenuAction.markUnwatched
        : _EpisodeRowMenuAction.markWatched;
    final downloadMenuAction = switch (downloadEntry?.status) {
      DownloadStatus.completed => _EpisodeRowMenuAction.removeDownload,
      DownloadStatus.failed => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.paused => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.downloading => _EpisodeRowMenuAction.downloadInProgress,
      DownloadStatus.queued => _EpisodeRowMenuAction.downloadInProgress,
      null => _EpisodeRowMenuAction.downloadEpisode,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy
            ? null
            : () => _openEpisodeInPlayer(
                context,
                series: series,
                episode: episode,
              ),
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EP',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      episode.numberLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (actionHint != null)
                      Text(
                        actionHint!.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color:
                              actionHint!.tone ==
                                  _EpisodeActionHintTone.secondary
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    if (actionHint != null) const SizedBox(height: 4),
                    Text(
                      episode.title.trim().isEmpty
                          ? 'Episode ${episode.numberLabel}'
                          : episode.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusParts.join('  •  '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((episode.synopsis ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        episode.synopsis!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (savedProgress != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        savedProgress!.isCompleted
                            ? 'Watched'
                            : savedProgress!.totalDuration != null
                            ? '${_formatPlaybackPosition(savedProgress!.position)} / ${_formatPlaybackPosition(savedProgress!.totalDuration!)} watched'
                            : '${_formatPlaybackPosition(savedProgress!.position)} watched',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (progressFraction != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: isBusy
                        ? null
                        : () => _openEpisodeInPlayer(
                            context,
                            series: series,
                            episode: episode,
                          ),
                    icon: Icon(
                      downloadEntry?.isPlayableOffline == true
                          ? Icons.offline_pin_rounded
                          : Icons.play_circle_fill_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: downloadEntry?.isPlayableOffline == true
                        ? 'Play offline'
                        : 'Play episode',
                  ),
                  PopupMenuButton<_EpisodeRowMenuAction>(
                    enabled: !isBusy,
                    tooltip: 'Episode actions',
                    onSelected: (action) async {
                      await _handleEpisodeMenuAction(
                        context,
                        ref,
                        action,
                        downloadKey: downloadKey,
                        downloadEntry: downloadEntry,
                      );
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<_EpisodeRowMenuAction>(
                        value: _EpisodeRowMenuAction.play,
                        child: Text('Play episode'),
                      ),
                      PopupMenuItem<_EpisodeRowMenuAction>(
                        value: downloadMenuAction,
                        enabled:
                            downloadMenuAction !=
                            _EpisodeRowMenuAction.downloadInProgress,
                        child: Text(downloadMenuAction.label),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<_EpisodeRowMenuAction>(
                        value: watchedMenuAction,
                        child: Text(watchedMenuAction.label),
                      ),
                    ],
                    icon: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.more_vert_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEpisodeMenuAction(
    BuildContext context,
    WidgetRef ref,
    _EpisodeRowMenuAction action, {
    required EpisodeDownloadKey downloadKey,
    required DownloadEntry? downloadEntry,
  }) async {
    if (action == _EpisodeRowMenuAction.play) {
      _openEpisodeInPlayer(context, series: series, episode: episode);
      return;
    }

    final watchController = ref.read(
      seriesWatchStateOperationsControllerProvider(series.id).notifier,
    );
    final downloadController = ref.read(
      episodeDownloadActionControllerProvider(downloadKey).notifier,
    );

    try {
      switch (action) {
        case _EpisodeRowMenuAction.play:
        case _EpisodeRowMenuAction.downloadInProgress:
          return;
        case _EpisodeRowMenuAction.markWatched:
          await watchController.markEpisodeWatched(episode.id);
          break;
        case _EpisodeRowMenuAction.markUnwatched:
          await watchController.markEpisodeUnwatched(episode.id);
          break;
        case _EpisodeRowMenuAction.downloadEpisode:
        case _EpisodeRowMenuAction.retryDownload:
          await downloadController.startDownload();
          break;
        case _EpisodeRowMenuAction.removeDownload:
          final downloadId = downloadEntry?.id;
          if (downloadId == null) {
            throw StateError(
              'A stored download could not be found for this episode.',
            );
          }
          await downloadController.removeDownload(downloadId);
          break;
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not update Episode ${episode.numberLabel}.\n$error',
            ),
          ),
        );
      return;
    }

    if (!context.mounted) {
      return;
    }

    final message = switch (action) {
      _EpisodeRowMenuAction.play => 'Opening Episode ${episode.numberLabel}.',
      _EpisodeRowMenuAction.markWatched =>
        'Episode ${episode.numberLabel} marked as watched.',
      _EpisodeRowMenuAction.markUnwatched =>
        'Episode ${episode.numberLabel} reset to unwatched.',
      _EpisodeRowMenuAction.downloadEpisode =>
        'Episode ${episode.numberLabel} downloaded for offline playback.',
      _EpisodeRowMenuAction.retryDownload =>
        'Episode ${episode.numberLabel} download retried.',
      _EpisodeRowMenuAction.removeDownload =>
        'Offline download removed for Episode ${episode.numberLabel}.',
      _EpisodeRowMenuAction.downloadInProgress =>
        'Download already in progress.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

enum _EpisodeListFilter { all, continueWatching, unwatched, watched }

enum _EpisodeSortOrder {
  oldestFirst('Oldest first'),
  newestFirst('Newest first');

  const _EpisodeSortOrder(this.label);

  final String label;
}

class _EpisodeActionHint {
  const _EpisodeActionHint({required this.label, required this.tone});

  final String label;
  final _EpisodeActionHintTone tone;
}

enum _EpisodeActionHintTone { primary, secondary }

enum _EpisodeRowMenuAction {
  play('Play episode'),
  downloadEpisode('Download for offline'),
  retryDownload('Retry download'),
  removeDownload('Remove offline download'),
  downloadInProgress('Download in progress'),
  markWatched('Mark as watched'),
  markUnwatched('Mark as unwatched');

  const _EpisodeRowMenuAction(this.label);

  final String label;
}

class _SeriesArtwork extends StatelessWidget {
  const _SeriesArtwork({
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
