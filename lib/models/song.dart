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
