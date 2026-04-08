import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_stage_copy.dart';

void main() {
  group('buildPlayerOpeningStageCopy', () {
    test('maps initial stream opening into honest stage copy', () {
      final copy = buildPlayerOpeningStageCopy(
        phase: PlayerPlaybackOpeningPhase.openingStream,
        qualityLabel: '1080p',
      );

      expect(copy.title, 'Opening Stream');
      expect(copy.message, contains('1080p'));
      expect(copy.statusLabel, 'Opening');
      expect(copy.statusText, 'Player is opening this stream.');
    });

    test('maps quality switching into recoverable transition copy', () {
      final copy = buildPlayerOpeningStageCopy(
        phase: PlayerPlaybackOpeningPhase.switchingQuality,
        qualityLabel: '720p',
      );

      expect(copy.title, 'Switching Quality');
      expect(copy.message, contains('720p'));
      expect(copy.statusLabel, 'Switching');
      expect(copy.statusText, contains('different stream quality'));
    });

    test('maps playback recovery into explicit fallback copy', () {
      final copy = buildPlayerOpeningStageCopy(
        phase: PlayerPlaybackOpeningPhase.recoveringPlayback,
        qualityLabel: '480p',
      );

      expect(copy.title, 'Recovering Playback');
      expect(copy.message, contains('480p'));
      expect(copy.statusLabel, 'Recovering');
      expect(copy.statusText, contains('another available stream'));
    });

    test('maps retry flow into explicit retry copy', () {
      final copy = buildPlayerOpeningStageCopy(
        phase: PlayerPlaybackOpeningPhase.retryingPlayback,
        qualityLabel: '1080p',
      );

      expect(copy.title, 'Retrying Stream');
      expect(copy.message, contains('1080p'));
      expect(copy.statusLabel, 'Retrying');
      expect(copy.statusText, 'Player is retrying the current stream.');
    });
  });
}
