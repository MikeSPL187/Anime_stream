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
        children: const [
          _SectionIntro(
            title: 'Library shortcuts',
            message:
                'Open saved titles, offline downloads, and completed history from one utility route.',
          ),
          SizedBox(height: 16),
          _LibrarySection(),
          SizedBox(height: 28),
          _SectionIntro(
            title: 'Playback behavior',
            message:
                'These flows are already handled by the app and do not require manual setup.',
          ),
          SizedBox(height: 16),
          _PlaybackSection(),
          SizedBox(height: 28),
          _SectionIntro(
            title: 'Product scope',
            message:
                'This app stays single-user and relies on AniLibria-backed catalog, series, playback, and offline flows.',
          ),
          SizedBox(height: 16),
          _ProductScopeSection(),
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

class _PlaybackSection extends StatelessWidget {
  const _PlaybackSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionBlock(
      children: [
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
        Divider(height: 20),
        _InfoRow(
          icon: Icons.screen_rotation_alt_rounded,
          title: 'Handset playback adapts by state',
          subtitle:
              'Phone playback stays video-first and can expand into fullscreen watching.',
        ),
      ],
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
