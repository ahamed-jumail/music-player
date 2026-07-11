import 'package:flutter/foundation.dart';

import '../models/song.dart';
import 'audio_player_service.dart';

/// Thin wrapper around [AudioPlayerService.manualQueue].
///
/// Previously this service kept its own, separate list of "queued" songs
/// that was never connected to what [AudioPlayerService] actually played,
/// so adding/removing songs here had no effect on playback order. Now it
/// simply delegates to [AudioPlayerService], which splices songs directly
/// into the live playing queue (and the underlying just_audio playlist).
class PlaybackQueueService {
  PlaybackQueueService._();

  static final PlaybackQueueService instance = PlaybackQueueService._();

  final AudioPlayerService _audioPlayer = AudioPlayerService.instance;

  ValueNotifier<List<Song>> get queue => _audioPlayer.manualQueue;

  bool get hasItems => queue.value.isNotEmpty;

  List<Song> get items => List.unmodifiable(queue.value);

  Future<void> add(Song song) async {
    if (contains(song.id)) {
      return;
    }

    await _audioPlayer.addToQueue(song);
  }

  Future<Song?> popNext() async {
    if (queue.value.isEmpty) {
      return null;
    }

    final nextSong = queue.value.first;
    await remove(nextSong.id);
    return nextSong;
  }

  Future<void> remove(int songId) async {
    await _audioPlayer.removeFromQueue(songId);
  }

  void clear() {
    _audioPlayer.clearManualQueue();
  }

  bool contains(int songId) {
    return queue.value.any((e) => e.id == songId);
  }

  int get length => queue.value.length;
}