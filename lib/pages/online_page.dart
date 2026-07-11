import 'dart:math' as math;

import 'package:flutter/material.dart';

class OnlinePage extends StatelessWidget {
  const OnlinePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050505),
      body: Stack(
        children: [
          const _BackgroundGlow(),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _StreamingAnimation(),

                    const SizedBox(height: 45),

                    Text(
                      'STREAM',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff00E5FF),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'A completely redesigned online\nstreaming experience\nis on its way.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 40),

                    const SizedBox(height: 40),

                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => onNavigate(1),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: const Color(0xff00E5FF).withValues(alpha: .12),
                          border: Border.all(
                            color: const Color(
                              0xff00E5FF,
                            ).withValues(alpha: .35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff00E5FF,
                              ).withValues(alpha: .18),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.library_music_rounded,
                              color: Color(0xff00E5FF),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'GO OFFLINE',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                color: const Color(0xff00E5FF),
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -140,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xff00E5FF),
                  blurRadius: 160,
                  spreadRadius: 45,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -120,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xff00E5FF),
                  blurRadius: 140,
                  spreadRadius: 35,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StreamingAnimation extends StatefulWidget {
  const _StreamingAnimation();

  @override
  State<_StreamingAnimation> createState() => _StreamingAnimationState();
}

class _StreamingAnimationState extends State<_StreamingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children:
                List.generate(4, (index) {
                  final progress = (controller.value + index * .25) % 1;

                  final size = 70 + progress * 130;

                  return Opacity(
                    opacity: 1 - progress,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff00E5FF).withValues(alpha: .45),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                })..add(
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xff00E5FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff00E5FF).withValues(alpha: .6),
                          blurRadius: 35,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: controller.value * math.pi * 2,
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        color: Colors.black,
                        size: 38,
                      ),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }
}
