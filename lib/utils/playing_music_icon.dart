import 'package:flutter/material.dart';

class PlayingMusicIcon extends StatefulWidget {
  const PlayingMusicIcon({super.key, required this.isPlaying, this.size = 52});

  final bool isPlaying;
  final double size;

  @override
  State<PlayingMusicIcon> createState() => _PlayingMusicIconState();
}

class _PlayingMusicIconState extends State<PlayingMusicIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _scale;

  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scale = Tween(
      begin: .9,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotation = Tween(
      begin: -.08,
      end: .08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PlayingMusicIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
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
        return Transform.rotate(
          angle: widget.isPlaying ? _rotation.value : 0,
          child: Transform.scale(
            scale: widget.isPlaying ? _scale.value : 1,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                boxShadow: widget.isPlaying
                    ? const [
                        BoxShadow(
                          color: Color(0xff00E5FF),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                widget.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: const Color(0xff00E5FF),
                size: widget.size * .52,
              ),
            ),
          ),
        );
      },
    );
  }
}
