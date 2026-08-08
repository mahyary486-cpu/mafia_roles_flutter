import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../logic/ad_service.dart';
import '../logic/game_state.dart';
import '../logic/locale_service.dart';
import '../logic/night_audio_service.dart';
import '../widgets/night_music_mute_button.dart';
import '../models/role.dart';
import '../models/role_type.dart';
import '../models/team.dart';
import '../widgets/action_marks_row.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/role_emoji_badge.dart';
import '../widgets/role_toolbar_button.dart';
import '../widgets/tr_text.dart';
import '../widgets/win_celebration_dialog.dart';
import 'day_night_transition_screen.dart';
import 'full_roster_screen.dart';
import 'night_actions_screen.dart';
import 'night_history_screen.dart';

/// A spoiler view for the game master only: every player number next to
/// their assigned role, all at once (instead of tapping through cards one
/// by one). Lets the game master mark players as removed (e.g. voted out
/// or shot at night) as bookkeeping, grouped and labeled by which night
/// they were removed in, and ends the game from here.
///
/// This screen reads live from [GameState], so navigating away and back
/// (even via the system back button) never loses anything - only pressing
/// "End Game" (which starts a fresh game) clears the history.
class RosterScreen extends StatefulWidget {
  final GameState gameState;

  const RosterScreen({super.key, required this.gameState});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final _interstitial = InterstitialAdController();

  /// Whether the "removed" section lists nights oldest-first (Night 1 at
  /// the top) or newest-first. Toggled by double-tapping any night divider.
  bool _oldestFirst = true;

  /// The day-action role currently armed (Cowboy/Bomber/Terrorist/...),
  /// or null if none is armed. While armed, tapping a player applies that
  /// role's day action instead of the normal remove/restore toggle.
  RoleType? _armedDayActionType;

  /// Explicit order for the day-action toolbar. Every role listed here
  /// shares the same simple mechanic: arm the icon, tap one target, and
  /// both the role's holder and the target are eliminated - unless the
  /// holder was blocked by the Bartender the night before, in which case
  /// only the holder is eliminated.
  static const _dayActionOrder = [
    RoleType.cowboy,
    RoleType.bomber,
    RoleType.terrorist,
  ];

  List<Role> _dayActionRolesPresent() {
    final byType = <RoleType, Role>{};
    for (final role in widget.gameState.allAssignedRoles) {
      if (_dayActionOrder.contains(role.type)) byType[role.type] = role;
    }
    return [
      for (final type in _dayActionOrder)
        if (byType[type] != null && !widget.gameState.isDayAbilitySpent(type))
          byType[type]!,
    ];
  }

  int? _findPlayerNumber(RoleType type) {
    final all = widget.gameState.allAssignedRoles;
    for (int i = 0; i < all.length; i++) {
      if (all[i].type == type) return i + 1;
    }
    return null;
  }

  void _toggleArmDayAction(RoleType type) {
    setState(() {
      _armedDayActionType = _armedDayActionType == type ? null : type;
    });
  }

  void _applyDayAction(int targetPlayerNumber) {
    final type = _armedDayActionType;
    if (type == null) return;

    // Simple Mode: no elimination or chain logic - just note the role's
    // icon in front of the tapped player and disarm.
    if (!widget.gameState.abilitiesAutoExecuted) {
      final role = RoleData.all[type];
      if (role != null) {
        widget.gameState.addActionBadge(targetPlayerNumber, role.emoji);
      }
      setState(() => _armedDayActionType = null);
      return;
    }

    if (widget.gameState.currentNight == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Day-action roles cannot act on Day 1. / '
            'نقش‌های اکت روز، روز اول نمی‌توانند اکت کنند.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final originalHolder = _findPlayerNumber(type);
    // If the Thief stole this role's ability last night, the Thief acts
    // in the original holder's place today.
    final actorNumber = (originalHolder != null
            ? widget.gameState.dayActionDelegateFor(originalHolder)
            : null) ??
        originalHolder;

    if (actorNumber == null || widget.gameState.isRemoved(actorNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That role\'s holder is no longer in the game. / '
            'دارنده این نقش دیگر در بازی نیست.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _armedDayActionType = null);
      return;
    }

    final wasStolen = actorNumber != originalHolder;
    final blocked = widget.gameState.isBartenderBlockedForDay(actorNumber);
    final role = widget.gameState.roleFor(originalHolder!);
    setState(() {
      if (blocked) {
        widget.gameState.eliminate(actorNumber);
        widget.gameState.consumeBartenderBlock();
      } else {
        widget.gameState.eliminate(actorNumber);
        widget.gameState.eliminate(targetPlayerNumber);
        widget.gameState.addActionBadge(targetPlayerNumber, role.emoji);
        // The ability itself is spent for the rest of the game - its
        // icon disappears from the day toolbar for good, whether or not
        // it was ever stolen.
        widget.gameState.markDayAbilitySpent(type);
        if (wasStolen) {
          // The original holder survives (only the Thief went out with
          // the target) - from now on he's shown as an ordinary member
          // of his own team, and the round's log explains what really
          // happened.
          widget.gameState.markPlainRoleBadge(originalHolder);
          widget.gameState.setNightMark(
            originalHolder,
            role.color,
            'Thief stole the ${role.name} ability - on the final exit '
            'vote, the Thief was eliminated along with Player '
            '$targetPlayerNumber instead. Player $originalHolder remains '
            'in the game as an ordinary ${role.team.name} member. / '
            'توانایی ${role.nameFa} توسط دزد دزدیده شد - در رأی خروج '
            'نهایی، به‌جای او دزد همراه با بازیکن $targetPlayerNumber از '
            'بازی خارج شد. بازیکن $originalHolder به‌عنوان یک عضو ساده '
            'از تیم خودش در بازی باقی ماند.',
          );
        }
      }
      if (wasStolen) widget.gameState.consumeThiefSteal();
      _armedDayActionType = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          blocked
              ? 'Blocked by the Bartender last night - only player '
                  '$actorNumber is out. / '
                  'دیشب توسط ساقی بسته شده بود - فقط بازیکن $actorNumber خارج شد.'
              : 'Players $actorNumber and $targetPlayerNumber are out. / '
                  'بازیکنان $actorNumber و $targetPlayerNumber خارج شدند.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openVotePicker(int playerNumber, int activePlayerCount) {
    // Can't get more votes than there are other active players to cast
    // them - and never show more than 100 even in a huge custom game.
    final maxVote = (activePlayerCount - 1).clamp(0, 100);
    final majorityAt = widget.gameState.voteMajorityFor(activePlayerCount);
    final current = widget.gameState.voteCountFor(playerNumber);
    final initialIndex = current.clamp(0, maxVote);
    showModalBottomSheet(
      context: context,
      backgroundColor: _daySurface,
      builder: (sheetContext) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Votes for Player $playerNumber',
                  style: const TextStyle(color: _dayText, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: initialIndex),
                  itemExtent: 46,
                  onSelectedItemChanged: (index) {
                    setState(() => widget.gameState.setVote(playerNumber, index));
                  },
                  children: [
                    for (int i = 0; i <= maxVote; i++) Center(child: _JackpotNumber(i, majorityAt: majorityAt)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => widget.gameState.confirmVote(playerNumber));
                      Navigator.of(sheetContext).pop();
                    },
                    child: const TrText('Submit Vote'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullRoster() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullRosterScreen(
          gameState: widget.gameState,
          isInitialSetup: false,
        ),
      ),
    );
  }

  List<int> _nightOrder(int nightCount) {
    final indices = List<int>.generate(nightCount, (i) => i);
    return _oldestFirst ? indices : indices.reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    // Loaded ahead of time so it's ready the instant "End Game" is
    // pressed. If it never loads (e.g. no internet), that's fine -
    // showIfReady() just skips straight to actually ending the game.
    _interstitial.preload();
  }

  @override
  void dispose() {
    _interstitial.dispose();
    super.dispose();
  }

  /// Works out which side won (if any) from the current remaining counts,
  /// and whether that side had a "clean sheet" - never lost a single
  /// member the whole game. Returns null if the outcome isn't a clear win
  /// (e.g. the game master is ending early for some other reason).
  _Celebration? _determineCelebration() {
    final remaining = widget.gameState.remainingByTeam();
    final mafiaLeft = remaining[Team.mafia] ?? 0;
    final citizenLeft = remaining[Team.citizen] ?? 0;
    final independentLeft = remaining[Team.independent] ?? 0;

    Team? winner = widget.gameState.winner;
    if (winner == null) {
      if (mafiaLeft == 0 && citizenLeft == 0 && independentLeft > 0) {
        winner = Team.independent;
      } else if (mafiaLeft == 0 && independentLeft == 0 && citizenLeft > 0) {
        winner = Team.citizen;
      } else if (mafiaLeft == citizenLeft && independentLeft == 0 && mafiaLeft > 0) {
        winner = Team.mafia;
      }
    }
    if (winner == null) return null;

    final everRemoved = widget.gameState.removalsByNight.expand((n) => n);
    final cleanSheet = !everRemoved.any(
      (n) => widget.gameState.roleFor(n).team == winner,
    );

    switch (winner) {
      case Team.citizen:
        return _Celebration(
          color: AppColors.citizenTeam,
          titleEn: 'Citizens Win!',
          titleFa: 'شهروندان بردند!',
          cleanSheet: cleanSheet,
        );
      case Team.mafia:
        return _Celebration(
          color: AppColors.mafiaTeam,
          titleEn: 'Mafia Wins!',
          titleFa: 'مافیا برد!',
          cleanSheet: cleanSheet,
        );
      case Team.independent:
        return _Celebration(
          color: AppColors.independentTeam,
          titleEn: 'Independent Wins!',
          titleFa: 'مستقل برد!',
          cleanSheet: cleanSheet,
        );
    }
  }

  Future<void> _onEndGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const TrText('End Game?'),
        content: const Text(
          'Are you sure you want to end this game?\n'
          'آیا مطمئنید می‌خواهید از این بازی خارج شوید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TrText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const TrText('End Game'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final celebration = _determineCelebration();
    if (celebration != null && mounted) {
      await showWinCelebrationDialog(
        context,
        color: celebration.color,
        titleEn: celebration.titleEn,
        titleFa: celebration.titleFa,
        cleanSheet: celebration.cleanSheet,
      );
    }

    _interstitial.showIfReady(() {
      widget.gameState.endGame();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  static const _dayBg = Color(0xFFFFF8E1);
  static const _daySurface = Color(0xFFFFFDF5);
  static const _dayText = Colors.black;
  static const _daySecondary = Color(0xFF3A3A3A);

  /// White (diff >= 4), yellow (diff == 3), orange (diff == 2), or red
  /// (diff <= 1) - how far citizens are ahead of the combined "black side"
  /// (mafia + independent). A quick visual read on how close the game is.
  Color _statusColor(int diff) {
    if (diff <= 1) return AppColors.mafiaTeam;
    if (diff == 2) return Colors.deepOrange;
    if (diff == 3) return const Color(0xFFB8860B);
    return const Color(0xFF2E7D32);
  }

  String _statusLabel(int diff) {
    if (diff <= 1) return 'Red — Critical';
    if (diff == 2) return 'Orange — Tense';
    if (diff == 3) return 'Yellow — Caution';
    return 'Green — Safe';
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds live whenever GameState changes - including eliminations
    // applied from the Night Actions screen, so a player who gets shot
    // there instantly disappears from this list too, without needing to
    // back out and back in.
    return AnimatedBuilder(
      animation: widget.gameState,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final total = widget.gameState.playerCount ?? 0;
    final remaining = widget.gameState.remainingByTeam();
    final mafiaLeft = remaining[Team.mafia] ?? 0;
    final citizenLeft = remaining[Team.citizen] ?? 0;
    final independentLeft = remaining[Team.independent] ?? 0;
    final blackSideLeft = mafiaLeft + independentLeft;
    final diff = citizenLeft - blackSideLeft;
    final statusColor = _statusColor(diff);
    final statusLabel = _statusLabel(diff);

    final removalsByNight = widget.gameState.removalsByNight;
    final allRemoved = removalsByNight.expand((n) => n).toSet();
    final activeNumbers = [
      for (int n = 1; n <= total; n++)
        if (!allRemoved.contains(n)) n,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _dayBg,
        image: DecorationImage(
          image: AssetImage('assets/images/day_background.jpg'),
          fit: BoxFit.cover,
          opacity: 0.32,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _dayBg,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: const BannerAppBarBackground(),
          title: ValueListenableBuilder<String>(
            valueListenable: LocaleService.instance.languageCode,
            builder: (context, _, __) => Text(
              '${LocaleService.instance.tr('Day')} / روز',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            const NightMusicMuteButton(),
            IconButton(
              tooltip: 'Night History / تاریخچه شب‌ها',
              icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NightHistoryScreen(gameState: widget.gameState),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: LocaleService.instance.tr('Full Roster'),
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              onPressed: _openFullRoster,
            ),
            IconButton(
              tooltip: LocaleService.instance.tr('Night Actions'),
              icon: const Icon(Icons.nightlight_round, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DayNightTransitionScreen(gameState: widget.gameState),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Day ${widget.gameState.currentNight}',
                  style: const TextStyle(
                    color: _dayText,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _daySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.7),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Game Status: $statusLabel',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatChip(
                            label: 'Mafia', value: mafiaLeft, color: AppColors.mafiaTeam),
                        _StatChip(
                            label: 'Citizen',
                            value: citizenLeft,
                            color: AppColors.citizenTeam),
                        if (independentLeft > 0)
                          _StatChip(
                            label: 'Independent',
                            value: independentLeft,
                            color: AppColors.independentTeam,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _SpeakingTimer(activeNumbers: activeNumbers),
                  ],
                ),
              ),
              _DayActionToolbar(
                roles: _dayActionRolesPresent(),
                armedType: _armedDayActionType,
                onToggleArm: _toggleArmDayAction,
                gameState: widget.gameState,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final n in activeNumbers)
                      _PlayerTile(
                        playerNumber: n,
                        role: widget.gameState.roleFor(n),
                        removed: false,
                        textColor: _dayText,
                        secondaryColor: _daySecondary,
                        actionBadges: [
                          ...widget.gameState.actionBadgesFor(n),
                          if (widget.gameState.isNatashaSilencedForDay(n)) '🤐',
                          if (widget.gameState.dayActionDelegateFor(n) != null) '🥷',
                          if (widget.gameState.hasPlainRoleBadge(n)) '👤',
                        ],
                        voteCount: widget.gameState.voteCountFor(n),
                        voteMajority: widget.gameState.hasVoteMajority(n, activeNumbers.length),
                        voted: widget.gameState.hasVotedThisRound(n),
                        natashaSilenced: widget.gameState.isNatashaSilencedForDay(n),
                        voteGateActive: _armedDayActionType == null,
                        onTapVote: () => _openVotePicker(n, activeNumbers.length),
                        onToggle: () => _armedDayActionType != null
                            ? _applyDayAction(n)
                            : setState(() => widget.gameState.toggleRemoved(n)),
                      ),
                    for (final night in _nightOrder(removalsByNight.length))
                      if (removalsByNight[night].isNotEmpty) ...[
                        GestureDetector(
                          onDoubleTap: () =>
                              setState(() => _oldestFirst = !_oldestFirst),
                          child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: _daySecondary.withOpacity(0.3))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _oldestFirst
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      size: 12,
                                      color: _daySecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Night ${night + 1}',
                                      style: const TextStyle(
                                        color: _daySecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: Divider(color: _daySecondary.withOpacity(0.3))),
                            ],
                          ),
                          ),
                        ),
                        for (final n in removalsByNight[night])
                          _PlayerTile(
                            playerNumber: n,
                            role: widget.gameState.roleFor(n),
                            removed: true,
                            textColor: _dayText,
                            secondaryColor: _daySecondary,
                            onToggle: () => setState(
                              () => widget.gameState.toggleRemoved(n),
                            ),
                          ),
                      ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (widget.gameState.canUndoEndDay) ...[
                      SizedBox(
                        width: 44,
                        child: OutlinedButton(
                          onPressed: () => setState(widget.gameState.undoEndDay),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          child: const Icon(Icons.undo_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _BlinkOnCondition(
                        blinking: removalsByNight.last.isNotEmpty,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.blue),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DayNightTransitionScreen(gameState: widget.gameState),
                              ),
                            );
                          },
                          child: Row(mainAxisSize: MainAxisSize.min, children: [const TrText('End Day'), Text(' ${widget.gameState.currentNight}')]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onEndGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: ValueListenableBuilder<String>(
                          valueListenable: LocaleService.instance.languageCode,
                          builder: (context, _, __) =>
                              Text(LocaleService.instance.tr('End Game')),
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
    );
  }
}

/// Horizontal strip of icons for day-action roles present in this game
/// (Cowboy/Bomber/Terrorist and any future ones) - the daytime
/// counterpart to the Night Actions toolbar. Tap an icon to arm it, then
/// tap a player in the list below to apply it.
class _DayActionToolbar extends StatelessWidget {
  final List<Role> roles;
  final RoleType? armedType;
  final ValueChanged<RoleType> onToggleArm;
  final GameState gameState;

  const _DayActionToolbar({
    required this.roles,
    required this.armedType,
    required this.onToggleArm,
    required this.gameState,
  });

  bool _isDisabled(RoleType type) {
    // Simple Mode: no gating at all - every day-action icon is always
    // tappable, since there's no algorithm behind it, just a badge.
    if (!gameState.abilitiesAutoExecuted) return false;
    if (gameState.currentNight == 1) return true;
    final all = gameState.allAssignedRoles;
    int? originalHolder;
    for (int i = 0; i < all.length; i++) {
      if (all[i].type == type) {
        originalHolder = i + 1;
        break;
      }
    }
    if (originalHolder == null) return true;
    final actor = gameState.dayActionDelegateFor(originalHolder) ?? originalHolder;
    if (gameState.isRemoved(actor)) return true;

    // The Terrorist's ability only exists through the vote: the icon
    // stays locked until whoever currently holds it (the Terrorist
    // himself, or the Thief if it was stolen) reaches the vote majority
    // this round ("In Defense") - the same generic majority rule as any
    // other player. Cowboy/Bomber aren't gated this way.
    if (type == RoleType.terrorist) {
      final total = gameState.allAssignedRoles.length;
      int activeCount = 0;
      for (int n = 1; n <= total; n++) {
        if (!gameState.isRemoved(n)) activeCount++;
      }
      if (!gameState.hasVoteMajority(actor, activeCount)) return true;
    }
    return false;
  }

  /// True if this role's day action was stolen by the Thief the night
  /// before, and is still in effect (not yet consumed).
  bool _isStolen(RoleType type) {
    final all = gameState.allAssignedRoles;
    int? originalHolder;
    for (int i = 0; i < all.length; i++) {
      if (all[i].type == type) {
        originalHolder = i + 1;
        break;
      }
    }
    if (originalHolder == null) return false;
    return gameState.dayActionDelegateFor(originalHolder) != null;
  }

  /// True once the Terrorist (or the Thief, if stolen) has actually
  /// reached the vote majority ("In Defense") and his icon has just
  /// unlocked, but he hasn't been armed yet - this is the moment to show
  /// the game master the reminder about what's about to become possible.
  bool get _terroristJustEnteredDefense {
    if (!gameState.abilitiesAutoExecuted) return false;
    if (!roles.any((r) => r.type == RoleType.terrorist)) return false;
    if (armedType == RoleType.terrorist) return false;
    return !_isDisabled(RoleType.terrorist);
  }

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: roles.expand((role) {
              final button = RoleToolbarButton(
                role: role,
                armed: armedType == role.type,
                disabled: _isDisabled(role.type),
                onTap: () => onToggleArm(role.type),
                surfaceColor: _RosterScreenState._daySurface,
                labelColor: _RosterScreenState._dayText,
                borderColor: _RosterScreenState._daySecondary.withOpacity(0.4),
              );
              if (!_isStolen(role.type)) return [button];

              // Stolen: the Thief's icon shows right next to the
              // original role's icon - both share the exact same
              // armed/disabled state (locked until Defense, then both
              // unlock and blink together), since the ability now
              // really belongs to the Thief.
              final thiefButton = RoleToolbarButton(
                role: RoleData.all[RoleType.thief]!,
                armed: armedType == role.type,
                disabled: _isDisabled(role.type),
                onTap: () => onToggleArm(role.type),
                surfaceColor: _RosterScreenState._daySurface,
                labelColor: _RosterScreenState._dayText,
                borderColor: _RosterScreenState._daySecondary.withOpacity(0.4),
              );
              return [button, thiefButton];
            }).toList(),
          ),
        ),
        if (_terroristJustEnteredDefense)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Text(
              'The Terrorist is In Defense - if voted out, he can now '
              'eliminate one player from the roster. / '
              'تروریست در دفاعیه است - اگر رأی خروج بیاورد، اکنون می‌تواند '
              'یک نفر را از لیست بازیکنان حذف کند.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (armedType != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              armedType == RoleType.terrorist
                  ? 'Select one player from the list to eliminate. / '
                      'یک نفر را از لیست پلیرها انتخاب کنید تا حذف شود.'
                  : 'Armed - tap a player',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RosterScreenState._dayText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// A number in the vote picker wheel - styled like a casino jackpot
/// display: the bigger the number, the bigger and flashier it gets.
class _JackpotNumber extends StatelessWidget {
  final int value;
  final int? majorityAt;

  const _JackpotNumber(this.value, {this.majorityAt});

  bool get _isMajority => majorityAt != null && value >= majorityAt!;

  @override
  Widget build(BuildContext context) {
    final majorityColor = _isMajority ? Colors.redAccent : null;
    if (value < 10) {
      return Text(
        '$value',
        style: TextStyle(fontSize: 20, color: majorityColor ?? _RosterScreenState._dayText),
      );
    }
    if (value < 25) {
      return Text(
        '$value',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: majorityColor ?? const Color(0xFFFFC107),
        ),
      );
    }
    if (value < 50) {
      return Text(
        '$value',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: majorityColor ?? const Color(0xFFFF9800),
          shadows: [Shadow(color: majorityColor ?? Colors.orange, blurRadius: 6)],
        ),
      );
    }
    if (value < 75) {
      return Text(
        '$value',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: majorityColor ?? const Color(0xFFFF5252),
          shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)],
        ),
      );
    }
    // 75-100: full jackpot - big, gold, glowing (still flips solid red
    // once past the majority threshold).
    return Text(
      '🎰 $value',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: majorityColor ?? const Color(0xFFFFD700),
        shadows: [
          Shadow(color: majorityColor ?? Colors.amber, blurRadius: 14),
          const Shadow(color: Colors.redAccent, blurRadius: 20),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final int playerNumber;
  final Role role;
  final bool removed;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onToggle;
  final List<String> actionBadges;
  final int? voteCount;
  final bool voteMajority;
  final bool voted;
  final bool natashaSilenced;
  final bool voteGateActive;
  final VoidCallback? onTapVote;

  const _PlayerTile({
    required this.playerNumber,
    required this.role,
    required this.removed,
    required this.textColor,
    required this.secondaryColor,
    required this.onToggle,
    this.actionBadges = const [],
    this.voteCount,
    this.voteMajority = false,
    this.voted = false,
    this.natashaSilenced = false,
    this.voteGateActive = true,
    this.onTapVote,
  });

  @override
  Widget build(BuildContext context) {
    // Independent of vote count: red once a nominee has enough votes to
    // be lynched (In Defense), yellow once their vote has been submitted
    // this round, brown if Natasha silenced them last night (until
    // either of those takes over), otherwise a plain white "halo" card
    // so the row stays easy to read against the background art either
    // way.
    final BoxDecoration decoration;
    if (voteMajority) {
      decoration = BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent, width: 1.5),
      );
    } else if (voted) {
      decoration = BoxDecoration(
        color: Colors.amber.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber, width: 1.5),
      );
    } else if (natashaSilenced) {
      decoration = BoxDecoration(
        color: Colors.brown.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.brown, width: 1.5),
      );
    } else {
      decoration = BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: decoration,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        dense: true,
        leading: SizedBox(
          width: (onTapVote != null ? 92 : 24) +
              (role.type == RoleType.president ? 28 : 0),
          height: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              removed
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: role.color.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: role.color.withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Icon(Icons.gps_fixed, size: 12, color: role.color.withOpacity(0.7)),
                      ],
                    )
                  : RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 24),
              // The President always wakes with (and reads as) the plain
              // Mafia group, so a plain-Mafia icon rides along next to
              // his own icon for reference - it's informational only and
              // never counted as an actual Mafia player.
              if (role.type == RoleType.president) ...[
                const SizedBox(width: 4),
                RoleEmojiBadge(
                  emoji: RoleData.all[RoleType.mafia]!.emoji,
                  color: AppColors.mafiaTeam,
                  size: 20,
                ),
              ],
              if (onTapVote != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onTapVote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: voteMajority
                          ? Colors.redAccent.withOpacity(0.2)
                          : secondaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gavel,
                            size: 18, color: voteMajority ? Colors.redAccent : secondaryColor),
                        const SizedBox(width: 3),
                        Text(
                          '${voteCount ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: voteMajority ? Colors.redAccent : secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        title: Text(
          '$playerNumber',
          style: TextStyle(
            decoration: removed ? TextDecoration.lineThrough : null,
            color: removed ? role.color.withOpacity(0.7) : (voteMajority ? Colors.redAccent : textColor),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    role.name,
                    style: TextStyle(
                      decoration: removed ? TextDecoration.lineThrough : null,
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (voteMajority) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'In Defense',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              role.nameFa,
              style: TextStyle(
                decoration: removed ? TextDecoration.lineThrough : null,
                color: secondaryColor,
                fontSize: 10,
              ),
            ),
            if (actionBadges.isNotEmpty) ActionMarksRow(emojis: actionBadges),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                removed ? Icons.replay_circle_filled_outlined : Icons.track_changes,
                size: 22,
                color: removed
                    ? secondaryColor
                    : ((!voteGateActive || voteMajority)
                        ? AppColors.mafiaTeam
                        : AppColors.mafiaTeam.withOpacity(0.3)),
              ),
              tooltip: removed
                  ? 'Restore'
                  : ((!voteGateActive || voteMajority)
                      ? 'Remove'
                      : 'Reaches majority votes first'),
              onPressed: (removed || !voteGateActive || voteMajority) ? onToggle : null,
            ),
            if (!removed)
              const Text('Kick', style: TextStyle(fontSize: 9, color: AppColors.mafiaTeam)),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class _Celebration {
  final Color color;
  final String titleEn;
  final String titleFa;
  final bool cleanSheet;

  const _Celebration({
    required this.color,
    required this.titleEn,
    required this.titleFa,
    required this.cleanSheet,
  });
}

/// Pulses its child's opacity when [blinking] is true - used to catch the
/// game master's eye on the End Day button once someone's been removed
/// this round, so it's obvious a vote actually landed.
class _BlinkOnCondition extends StatefulWidget {
  final bool blinking;
  final Widget child;

  const _BlinkOnCondition({required this.blinking, required this.child});

  @override
  State<_BlinkOnCondition> createState() => _BlinkOnConditionState();
}

class _BlinkOnConditionState extends State<_BlinkOnCondition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.blinking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _BlinkOnCondition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinking && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.blinking) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.blinking) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25 + t * 0.55),
                blurRadius: 6 + t * 16,
                spreadRadius: 1 + t * 3,
              ),
            ],
          ),
          child: Opacity(opacity: 0.6 + (t * 0.4), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A per-player speaking timer, adjustable up to 3 minutes. Tap a
/// player's number to make them the current speaker and start (or
/// reset) their countdown; tapping the next player resets it for them
/// instead. Buzzes and plays an alert sound when time runs out.
class _SpeakingTimer extends StatefulWidget {
  final List<int> activeNumbers;

  const _SpeakingTimer({required this.activeNumbers});

  @override
  State<_SpeakingTimer> createState() => _SpeakingTimerState();
}

class _SpeakingTimerState extends State<_SpeakingTimer> {
  static const int _maxSeconds = 180; // 3 minutes
  int _durationSeconds = 60;
  int? _currentPlayer;
  int _remainingSeconds = 0;
  Timer? _ticker;

  void _selectPlayer(int playerNumber) {
    _ticker?.cancel();
    setState(() {
      _currentPlayer = playerNumber;
      _remainingSeconds = _durationSeconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _alarm();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  /// A single vibrate()/alert() was too easy to miss - repeat a strong
  /// buzz + alert tone several times so it's unmistakable even if the
  /// game master isn't looking at the screen.
  void _alarm() async {
    for (var i = 0; i < 5; i++) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  void _adjustDuration(int deltaSeconds) {
    setState(() {
      _durationSeconds = (_durationSeconds + deltaSeconds).clamp(15, _maxSeconds);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeUp = _currentPlayer != null && _remainingSeconds == 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: _RosterScreenState._dayText),
            const SizedBox(width: 6),
            Text(
              _currentPlayer == null
                  ? 'Timer'
                  : 'Player $_currentPlayer',
              style: const TextStyle(
                color: _RosterScreenState._dayText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _format(_currentPlayer == null ? _durationSeconds : _remainingSeconds),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: timeUp ? Colors.redAccent : _RosterScreenState._dayText,
              ),
            ),
            if (_currentPlayer == null) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: () => _adjustDuration(-15),
                tooltip: '-15s',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                onPressed: () => _adjustDuration(15),
                tooltip: '+15s',
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.replay, size: 18),
                tooltip: 'Reset',
                onPressed: () => _selectPlayer(_currentPlayer!),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.activeNumbers.map((n) {
              final isCurrent = n == _currentPlayer;
              return GestureDetector(
                onTap: () => _selectPlayer(n),
                child: Container(
                  width: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.amber : _RosterScreenState._daySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent ? Colors.amber.shade800 : Colors.black26,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.black : _RosterScreenState._dayText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
