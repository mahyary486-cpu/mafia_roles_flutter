import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';

/// A read-only rules page for one of the alternate rulebook variants -
/// standard, well-known Mafia/Werewolf setups, not yet wired up as
/// playable rulesets in this app (that's a later update). Tapping one of
/// these cards just opens this guide.
class RulebookDetailScreen extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final String body;

  const RulebookDetailScreen({
    super.key,
    required this.titleEn,
    required this.titleFa,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: Text(titleEn),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Compiled by Game Master Assistant',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(titleEn,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(titleFa, style: const TextStyle(color: AppColors.textGold, fontSize: 14)),
              const Divider(height: 24, color: Colors.white24),
              Text(
                body,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.7, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Text(
                'This variant isn\'t playable in-app yet - it\'s reference text only. / '
                'Reference only - not yet playable inside the app.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard, well-known rules text for the 4 not-yet-playable rulebook
/// variants listed in the selector.
const Map<String, String> kRulebookVariantText = {
  'Classic': '''
A basic 7-player Town-vs-Mafia setup, the classic starting point for the
genre.

Roles: 3 Villagers, 1 Cop (Detective), 1 Doctor, 2 Mafia.

Setup: All players close their eyes. Mafia wake first and silently agree
on a target. The Cop wakes and points at one player to learn whether
they're Mafia. The Doctor wakes and points at one player to protect them
from that night's kill.

Flow: Night phase (Mafia kill, Cop investigates, Doctor protects) is
followed by a Day phase where the town discusses and votes to lynch one
suspect. Repeat until one side is eliminated.

Win condition: Town wins when both Mafia are eliminated. Mafia win when
they equal or outnumber the Town.
''',
  'Mountainous 11v2': '''
A high-player-count, no-power-role variant that emphasizes pure
discussion and deduction over special abilities.

Roles: 11 Villagers, 2 Mafia. No Cop, Doctor, or any other power role -
everyone is a plain Villager or plain Mafia.

Setup: Mafia know each other from the start. Villagers have no special
information beyond what's said at the table.

Flow: Each night, Mafia silently choose one Villager to eliminate. Each
day, the group discusses and votes to lynch one suspect. Since there's
no investigative role, all information has to come from behavior,
voting patterns, and accusations.

Win condition: Villagers win when both Mafia are eliminated. Mafia win
when they equal or outnumber the Villagers.
''',
  'Advanced Roles Mix (11 Players)': '''
An 11-player game with a wider mix of special abilities on both sides,
for groups who want more nightly interaction.

Roles: Seer (learns one player's alignment each night), Martyr (can
sacrifice themselves to save another player from being eliminated),
Hunter (if lynched or killed, can immediately eliminate one other
player), 2 Wolves/Mafia, 1 Cultist (wins with the Wolves but doesn't
know who they are), remaining players are plain Villagers.

Flow: Night order matters - typically Wolves choose a target first,
then the Seer investigates, then the Martyr decides whether to
intervene. During the day, the town debates and votes as usual.

Win condition: Village wins when all Wolves and the Cultist are
eliminated. Wolves (and the Cultist, if still alive) win when they
equal or outnumber the Village.
''',
  'Town-Heavy Power Setup': '''
A 7-player game weighted more toward the Town side, good for newer
groups who want the Town to have a bit more breathing room.

Roles: 5 Villagers, 1 Cop (Detective), 1 Doctor, 2 Mafia.

Setup and flow are the same as the Classic setup - Mafia choose a
target each night, the Cop investigates, the Doctor protects - but with
more plain Villagers in the mix, giving the Town more votes and more
cover before Mafia gain the upper hand.

Win condition: Town wins when both Mafia are eliminated. Mafia win when
they equal or outnumber the Town.
''',
};
