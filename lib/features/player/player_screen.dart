import 'package:flutter/material.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, this.sessionContext});

  final PlayerScreenContext? sessionContext;

  @override
  Widget build(BuildContext context) {
    final contextLabel = sessionContext == null
        ? 'No session context provided'
        : 'Session context placeholder';

    return Scaffold(
      appBar: AppBar(title: const Text('Player')),
      body: Center(child: Text('Player screen placeholder\n$contextLabel')),
    );
  }
}

class PlayerScreenContext {
  const PlayerScreenContext({this.seriesId, this.episodeId});

  final String? seriesId;
  final String? episodeId;
}
