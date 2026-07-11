import 'package:ajs_music_player/services/ajs_audio_handler.dart';
import 'package:ajs_music_player/services/online_payer_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  late final AjsAudioHandler _handler;

  late final AudioPlayer _player;

  AudioPlayer get player => _player;

  final ValueNotifier<List<Song>> queue = ValueNotifier([]);

  final ValueNotifier<int> currentIndex = ValueNotifier(-1);

  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  /// Songs that were manually added to "play next", in the order they were
  /// queued. These always sit immediately after [currentIndex] inside
  /// [queue] (and inside the underlying [ConcatenatingAudioSource]) until
  /// they start playing, at which point they fall off the front of this
  /// list automatically.
  final ValueNotifier<List<Song>> manualQueue = ValueNotifier([]);

  bool _initialized = false;

  Song? get currentSong {
    if (currentIndex.value < 0 || currentIndex.value >= queue.value.length) {
      return null;
    }

    return queue.value[currentIndex.value];
  }

  Future<void> init(AjsAudioHandler handler) async {
    if (_initialized) return;

    _initialized = true;

    _handler = handler;
    _player = handler.player;

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

        // Keep the notification's title/artist in sync with what's
        // actually playing.
        final playingSong = currentSong;

        if (playingSong != null) {
          _handler.mediaItem.add(playingSong.toMediaItem());
        }

        // Once a manually-queued song actually starts playing, it's no
        // longer "up next" — drop it from the manual queue so future
        // additions are inserted in the right place.
        if (playingSong != null &&
            manualQueue.value.isNotEmpty &&
            manualQueue.value.first.id == playingSong.id) {
          final updated = List<Song>.from(manualQueue.value)..removeAt(0);
          manualQueue.value = updated;
        }
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
    // Only one playback source is ever active at a time.
    await OnlinePlayerService.instance.stop();

    queue.value = songs;
    manualQueue.value = [];

    try {
      await _player.stop();

      final playlist = ConcatenatingAudioSource(
        children: songs.map((song) {
          debugPrint(song.title);
          debugPrint(song.uri);

          return AudioSource.uri(Uri.parse(song.uri));
        }).toList(),
      );

      _handler.queue.add(songs.map((s) => s.toMediaItem()).toList());
      _handler.mediaItem.add(songs[index].toMediaItem());

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

  /// Adds [song] so it plays right after the current song, and after any
  /// other songs that were already queued this way (preserving the order
  /// they were added in). This edits the *live* playing queue, so it takes
  /// effect immediately.
  Future<void> addToQueue(Song song) async {
    if (currentIndex.value < 0 || queue.value.isEmpty) {
      // Nothing is currently playing, so there's no "next" position to
      // insert into.
      return;
    }

    final insertPosition = currentIndex.value + 1 + manualQueue.value.length;

    final updatedQueue = List<Song>.from(queue.value);
    final safePosition = insertPosition.clamp(0, updatedQueue.length);
    updatedQueue.insert(safePosition, song);
    queue.value = updatedQueue;

    manualQueue.value = List<Song>.from(manualQueue.value)..add(song);
    _handler.queue.add(updatedQueue.map((s) => s.toMediaItem()).toList());

    try {
      final audioSource = _player.audioSource;

      if (audioSource is ConcatenatingAudioSource) {
        await audioSource.insert(
          safePosition,
          AudioSource.uri(Uri.parse(song.uri)),
        );
      }
    } catch (e, st) {
      debugPrint('ADD TO QUEUE ERROR');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  /// Removes a song (by id) that was previously added via [addToQueue].
  /// Only affects songs still sitting in the manual "up next" queue — it
  /// won't remove the currently playing song or already-played history.
  Future<void> removeFromQueue(int songId) async {
    final isManuallyQueued = manualQueue.value.any((s) => s.id == songId);

    if (!isManuallyQueued) return;

    final index = queue.value.indexWhere((s) => s.id == songId);

    if (index == -1) return;

    final updatedQueue = List<Song>.from(queue.value)..removeAt(index);
    queue.value = updatedQueue;

    manualQueue.value = List<Song>.from(manualQueue.value)
      ..removeWhere((s) => s.id == songId);
    _handler.queue.add(updatedQueue.map((s) => s.toMediaItem()).toList());

    try {
      final audioSource = _player.audioSource;

      if (audioSource is ConcatenatingAudioSource) {
        await audioSource.removeAt(index);
      }
    } catch (e, st) {
      debugPrint('REMOVE FROM QUEUE ERROR');
      debugPrint(e.toString());
      debugPrint(st.toString());
    }
  }

  void clearManualQueue() {
    manualQueue.value = [];
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
    await _handler.stop();
    currentIndex.value = -1;
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
