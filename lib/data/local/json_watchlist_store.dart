import 'dart:convert';
import 'dart:io';

class JsonWatchlistStore {
  JsonWatchlistStore({
    required Future<Directory> Function() directoryProvider,
    this.relativeFilePath = 'watchlist/watchlist.json',
  }) : _directoryProvider = directoryProvider;

  final Future<Directory> Function() _directoryProvider;
  final String relativeFilePath;

  Future<Map<String, dynamic>> readAll() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return const {};
    }

    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) {
        return const {};
      }

      final decoded = jsonDecode(contents);
      if (decoded is! Map) {
        return const {};
      }

      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return const {};
    }
  }

  Future<void> writeAll(Map<String, dynamic> payload) async {
    final file = await _resolveFile(createParentDirectory: true);
    await file.writeAsString(jsonEncode(payload));
  }

  Future<File> _resolveFile({bool createParentDirectory = false}) async {
    final directory = await _directoryProvider();
    final file = File('${directory.path}/$relativeFilePath');

    if (createParentDirectory) {
      await file.parent.create(recursive: true);
    }

    return file;
  }
}
