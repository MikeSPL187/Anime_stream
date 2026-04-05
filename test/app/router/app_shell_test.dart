import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/app/router/app_shell.dart';

void main() {
  testWidgets('AppShell switches between Home and Search destinations', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutePaths.home,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(location: state.uri.path, child: child);
          },
          routes: [
            GoRoute(
              path: AppRoutePaths.home,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Home Content'))),
            ),
            GoRoute(
              path: AppRoutePaths.search,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Search Content'))),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Home Content'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search Content'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutePaths.search,
    );
  });
}
