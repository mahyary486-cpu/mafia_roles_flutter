import 'package:flutter/material.dart' show Color;

/// A single mark left on a player during one night (who acted on them,
/// shown as a label + color) - archived for the history view.
class NightMarkEntry {
  final int playerNumber;
  final String label;
  final Color color;
  final List<String> actionEmojis;

  const NightMarkEntry({
    required this.playerNumber,
    required this.label,
    required this.color,
    required this.actionEmojis,
  });
}

/// A frozen snapshot of one full night/round: every mark that was made
/// and everyone who ended up eliminated. Saved permanently (for the rest
/// of the game session) when the night ends, so the game master can look
/// back at "what happened on Night 3" later - the live Night Actions
/// screen only ever shows the *current* night, not past ones.
class NightRecord {
  final int night;
  final List<NightMarkEntry> marks;
  final List<int> eliminated;
  final Map<int, int> votes;

  const NightRecord({
    required this.night,
    required this.marks,
    required this.eliminated,
    required this.votes,
  });
}
