import 'package:flutter/foundation.dart';

import '../models/song.dart';

class PlaybackQueueService {
  PlaybackQueueService._();

  static final PlaybackQueueService instance = PlaybackQueueService._();

  final ValueNotifier<List<Song>> queue = ValueNotifier([]);

  bool get hasItems => queue.value.isNotEmpty;

  List<Song> get items => List.unmodifiable(queue.value);

  void add(Song song) {
    final updated = List<Song>.from(queue.value);

    // Prevent duplicates
    if (updated.any((e) => e.id == song.id)) {
      return;
    }

    updated.add(song);

    queue.value = updated;
  }

  Song? popNext() {
    if (queue.value.isEmpty) {
      return null;
    }

    final updated = List<Song>.from(queue.value);

    final nextSong = updated.removeAt(0);

    queue.value = updated;

    return nextSong;
  }

  void remove(int songId) {
    final updated = List<Song>.from(queue.value)
      ..removeWhere((e) => e.id == songId);

    queue.value = updated;
  }

  void clear() {
    queue.value = [];
  }

  bool contains(int songId) {
    return queue.value.any((e) => e.id == songId);
  }

  int get length => queue.value.length;
}
