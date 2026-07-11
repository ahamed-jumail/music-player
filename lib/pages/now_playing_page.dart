// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:ajs_music_player/services/audio_player_service.dart';
import 'package:flutter/material.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with TickerProviderStateMixin {
  final player = AudioPlayerService.instance;

  late final AnimationController glowController;
  late final AnimationController footerController;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    footerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    glowController.dispose();
    footerController.dispose();
    super.dispose();
  }

  String format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
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
          Navigator.pop(context);
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

              child: AnimatedBuilder(
                animation: glowController,

                builder: (_, _) {
                  return Stack(
                    children: [
                      _background(),
                      SafeArea(
                        child: Column(
                          children: [
                            _albumArt(),
                            const SizedBox(height: 40),
                            _title(),
                            const SizedBox(height: 24),
                            _progress(),
                            const Spacer(),
                            _controls(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _background() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff050505), Color(0xff0B0B0B), Color(0xff050505)],
            ),
          ),
        ),

        Positioned(
          top: -120,
          left: -80,
          child: Transform.rotate(
            angle: glowController.value * math.pi * 2,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: .08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .45),
                    blurRadius: 120,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: -130,
          right: -70,
          child: Transform.rotate(
            angle: -(glowController.value * math.pi * 2),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: .07),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .40),
                    blurRadius: 110,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _albumArt() {
    return ValueListenableBuilder<bool>(
      valueListenable: player.isPlaying,
      builder: (_, playing, _) {
        return AnimatedBuilder(
          animation: glowController,
          builder: (_, _) {
            final rotation = playing ? glowController.value * math.pi * 2 : 0.0;

            return Transform.translate(
              offset: Offset(0, _dragOffset * .25),
              child: Transform.scale(
                scale: 1 - (_dragOffset * .00035),
                child: Transform.rotate(
                  angle: rotation,
                  child: SizedBox(
                    width: 310,
                    height: 310,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _outerGlow(),
                        ValueListenableBuilder<bool>(
                          valueListenable: player.isPlaying,
                          builder: (_, playing, _) {
                            return _SoundWave(isPlaying: playing);
                          },
                        ),
                        _disc(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _outerGlow() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff00E5FF).withValues(alpha: .28),
            blurRadius: 70,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _disc() {
    return Hero(
      tag: 'currentSongArtwork',
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff151515), Color(0xff252525), Color(0xff0F0F0F)],
          ),
          border: Border.all(color: const Color(0xff00E5FF), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00E5FF).withValues(alpha: .35),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
            ),

            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
            ),

            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .5),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),

            const Icon(Icons.music_note_rounded, size: 95, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    return AnimatedBuilder(
      animation: glowController,
      builder: (_, _) {
        return ValueListenableBuilder<int>(
          valueListenable: player.currentIndex,
          builder: (_, _, _) {
            final song = player.currentSong;

            if (song == null) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff121212),
                    Color(0xff1A1A1A),
                    Color(0xff101010),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xff00E5FF).withValues(alpha: .15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(
                      alpha:
                          .10 +
                          math.sin(glowController.value * 2 * math.pi) * .05,
                    ),
                    blurRadius: 35,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    song.title.trim().split('-')[0],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.artist.trim(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _progress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xff00E5FF).withValues(alpha: .15),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff00E5FF).withValues(
              alpha: .10 + math.sin(glowController.value * 2 * math.pi) * .05,
            ),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          ValueListenableBuilder<Duration>(
            valueListenable: player.position,
            builder: (_, position, _) {
              return ValueListenableBuilder<Duration>(
                valueListenable: player.duration,
                builder: (_, duration, _) {
                  final max = duration.inMilliseconds == 0
                      ? 1.0
                      : duration.inMilliseconds.toDouble();

                  final value = position.inMilliseconds.clamp(
                    0,
                    duration.inMilliseconds,
                  );

                  return Column(
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
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            format(duration),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(Icons.skip_previous_rounded, 58, () async {
                await player.previous();
              }),

              ValueListenableBuilder<bool>(
                valueListenable: player.isPlaying,
                builder: (_, playing, _) {
                  return _playPauseButton(playing);
                },
              ),

              _circleButton(Icons.skip_next_rounded, 58, () async {
                await player.next();
              }),
            ],
          ),
        ),

        const SizedBox(height: 35),

        AnimatedBuilder(
          animation: footerController,
          builder: (_, _) {
            final isOn = footerController.value < 0.75;

            return Text(
              'AJs Music Player',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                letterSpacing: 3,
                color: isOn ? Colors.white : Colors.white12,
                shadows: isOn
                    ? [const Shadow(color: Color(0xff00E5FF), blurRadius: 28)]
                    : [],
              ),
            );
          },
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  Widget _playPauseButton(bool playing) {
    return GestureDetector(
      onTap: () async {
        await player.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xff00E5FF), Color(0xff00B8D4)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00E5FF).withValues(alpha: .45),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 52,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, double size, VoidCallback onPressed) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .05),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 34),
      ),
    );
  }

  //   Widget _smallButton(IconData icon, VoidCallback onPressed) {
  //     return InkWell(
  //       borderRadius: BorderRadius.circular(30),
  //       onTap: onPressed,
  //       child: Container(
  //         width: 46,
  //         height: 46,
  //         decoration: BoxDecoration(
  //           shape: BoxShape.circle,
  //           color: Colors.white.withValues(.03),
  //         ),
  //         child: Icon(icon, color: Colors.white54, size: 24),
  //       ),
  //     );
  //   }
}

class _SoundWave extends StatefulWidget {
  const _SoundWave({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void didUpdateWidget(covariant _SoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying) {
      if (!controller.isAnimating) {
        controller.repeat();
      }
    } else {
      controller.stop();
    }
  }

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isPlaying) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      const baseSize = 220.0;
      const gap = 12.0;
      const ringCount = 8;

      return Stack(
        alignment: Alignment.center,
        children: List.generate(ringCount, (index) {
          final size = baseSize + (index * gap) + 20;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(
                  0xff00E5FF,
                ).withValues(alpha: 0.16 - (index * 0.012)),
                width: 1.5,
              ),
            ),
          );
        }),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(4, (index) {
            final value = ((controller.value + index * .25) % 1);

            final size = 220 + (value * 140);

            final opacity = (1 - value) * .28;

            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xff00E5FF).withValues(alpha: opacity),
                  width: 2,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
