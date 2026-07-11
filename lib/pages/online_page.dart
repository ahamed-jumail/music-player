import 'dart:math' as math;

import 'package:ajs_music_player/models/youtube_video.dart';
import 'package:ajs_music_player/pages/online_now_playing_page.dart';
import 'package:ajs_music_player/services/online_payer_service.dart';
import 'package:ajs_music_player/services/youtube_search_service.dart';
import 'package:flutter/material.dart';

class OnlinePage extends StatefulWidget {
  const OnlinePage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage>
    with SingleTickerProviderStateMixin {
  final _search = YoutubeSearchService.instance;
  final _player = OnlinePlayerService.instance;
  final _controller = TextEditingController();

  bool _loading = false;
  String? _error;
  List<YoutubeVideo> _results = [];
  bool _searched = false;

  // The full-screen "Online Now Playing" panel (and the YoutubePlayer
  // WebView inside it) is mounted from the very first build of this page —
  // never lazily — and kept permanently in the tree afterwards. It's only
  // ever slid/faded in and out via _panelController, never removed.
  //
  // This matters because `player.play(video)` needs an already-attached
  // WebView to load the video into. If the panel were built lazily (only
  // once a video first starts playing), the very first play() call would
  // fire before any YoutubePlayer widget existed anywhere in the tree, so
  // the video would silently fail to attach — the mini bar would still
  // show (since the video info is set immediately), but nothing would
  // actually play until the panel was opened for the first time and the
  // WebView finally attached.

  late final AnimationController _panelController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    reverseDuration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _panelFade = CurvedAnimation(
    parent: _panelController,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<Offset> _panelSlide =
      Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero).animate(
        CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
      );

  void _openNowPlaying() {
    FocusScope.of(context).unfocus();
    _player.expand();
    _panelController.forward();
  }

  void _closeNowPlaying() {
    _panelController.reverse();
    _player.minimize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _panelController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _controller.text;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });

    try {
      final results = await _search.search(query);

      if (!mounted) return;

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _play(YoutubeVideo video) async {
    FocusScope.of(context).unfocus();

    // The panel (and its YoutubePlayer WebView) is mounted from the very
    // first build() — see the persistent overlay below — so it's always
    // safe to start playback first and then reveal the panel, even on the
    // very first video played in this page's lifetime.
    await _player.play(video);

    if (!mounted) return;

    _openNowPlaying();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        viewInsets: EdgeInsets.zero,
        viewPadding: mediaQuery.viewPadding,
        padding: mediaQuery.padding,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff050505),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const _BackgroundGlow(),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(26, 15, 26, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Discover',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  _searchBar(),
                  Expanded(child: _body()),
                ],
              ),
            ),

            // Permanently-mounted mini player bar.
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: AnimatedBuilder(
                animation: _panelController,
                builder: (_, child) {
                  return IgnorePointer(
                    ignoring: _panelController.value > 0,
                    child: Opacity(
                      opacity: 1 - _panelController.value,
                      child: child,
                    ),
                  );
                },
                child: SafeArea(top: false, child: _miniPlayer()),
              ),
            ),

            // Full-screen "Online Now Playing" panel. Mounted from the very
            // first build of this page (see note on the field removed above)
            // and kept permanently in the tree — only its opacity/position
            // animate — so the embedded YouTube WebView, and therefore the
            // audio, keeps playing even after the panel is dismissed or the
            // app is sent to the background. The fade + slide-up transition
            // and the drag-down-to-dismiss gesture match the offline Now
            // Playing page exactly.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _panelController,
                builder: (_, child) {
                  return IgnorePointer(
                    ignoring: _panelController.value == 0,
                    child: child,
                  );
                },
                child: FadeTransition(
                  opacity: _panelFade,
                  child: SlideTransition(
                    position: _panelSlide,
                    child: OnlineNowPlayingPage(
                      onNavigate: widget.onNavigate,
                      onDismiss: _closeNowPlaying,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Color(0xff00E5FF),
                        Color(0xff80D8FF),
                        Colors.white,
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'STREAM',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Cloud Music Streaming',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: .55),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff00E5FF).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xff00E5FF).withValues(alpha: .25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: Color(0xff00E5FF),
                        size: 10,
                      ),

                      SizedBox(width: 6),

                      Text(
                        'ONLINE',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          letterSpacing: 2,
                          color: Color(0xff00E5FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => widget.onNavigate(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xff00E5FF), Color(0xff00BCD4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: .35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    color: Colors.black,
                    size: 15,
                  ),

                  SizedBox(width: 8),

                  Text(
                    'GO OFFLINE',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withValues(alpha: .035),
          border: Border.all(
            color: const Color(0xff00E5FF).withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00E5FF).withValues(alpha: .08),
              blurRadius: 35,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: .45),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xff00E5FF),
                  size: 24,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _runSearch(),
                    onTapOutside: (_) {
                      FocusScope.of(context).unfocus();
                    },
                    cursorColor: const Color(0xff00E5FF),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: .30),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Divider(color: Colors.white.withValues(alpha: .08), thickness: 1),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _runSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00E5FF),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded),

                    SizedBox(width: 10),

                    Text(
                      'GET SONG',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff00E5FF)),
      );
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 54, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );
    }

    if (!_searched) {
      return _idleState();
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No results found.',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 140),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (_, index) {
        final video = _results[index];
        return _ResultTile(video: video, onTap: () => _play(video));
      },
    );
  }

  Widget _idleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _StreamingAnimation(),
            const SizedBox(height: 40),
            const Text(
              'Search for a song above and tap GET\nto stream it instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Colors.white54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPlayer() {
    return ValueListenableBuilder<YoutubeVideo?>(
      valueListenable: _player.currentVideo,
      builder: (_, video, _) {
        if (video == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: _openNowPlaying,
          child: Container(
            width: double.infinity,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          video.thumbnailUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: Colors.black,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        video.channelTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultTile extends StatefulWidget {
  const _ResultTile({required this.video, required this.onTap});

  final YoutubeVideo video;
  final VoidCallback onTap;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
      },
      onTapCancel: () {
        setState(() => _pressed = false);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? .98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: .045),
            border: Border.all(
              color: const Color(0xff00E5FF).withValues(alpha: .15),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00E5FF).withValues(alpha: .06),
                blurRadius: 22,
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                height: 68,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.video.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: SizedBox(
                  height: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xff00E5FF),
                            ),
                          ),

                          const SizedBox(width: 6),

                          Expanded(
                            child: Text(
                              widget.video.channelTitle,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white.withValues(alpha: .60),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: widget.onTap,
                  child: Ink(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xff00E5FF), Color(0xff00BCD4)],
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatefulWidget {
  const _BackgroundGlow();

  @override
  State<_BackgroundGlow> createState() => _BackgroundGlowState();
}

class _BackgroundGlowState extends State<_BackgroundGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
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
        final value = _controller.value;

        return Stack(
          children: [
            /// Main Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xff020305),
                    Color(0xff090B11),
                    Color(0xff030303),
                  ],
                ),
              ),
            ),

            Positioned(
              top: -180 + value * 50,
              right: -120,
              child: _glow(340, const Color(0xff00E5FF).withValues(alpha: .12)),
            ),

            Positioned(
              bottom: -140,
              left: -140 + value * 40,
              child: _glow(300, const Color(0xff00B8D4).withValues(alpha: .08)),
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * .38,
              right: -90,
              child: _glow(180, Colors.white.withValues(alpha: .03)),
            ),

            IgnorePointer(
              child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
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
        boxShadow: [BoxShadow(color: color, blurRadius: 160, spreadRadius: 60)],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .03)
      ..strokeWidth = .5;

    const gap = 36.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
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
