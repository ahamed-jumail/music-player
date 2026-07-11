import 'dart:async';

import 'package:flutter/material.dart';

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static AnimationController? _controller;
  static Timer? _timer;

  static Future<void> show({
    required BuildContext context,
    required String message,
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xff00E5FF),
    Duration duration = const Duration(seconds: 2),
  }) async {
    await dismiss();

    if (!context.mounted) {
      return;
    }

    final overlay = Overlay.of(context);

    _controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 220),
    );

    final animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _entry = OverlayEntry(
      builder: (_) {
        return SafeArea(
          child: IgnorePointer(
            ignoring: false,
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff111111),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xff00E5FF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff00E5FF,
                                ).withValues(alpha: .25),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: iconColor, size: 22),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),

                              GestureDetector(
                                onTap: dismiss,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);

    _controller!.forward();

    _timer = Timer(duration, dismiss);
  }

  static Future<void> dismiss() async {
    _timer?.cancel();
    _timer = null;

    if (_entry == null) {
      return;
    }

    if (_controller != null) {
      await _controller!.reverse();

      _controller!.dispose();
      _controller = null;
    }

    _entry?.remove();
    _entry = null;
  }
}
