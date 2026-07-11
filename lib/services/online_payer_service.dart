import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/youtube_video.dart';
import 'audio_player_service.dart';

/// Drives online (streamed) playback through YouTube's official embedded
/// IFrame player (`youtube_player_iframe`). This is a deliberately separate
/// service from [AudioPlayerService] — it does not touch just_audio, the
/// notification handler, or the local song queue. The two playback engines
/// are never meant to run at the same time: starting one always stops the
/// other first.
class OnlinePlayerService {
  OnlinePlayerService._();

  static final OnlinePlayerService instance = OnlinePlayerService._();

  final YoutubePlayerController controller = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: false,
      showFullscreenButton: false,
      strictRelatedVideos: true,
      enableCaption: false,
      mute: false,
      enableJavaScript: true,
      playsInline: true,
    ),
  );

  final ValueNotifier<YoutubeVideo?> currentVideo = ValueNotifier(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<YoutubeError> error = ValueNotifier(YoutubeError.none);

  /// Whether the full "now playing" panel is expanded over the search
  /// screen. This is purely a UI concern — the underlying [controller] and
  /// its WebView stay alive and keep playing regardless of this value, so
  /// minimizing back to the mini player never interrupts playback.
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);

  StreamSubscription<YoutubePlayerValue>? _valueSub;
  StreamSubscription<YoutubeVideoState>? _stateSub;
  bool _listening = false;

  void _ensureListening() {
    if (_listening) return;
    _listening = true;

    _valueSub = controller.stream.listen((value) {
      isPlaying.value = value.playerState == PlayerState.playing;
      error.value = value.error;

      if (value.metaData.duration > Duration.zero) {
        duration.value = value.metaData.duration;
      }
    });

    _stateSub = controller.videoStateStream.listen((state) {
      position.value = state.position;
    });
  }

  /// Loads and plays [video]. Stops any local/offline playback first so
  /// only one source is ever audible at a time.
  ///
  /// Note: some official/label uploads disable embedding outside YouTube
  /// itself (a choice made by the video owner, not something this app can
  /// work around). When that happens the player reports [YoutubeError] via
  /// [error] instead of silently failing.
  Future<void> play(YoutubeVideo video) async {
    _ensureListening();

    await AudioPlayerService.instance.stop();

    error.value = YoutubeError.none;
    currentVideo.value = video;

    // The controller is only usable once its YoutubePlayer widget (and the
    // WebView underneath it) has actually been mounted — see the always-on
    // Visibility(maintainState: true) panel in OnlinePage. If this is ever
    // called before that first build completes, retry briefly instead of
    // throwing a PlatformException straight at the user.
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        await controller.stopVideo();
        break;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    await controller.loadVideoById(videoId: video.id);

    await Future.delayed(const Duration(milliseconds: 700));

    await controller.playVideo();
  }

  /// Shows the full "now playing" panel. Safe to call at any time — the
  /// WebView is already alive by this point (see [OnlinePage]'s persistent,
  /// always-mounted panel), so this never triggers a PlatformException.
  void expand() => isExpanded.value = true;

  /// Collapses the full panel back to the mini player without stopping
  /// playback, so the song keeps streaming while the user keeps browsing.
  void minimize() => isExpanded.value = false;

  Future<void> toggle() async {
    final state = await controller.playerState;

    if (state == PlayerState.playing) {
      await controller.pauseVideo();
    } else {
      await controller.playVideo();
    }
  }

  Future<void> seek(Duration value) async {
    await controller.seekTo(
      seconds: value.inSeconds.toDouble(),
      allowSeekAhead: true,
    );
  }

  Future<void> stop() async {
    if (currentVideo.value == null) return;

    isExpanded.value = false;

    try {
      await controller.stopVideo();
    } catch (_) {
      // Controller may not be attached to a live WebView yet (e.g. called
      // during app startup) — nothing to stop in that case.
    }

    isPlaying.value = false;
    position.value = Duration.zero;
    currentVideo.value = null;
  }

  Future<void> dispose() async {
    await _valueSub?.cancel();
    await _stateSub?.cancel();
    await controller.close();
  }
}
