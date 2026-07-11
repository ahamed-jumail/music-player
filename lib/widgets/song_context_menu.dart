import 'package:ajs_music_player/models/song.dart';
import 'package:ajs_music_player/services/liked_songs_service.dart';
import 'package:ajs_music_player/services/playback_queue_service.dart';
import 'package:flutter/material.dart';

class SongContextMenu {
  SongContextMenu._();

  static OverlayEntry? _overlayEntry;

  static AnimationController? _controller;

  static bool get isShowing => _overlayEntry != null;

  static Future<void> show({
    required BuildContext context,
    required LayerLink layerLink,
    required Song song,
    required VoidCallback onLike,
    required VoidCallback onAddToQueue,
  }) async {
    hide();

    final overlay = Overlay.of(context);

    _controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    final likedService = LikedSongsService.instance;
    final queueService = PlaybackQueueService.instance;
    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: hide,
                  child: const SizedBox.expand(),
                ),
              ),

              CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(0, -12),

                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    alignment: Alignment.bottomCenter,

                    child: Material(
                      color: Colors.transparent,

                      child: Container(
                        width: 230,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff063840),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: const Color(
                              0xff00E5FF,
                            ).withValues(alpha: .25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff00E5FF,
                              ).withValues(alpha: .35),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                            const BoxShadow(
                              color: Colors.black54,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),

                        child: SizedBox(
                          height: 58,
                          child: ValueListenableBuilder<Set<int>>(
                            valueListenable: likedService.likedSongs,
                            builder: (_, likedSongs, _) {
                              return ValueListenableBuilder<List<Song>>(
                                valueListenable: queueService.queue,
                                builder: (_, queue, _) {
                                  final liked = likedSongs.contains(song.id);
                                  final queued = queue.any(
                                    (e) => e.id == song.id,
                                  );

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _ActionButton(
                                        icon: liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: Colors.pinkAccent,
                                        onTap: () {
                                          hide();
                                          onLike();
                                        },
                                      ),

                                      _ActionButton(
                                        icon: queued
                                            ? Icons.queue_music
                                            : Icons.queue_music_outlined,
                                        color: queued
                                            ? const Color(0xff00E5FF)
                                            : Colors.white,
                                        onTap: () {
                                          hide();
                                          onAddToQueue();
                                        },
                                      ),

                                      _ActionButton(
                                        icon: Icons.close_rounded,
                                        color: Colors.redAccent,
                                        onTap: hide,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    _controller!.forward();
  }

  static Future<void> hide() async {
    if (_overlayEntry == null) {
      return;
    }

    if (_controller != null) {
      await _controller!.reverse();
      _controller!.dispose();
      _controller = null;
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        splashColor: const Color(0xff00E5FF).withValues(alpha: .15),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: .18),
          ),
          child: AnimatedScale(
            scale: 1,
            duration: const Duration(milliseconds: 180),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
