import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SummaryStrip(),
          const SizedBox(height: 20),
          _SectionBlock(
            title: 'Library',
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
          ),
          const SizedBox(height: 28),
          const _SectionBlock(
            title: 'Playback',
            children: [
              _InfoRow(
                icon: Icons.fullscreen_rounded,
                title: 'Fullscreen-first handset player',
                subtitle: 'Phone playback opens as an immersive watch surface.',
              ),
              Divider(height: 20),
              _InfoRow(
                icon: Icons.save_rounded,
                title: 'Automatic progress sync',
                subtitle:
                    'Playback progress is stored for Continue Watching and Series.',
              ),
              Divider(height: 20),
              _InfoRow(
                icon: Icons.offline_pin_rounded,
                title: 'Offline playback supported',
                subtitle:
                    'Downloaded episodes can open through the player when ready.',
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionBlock(
            title: 'App scope',
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
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountBadge(label: 'Utility route', color: colorScheme.primary),
        _CountBadge(label: 'Player ready', color: colorScheme.secondary),
        _CountBadge(label: 'Offline active', color: colorScheme.tertiary),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.color});

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
