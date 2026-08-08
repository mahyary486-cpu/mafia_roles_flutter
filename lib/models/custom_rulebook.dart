/// A game-master-written win condition: "when [sideA] and [sideB] are
/// equal in count, and [sideC] is at [sideCCount], [winner] wins" - e.g.
/// "Citizen equals Mafia, and Independent is 0, Mafia wins."
class CustomWinRule {
  final String sideA;
  final String sideB;
  final String sideC;
  final int sideCCount;
  final String winner;

  const CustomWinRule({
    required this.sideA,
    required this.sideB,
    required this.sideC,
    required this.sideCCount,
    required this.winner,
  });

  String describeEn() =>
      'When $sideA equals $sideB in count, and $sideC is at $sideCCount, $winner wins.';
  String describeFa() =>
      'وقتی تعداد $sideA با $sideB برابر باشد، و $sideC برابر $sideCCount باشد، $winner برنده می‌شود.';

  Map<String, dynamic> toJson() => {
        'sideA': sideA,
        'sideB': sideB,
        'sideC': sideC,
        'sideCCount': sideCCount,
        'winner': winner,
      };

  factory CustomWinRule.fromJson(Map<String, dynamic> json) => CustomWinRule(
        sideA: json['sideA'] as String,
        sideB: json['sideB'] as String,
        sideC: json['sideC'] as String,
        sideCCount: json['sideCCount'] as int,
        winner: json['winner'] as String,
      );
}

/// A game-master-authored rulebook: a title, a long free-form
/// description (the actual rules, in the game master's own words), and
/// an optional structured win rule. Saved locally, forever, so it's
/// ready to read from again in any future game.
class CustomRulebook {
  final String id;
  final String title;
  final String bodyText;
  final CustomWinRule? winRule;

  const CustomRulebook({
    required this.id,
    required this.title,
    required this.bodyText,
    this.winRule,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'bodyText': bodyText,
        'winRule': winRule?.toJson(),
      };

  factory CustomRulebook.fromJson(Map<String, dynamic> json) => CustomRulebook(
        id: json['id'] as String,
        title: json['title'] as String,
        bodyText: json['bodyText'] as String,
        winRule: json['winRule'] == null
            ? null
            : CustomWinRule.fromJson(json['winRule'] as Map<String, dynamic>),
      );
}
