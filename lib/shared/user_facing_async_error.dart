String userFacingAsyncErrorMessage(
  Object error, {
  required String fallbackMessage,
  String? preferredMessage,
  bool allowStructuredMessage = false,
}) {
  final normalizedPreferred = _normalizeErrorMessage(preferredMessage);
  if (normalizedPreferred != null) {
    return normalizedPreferred;
  }

  if (!allowStructuredMessage) {
    return fallbackMessage;
  }

  final normalizedError = _normalizeErrorMessage(
    _extractStructuredMessage(error),
  );
  return normalizedError ?? fallbackMessage;
}

String? _extractStructuredMessage(Object error) {
  return switch (error) {
    StateError(:final message) => message.toString(),
    ArgumentError(:final message) => message?.toString(),
    _ => null,
  };
}

String? _normalizeErrorMessage(String? message) {
  final trimmedMessage = message?.trim();
  if (trimmedMessage == null || trimmedMessage.isEmpty) {
    return null;
  }

  final normalizedMessage = trimmedMessage
      .replaceFirst(RegExp(r'^Bad state:\s*'), '')
      .replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '')
      .replaceFirst(RegExp(r'^[A-Za-z]+Error:\s*'), '')
      .trim();
  if (normalizedMessage.isEmpty || _looksDiagnostic(normalizedMessage)) {
    return null;
  }

  return normalizedMessage;
}

bool _looksDiagnostic(String message) {
  final lowerCaseMessage = message.toLowerCase();
  return lowerCaseMessage.startsWith('instance of ') ||
      lowerCaseMessage.contains('stack trace') ||
      lowerCaseMessage.contains('socketexception') ||
      lowerCaseMessage.contains('dioexception') ||
      lowerCaseMessage.contains('xmlhttprequest') ||
      lowerCaseMessage.contains('typeerror') ||
      lowerCaseMessage.contains('fluttererror') ||
      lowerCaseMessage.contains('assertion failed');
}
