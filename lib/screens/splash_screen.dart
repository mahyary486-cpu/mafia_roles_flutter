import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../widgets/app_background.dart';
import 'mode_selection_screen.dart';

/// Shown right after the intro poster: the club logo zooms in, settles,
/// then holds still while Sign In / Sign Up and the app's update-status
/// badge fade in underneath it. Nothing auto-advances anymore - the
/// person has to actually sign in to continue.
class SplashScreen extends StatefulWidget {
  final GameState gameState;

  const SplashScreen({super.key, required this.gameState});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Where the app currently stands relative to the latest published
/// version. TODO: replace this hard-coded value with a real check
/// against a remote config / store listing once that's wired up.
enum _AppVersionStatus { current, updateAvailable, expired }

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  bool _showAuth = false;
  bool _signingIn = false;

  // TODO: wire this up to a real version check once there's a backend
  // to check against.
  static const _versionStatus = _AppVersionStatus.current;

  static const _animationDuration = Duration(milliseconds: 1200);
  static const _holdDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);
    _opacity = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_controller);
    _controller.forward();
    _revealAuth();
  }

  Future<void> _revealAuth() async {
    // Let the logo animation play and settle first, then fade the
    // sign-in options in underneath the now-still logo.
    await Future.delayed(_animationDuration + _holdDuration);
    if (!mounted) return;
    setState(() => _showAuth = true);
  }

  Future<void> _continueToApp() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ModeSelectionScreen(gameState: widget.gameState),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // TODO: replace with real Firebase Auth (Google Sign-In). This just
  // simulates the round trip so the rest of the flow can be built and
  // tested before the backend exists.
  Future<void> _signInWithGoogle() async {
    setState(() => _signingIn = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _signingIn = false);
    _continueToApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.width * 0.55;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacity.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/app_icon.png',
                      width: logoSize,
                      height: logoSize,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Game Master Assistant ⭐',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: _showAuth ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: IgnorePointer(
                  ignoring: !_showAuth,
                  child: _AuthButtons(
                    signingIn: _signingIn,
                    onGoogleSignIn: _signInWithGoogle,
                  ),
                ),
              ),
              const Spacer(),
              const _VersionStatusBadge(status: _versionStatus),
              const SizedBox(height: 10),
              const Text(
                'Mafia Psychology Academy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final bool signingIn;
  final VoidCallback onGoogleSignIn;

  const _AuthButtons({required this.signingIn, required this.onGoogleSignIn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: signingIn ? null : onGoogleSignIn,
              icon: signingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata_rounded, size: 26),
              label: Text(signingIn ? 'Signing in...' : 'Sign In with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: signingIn ? null : onGoogleSignIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign Up with Google'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small 3-state pill: green ("up to date"), orange ("update
/// available, still usable"), red ("this version has expired").
class _VersionStatusBadge extends StatelessWidget {
  final _AppVersionStatus status;

  const _VersionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case _AppVersionStatus.current:
        color = Colors.green;
        label = 'Up to date';
        break;
      case _AppVersionStatus.updateAvailable:
        color = Colors.orange;
        label = 'Update available';
        break;
      case _AppVersionStatus.expired:
        color = Colors.redAccent;
        label = 'This version has expired - please update';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
