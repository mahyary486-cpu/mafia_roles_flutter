import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/tr_text.dart';
import 'rulebook_selector_screen.dart';

/// After the total player count is chosen, the game master decides here
/// exactly how many mafia and independent players there are. The citizen
/// count is whatever's left over from the fixed total.
///
/// This is entirely the game master's call - even a joke setup like "all
/// citizens" is allowed. The app only shows a friendly (non-blocking)
/// warning if citizens don't outnumber mafia; it never forces a choice.
class MafiaCountScreen extends StatefulWidget {
  final int totalPlayers;
  final GameState gameState;

  const MafiaCountScreen({
    super.key,
    required this.totalPlayers,
    required this.gameState,
  });

  @override
  State<MafiaCountScreen> createState() => _MafiaCountScreenState();
}

class _MafiaCountScreenState extends State<MafiaCountScreen> {
  late int _mafiaCount;
  int _independentCount = 0;

  @override
  void initState() {
    super.initState();
    _mafiaCount = _suggestedMafiaCount(widget.totalPlayers);
  }

  /// Suggested *starting point* only - the game master can freely change
  /// it with the +/- buttons. Matches the balance pattern given for small
  /// and mid-size games; for anything else, a simple ~1/3 approximation.
  static const Map<int, int> _suggestedTable = {
    3: 1, 4: 1, 5: 1, 6: 2, 7: 2, 8: 2,
    9: 3, 10: 3, 11: 3,
    12: 4, 13: 4, 14: 5, 15: 5, 16: 6, 17: 6, 18: 7, 19: 7,
    20: 7, 21: 8, 22: 8, 23: 9, 24: 9, 25: 9,
  };

  static int _suggestedMafiaCount(int total) {
    final tableValue = _suggestedTable[total];
    if (tableValue != null) return tableValue;
    final suggestion = (total / 2.7).round();
    return suggestion < 1 ? 1 : suggestion;
  }

  int get _maxMafia => widget.totalPlayers - _independentCount;

  int get _citizenCount => widget.totalPlayers - _mafiaCount - _independentCount;

  bool get _showBalanceWarning => _citizenCount <= _mafiaCount;

  void _changeMafia(int delta) {
    setState(() {
      final next = _mafiaCount + delta;
      if (next < 0 || next > _maxMafia) return;
      _mafiaCount = next;
    });
  }

  void _changeIndependent(int delta) {
    setState(() {
      final next = _independentCount + delta;
      if (next < 0 || _mafiaCount + next > widget.totalPlayers) return;
      _independentCount = next;
      // Keep mafia within the new bound.
      if (_mafiaCount > _maxMafia) _mafiaCount = _maxMafia;
    });
  }

  void _onNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RulebookSelectorScreen(
          totalPlayers: widget.totalPlayers,
          mafiaCount: _mafiaCount,
          citizenCount: _citizenCount,
          independentCount: _independentCount,
          gameState: widget.gameState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TrText(
                'Team Sizes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.totalPlayers} Players',
                style: const TextStyle(fontSize: 12, color: AppColors.textGold),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CounterRow(
                  titleEn: 'Mafia',
                  titleFa: 'مافیا',
                  color: AppColors.mafiaTeam,
                  value: _mafiaCount,
                  onDecrement: () => _changeMafia(-1),
                  onIncrement: () => _changeMafia(1),
                ),
                const SizedBox(height: 20),
                _CounterRow(
                  titleEn: 'Independent',
                  titleFa: 'مستقل (اختیاری)',
                  color: AppColors.independentTeam,
                  value: _independentCount,
                  onDecrement: () => _changeIndependent(-1),
                  onIncrement: () => _changeIndependent(1),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        labelEn: 'Mafia',
                        labelFa: 'مافیا',
                        value: _mafiaCount.toString(),
                        color: AppColors.mafiaTeam,
                      ),
                      _SummaryRow(
                        labelEn: 'Citizen',
                        labelFa: 'شهروند',
                        value: _citizenCount.toString(),
                        color: AppColors.citizenTeam,
                      ),
                      if (_independentCount > 0)
                        _SummaryRow(
                          labelEn: 'Independent',
                          labelFa: 'مستقل',
                          value: _independentCount.toString(),
                          color: AppColors.independentTeam,
                        ),
                    ],
                  ),
                ),
                if (_showBalanceWarning) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              TrText(
                                "Usually citizens should outnumber mafia, but this "
                                'is just a suggestion - any combination is allowed.',
                                style: TextStyle(fontSize: 12, color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: _onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [TrText('Next: Select Roles')],
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

class _CounterRow extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final Color color;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterRow({
    required this.titleEn,
    required this.titleFa,
    required this.color,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            TrText(
              titleEn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _RoundIconButton(icon: Icons.remove, onTap: onDecrement),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            _RoundIconButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String labelEn;
  final String labelFa;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.labelEn,
    required this.labelFa,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              TrText(labelEn),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
