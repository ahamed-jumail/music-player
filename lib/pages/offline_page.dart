import 'dart:io';
import 'package:ajs_music_player/pages/now_playing_page.dart';
import 'package:ajs_music_player/services/audio_player_service.dart';
import 'package:ajs_music_player/services/liked_songs_service.dart';
import 'package:ajs_music_player/services/playback_queue_service.dart';
import 'package:ajs_music_player/utils/animated_song_border.dart';
import 'package:ajs_music_player/widgets/app_toast.dart';
import 'package:ajs_music_player/widgets/song_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import '../services/media_store_service.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final _service = MediaStoreService();
  final _player = AudioPlayerService.instance;
  final _likedSongs = LikedSongsService.instance;
  final _playbackQueue = PlaybackQueueService.instance;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _songTileKeys = {};
  final Map<int, LayerLink> _layerLinks = {};

  bool _loading = true;
  String? _error;

  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _likedSongs.init();
    _loadSongs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (forceRefresh) {
        MediaStoreService.clearCache();
      }

      await _requestPermission();

      final songs = await _service.getSongs();

      const folder = '/storage/emulated/0/Music/Songs';

      final filteredSongs = songs.where((song) {
        return song.path.toLowerCase().startsWith(folder.toLowerCase());
      }).toList();

      filteredSongs.sort(
        (a, b) => a.title.trim().toLowerCase().compareTo(
          b.title.trim().toLowerCase(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _songs = filteredSongs;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentSong();
        });
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToCurrentSong() {
    if (!_scrollController.hasClients) {
      return;
    }

    final currentSong = _player.currentSong;

    if (currentSong == null) {
      return;
    }

    final index = _songs.indexWhere((song) => song.id == currentSong.id);

    if (index == -1) {
      return;
    }

    const itemExtent = 83.0; // Adjust once to match your tile + separator

    final targetOffset = (index * itemExtent).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if ((targetOffset - _scrollController.offset).abs() < 2) {
      return;
    }

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _requestPermission() async {
    Permission permission;

    if (Platform.isAndroid) {
      permission = Permission.audio;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.request();

    if (!status.isGranted) {
      throw Exception('Audio permission denied');
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);

    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xff00E5FF), Colors.white, Color(0xff00E5FF)],
            ).createShader(bounds);
          },
          child: Text(
            'LIBRARY',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSongs(forceRefresh: true),
        child: Builder(
          builder: (_) {
            if (_loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null) {
              return ListView(
                children: [
                  const SizedBox(height: 150),
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(_error!, textAlign: TextAlign.center)),
                ],
              );
            }

            if (_songs.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.music_off, size: 70),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'No songs found.',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              );
            }

            return ValueListenableBuilder<Set<int>>(
              valueListenable: _likedSongs.likedSongs,
              builder: (_, likedSongs, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: _player.currentIndex,
                  builder: (_, _, _) {
                    final currentSong = _player.currentSong;

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: _songs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 15),
                      itemBuilder: (_, index) {
                        final song = _songs[index];
                        final tileKey = _songTileKeys.putIfAbsent(
                          song.id,
                          () => GlobalKey(),
                        );
                        final layerLink = _layerLinks.putIfAbsent(
                          song.id,
                          () => LayerLink(),
                        );
                        final isPlayingSong =
                            currentSong != null && currentSong.id == song.id;
                        final isLiked = likedSongs.contains(song.id);

                        return CompositedTransformTarget(
                          link: layerLink,
                          child: Container(
                            key: tileKey,
                            child: AnimatedSongBorder(
                              isPlaying: isPlayingSong,
                              child: ListTile(
                                splashColor: Colors.transparent,
                                hoverColor: Colors.transparent,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),

                                leading: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xff00E5FF,
                                    ).withValues(alpha: .15),
                                  ),
                                  child: Icon(
                                    isPlayingSong
                                        ? Icons.equalizer
                                        : Icons.music_note_rounded,
                                    color: const Color(0xff00E5FF),
                                  ),
                                ),

                                title: Text(
                                  song.title.trim().split('-').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),

                                subtitle: Text(
                                  song.artist.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),

                                trailing: SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isLiked)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.pinkAccent,
                                            size: 18,
                                          ),
                                        ),

                                      Expanded(
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: _player.isPlaying,
                                          builder: (_, playing, _) {
                                            if (!isPlayingSong) {
                                              return Text(
                                                _formatDuration(song.duration),
                                                textAlign: TextAlign.end,
                                              );
                                            }

                                            return Icon(
                                              playing
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_fill,
                                              color: const Color(0xff00E5FF),
                                              size: 34,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                onTap: () async {
                                  final currentSong = _player.currentSong;

                                  if (currentSong != null &&
                                      currentSong.id == song.id) {
                                    await _player.toggle();
                                  } else {
                                    await _player.play(_songs, index);
                                  }
                                },

                                onLongPress: () {
                                  SongContextMenu.show(
                                    context: context,
                                    layerLink: layerLink,
                                    song: song,

                                    onLike: () async {
                                      await _likedSongs.toggleLike(song.id);
                                    },

                                    onAddToQueue: () {
                                      if (_playbackQueue.contains(song.id)) {
                                        _playbackQueue.remove(song.id);

                                        AppToast.show(
                                          context: context,
                                          message:
                                              '${song.title} removed from queue',
                                          icon: Icons.playlist_remove_rounded,
                                          iconColor: Colors.redAccent,
                                        );
                                      } else {
                                        _playbackQueue.add(song);

                                        AppToast.show(
                                          context: context,
                                          message:
                                              '${song.title} added to queue',
                                          icon: Icons.playlist_add_rounded,
                                          iconColor: const Color(0xff00E5FF),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _player.currentIndex,
        builder: (_, index, _) {
          if (index == -1) {
            return const SizedBox.shrink();
          }

          final song = _player.currentSong!;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  transitionDuration: const Duration(milliseconds: 500),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                  pageBuilder: (_, animation, _) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position:
                            Tween(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: const NowPlayingPage(),
                      ),
                    );
                  },
                ),
              );
            },
            child: Container(
              width: MediaQuery.of(context).size.width - 24,
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xff00E5FF),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x8000E5FF),
                    blurRadius: 18,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () => _player.previous(),
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),

                  ValueListenableBuilder<bool>(
                    valueListenable: _player.isPlaying,
                    builder: (_, playing, _) {
                      return IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onPressed: () => _player.toggle(),
                        icon: Icon(
                          playing
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: Colors.black,
                          size: 42,
                        ),
                      );
                    },
                  ),

                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () => _player.next(),
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
