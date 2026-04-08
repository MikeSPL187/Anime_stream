import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_playback_source.dart';

void main() {
  group('PlayerPlaybackSource quality options', () {
    test('builds manual quality options with selected and offline flags', () {
      final source = PlayerPlaybackSource(
        variants: const [
          PlayerPlaybackVariant(
            sourceUri: 'https://cdn.example.com/episode-3-1080.m3u8',
            qualityLabel: '1080p',
            kind: PlayerPlaybackSourceKind.remoteHls,
          ),
          PlayerPlaybackVariant(
            sourceUri: 'https://cdn.example.com/episode-3-720.m3u8',
            qualityLabel: '720p',
            kind: PlayerPlaybackSourceKind.remoteHls,
          ),
          PlayerPlaybackVariant(
            sourceUri: 'file:///downloads/episode-3-480/index.m3u8',
            qualityLabel: '480p offline',
            kind: PlayerPlaybackSourceKind.localHlsManifest,
          ),
        ],
      );

      final options = source.qualityOptions(activeVariantIndex: 1);

      expect(source.supportsManualQualitySelection, isTrue);
      expect(options, hasLength(3));
      expect(options.map((option) => option.label), [
        '1080p',
        '720p',
        '480p offline',
      ]);
      expect(options.map((option) => option.isSelected), [false, true, false]);
      expect(options.map((option) => option.isOffline), [false, false, true]);
    });

    test('returns no manual quality options for a single variant source', () {
      final source = PlayerPlaybackSource(
        variants: const [
          PlayerPlaybackVariant(
            sourceUri: 'file:///downloads/episode-3/index.mp4',
            qualityLabel: '1080p offline',
            kind: PlayerPlaybackSourceKind.localFile,
          ),
        ],
      );

      expect(source.supportsManualQualitySelection, isFalse);
      expect(source.qualityOptions(activeVariantIndex: 0), isEmpty);
    });
  });
}
