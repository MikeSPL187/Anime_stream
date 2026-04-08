import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/shared/user_facing_async_error.dart';

void main() {
  group('userFacingAsyncErrorMessage', () {
    test('uses the fallback when the error only contains diagnostic text', () {
      final message = userFacingAsyncErrorMessage(
        StateError('SocketException: upstream transport failed'),
        fallbackMessage: 'Fallback copy.',
      );

      expect(message, 'Fallback copy.');
    });

    test('preserves an explicit preferred message', () {
      final message = userFacingAsyncErrorMessage(
        StateError('ignored'),
        fallbackMessage: 'Fallback copy.',
        preferredMessage: 'Playable stream could not be resolved right now.',
      );

      expect(message, 'Playable stream could not be resolved right now.');
    });

    test('normalizes safe state error messages', () {
      final message = userFacingAsyncErrorMessage(
        StateError('Offline file is missing on this device.'),
        fallbackMessage: 'Fallback copy.',
        allowStructuredMessage: true,
      );

      expect(message, 'Offline file is missing on this device.');
    });
  });
}
