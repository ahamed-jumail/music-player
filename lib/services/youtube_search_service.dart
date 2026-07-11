import 'dart:convert';

import 'package:ajs_music_player/config/youtube_config.dart';
import 'package:http/http.dart' as http;

import '../models/youtube_video.dart';

/// Thin wrapper around the YouTube Data API v3 `search.list` endpoint.
/// This is the official, ToS-compliant way to search YouTube — unlike
/// scraping tools, it won't silently break and won't risk the app getting
/// flagged for abusing YouTube's internal endpoints.
class YoutubeSearchService {
  YoutubeSearchService._();

  static final YoutubeSearchService instance = YoutubeSearchService._();

  static const _baseUrl = 'https://www.googleapis.com/youtube/v3/search';

  Future<List<YoutubeVideo>> search(String query, {int maxResults = 20}) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    if (YoutubeConfig.apiKey == 'YOUR_YOUTUBE_DATA_API_KEY') {
      throw StateError(
        'Add your YouTube Data API v3 key in lib/config/youtube_config.dart '
        'before searching.',
      );
    }

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'part': 'snippet',
        'q': trimmed,
        'type': 'video',
        'videoCategoryId': '10', // "Music" category
        'maxResults': '$maxResults',
        'key': YoutubeConfig.apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'YouTube search failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>?) ?? [];

    return items
        .map((e) => YoutubeVideo.fromJson(e as Map<String, dynamic>))
        .where((v) => v.id.isNotEmpty)
        .toList();
  }
}
