import 'package:flutter/material.dart';

import '../logic/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/role_reveal_card.dart';
import '../widgets/tr_text.dart';
import 'full_roster_screen.dart';

/// The single screen that steps through every player, one at a time.
///
/// Internally this just advances an index rather than pushing a new route
/// per player - simpler, faster, and it's what "no unnecessary features"
/// calls for. Giving [RoleRevealCard] a fresh key per player makes each
/// new player's card start closed automatically.
class GameScreen extends StatefulWidget {
  final GameState gameState;

  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentPlayerNumber = 1;

  bool get _isLastPlayer =>
      _currentPlayerNumber == widget.gameState.playerCount;

  bool get _isFirstPlayer => _currentPlayerNumber == 1;

  void _onNext() {
    setState(() => _currentPlayerNumber++);
  }

  void _onPrevious() {
    if (!_isFirstPlayer) {
      setState(() => _currentPlayerNumber--);
    }
  }

  void _openRoster() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullRosterScreen(
          gameState: widget.gameState,
          isInitialSetup: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.gameState.roleFor(_currentPlayerNumber);

    return PopScope(
      // Prevent leaving mid-game via the system back gesture, so the game
      // master can only exit through the explicit "End Game" action.
      canPop: false,
      child: AppBackground(
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: const BannerAppBarBackground(),
          leading: IconButton(
            tooltip: 'Skip to Day',
            icon: const Icon(Icons.wb_sunny_rounded, color: Colors.amber),
            onPressed: _openRoster,
          ),
          actions: [
            IconButton(
              tooltip: 'Full Roster',
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              onPressed: _openRoster,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            'Player $_currentPlayerNumber',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          RoleRevealCard(
                            key: ValueKey(_currentPlayerNumber),
                            role: role,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isFirstPlayer ? null : _onPrevious,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TrText('Previous', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLastPlayer ? _openRoster : _onNext,
                          style: _isLastPlayer
                              ? ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                )
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isLastPlayer ? 'Full Roster' : 'Next',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
