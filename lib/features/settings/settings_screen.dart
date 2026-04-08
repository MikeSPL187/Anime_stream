import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/player/player_playback_speed.dart';
import '../../app/router/app_router.dart';
import '../../app/settings/playback_preferences_providers.dart';
import '../../domain/models/playback_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SectionIntro(
            title: 'Library shortcuts',
            message:
                'Open saved titles, offline downloads, and completed history from one utility route.',
          ),
          const SizedBox(height: 16),
          const _LibrarySection(),
          const SizedBox(height: 28),
          const _SectionIntro(
            title: 'Playback preferences',
            message:
                'Set the default watch behavior the player should reuse every time you open an episode.',
          ),
          const SizedBox(height: 16),
          const _PlaybackPreferencesSection(),
          const SizedBox(height: 28),
          const _SectionIntro(
            title: 'Product scope',
            message:
                'This app stays single-user and relies on AniLibria-backed catalog, series, playback, and offline flows.',
          ),
          const SizedBox(height: 16),
          const _ProductScopeSection(),
        ],
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LibrarySection extends StatelessWidget {
  const _LibrarySection();

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      children: [
        _ActionRow(
          icon: Icons.bookmarks_rounded,
          title: 'Open My Lists',
          subtitle: 'Saved titles, downloads, and watch history.',
          onTap: () => context.go(AppRoutePaths.myLists),
        ),
        const Divider(height: 20),
        _ActionRow(
          icon: Icons.bookmark_outline_rounded,
          title: 'Open Watchlist',
          subtitle: 'Saved-for-later titles outside active playback.',
          onTap: () => context.push(AppRoutePaths.watchlist),
        ),
        const Divider(height: 20),
        _ActionRow(
          icon: Icons.download_rounded,
          title: 'Open Downloads',
          subtitle: 'Offline-ready episodes and active download states.',
          onTap: () => context.push(AppRoutePaths.downloads),
        ),
        const Divider(height: 20),
        _ActionRow(
          icon: Icons.history_rounded,
          title: 'Open History',
          subtitle: 'Completed episodes kept separate from re-entry.',
          onTap: () => context.push(AppRoutePaths.history),
        ),
      ],
    );
  }
}

class _PlaybackPreferencesSection extends ConsumerWidget {
  const _PlaybackPreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(playbackPreferencesControllerProvider);

    Future<void> savePreference(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (_) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Playback preferences could not be saved right now.',
              ),
            ),
          );
      }
    }

    return preferencesAsync.when(
      loading: () => const _SectionBlock(
        children: [
          _InfoRow(
            icon: Icons.tune_rounded,
            title: 'Loading playback preferences',
            subtitle: 'Reading your saved default watch behavior.',
          ),
        ],
      ),
      error: (error, stackTrace) => _SectionBlock(
        children: [
          const _InfoRow(
            icon: Icons.error_outline_rounded,
            title: 'Playback preferences unavailable',
            subtitle:
                'The player defaults could not be loaded right now. Retry to restore them.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(playbackPreferencesControllerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
      data: (preferences) => _SectionBlock(
        children: [
          _TogglePreferenceRow(
            icon: Icons.skip_next_rounded,
            title: 'Autoplay next episode',
            subtitle:
                'Start the next episode automatically after the countdown finishes.',
            value: preferences.autoplayNextEpisode,
            onChanged: (enabled) => savePreference(
              () => ref
                  .read(playbackPreferencesControllerProvider.notifier)
                  .setAutoplayNextEpisode(enabled),
            ),
          ),
          const Divider(height: 28),
          _ChoicePreferenceRow(
            icon: Icons.speed_rounded,
            title: 'Default playback speed',
            subtitle:
                'Used when a fresh player session starts. Manual changes during playback still take over for the current watch session.',
            selectedRate: preferences.defaultPlaybackSpeed,
            onSelected: (rate) => savePreference(
              () => ref
                  .read(playbackPreferencesControllerProvider.notifier)
                  .setDefaultPlaybackSpeed(rate),
            ),
          ),
          const Divider(height: 28),
          _TextChoicePreferenceRow(
            icon: Icons.download_for_offline_rounded,
            title: 'Default download quality',
            subtitle:
                'Preselected when you save an episode for offline playback. You can still override it per episode.',
            selectedValue: preferences.defaultDownloadQuality,
            options: supportedDownloadQualityLabels,
            onSelected: (qualityLabel) => savePreference(
              () => ref
                  .read(playbackPreferencesControllerProvider.notifier)
                  .setDefaultDownloadQuality(qualityLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductScopeSection extends StatelessWidget {
  const _ProductScopeSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionBlock(
      children: [
        _InfoRow(
          icon: Icons.person_outline_rounded,
          title: 'Single-user product',
          subtitle:
              'No profiles, subscriptions, or service-scale account systems.',
        ),
        Divider(height: 20),
        _InfoRow(
          icon: Icons.cloud_outlined,
          title: 'AniLibria-backed flows',
          subtitle:
              'Catalog, series, playback resolution, and offline packaging use AniLibria-backed data.',
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TogglePreferenceRow extends StatelessWidget {
  const _TogglePreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _ChoicePreferenceRow extends StatelessWidget {
  const _ChoicePreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedRate,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double selectedRate;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedRate = normalizePlayerPlaybackRate(selectedRate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final rate in supportedPlayerPlaybackRates)
                    ChoiceChip(
                      label: Text(formatPlayerPlaybackRateLabel(rate)),
                      selected: (normalizedRate - rate).abs() < 0.001,
                      onSelected: (_) => onSelected(rate),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextChoicePreferenceRow extends StatelessWidget {
  const _TextChoicePreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String selectedValue;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedValue = normalizeDownloadQualityLabel(selectedValue);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in options)
                    ChoiceChip(
                      label: Text(option),
                      selected: option == normalizedValue,
                      onSelected: (_) => onSelected(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: theme.colorScheme.primary),
    );
  }
}
