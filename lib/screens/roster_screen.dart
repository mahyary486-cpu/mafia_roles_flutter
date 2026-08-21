import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../logic/ad_service.dart';
import '../logic/game_state.dart';
import '../logic/seating.dart';
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

  /// Which night we last rendered for - lets build() notice a new day
  /// has started and clear any Bomber action that got stuck waiting
  /// for a tap that never came (day-screen state persists across
  /// nights, so without this a stuck action would dim the whole
  /// roster forever).
  int? _lastSeenNight;

  /// First target selected for the Bomber's two-target night action.
  int? _bomberFirstTarget;

  /// Whether the speaking-timer card is expanded or rolled up out of
  /// the way (like a shutter). Starts open on Day 1 so the timer is
  /// front and center; auto-collapses once a full speaking round
  /// finishes, to give the player list more room.
  bool _timerExpanded = true;

  /// Once the speaking-timer round finishes, voting picks up in the
  /// same order starting from whoever spoke first that day - these
  /// two only apply for the night they were set on.
  int? _voteRotationAnchor;
  int? _voteRotationAnchorNight;

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

    // Hard rule, regardless of mode: nobody with a day action can act
    // on Day 1 (the toolbar icon is already disabled then too, but this
    // guards against it being triggered some other way).
    if (widget.gameState.currentNight == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Day-action roles cannot act on Day 1.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _armedDayActionType = null);
      return;
    }

    if (type == RoleType.bomber) {
      _applyBomberAction(targetPlayerNumber);
      return;
    }

    // Simple Mode: no elimination or chain logic - just note the role's
    // icon in front of the tapped player and disarm. The Terrorist is
    // the exception: his double-elimination isn't an "auto-execute
    // convenience", it's the actual rule of the role, so it always
    // applies even in Simple Mode.
    if (!widget.gameState.abilitiesAutoExecuted && type != RoleType.terrorist) {
      final role = RoleData.all[type];
      if (role != null) {
        widget.gameState.addActionBadge(targetPlayerNumber, role.emoji);
      }
      setState(() => _armedDayActionType = null);
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
            'That role\'s holder is no longer in the game.',
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
            'Thief stole the ${role.name} ability - the Thief acted in '
            'his place and was eliminated along with Player '
            '$targetPlayerNumber instead. Player $originalHolder remains '
            'in the game as an ordinary ${role.team.name} member.',
          );
        }
      }
      if (wasStolen) widget.gameState.consumeThiefSteal();
      // Someone just left the game outside of voting - the old tally
      // and majority threshold no longer make sense, so start the
      // round's voting over.
      widget.gameState.clearVotesThisRound();
      _armedDayActionType = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          blocked
              ? 'Blocked by the Bartender last night - only player '
                  '$actorNumber is out.'
              : 'Players $actorNumber and $targetPlayerNumber are out.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// The Bomber's own two-step chain: sitting "next to" whoever's
  /// tapped first eliminates the Bomber and that player together, then
  /// only the nearest still-alive seat in each direction from that
  /// player stays tappable to finish the job (skipping anyone already
  /// eliminated, whether from earlier voting or the blast itself) -
  /// unless the Bomber targets his own seat, which is a one-tap
  /// shortcut with no second step.
  ///
  /// Walks outward from [seat] in the given [direction] (+1 or -1),
  /// skipping removed seats, until it finds someone still alive - or
  /// null if nobody else is left. The circular step math is a
  /// standalone, unit-tested function; this just supplies the current
  /// player count and alive-check.
  int? _bomberNearestAlive(int seat, int direction) => nearestAliveSeat(
        seat,
        direction,
        widget.gameState.playerCount ?? 0,
        widget.gameState.isRemoved,
      );

  void _applyBomberAction(int targetPlayerNumber) {
    final total = widget.gameState.playerCount ?? 0;
    if (total == 0) return;

    final bomberSeat = _findPlayerNumber(RoleType.bomber);
    if (bomberSeat == null) {
      setState(() => _armedDayActionType = null);
      return;
    }

    // If the Thief stole the Bomber's ability last night, the Thief is
    // the one who actually detonates today - the Bomber himself
    // survives as an ordinary citizen.
    final actorNumber = widget.gameState.dayActionDelegateFor(bomberSeat) ?? bomberSeat;
    final wasStolen = actorNumber != bomberSeat;
    if (widget.gameState.isRemoved(actorNumber)) {
      setState(() => _armedDayActionType = null);
      return;
    }

    // Simple Mode: just note the icon, no elimination chain.
    if (!widget.gameState.abilitiesAutoExecuted) {
      widget.gameState.addActionBadge(targetPlayerNumber, '💣');
      setState(() {
        _armedDayActionType = null;
        _bomberFirstTarget = null;
      });
      return;
    }

    void applySubstitutionIfStolen() {
      if (!wasStolen) return;
      widget.gameState.markPlainRoleBadge(bomberSeat);
      widget.gameState.setNightMark(
        bomberSeat,
        RoleData.all[RoleType.bomber]!.color,
        'Thief stole the Bomber ability - the Thief detonated in his '
        'place today instead. Player $bomberSeat remains in the game as '
        'an ordinary citizen.',
      );
    }

    if (_bomberFirstTarget == null) {
      // First tap of a fresh Bomber action.
      if (targetPlayerNumber == bomberSeat) {
        // Exception: detonating in his own seat - one tap does
        // everything, no second choice needed.
        final neighbor = _bomberNearestAlive(bomberSeat, -1);
        setState(() {
          widget.gameState.eliminate(actorNumber);
          if (neighbor != null) widget.gameState.eliminate(neighbor);
          applySubstitutionIfStolen();
          widget.gameState.markDayAbilitySpent(RoleType.bomber);
          widget.gameState.clearVotesThisRound();
          _armedDayActionType = null;
          _bomberFirstTarget = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              neighbor != null
                  ? 'The Bomber detonated in his own seat - players '
                      '$actorNumber and $neighbor are out.'
                  : 'The Bomber detonated in his own seat - player '
                      '$actorNumber is out.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() {
        widget.gameState.eliminate(actorNumber);
        widget.gameState.eliminate(targetPlayerNumber);
        _bomberFirstTarget = targetPlayerNumber;
      });
      final a = _bomberNearestAlive(targetPlayerNumber, -1);
      final b = _bomberNearestAlive(targetPlayerNumber, 1);
      if (a == null && b == null) {
        // Nobody left to finish the job with - the action just ends.
        setState(() {
          applySubstitutionIfStolen();
          widget.gameState.markDayAbilitySpent(RoleType.bomber);
          widget.gameState.clearVotesThisRound();
          _bomberFirstTarget = null;
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'The Bomber and player $targetPlayerNumber are out - now tap '
            '${[a, b].whereType<int>().map((n) => 'player $n').join(' or ')} '
            'to finish.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Second tap: only the nearest-alive seat in each direction from
    // the first target counts - everything else is dimmed and locked
    // out in the UI too.
    final a = _bomberNearestAlive(_bomberFirstTarget!, -1);
    final b = _bomberNearestAlive(_bomberFirstTarget!, 1);
    if (targetPlayerNumber != a && targetPlayerNumber != b) {
      return;
    }
    setState(() {
      widget.gameState.eliminate(targetPlayerNumber);
      applySubstitutionIfStolen();
      widget.gameState.markDayAbilitySpent(RoleType.bomber);
      widget.gameState.clearVotesThisRound();
      _armedDayActionType = null;
      _bomberFirstTarget = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Player $targetPlayerNumber is out too - the Bomber\'s action '
          'is complete.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  /// The order voting should proceed in: starting from whoever spoke
  /// first today (if the speaking timer was used this round), looping
  /// through the rest of the active players from there - otherwise
  /// just plain numeric order.
  List<int> _voteOrder(List<int> activeNumbers) {
    final anchor = _voteRotationAnchorNight == widget.gameState.currentNight
        ? _voteRotationAnchor
        : null;
    if (anchor == null) return activeNumbers;
    final idx = activeNumbers.indexOf(anchor);
    if (idx == -1) return activeNumbers;
    return [
      for (int i = 0; i < activeNumbers.length; i++)
        activeNumbers[(idx + i) % activeNumbers.length],
    ];
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
        content: const Text('Are you sure you want to end this game?'),
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
          title: TrText(
            'Day',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            const NightMusicMuteButton(),
            IconButton(
              tooltip: 'Night History',
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
              tooltip: 'Full Roster',
              icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
              onPressed: _openFullRoster,
            ),
            IconButton(
              tooltip: 'Night Actions',
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _timerExpanded = !_timerExpanded),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: _dayText),
                          const SizedBox(width: 6),
                          const Text(
                            'Speaking Timer',
                            style: TextStyle(
                              color: _dayText,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Icon(
                            _timerExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: _dayText,
                          ),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _timerExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _SpeakingTimer(
                          // A fresh key each day throws away yesterday's
                          // finished/used state instead of carrying it
                          // over and showing everyone as already spoken.
                          key: ValueKey('speaking-timer-day-${widget.gameState.currentNight}'),
                          activeNumbers: activeNumbers,
                          onVoteAnchorReady: (n) => setState(() {
                            _voteRotationAnchor = n;
                            _voteRotationAnchorNight = widget.gameState.currentNight;
                          }),
                          onRoundFinished: () => setState(() => _timerExpanded = false),
                        ),
                      ),
                      secondChild: const SizedBox(width: double.infinity),
                    ),
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
                      _BlinkOnCondition(
                        // Guides voting through the list in order: once
                        // this player is the first one who hasn't voted
                        // yet, their row blinks so the game master knows
                        // whose turn it is to be voted on. If the
                        // speaking timer was used, this order starts
                        // from whoever spoke first instead of player 1.
                        blinking: !widget.gameState.hasVotedThisRound(n) &&
                            _voteOrder(activeNumbers)
                                    .firstWhere((p) => !widget.gameState.hasVotedThisRound(p),
                                        orElse: () => -1) ==
                                n,
                        child: _PlayerTile(
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
                        voteMajority: widget.gameState.hasVoteMajority(n, activeNumbers.length) ||
                            (_bomberFirstTarget != null &&
                                (n == _bomberNearestAlive(_bomberFirstTarget!, -1) ||
                                    n == _bomberNearestAlive(_bomberFirstTarget!, 1))),
                        voted: widget.gameState.hasVotedThisRound(n),
                        natashaSilenced: widget.gameState.isNatashaSilencedForDay(n),
                        voteGateActive: _armedDayActionType == null,
                        onTapVote: () => _openVotePicker(n, activeNumbers.length),
                        onToggle: () => _armedDayActionType != null
                            ? _applyDayAction(n)
                            : setState(() => widget.gameState.toggleRemoved(n)),
                        dimmed: _bomberFirstTarget != null &&
                            n != _bomberNearestAlive(_bomberFirstTarget!, -1) &&
                            n != _bomberNearestAlive(_bomberFirstTarget!, 1),
                        ),
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
                      flex: 2,
                      child: _BlinkOnCondition(
                        blinking: removalsByNight.last.isNotEmpty ||
                            (activeNumbers.isNotEmpty &&
                                activeNumbers.every(widget.gameState.hasVotedThisRound)),
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
                      flex: 1,
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

  /// Which player currently holds this role - for the small number
  /// badge on the icon, so the game master doesn't have to
  /// cross-reference the roster.
  int? _holderOf(RoleType type) {
    final all = gameState.allAssignedRoles;
    for (int i = 0; i < all.length; i++) {
      if (all[i].type == type) return i + 1;
    }
    return null;
  }

  bool _isDisabled(RoleType type) {
    // Day 1, nobody with a day action can act yet - Cowboy, Bomber, and
    // Terrorist alike - regardless of Simple Mode, since this is a hard
    // rule of the game, not an auto-execute convenience.
    if (gameState.currentNight == 1) return true;
    // Simple Mode: no further gating - every day-action icon is always
    // tappable, since there's no algorithm behind it, just a badge.
    // The Terrorist is the one exception: his defense-vote gate isn't
    // an "auto-execute convenience", it's the actual rule of the role,
    // so it always applies even in Simple Mode.
    if (!gameState.abilitiesAutoExecuted && type != RoleType.terrorist) return false;
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
                playerNumber: _holderOf(role.type),
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
                playerNumber: _holderOf(RoleType.thief),
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
              'eliminate one player from the roster.',
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
                  ? 'Select one player from the list to eliminate.'
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

  /// True while this specific row is locked out of the current day
  /// action (e.g. the Bomber's second tap only allows two specific
  /// neighbors) - greyed out and untappable until that clears.
  final bool dimmed;

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
    this.dimmed = false,
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
    return Opacity(
      opacity: dimmed ? 0.3 : 1.0,
      child: Container(
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
              // Eliminated players still show their real role icon (just
              // dimmed a touch) instead of a generic placeholder, so the
              // roster stays a readable reference of who had what.
              removed
                  ? Opacity(
                      opacity: 0.55,
                      child: RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 24),
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
                  child: TrText(
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
            TrText(
              role.displayShortDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              onPressed: (dimmed
                      ? false
                      : (removed || !voteGateActive || voteMajority))
                  ? onToggle
                  : null,
            ),
            if (!removed)
              const Text('Kick', style: TextStyle(fontSize: 9, color: AppColors.mafiaTeam)),
          ],
        ),
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

/// A per-player speaking timer with strict turn order.
///
/// Tap any untouched seat to start the session - that becomes the
/// "anchor". After that, only two kinds of taps are ever allowed:
/// - The official next seat in circular order from the anchor.
/// - Exactly ONE "detour": any other eligible seat, allowed once per
///   official slot (between one official turn ending and the next
///   official turn's own time running out). Once a detour has been
///   used for a slot, every other seat is locked until the official
///   seat is finally tapped.
///
/// Once every seat has had its official turn, a 10-second grace
/// window opens for a single last-minute detour from anyone who
/// never got one mid-round; then the round locks and the shutter
/// collapses.
class _SpeakingTimer extends StatefulWidget {
  final List<int> activeNumbers;

  /// Called once the whole speaking round is over (every active player
  /// has had a turn) and the closing grace window has resolved, with
  /// the anchor (first speaker) - so the player list can pick up
  /// voting in that same order.
  final ValueChanged<int?>? onVoteAnchorReady;

  /// Called at that same moment, so the parent can roll the timer
  /// shutter back up automatically.
  final VoidCallback? onRoundFinished;

  const _SpeakingTimer({
    super.key,
    required this.activeNumbers,
    this.onVoteAnchorReady,
    this.onRoundFinished,
  });

  @override
  State<_SpeakingTimer> createState() => _SpeakingTimerState();
}

/// A snapshot of everything the Undo button needs to restore, taken
/// right before every state-changing tap.
class _TimerSnapshot {
  final int? anchor;
  final Set<int> usedOnce;
  final Set<int> done;
  final int? activePlayer;
  final bool running;
  final bool activeIsOfficial;
  final int remainingSeconds;
  final bool detourUsedForCurrentSlot;
  final bool roundOverBlinking;
  final bool roundLocked;

  _TimerSnapshot({
    required this.anchor,
    required Set<int> usedOnce,
    required Set<int> done,
    required this.activePlayer,
    required this.running,
    required this.activeIsOfficial,
    required this.remainingSeconds,
    required this.detourUsedForCurrentSlot,
    required this.roundOverBlinking,
    required this.roundLocked,
  })  : usedOnce = Set.of(usedOnce),
        done = Set.of(done);
}

class _SpeakingTimerState extends State<_SpeakingTimer> {
  static const int _maxSeconds = 180; // 3 minutes
  int _durationSeconds = 30;

  final Set<int> _usedOnce = {}; // has spoken at least once (light blue)
  final Set<int> _done = {}; // unused now, kept only for snapshot compatibility

  // Seats that have had their real, in-order official turn - these can
  // be picked again and again as a bonus/challenge target for any
  // later slot, with no limit.
  final Set<int> _hadOfficialTurn = {};

  // Seats that got picked as an early bonus BEFORE their own official
  // turn happened - locked out of every further pick (by anyone) until
  // their own official turn comes up naturally in the order.
  final Set<int> _usedBonusBeforeOfficial = {};

  int? _anchor; // the very first seat tapped this round

  int? _activePlayer; // whoever is on the clock right now
  bool _running = false;
  bool _activeIsOfficial = false;
  int _remainingSeconds = 0;
  Timer? _ticker;

  // Exactly one out-of-order "detour" is allowed between one official
  // turn ending and the next official turn happening.
  bool _detourUsedForCurrentSlot = false;

  bool _roundOverBlinking = false; // the 10s grace window after the
  // very last official turn, before the round locks for good.
  int _graceSecondsLeft = 10;
  Timer? _graceTimer;
  bool _roundLocked = false;

  final List<_TimerSnapshot> _history = [];

  /// The next seat, in circular order from the anchor, that hasn't had
  /// its official turn yet - or null if the round is complete.
  int? get _officialNext {
    final anchor = _anchor;
    if (anchor == null) return null;
    final list = widget.activeNumbers;
    final anchorIdx = list.indexOf(anchor);
    if (anchorIdx == -1) return null;
    for (int step = 0; step < list.length; step++) {
      final candidate = list[(anchorIdx + step) % list.length];
      if (!_hadOfficialTurn.contains(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  void _pushSnapshot() {
    _history.add(_TimerSnapshot(
      anchor: _anchor,
      usedOnce: _usedOnce,
      done: _done,
      activePlayer: _activePlayer,
      running: _running,
      activeIsOfficial: _activeIsOfficial,
      remainingSeconds: _remainingSeconds,
      detourUsedForCurrentSlot: _detourUsedForCurrentSlot,
      roundOverBlinking: _roundOverBlinking,
      roundLocked: _roundLocked,
    ));
    // Keep a bounded history so this can't grow forever in a long game.
    if (_history.length > 30) _history.removeAt(0);
  }

  void _undo() {
    if (_history.isEmpty) return;
    final s = _history.removeLast();
    _ticker?.cancel();
    _graceTimer?.cancel();
    setState(() {
      _anchor = s.anchor;
      _usedOnce
        ..clear()
        ..addAll(s.usedOnce);
      _done
        ..clear()
        ..addAll(s.done);
      _activePlayer = s.activePlayer;
      _running = s.running;
      _activeIsOfficial = s.activeIsOfficial;
      _remainingSeconds = s.remainingSeconds;
      _detourUsedForCurrentSlot = s.detourUsedForCurrentSlot;
      _roundOverBlinking = s.roundOverBlinking;
      _roundLocked = s.roundLocked;
    });
    if (_running) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        _alarm();
        _finishActiveTurn();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _beginTurn(int n, {required bool isOfficial}) {
    _pushSnapshot();
    _ticker?.cancel();
    setState(() {
      _activePlayer = n;
      _activeIsOfficial = isOfficial;
      _running = true;
      _remainingSeconds = _durationSeconds;
      if (isOfficial) _detourUsedForCurrentSlot = false;
    });
    _startTicker();
  }

  void _pauseResume() {
    if (_activePlayer == null) return;
    _pushSnapshot();
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _startTicker();
    }
  }

  void _resetActiveClock() {
    if (_activePlayer == null) return;
    _pushSnapshot();
    setState(() => _remainingSeconds = _durationSeconds);
    if (_running) _startTicker();
  }

  void _finishActiveTurn() {
    final n = _activePlayer;
    if (n == null) return;
    final wasOfficial = _activeIsOfficial;
    final wasGraceCourtesy = _roundOverBlinking;
    _ticker?.cancel();
    setState(() {
      // First turn ever for this seat -> light blue. Second turn (a
      // detour or the final courtesy) -> fully done.
      if (_usedOnce.contains(n)) {
        _usedOnce.remove(n);
        _done.add(n);
      } else {
        _usedOnce.add(n);
      }
      if (wasOfficial) {
        _hadOfficialTurn.add(n);
      } else if (!_hadOfficialTurn.contains(n)) {
        // A bonus turn taken BEFORE this seat's own official turn -
        // that seat is now locked from any further picks until its
        // real turn comes up in order.
        _usedBonusBeforeOfficial.add(n);
      }
      _activePlayer = null;
      _running = false;
      _remainingSeconds = 0;

      if (wasGraceCourtesy) {
        _graceTimer?.cancel();
        _roundOverBlinking = false;
        _lockRound();
        return;
      }

      if (wasOfficial) {
        if (_officialNext == null) {
          _startFinalGrace();
        }
        // detourUsedForCurrentSlot resets automatically the next time
        // an official turn actually begins (see _beginTurn).
      }
      // If it was a mid-round detour, the official seat is still
      // pending and the lock (detourUsedForCurrentSlot) stays on.
    });
  }

  void _startFinalGrace() {
    setState(() {
      _roundOverBlinking = true;
      _graceSecondsLeft = 10;
    });
    _graceTimer?.cancel();
    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_graceSecondsLeft <= 1) {
        timer.cancel();
        setState(() => _roundOverBlinking = false);
        _lockRound();
      } else {
        setState(() => _graceSecondsLeft--);
      }
    });
  }

  void _lockRound() {
    setState(() => _roundLocked = true);
    widget.onVoteAnchorReady?.call(_anchor);
    widget.onRoundFinished?.call();
  }

  void _tapNumber(int n) {
    if (_roundLocked || _done.contains(n)) return;

    if (_activePlayer != null) {
      if (n == _activePlayer) _pauseResume();
      return; // everything else locked while someone's on the clock
    }

    // The 10-second grace window after the round's last official turn:
    // exactly one more courtesy pick, from anyone still eligible.
    if (_roundOverBlinking) {
      if (!_usedOnce.contains(n)) return; // only light-blue seats qualify
      _graceTimer?.cancel();
      _beginTurn(n, isOfficial: false);
      return;
    }

    final official = _officialNext;

    // Very first tap of the whole session.
    if (_anchor == null) {
      _anchor = n;
      _beginTurn(n, isOfficial: true);
      return;
    }

    if (n == official) {
      _beginTurn(n, isOfficial: true);
      return;
    }

    // Out-of-order tap: only allowed once per slot, and only on a seat
    // that hasn't already had its bonus turn. A seat that already used
    // its one pre-turn bonus (and still hasn't reached its own official
    // turn) is locked - it can only be picked again once that official
    // turn comes up naturally. Seats that already HAD their official
    // turn (behind in the order) have no such limit - they can be
    // challenged again any time a slot is open.
    final alreadyUsedPreTurnBonus =
        _usedBonusBeforeOfficial.contains(n) && !_hadOfficialTurn.contains(n);
    if (!_detourUsedForCurrentSlot && !_done.contains(n) && !alreadyUsedPreTurnBonus) {
      _pushSnapshot();
      setState(() => _detourUsedForCurrentSlot = true);
      _beginTurn(n, isOfficial: false);
      return;
    }
    // Otherwise: locked. The next tap has to be the official seat.
  }

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
    _graceTimer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final timeUp = _activePlayer != null && _remainingSeconds == 0 && _running;
    final digits = Text(
      _format(_activePlayer != null ? _remainingSeconds : _durationSeconds),
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: timeUp ? Colors.redAccent : _RosterScreenState._dayText,
      ),
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: _RosterScreenState._dayText),
            const SizedBox(width: 6),
            Text(
              _roundLocked
                  ? 'Speaking round complete'
                  : _roundOverBlinking
                      ? 'Last call - ${_graceSecondsLeft}s for one more turn...'
                      : _activePlayer == null
                          ? 'Timer'
                          : (_activeIsOfficial
                              ? 'Player $_activePlayer'
                              : 'Bonus turn: Player $_activePlayer'),
              style: const TextStyle(
                color: _RosterScreenState._dayText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (_activePlayer != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded, size: 28, color: Colors.black),
                tooltip: 'Reset clock',
                onPressed: _resetActiveClock,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 28, color: Colors.black),
                tooltip: 'Next',
                onPressed: _finishActiveTurn,
              ),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 24, color: Colors.black87),
                tooltip: 'Undo',
                onPressed: _undo,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle, size: 34, color: Colors.black),
              onPressed: _running ? null : () => _adjustDuration(-15),
              tooltip: '-15s',
            ),
            const SizedBox(width: 8),
            digits,
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 34, color: Colors.black),
              onPressed: _running ? null : () => _adjustDuration(15),
              tooltip: '+15s',
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          // Sized so about 5 and a half cells show at once - a visible
          // hint that there's more to scroll to horizontally.
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.activeNumbers.map((n) {
              final isDone = _done.contains(n);
              final isActive = n == _activePlayer;
              final isArmedWaiting = !_roundLocked &&
                  !_roundOverBlinking &&
                  _activePlayer == null &&
                  n == _officialNext;
              final isUsedOnce = !isActive && _usedOnce.contains(n);
              final Color bg;
              final Color border;
              final Color fg;
              if (isDone) {
                bg = Colors.blue.shade900;
                border = Colors.blue.shade900;
                fg = Colors.white70;
              } else if (isActive || isArmedWaiting) {
                bg = Colors.amber;
                border = Colors.amber.shade800;
                fg = Colors.black;
              } else if (isUsedOnce) {
                bg = Colors.lightBlueAccent.withOpacity(0.6);
                border = Colors.lightBlue;
                fg = Colors.black;
              } else {
                bg = _RosterScreenState._daySurface;
                border = Colors.black26;
                fg = _RosterScreenState._dayText;
              }
              final cell = GestureDetector(
                onTap: () => _tapNumber(n),
                child: Container(
                  width: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: isActive ? 2 : 1),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$n',
                        style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 16),
                      ),
                      if (isActive)
                        Positioned(
                          bottom: 1,
                          child: Icon(
                            _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      if (isArmedWaiting)
                        const Positioned(
                          bottom: 1,
                          child: Icon(Icons.play_arrow_rounded, size: 20, color: Colors.red),
                        ),
                    ],
                  ),
                ),
              );
              // The "waiting for a tap" seat pulses like a little light
              // dance, so it's unmistakable which one is up next.
              return (isArmedWaiting || (isActive && _running))
                  ? _BlinkOnCondition(blinking: true, child: cell)
                  : cell;
            }).toList(),
          ),
        ),
      ],
    );
  }
}
