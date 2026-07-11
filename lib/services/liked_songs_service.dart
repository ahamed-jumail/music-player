import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LikedSongsService {
  LikedSongsService._();

  static final LikedSongsService instance = LikedSongsService._();

  static const _key = 'liked_songs';

  final ValueNotifier<Set<int>> likedSongs = ValueNotifier(<int>{});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final ids = prefs.getStringList(_key) ?? [];

    likedSongs.value = ids.map(int.parse).toSet();
  }

  bool isLiked(int songId) {
    return likedSongs.value.contains(songId);
  }

  Future<void> toggleLike(int songId) async {
    final updated = Set<int>.from(likedSongs.value);

    if (updated.contains(songId)) {
      updated.remove(songId);
    } else {
      updated.add(songId);
    }

    likedSongs.value = updated;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_key, updated.map((e) => e.toString()).toList());
  }

  Future<void> clear() async {
    likedSongs.value = {};

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
