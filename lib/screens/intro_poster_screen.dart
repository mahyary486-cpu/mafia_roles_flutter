import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import 'splash_screen.dart';

/// The very first thing the app shows: the "Game Master Assistant"
/// poster, full screen, for 3 seconds - then it fades into the animated
/// logo splash screen.
class IntroPosterScreen extends StatefulWidget {
  final GameState gameState;

  const IntroPosterScreen({super.key, required this.gameState});

  @override
  State<IntroPosterScreen> createState() => _IntroPosterScreenState();
}

class _IntroPosterScreenState extends State<IntroPosterScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            SplashScreen(gameState: widget.gameState),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/intro_poster.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
