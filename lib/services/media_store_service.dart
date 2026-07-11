import 'package:ajs_music_player/models/song.dart';
import 'package:flutter/services.dart';

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel(
    'ajs_music_player/media_store',
  );

  static List<Song>? _cachedSongs;

  static bool get hasCache => _cachedSongs != null;

  static List<Song>? get cachedSongs => _cachedSongs;

  static void clearCache() {
    _cachedSongs = null;
  }

  Future<List<Song>> getSongs() async {
    if (_cachedSongs != null) {
      return _cachedSongs!;
    }

    final List<dynamic> result = await _channel.invokeMethod('getSongs');

    final songs = result
        .map((e) => Song.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();

    _cachedSongs = songs;

    return songs;
  }
}
