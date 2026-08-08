import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays a short (few-second) video clip full-screen over whatever's
/// behind it, then calls [onFinished] automatically - either when the
/// video ends or after [maxDuration], whichever comes first (a safety
/// net in case the video is longer than expected or fails to report its
/// length). Tapping anywhere skips it immediately.
///
/// If the asset is missing or fails to load, this fails silently and
/// calls [onFinished] right away - a missing video clip should never
/// block the game from continuing.
class RoleActionVideoOverlay extends StatefulWidget {
  final String assetPath;
  final VoidCallback onFinished;
  final Duration maxDuration;
  final bool muted;

  const RoleActionVideoOverlay({
    super.key,
    required this.assetPath,
    required this.onFinished,
    this.maxDuration = const Duration(seconds: 6),
    this.muted = false,
  });

  @override
  State<RoleActionVideoOverlay> createState() => _RoleActionVideoOverlayState();
}

class _RoleActionVideoOverlayState extends State<RoleActionVideoOverlay> {
  VideoPlayerController? _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      if (widget.muted) await controller.setVolume(0);
      setState(() => _controller = controller);
      controller.addListener(_checkDone);
      await controller.play();
      Future.delayed(widget.maxDuration, _finish);
    } catch (_) {
      // Missing/broken video asset - just move on without it.
      _finish();
    }
  }

  void _checkDone() {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isPlaying &&
        controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkDone);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return GestureDetector(
      onTap: _finish,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: controller != null && controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

/// Shows [RoleActionVideoOverlay] as a full-screen dialog and waits for
/// it to finish before returning.
Future<void> showRoleActionVideo(BuildContext context, String assetPath, {bool muted = false}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    pageBuilder: (context, animation, secondaryAnimation) {
      return RoleActionVideoOverlay(
        assetPath: assetPath,
        muted: muted,
        onFinished: () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        },
      );
    },
  );
}
