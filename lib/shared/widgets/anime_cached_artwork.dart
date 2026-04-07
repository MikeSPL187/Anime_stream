import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AnimeCachedArtwork extends StatelessWidget {
  const AnimeCachedArtwork({
    super.key,
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
      return AnimeArtworkFallback(label: label, icon: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: CachedNetworkImage(
        imageUrl: trimmedUrl,
        fit: BoxFit.cover,
        imageBuilder: (context, imageProvider) {
          return DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                alignment: alignment,
              ),
            ),
          );
        },
        placeholder: (context, url) {
          return Stack(
            fit: StackFit.expand,
            children: const [
              AnimeArtworkFallback(
                label: '',
                icon: Icons.movie_creation_outlined,
              ),
              Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorWidget: (context, url, error) {
          return AnimeArtworkFallback(label: label, icon: icon);
        },
      ),
    );
  }
}

class AnimeArtworkFallback extends StatelessWidget {
  const AnimeArtworkFallback({
    super.key,
    required this.label,
    required this.icon,
  });

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
            if (label.trim().isNotEmpty) ...[
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
          ],
        ),
      ),
    );
  }
}
