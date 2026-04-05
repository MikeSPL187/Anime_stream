import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';

class AnimeStreamApp extends ConsumerWidget {
  const AnimeStreamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Anime Stream',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
