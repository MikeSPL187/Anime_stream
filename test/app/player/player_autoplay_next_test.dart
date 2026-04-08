import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_autoplay_next.dart';

void main() {
  group('Player autoplay next labels', () {
    test('formats the next-episode countdown label', () {
      expect(
        formatPlayerAutoplayNextEpisodeLabel(
          episodeNumberLabel: '12',
          secondsRemaining: 6,
        ),
        'Next Episode 12 in 6s',
      );
    });

    test('formats the autoplay status copy', () {
      expect(
        formatPlayerAutoplayNextEpisodeStatus(4),
        'Next episode starts in 4s unless you stay here.',
      );
    });
  });
}
