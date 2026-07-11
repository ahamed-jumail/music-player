// ignore_for_file: deprecated_member_use

import 'package:ajs_music_player/services/online_payer_service.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class OnlineNowPlayingPage extends StatefulWidget {
  const OnlineNowPlayingPage({super.key, this.onNavigate, this.onDismiss});

  /// Lets the panel jump straight to another tab (e.g. Offline) without
  /// the user having to minimize first.
  final ValueChanged<int>? onNavigate;

  /// Called when the user drags the panel down past the dismiss threshold.
  /// The panel itself is permanently mounted by the parent (OnlinePage) so
  /// that the embedded YouTube WebView is never disposed and playback keeps
  /// going in the background — this callback just tells the parent to
  /// animate the panel out of view.
  final VoidCallback? onDismiss;

  @override
  State<OnlineNowPlayingPage> createState() => _OnlineNowPlayingPageState();
}

class _OnlineNowPlayingPageState extends State<OnlineNowPlayingPage> {
  final player = OnlinePlayerService.instance;

  double _dragOffset = 0;

  String format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Human-readable explanation for the YouTube-reported error codes.
  /// `notEmbeddable` / `html5Error` are what you get when the uploader
  /// (often an official label/label channel) has disabled playback outside
  /// youtube.com — that's a choice made by the video owner, not something
  /// this app can bypass while staying within YouTube's terms.
  String _errorMessage(YoutubeError error) {
    switch (error) {
      case YoutubeError.notEmbeddable:
      case YoutubeError.sameAsNotEmbeddable:
      case YoutubeError.sameAsNotEmbeddable2:
      case YoutubeError.html5Error:
        return "This video can't be streamed here — the uploader has "
            'disabled playback outside YouTube. Try a different result.';
      case YoutubeError.videoNotFound:
      case YoutubeError.cannotFindVideo:
        return 'This video is unavailable or has been removed.';
      case YoutubeError.invalidParam:
      case YoutubeError.unknown:
        return "Couldn't load this video. Try a different result.";
      case YoutubeError.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 0) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        }
      },
      onVerticalDragEnd: (_) {
        if (_dragOffset > 180) {
          // Minimize rather than pop: this panel is a permanently-mounted
          // overlay (not a pushed route), so it stays alive and keeps the
          // WebView — and therefore the audio — playing in the background.
          setState(() => _dragOffset = 0);
          player.minimize();
          widget.onDismiss?.call();
          return;
        }

        setState(() {
          _dragOffset = 0;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xff050505),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _dragOffset)
            ..scale(1 - (_dragOffset * .00018)),
          child: Transform.scale(
            scale: 1 - (_dragOffset * .00018),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: 1 - (_dragOffset * .0012).clamp(0, .45),
              child: Stack(
                children: [
                  _background(),
                  ValueListenableBuilder(
                    valueListenable: player.currentVideo,
                    builder: (_, video, _) {
                      return SizedBox.expand(
                        child: SafeArea(
                          child: Column(
                            children: [
                              _topBar(),
                              const SizedBox(height: 26),
                              _playerDisc(),
                              const SizedBox(height: 40),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: Text(
                                  video?.title ?? 'Nothing playing',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                video?.channelTitle ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 18),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xff00E5FF,
                                  ).withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(
                                      0xff00E5FF,
                                    ).withValues(alpha: .20),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.radio_button_checked,
                                      size: 10,
                                      color: Color(0xff00E5FF),
                                    ),

                                    SizedBox(width: 8),

                                    Text(
                                      'LIVE STREAM',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 11,
                                        letterSpacing: 2,
                                        color: Color(0xff00E5FF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),
                              ValueListenableBuilder<YoutubeError>(
                                valueListenable: player.error,
                                builder: (_, error, _) {
                                  if (error == YoutubeError.none) {
                                    return const SizedBox.shrink();
                                  }
                                  return _errorBanner(_errorMessage(error));
                                },
                              ),
                              const SizedBox(height: 8),
                              _progress(),

                              const SizedBox(height: 42),

                              _controls(),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Color(0xff00E5FF), Colors.white],
              ).createShader(bounds);
            },
            child: const Text(
              'NOW PLAYING',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Streaming from YouTube',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: .45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.redAccent.withValues(alpha: .1),
          border: Border.all(color: Colors.redAccent.withValues(alpha: .4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      children: [
        /// Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff010203), Color(0xff05070D), Color(0xff010203)],
            ),
          ),
        ),

        const _AmbientGlow(),

        const _FloatingParticles(),

        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .015),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The YouTube player itself, framed to look like the app's neon "disc"
  /// artwork instead of a bare video rectangle. Kept visible (rather than
  /// hidden) since playing through YouTube's own embedded surface is what
  /// keeps this compliant with YouTube's terms.
  Widget _playerDisc() {
    return ValueListenableBuilder(
      valueListenable: player.currentVideo,
      builder: (_, video, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: .92, end: 1),
            builder: (_, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff00E5FF).withValues(alpha: .30),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .22),
                    blurRadius: 40,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: YoutubePlayer(controller: player.controller),
                    ),

                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .08),
                              Colors.transparent,
                              Colors.black.withValues(alpha: .25),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ValueListenableBuilder<Duration>(
        valueListenable: player.duration,
        builder: (_, duration, _) {
          final max = duration.inMilliseconds > 0
              ? duration.inMilliseconds.toDouble()
              : 1.0;

          return ValueListenableBuilder<Duration>(
            valueListenable: player.position,
            builder: (_, position, _) {
              final value = position.inMilliseconds.clamp(0, max.toInt());

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: .045),
                  border: Border.all(
                    color: const Color(0xff00E5FF).withValues(alpha: .12),
                  ),
                ),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
                        activeTrackColor: const Color(0xff00E5FF),
                        inactiveTrackColor: Colors.white12,
                        thumbColor: const Color(0xff00E5FF),
                        overlayColor: const Color(
                          0xff00E5FF,
                        ).withValues(alpha: .2),
                      ),
                      child: Slider(
                        min: 0,
                        max: max,
                        value: value.toDouble(),
                        onChanged: (v) {
                          player.seek(Duration(milliseconds: v.toInt()));
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          format(position),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          format(duration),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _controls() {
    return ValueListenableBuilder<bool>(
      valueListenable: player.isPlaying,
      builder: (_, playing, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: .045),
            border: Border.all(
              color: const Color(0xff00E5FF).withValues(alpha: .12),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00E5FF).withValues(alpha: .08),
                blurRadius: 25,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dockButton(icon: Icons.favorite_border_rounded, onTap: () {}),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: playing ? 1 : .96, end: playing ? 1.08 : 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (_, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: player.toggle,
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xff00E5FF), Color(0xff00BCD4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff00E5FF).withValues(alpha: .45),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 46,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              _dockButton(icon: Icons.more_horiz_rounded, onTap: () {}),
            ],
          ),
        );
      },
    );
  }

  Widget _dockButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: .04),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: Icon(icon, color: Colors.white70, size: 24),
      ),
    );
  }
}

class _AmbientGlow extends StatefulWidget {
  const _AmbientGlow();

  @override
  State<_AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<_AmbientGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final value = controller.value;

        return Stack(
          children: [
            Positioned(
              top: -140 + value * 40,
              left: -100,
              child: _glow(330, const Color(0xff00E5FF).withValues(alpha: .12)),
            ),

            Positioned(
              bottom: -120,
              right: -120 + value * 30,
              child: _glow(260, const Color(0xff00BCD4).withValues(alpha: .10)),
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * .45,
              right: -60,
              child: _glow(180, Colors.white.withValues(alpha: .03)),
            ),
          ],
        );
      },
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 40)],
      ),
    );
  }
}

class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _ParticlePainter(controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff00E5FF).withValues(alpha: .16);

    for (int i = 0; i < 35; i++) {
      final x = (i * 53.0) % size.width;

      final y =
          (size.height - ((progress * size.height * 1.2) + i * 95)) %
          size.height;

      canvas.drawCircle(Offset(x, y), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}
