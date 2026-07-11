import 'package:flutter/material.dart';

class AnimatedSongBorder extends StatefulWidget {
  const AnimatedSongBorder({
    super.key,
    required this.child,
    required this.isPlaying,
    this.radius = 18,
  });

  final Widget child;
  final bool isPlaying;
  final double radius;

  @override
  State<AnimatedSongBorder> createState() => _AnimatedSongBorderState();
}

class _AnimatedSongBorderState extends State<AnimatedSongBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSongBorder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    }

    if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: const Color(0xff181818),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(4, 4),
            ),
            BoxShadow(
              color: Color(0xff2A2A2A),
              blurRadius: 8,
              offset: Offset(-2, -2),
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return CustomPaint(
          painter: _BorderPainter(
            progress: _controller.value,
            radius: widget.radius,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              color: const Color(0xff181818),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _BorderPainter extends CustomPainter {
  final double progress;
  final double radius;

  _BorderPainter({required this.progress, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      Radius.circular(radius),
    );

    final borderPath = Path()..addRRect(rrect);

    // Base border
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = const Color(0xff2A2A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final metrics = borderPath.computeMetrics().first;

    final length = metrics.length;

    const cometLength = 500.0;

    final start = progress * length;

    final end = start + cometLength;

    Path glowingPath;

    if (end <= length) {
      glowingPath = metrics.extractPath(start, end);
    } else {
      glowingPath = Path()
        ..addPath(metrics.extractPath(start, length), Offset.zero)
        ..addPath(metrics.extractPath(0, end - length), Offset.zero);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = const Color(0xff00E5FF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(glowingPath, glowPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = Colors.white;

    canvas.drawPath(glowingPath, paint);
  }

  @override
  bool shouldRepaint(_BorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
