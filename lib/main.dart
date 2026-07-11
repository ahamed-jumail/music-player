import 'package:ajs_music_player/pages/parent_page.dart';
import 'package:ajs_music_player/services/audio_player_service.dart';
import 'package:ajs_music_player/services/liked_songs_service.dart';
import 'package:ajs_music_player/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioPlayerService.instance.init();
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
