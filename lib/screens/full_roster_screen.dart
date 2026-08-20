import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../logic/game_state.dart';
import '../logic/locale_service.dart';
import '../models/role.dart';
import '../models/role_type.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/role_emoji_badge.dart';
import '../widgets/tr_text.dart';
import 'roster_screen.dart';

/// Pre-game (and re-visitable) editor for the whole role list: the game
/// master can swap which player holds which role, remove a role (turning
/// that player into a plain Citizen or plain Mafia), or assign any role
/// from the full list to a player.
///
/// Reached from the "Full Roster" button on the player-by-player reveal
/// screen ([isInitialSetup] true - confirming here moves on to the Day
/// screen), or later from the Day screen itself to review/adjust things
/// ([isInitialSetup] false - confirming here just goes back). Either way,
/// players already eliminated are shown deactivated and can't be edited.
class FullRosterScreen extends StatefulWidget {
  final GameState gameState;
  final bool isInitialSetup;

  const FullRosterScreen({
    super.key,
    required this.gameState,
    this.isInitialSetup = false,
  });

  @override
  State<FullRosterScreen> createState() => _FullRosterScreenState();
}

class _FullRosterScreenState extends State<FullRosterScreen> {
  /// Player number currently picked as the first half of a swap, or null
  /// if nothing is selected yet.
  int? _swapSelection;

  void _onTapSwap(int playerNumber) {
    setState(() {
      if (_swapSelection == null) {
        _swapSelection = playerNumber;
      } else if (_swapSelection == playerNumber) {
        _swapSelection = null;
      } else {
        widget.gameState.swapRoles(_swapSelection!, playerNumber);
        _swapSelection = null;
      }
    });
  }

  Future<void> _changeRole(int playerNumber) async {
    final current = widget.gameState.roleFor(playerNumber);
    final usedElsewhere = <RoleType>{
      for (final role in widget.gameState.allAssignedRoles)
        if (role.type != current.type) role.type,
    };
    final picked = await showDialog<Role>(
      context: context,
      builder: (context) => _RolePickerDialog(
        currentType: current.type,
        usedElsewhere: usedElsewhere,
      ),
    );
    if (picked == null) return;
    setState(() {
      widget.gameState.setRoleAt(playerNumber, picked);
      _swapSelection = null;
    });
  }

  void _convertTo(int playerNumber, RoleType type) {
    final role = RoleData.all[type];
    if (role == null) return;
    setState(() {
      widget.gameState.setRoleAt(playerNumber, role);
      _swapSelection = null;
    });
  }

  void _onConfirm() {
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RosterScreen(gameState: widget.gameState),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.gameState.playerCount ?? 0;
    final activeNumbers = <int>[];
    final removedNumbers = <int>[];
    for (int n = 1; n <= total; n++) {
      if (widget.gameState.isRemoved(n)) {
        removedNumbers.add(n);
      } else {
        activeNumbers.add(n);
      }
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: const TrText('Full Roster'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Game Master Assistant ⭐',
                  style: TextStyle(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Text(
                  _swapSelection == null
                      ? 'Tap the swap icon on two players to trade roles. '
                          'Tap a role to change it.'
                      : 'Player $_swapSelection selected - tap another '
                          'player\'s swap icon to trade roles with them.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFF9C4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final n in activeNumbers)
                      _RosterRow(
                        playerNumber: n,
                        role: widget.gameState.roleFor(n),
                        selected: _swapSelection == n,
                        onTapSwap: () => _onTapSwap(n),
                        onTapRole: () => _changeRole(n),
                        onConvert: (type) => _convertTo(n, type),
                        deactivated: false,
                      ),
                    if (removedNumbers.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'Eliminated',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                      ),
                      for (final n in removedNumbers)
                        _RosterRow(
                          playerNumber: n,
                          role: widget.gameState.roleFor(n),
                          selected: false,
                          onTapSwap: null,
                          onTapRole: null,
                          onConvert: null,
                          deactivated: true,
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: ValueListenableBuilder<String>(
                      valueListenable: LocaleService.instance.languageCode,
                      builder: (context, _, __) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TrText(
                            widget.isInitialSetup ? 'Confirm & Go to Day' : 'Back to Day',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  final int playerNumber;
  final Role role;
  final bool selected;
  final bool deactivated;
  final VoidCallback? onTapSwap;
  final VoidCallback? onTapRole;
  final ValueChanged<RoleType>? onConvert;

  const _RosterRow({
    required this.playerNumber,
    required this.role,
    required this.selected,
    required this.deactivated,
    required this.onTapSwap,
    required this.onTapRole,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: deactivated ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 32),
            if (role.type == RoleType.president) ...[
              const SizedBox(width: 4),
              RoleEmojiBadge(
                emoji: RoleData.all[RoleType.mafia]!.emoji,
                color: AppColors.mafiaTeam,
                size: 22,
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onTapRole,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$playerNumber',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      role.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      role.nameFa,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!deactivated) ...[
              IconButton(
                tooltip: 'Swap with another player',
                icon: Icon(
                  Icons.swap_horiz,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
                onPressed: onTapSwap,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'change') {
                    onTapRole?.call();
                  } else if (value == 'citizen') {
                    onConvert?.call(RoleType.citizen);
                  } else if (value == 'mafia') {
                    onConvert?.call(RoleType.mafia);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'change',
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Change Role...')]),
                  ),
                  PopupMenuItem(
                    value: 'citizen',
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Convert to plain Citizen')]),
                  ),
                  PopupMenuItem(
                    value: 'mafia',
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Convert to plain Mafia')]),
                  ),
                ],
              ),
            ] else
              const Icon(Icons.remove_circle_outline,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// A scrollable list of every built-in role to assign to a player -
/// excluding named/specialty roles already held by someone else, since a
/// game shouldn't end up with two Doctors, two Detectives, etc. Plain
/// Citizen and plain Mafia are the exception: those are expected to
/// repeat across many players.
class _RolePickerDialog extends StatelessWidget {
  final RoleType currentType;
  final Set<RoleType> usedElsewhere;

  const _RolePickerDialog({required this.currentType, required this.usedElsewhere});

  @override
  Widget build(BuildContext context) {
    const alwaysAllowed = {RoleType.citizen, RoleType.mafia};
    final roles = RoleData.all.values
        .where((r) => alwaysAllowed.contains(r.type) || !usedElsewhere.contains(r.type))
        .toList();
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Choose a Role')]),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: ListView.builder(
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            final isCurrent = role.type == currentType;
            return ListTile(
              leading: RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 28),
              title: Row(mainAxisSize: MainAxisSize.min, children: [TrText(role.name), Text(' / ${role.nameFa}')]),
              selected: isCurrent,
              selectedTileColor: AppColors.accent.withOpacity(0.12),
              onTap: () => Navigator.of(context).pop(role),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Cancel')]),
        ),
      ],
    );
  }
}
