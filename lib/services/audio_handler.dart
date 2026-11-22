import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/station.dart';

/// Runs inside audio_service so playback continues in the background,
/// with controls in the notification and on the lock screen.
class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  Station? current;
  Timer? _sleepTimer;
  DateTime? sleepAt;

  RadioAudioHandler() {
    _player.playbackEventStream.listen(
      (e) => playbackState.add(_transform(e)),
      // Stream dropped mid-play: state goes idle; tapping play reconnects.
      onError: (Object _, StackTrace __) =>
          playbackState.add(_transform(_player.playbackEvent)),
    );
    // Keep the notification's play/pause button in sync.
    _player.playingStream.listen((_) {
      playbackState.add(_transform(_player.playbackEvent));
    });
  }

  Future<void> playStation(Station s) async {
    current = s;
    mediaItem.add(MediaItem(
      id: s.url,
      title: s.name,
      artist: s.subtitle,
      artUri: s.favicon.isNotEmpty ? Uri.tryParse(s.favicon) : null,
      isLive: true,
    ));
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(s.url)));
      // Note: play() completes only when playback stops, so don't await it.
      unawaited(_player.play());
    } on PlayerException catch (e) {
      await _player.stop();
      throw Exception('المحطة دي مش شغالة دلوقتي (${e.code})');
    } on PlayerInterruptedException {
      // Another station was selected while this one was loading — fine.
    }
  }

  @override
  Future<void> play() async {
    if (current == null) return;
    if (_player.processingState == ProcessingState.idle) {
      // Live streams: reconnect instead of resuming a stale buffer.
      await playStation(current!);
    } else {
      unawaited(_player.play());
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    cancelSleepTimer();
    await _player.stop();
    await super.stop();
  }

  void setSleepTimer(Duration d) {
    _sleepTimer?.cancel();
    sleepAt = DateTime.now().add(d);
    _sleepTimer = Timer(d, () {
      sleepAt = null;
      stop();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepAt = null;
  }

  PlaybackState _transform(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
      ],
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
    );
  }
}
