import 'package:ajs_music_player/pages/parent_page.dart';
import 'package:ajs_music_player/services/ajs_audio_handler.dart';
import 'package:ajs_music_player/services/audio_player_service.dart';
import 'package:ajs_music_player/services/liked_songs_service.dart';
import 'package:ajs_music_player/theme/app_theme.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => AjsAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ajs.music_player.channel.audio',
      androidNotificationChannelName: 'Playback',
      // Keep the foreground service (and notification) alive while paused
      // too — it should only go away when the app task is actually killed.
      androidStopForegroundOnPause: false,
    ),
  );

  await AudioPlayerService.instance.init(audioHandler);
  await LikedSongsService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: ParentPage(),
    );
  }
}
