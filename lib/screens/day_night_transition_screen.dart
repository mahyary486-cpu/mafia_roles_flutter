import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../logic/night_audio_service.dart';
import 'night_actions_screen.dart';

/// The short cinematic shown between the Day and Night screens: the Day
/// background fades out as the "Game Master Assistant" wooden sign fades
/// in and holds for a few seconds, then fades into the Night background,
/// before landing on the real Night Actions screen.
class DayNightTransitionScreen extends StatefulWidget {
  final GameState gameState;

  const DayNightTransitionScreen({super.key, required this.gameState});

  @override
  State<DayNightTransitionScreen> createState() => _DayNightTransitionScreenState();
}

enum _Phase { dayFadingOut, signHolding, nightFadingIn }

class _DayNightTransitionScreenState extends State<DayNightTransitionScreen> {
  _Phase _phase = _Phase.dayFadingOut;

  static const _fadeDuration = Duration(milliseconds: 1000);
  static const _signHoldDuration = Duration(seconds: 3);
  static const _nightFadeDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    // Start the night music right away, together with the board/sign
    // images, instead of waiting for the Night Actions screen to load.
    NightAudioService.instance.startNightLoop();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Day fades out, sign fades in together.
    await Future.delayed(_fadeDuration);
    if (!mounted) return;
    setState(() => _phase = _Phase.signHolding);

    // Sign holds on screen.
    await Future.delayed(_signHoldDuration);
    if (!mounted) return;
    setState(() => _phase = _Phase.nightFadingIn);

    // Sign fades out, night background fades in.
    await Future.delayed(_nightFadeDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NightActionsScreen(gameState: widget.gameState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayVisible = _phase == _Phase.dayFadingOut;
    final signVisible = _phase == _Phase.dayFadingOut || _phase == _Phase.signHolding;
    final nightVisible = _phase == _Phase.nightFadingIn;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: dayVisible ? 1 : 0,
            duration: _fadeDuration,
            child: Image.asset('assets/images/day_background.jpg', fit: BoxFit.cover),
          ),
          AnimatedOpacity(
            opacity: nightVisible ? 1 : 0,
            duration: _nightFadeDuration,
            child: Image.asset('assets/images/night_background.jpg', fit: BoxFit.cover),
          ),
          AnimatedOpacity(
            opacity: signVisible ? 1 : 0,
            duration: _fadeDuration,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Image.asset('assets/images/transition_sign.jpg', fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
