import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/app/router/app_shell.dart';

void main() {
  testWidgets('AppShell switches across Home, Browse, and My Lists', (
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
              path: AppRoutePaths.browse,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Browse Content'))),
            ),
            GoRoute(
              path: AppRoutePaths.myLists,
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('My Lists Content'))),
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
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('My Lists'), findsOneWidget);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();

    expect(find.text('Browse Content'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutePaths.browse,
    );

    await tester.tap(find.text('My Lists'));
    await tester.pumpAndSettle();

    expect(find.text('My Lists Content'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutePaths.myLists,
    );
  });
}
