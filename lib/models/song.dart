import 'package:audio_service/audio_service.dart';

class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final String uri;
  final int duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.uri,
    required this.duration,
  });

  factory Song.fromMap(Map<dynamic, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      path: json['path'] ?? '',
      uri: json['uri'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

/// Maps a [Song] to the [MediaItem] the notification / lock screen reads
/// title, artist, and duration from.
extension SongMediaItem on Song {
  MediaItem toMediaItem() {
    return MediaItem(
      id: id.toString(),
      title: title.trim().split('-').first,
      artist: artist.trim(),
      album: album,
      duration: Duration(milliseconds: duration),
      extras: {'uri': uri},
    );
  }
}
