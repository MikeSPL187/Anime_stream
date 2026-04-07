import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/json_downloads_store.dart';
import '../../data/repositories/local/local_downloads_repository.dart';
import '../../domain/repositories/downloads_repository.dart';
import 'series_repository_provider.dart';

final downloadsStoreProvider = Provider<JsonDownloadsStore>((ref) {
  return JsonDownloadsStore(
    directoryProvider: getApplicationDocumentsDirectory,
  );
});

final downloadsRootDirectoryProvider = Provider<Future<Directory> Function()>((
  ref,
) {
  return getApplicationDocumentsDirectory;
});

final downloadsRepositoryProvider = Provider<DownloadsRepository>((ref) {
  return LocalDownloadsRepository(
    downloadsStore: ref.watch(downloadsStoreProvider),
    remoteDataSource: ref.watch(anilibriaRemoteDataSourceProvider),
    dio: ref.watch(anilibriaDioProvider),
    downloadsRootDirectoryProvider: ref.watch(downloadsRootDirectoryProvider),
  );
});
