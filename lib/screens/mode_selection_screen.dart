import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/neon_dot_frame.dart';
import 'player_count_screen.dart';

/// Shown right after signing in: choose between the (upcoming) online
/// multiplayer mode and the existing offline Game Master Assistant.
class ModeSelectionScreen extends StatelessWidget {
  final GameState gameState;

  const ModeSelectionScreen({super.key, required this.gameState});

  void _openOnlineGame(BuildContext context) {
    // TODO: real online mode needs a backend (accounts, live game sync
    // across devices) that doesn't exist yet - this is a placeholder
    // until that's built.
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'Online multiplayer is being built using the same roles and '
          'cards from Game Master Assistant. Check back soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openAssistant(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PlayerCountScreen(gameState: gameState)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Text(
                  'Choose Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'How do you want to play?',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 36),
                _ModeCard(
                  icon: Icons.wifi_rounded,
                  title: 'Online Game',
                  subtitle: 'Play with friends on their own phones',
                  color: Colors.blueAccent,
                  onTap: () => _openOnlineGame(context),
                ),
                const SizedBox(height: 18),
                _ModeCard(
                  icon: Icons.record_voice_over_rounded,
                  title: 'Game Master Assistant',
                  subtitle: 'Run an in-person game from this phone',
                  color: Colors.deepPurpleAccent,
                  onTap: () => _openAssistant(context),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: NeonDotFrame(
        dotCount: 4,
        dotSize: 5,
        borderRadius: 18,
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
        ),
      ),
    );
  }
}
