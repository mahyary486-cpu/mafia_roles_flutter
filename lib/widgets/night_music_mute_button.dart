import 'package:flutter/material.dart';

import '../logic/night_audio_service.dart';

/// Mute/unmute toggle for the looping night background narration. Shown
/// in the AppBar of both the Day and Night Actions screens - tapping it
/// stops the music immediately if it's playing, and silences all future
/// nights until tapped again.
class NightMusicMuteButton extends StatelessWidget {
  const NightMusicMuteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NightAudioService.instance,
      builder: (context, _) {
        final muted = NightAudioService.instance.muted;
        return IconButton(
          tooltip: muted
              ? 'Unmute night music / پخش صدای شب'
              : 'Mute night music / قطع صدای شب',
          icon: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: Colors.white,
          ),
          onPressed: () => NightAudioService.instance.toggleMuted(),
        );
      },
    );
  }
}
