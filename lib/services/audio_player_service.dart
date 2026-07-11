import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  final ValueNotifier<List<Song>> queue = ValueNotifier([]);

  final ValueNotifier<int> currentIndex = ValueNotifier(-1);

  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  bool _initialized = false;

  Song? get currentSong {
    if (currentIndex.value < 0 || currentIndex.value >= queue.value.length) {
      return null;
    }

    return queue.value[currentIndex.value];
  }

  Future<void> init() async {
    if (_initialized) return;

    _initialized = true;

    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });

    _player.positionStream.listen((value) {
      position.value = value;
    });

    _player.durationStream.listen((value) {
      duration.value = value ?? Duration.zero;
    });

    _player.currentIndexStream.listen((index) {
      if (index != null) {
        currentIndex.value = index;
      }
    });

    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        debugPrint('PLAYER ERROR');
        debugPrint(e.toString());
      },
    );
  }

  Future<void> play(List<Song> songs, int index) async {
    queue.value = songs;

    try {
      await _player.stop();

      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) {
          debugPrint(song.title);
          debugPrint(song.uri);

          return AudioSource.uri(Uri.parse(song.uri));
        }).toList(),
      );

      await _player.setAudioSource(
        playlist,
        initialIndex: index,
        preload: true,
      );

      await _player.play();
    } catch (e, st) {
      debugPrint('PLAY ERROR');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async {
    if (queue.value.isEmpty) return;

    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero, index: 0);
    }

    await _player.play();
  }

  Future<void> previous() async {
    if (queue.value.isEmpty) return;

    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero, index: queue.value.length - 1);
    }

    await _player.play();
  }

  Future<void> seek(Duration value) async {
    await _player.seek(value);
  }

  Future<void> stop() async {
    await _player.stop();
    currentIndex.value = -1;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
