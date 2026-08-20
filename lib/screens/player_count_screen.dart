import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/game_state.dart';
import '../logic/locale_service.dart';
import '../logic/premium_service.dart';
import '../widgets/app_background.dart';
import '../widgets/language_picker_button.dart';
import '../widgets/neon_dot_frame.dart';
import '../widgets/banner_app_bar_background.dart';
import 'about_us_screen.dart';
import 'help_screen.dart';
import 'mafia_count_screen.dart';
import 'rulebook_screen.dart';

/// Screen 1 — "تعداد بازیکنان" (Number of players).
///
/// Tapping a number (or entering a custom one via "بیشتر") moves on to
/// choosing the mafia/citizen/independent split, then role selection.
class PlayerCountScreen extends StatelessWidget {
  final GameState gameState;

  const PlayerCountScreen({super.key, required this.gameState});

  static const List<int> _gridCounts = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];

  Future<void> _goToMafiaCount(BuildContext context, int count) async {
    if (PremiumService.needsPaywall(count)) {
      final unlocked = await _showPaywall(context, count);
      if (unlocked != true) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MafiaCountScreen(totalPlayers: count, gameState: gameState),
      ),
    );
  }

  /// Free forever up to [PremiumService.freePlayerLimit] players; above
  /// that, this explains the subscription and offers to unlock. There is
  /// no real payment processing behind the "Unlock" button yet - see
  /// `PremiumService`'s doc comment for why, and what to replace it with.
  Future<bool?> _showPaywall(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('More than 7 Players'),
        content: Text(
          'Free games support up to ${PremiumService.freePlayerLimit} '
          'players. $count players needs the '
          '${PremiumService.unlockPriceLabel} subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await PremiumService.debugSetPremium(true);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<void> _onMoreTap(BuildContext context) async {
    final controller = TextEditingController();
    final count = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('More Players (13-100)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. 20'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(controller.text);
                if (value == null || value < 13 || value > 100) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (count != null && context.mounted) {
      _goToMafiaCount(context, count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          leading: IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Rulebook',
              icon: const Icon(Icons.bolt_rounded, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RulebookScreen()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    TrText(
                      'Number of Players',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    _AbilitiesModeToggle(gameState: gameState),
                    const SizedBox(height: 5),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 1.5,
                        children: [
                          for (final count in _gridCounts)
                            if (count != 15)
                              _NumberButton(
                                label: count == 3 ? 'Ace' : '$count',
                                fontSize: count == 3 ? 16 : 20,
                                onTap: () => _goToMafiaCount(context, count),
                              ),
                          // Blank cell so "15" (the lone item in the last
                          // row) lands in the middle column, under "13",
                          // instead of under "12".
                          const SizedBox.shrink(),
                          _NumberButton(
                            label: '15',
                            fontSize: 20,
                            onTap: () => _goToMafiaCount(context, 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MorePlayersButton(onTap: () => _onMoreTap(context)),
                    const SizedBox(height: 4),
                    const _CreditLine(),
                    // Clearance so this never sits under the About Us /
                    // language-picker buttons pinned to the bottom
                    // corners of the screen.
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              const Positioned(
                left: 8,
                bottom: 8,
                child: _CornerButtonBackdrop(child: _AboutUsButton()),
              ),
              const Positioned(
                right: 8,
                bottom: 8,
                child: _CornerButtonBackdrop(child: LanguagePickerButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle shown once per game, right on the player-count screen:
/// "Execute Abilities Automatically" - ON runs each role's full
/// algorithm on a tap (the normal behavior). OFF switches to a
/// simpler mode where tapping a role then a player only records that
/// role's icon in front of the player, both at night and during the
/// day - no elimination, no saving, no side effects - just a visual
/// note for the game master to run the round by hand.
class _AbilitiesModeToggle extends StatelessWidget {
  final GameState gameState;

  const _AbilitiesModeToggle({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: gameState,
      builder: (context, _) {
        final enabled = gameState.abilitiesAutoExecuted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textGold.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  enabled ? 'Execute Abilities Automatically' : 'Simple Mode - icons only',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: enabled,
                  onChanged: (value) => gameState.setAbilitiesAutoExecuted(value),
                  activeColor: AppColors.brightViolet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerButtonBackdrop extends StatelessWidget {
  final Widget child;

  const _CornerButtonBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.45),
        border: Border.all(color: AppColors.textGold.withOpacity(0.5)),
      ),
      child: child,
    );
  }
}

class _AboutUsButton extends StatelessWidget {
  const _AboutUsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'About Us',
      icon: ClipOval(
        child: Image.asset(
          'assets/images/mask_logo.png',
          width: 30,
          height: 30,
          fit: BoxFit.cover,
        ),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutUsScreen()),
        );
      },
    );
  }
}

/// Small, unobtrusive attribution shown at the bottom of the first screen -
/// not an ad, just a source credit so people know who made the app.
class _CreditLine extends StatelessWidget {
  const _CreditLine();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Mafia Psychology Academy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Mahyar Yaghoobalipour',
          style: TextStyle(
            color: AppColors.textGold,
            fontFamily: 'serif',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// A bigger, English-labeled button for entering a custom player count
/// above 12 - separate from the numbered grid so it stands out.
class _MorePlayersButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MorePlayersButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeonDotFrame(
      dotCount: 4,
      dotSize: 4,
      borderRadius: 18,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TrText(
                    'More Players',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Advanced Mafia',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.yellowAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const _NumberButton({
    required this.label,
    required this.onTap,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return NeonDotFrame(
      dotCount: 3,
      dotSize: 3.5,
      borderRadius: 18,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brightViolet,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
