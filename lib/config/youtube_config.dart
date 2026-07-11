/// Holds the YouTube Data API v3 key used for search.
///
/// How to get a free key:
/// 1. Go to https://console.cloud.google.com/ and create a project.
/// 2. APIs & Services -> Library -> enable "YouTube Data API v3".
/// 3. APIs & Services -> Credentials -> Create Credentials -> API key.
/// 4. (Recommended) Restrict the key to "YouTube Data API v3" so it can't
///    be used for anything else if it ever leaks.
///
/// Free quota is 10,000 units/day; a single search call costs 100 units,
/// so you get roughly 100 searches/day per key at no cost.
///
/// NOTE: shipping an API key inside a mobile app binary means a determined
/// user can extract it. That's normal for client-only apps using this API,
/// but if you want tighter control (e.g. rotating the key without an app
/// update, hiding it from decompilation) route this call through a small
/// backend you control instead of calling Google directly from Flutter.
class YoutubeConfig {
  static const String apiKey = 'AIzaSyCRGhCS6jAvkdvIDuHdCPCy8-wTJm8ON8Q';
}
