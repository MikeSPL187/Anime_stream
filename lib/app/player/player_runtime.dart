import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

final playerRuntimeFactoryProvider = Provider<PlayerRuntimeFactory>((ref) {
  return const MediaKitPlayerRuntimeFactory();
});

abstract interface class PlayerRuntimeFactory {
  Future<void> ensureInitialized();

  PlayerRuntimeHandle create();
}

abstract interface class PlayerRuntimeHandle {
  Stream<String> get errorStream;

  Stream<Duration> get positionStream;

  Stream<Duration> get durationStream;

  Stream<bool> get completedStream;

  Stream<bool> get playingStream;

  Stream<bool> get bufferingStream;

  Stream<double> get rateStream;

  Widget buildView();

  Future<void> open(String sourceUri);

  Future<void> seek(Duration position);

  Future<void> pause();

  Future<void> play();

  Future<void> setRate(double rate);

  Future<void> dispose();
}

class MediaKitPlayerRuntimeFactory implements PlayerRuntimeFactory {
  const MediaKitPlayerRuntimeFactory();

  @override
  Future<void> ensureInitialized() async {
    MediaKit.ensureInitialized();
  }

  @override
  PlayerRuntimeHandle create() {
    return _MediaKitPlayerRuntimeHandle();
  }
}

class _MediaKitPlayerRuntimeHandle implements PlayerRuntimeHandle {
  _MediaKitPlayerRuntimeHandle() : _player = Player() {
    _videoController = VideoController(_player);
  }

  final Player _player;
  late final VideoController _videoController;

  @override
  Stream<String> get errorStream => _player.stream.error;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  Stream<double> get rateStream => _player.stream.rate;

  @override
  Widget buildView() {
    return Video(
      controller: _videoController,
      controls: NoVideoControls,
      fill: Colors.black,
      fit: BoxFit.contain,
    );
  }

  @override
  Future<void> open(String sourceUri) async {
    await _player.open(Media(sourceUri));
  }

  @override
  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  @override
  Future<void> pause() {
    return _player.pause();
  }

  @override
  Future<void> play() {
    return _player.play();
  }

  @override
  Future<void> setRate(double rate) {
    return _player.setRate(rate);
  }

  @override
  Future<void> dispose() {
    return _player.dispose();
  }
}
