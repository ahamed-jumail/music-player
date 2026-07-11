/// A single result from the YouTube Data API's `search.list` endpoint,
/// trimmed down to what the player UI needs.
class YoutubeVideo {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;

  const YoutubeVideo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    final idField = json['id'];

    // search.list returns id as {"kind": "...", "videoId": "..."}
    final videoId = idField is Map
        ? (idField['videoId'] as String? ?? '')
        : (idField as String? ?? '');

    final snippet = (json['snippet'] as Map<dynamic, dynamic>?) ?? {};
    final thumbnails = (snippet['thumbnails'] as Map<dynamic, dynamic>?) ?? {};

    final thumb =
        (thumbnails['high'] ?? thumbnails['medium'] ?? thumbnails['default'])
            as Map<dynamic, dynamic>?;

    return YoutubeVideo(
      id: videoId,
      title: (snippet['title'] as String?) ?? '',
      channelTitle: (snippet['channelTitle'] as String?) ?? '',
      thumbnailUrl: (thumb?['url'] as String?) ?? '',
    );
  }
}
