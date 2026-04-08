import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_playback_speed.dart';

void main() {
  group('Player playback speed options', () {
    test('builds playback speed options with the selected rate', () {
      final options = buildPlayerPlaybackSpeedOptions(activeRate: 1.5);

      expect(options.map((option) => option.label), [
        '0.75x',
        '1x',
        '1.25x',
        '1.5x',
        '2x',
      ]);
      expect(options.map((option) => option.isSelected), [
        false,
        false,
        false,
        true,
        false,
      ]);
    });

    test('normalizes unsupported playback rates back to the default rate', () {
      expect(normalizePlayerPlaybackRate(1.1), 1.0);
      expect(formatPlayerPlaybackRateLabel(1.1), '1x');
    });
  });
}
