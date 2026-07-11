import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff050505),
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  const SizedBox(height: 35),

                  const _HomeHeader(),

                  const SizedBox(height: 40),

                  const Spacer(),

                  _HomeCard(
                    icon: Icons.library_music_rounded,
                    title: 'Offline Library',
                    subtitle: 'Play music stored on your device',
                    onTap: () => onNavigate(1),
                  ),

                  const SizedBox(height: 24),

                  _HomeCard(
                    icon: Icons.cloud_rounded,
                    title: 'Online Streaming',
                    subtitle: 'Search and stream music online',
                    onTap: () => onNavigate(2),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xff151515),
          border: Border.all(
            color: const Color(0xff00E5FF).withValues(alpha: .18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00E5FF).withValues(alpha: .08),
              blurRadius: 30,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: .12),
              ),
              child: Icon(icon, color: const Color(0xff00E5FF), size: 36),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, color: Color(0xff00E5FF)),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatefulWidget {
  const _Background();

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xff040404),
                    Color(0xff0A0A0A),
                    Color(0xff050505),
                  ],
                ),
              ),
            ),

            Positioned(
              top: -120,
              right: -120,
              child: Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff00E5FF).withValues(alpha: .18),
                        blurRadius: 180,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -140,
              left: -110,
              child: Transform.rotate(
                angle: -_controller.value * math.pi * 2,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff00E5FF).withValues(alpha: .12),
                        blurRadius: 160,
                        spreadRadius: 35,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_controller.value),
            ),
          ],
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double animation;

  _ParticlePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final random = math.Random(7);

    for (int i = 0; i < 45; i++) {
      final x =
          (random.nextDouble() * size.width + animation * 120 * (i % 3)) %
          size.width;

      final y =
          (random.nextDouble() * size.height -
              animation * 80 * (i % 2 == 0 ? 1 : -1)) %
          size.height;

      final radius = 1.5 + random.nextDouble() * 2.5;

      paint.color = const Color(
        0xff00E5FF,
      ).withValues(alpha: 0.15 + random.nextDouble() * 0.25);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final glow = 8 + (_controller.value * 14);

        return Column(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: .08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .45),
                    blurRadius: glow,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                color: Color(0xff00E5FF),
                size: 48,
              ),
            ),

            const SizedBox(height: 22),

            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [Color(0xff00E5FF), Colors.white, Color(0xff00E5FF)],
                ).createShader(bounds);
              },
              child: Text(
                'AJs MUSIC PLAYER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Feel Every Beat • Anytime • Anywhere',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white60,
                letterSpacing: 1.2,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 26),

            const _Equalizer(),
          ],
        );
      },
    );
  }
}

class _Equalizer extends StatefulWidget {
  const _Equalizer();

  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return SizedBox(
          width: 120,
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final phase = (_controller.value + index * .18) % 1;

              final height =
                  8 + (18 * (0.5 + 0.5 * math.sin(phase * math.pi * 2)));

              return Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xff00E5FF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff00E5FF).withValues(alpha: .7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
