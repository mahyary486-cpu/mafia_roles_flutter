import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Colors;

import '../models/night_record.dart';
import '../models/role.dart';
import '../models/role_type.dart';
import '../models/team.dart';
import 'role_generator.dart';

/// Holds the current game's role assignments purely in RAM.
///
/// There is no persistence layer by design: nothing is written to disk or
/// any database. Calling [endGame] wipes everything, and restarting the
/// app (or the OS reclaiming memory) wipes it just the same. Navigating
/// back and forth between screens (e.g. the system back button) does NOT
/// lose anything, since this object lives above the screens in the widget
/// tree - only [endGame] (a fresh "Number of Players" pick) resets it.
class GameState extends ChangeNotifier {
  List<Role>? _assignments;

  /// Removed player numbers, grouped by the night they were removed in.
  /// `_removalsByNight[0]` is night 1's removals, `[1]` is night 2's, etc.
  /// The last entry is always the "current" (not yet ended) night.
  final List<List<int>> _removalsByNight = [[]];

  /// This night's in-progress action markers: playerNumber -> (color,
  /// label), set from the Night Actions screen. Cleared automatically
  /// whenever the night ends (or the game ends), since they represent
  /// only the current night's unfinished bookkeeping.
  final Map<int, Color> _nightMarkColors = {};
  final Map<int, String> _nightMarkLabels = {};

  /// Role types whose ability is blocked for the current night (e.g. the
  /// Bartender, Thief, or Enchanter targeted that role's holder). Cleared
  /// when the night ends.
  final Set<RoleType> _disabledRolesTonight = {};

  Set<RoleType> get disabledRolesTonight => Set.unmodifiable(_disabledRolesTonight);

  void disableRoleTonight(RoleType type) {
    _disabledRolesTonight.add(type);
    notifyListeners();
  }

  /// Which player each role type has already acted on tonight - once a
  /// role has acted, its toolbar icon goes dark for the rest of the
  /// night (can't act twice), until [undoActedTonight] clears it.
  final Map<RoleType, int> _roleActedOnTonight = {};

  /// The Psycho's two-step night action: first he points at a target
  /// (marked, not yet eliminated), then he secretly appoints a second
  /// player as "the judge" who gets woken separately and decides
  /// (like/no like) whether the target actually dies. Both clear at the
  /// end of the night either way.
  int? _psychoTarget;
  int? _psychoJudge;

  int? get psychoTarget => _psychoTarget;
  int? get psychoJudge => _psychoJudge;

  void setPsychoTarget(int target) {
    _psychoTarget = target;
    notifyListeners();
  }

  void setPsychoJudge(int judge) {
    _psychoJudge = judge;
    notifyListeners();
  }

  void clearPsycho() {
    _psychoTarget = null;
    _psychoJudge = null;
    notifyListeners();
  }

  bool hasActedTonight(RoleType type) => _roleActedOnTonight.containsKey(type);
  int? actedTargetTonight(RoleType type) => _roleActedOnTonight[type];

  void recordActedTonight(RoleType type, int target) {
    _roleActedOnTonight[type] = target;
    notifyListeners();
  }

  /// Reverses [type]'s action from earlier tonight (the "X" button next
  /// to a used-up role icon) - re-arms the icon and lets it be used on
  /// someone else instead. Best-effort on the visible mark/label if
  /// another role also touched the same target tonight, since only one
  /// mark is shown per player at a time.
  void undoActedTonight(RoleType type, {required String actionEmoji}) {
    final target = _roleActedOnTonight.remove(type);
    if (target == null) {
      notifyListeners();
      return;
    }
    _actionBadges[target]?.remove(actionEmoji);
    if (_actionBadges[target]?.isEmpty ?? false) _actionBadges.remove(target);
    _shotTonight.remove(target);
    _savedTonight.remove(target);
    if (!(_actionBadges[target]?.isNotEmpty ?? false)) {
      _nightMarkColors.remove(target);
      _nightMarkLabels.remove(target);
    }
    notifyListeners();
  }

  bool isRoleDisabledTonight(RoleType type) => _disabledRolesTonight.contains(type);

  /// The player number the Bartender ("ساقی") blocked most recently, and
  /// which round that happened in. Unlike [_disabledRolesTonight] (which
  /// is cleared the instant the night ends), this needs to survive into
  /// the *following day* - a day-action role (Cowboy/Bomber/Terrorist)
  /// that was blocked at night only takes himself out when he acts the
  /// next day, instead of taking his target too. It's cleared once
  /// consumed, or automatically once a second night passes unused.
  int? _bartenderBlockedPlayer;
  int? _bartenderBlockedAtRound;

  void setBartenderBlock(int playerNumber) {
    _bartenderBlockedPlayer = playerNumber;
    _bartenderBlockedAtRound = currentNight;
    notifyListeners();
  }

  /// True if [playerNumber] was the Bartender's target the night just
  /// before the current day.
  bool isBartenderBlockedForDay(int playerNumber) =>
      _bartenderBlockedPlayer == playerNumber;

  void consumeBartenderBlock() {
    _bartenderBlockedPlayer = null;
    _bartenderBlockedAtRound = null;
    notifyListeners();
  }

  /// The player Natasha silenced most recently, and which round - shown
  /// as a brown box on the Day screen the following day (their icon
  /// badge already shows via [addActionBadge]). Same survive-one-day
  /// staleness rule as the Bartender block.
  int? _natashaSilencedPlayer;
  int? _natashaSilencedAtRound;

  void setNatashaSilence(int playerNumber) {
    _natashaSilencedPlayer = playerNumber;
    _natashaSilencedAtRound = currentNight;
    notifyListeners();
  }

  bool isNatashaSilencedForDay(int playerNumber) =>
      _natashaSilencedPlayer == playerNumber;

  /// The Godfather's shield - good for exactly one shot, ever, across
  /// the whole game.
  bool _godfatherShieldUsed = false;

  bool get godfatherShieldAvailable => !_godfatherShieldUsed;

  void consumeGodfatherShield() {
    _godfatherShieldUsed = true;
    notifyListeners();
  }

  /// When true (default), tapping a role icon then a player runs that
  /// role's full algorithm (eliminate/save/silence/etc.). When false
  /// ("simple mode"), the same tap only records that role's icon in
  /// front of the player - no elimination, no saving, no side effects -
  /// just a visual note for the game master. Chosen fresh on the
  /// player-count screen at the start of every game.
  bool _abilitiesAutoExecuted = true;

  bool get abilitiesAutoExecuted => _abilitiesAutoExecuted;

  void setAbilitiesAutoExecuted(bool value) {
    _abilitiesAutoExecuted = value;
    notifyListeners();
  }

  /// Day-action roles (Terrorist/Cowboy/Bomber/...) whose ability has
  /// already fired once, for good - across the whole game. Once a role
  /// type lands in here its toolbar icon is gone for the rest of the
  /// game, even if its original holder is still alive (e.g. the Thief
  /// stole and used it, so the original holder just carries on as an
  /// ordinary player with nothing left to trigger).
  final Set<RoleType> _dayAbilitySpent = {};

  bool isDayAbilitySpent(RoleType type) => _dayAbilitySpent.contains(type);

  void markDayAbilitySpent(RoleType type) {
    _dayAbilitySpent.add(type);
    notifyListeners();
  }

  /// Players who keep going after their stolen day-action role's ability
  /// was used up by the Thief - shown a plain-citizen badge next to
  /// their name for the rest of the game as a reminder they're now just
  /// an ordinary player of their team. Never cleared per-round, only at
  /// game start/end.
  final Set<int> _plainRoleBadge = {};

  bool hasPlainRoleBadge(int playerNumber) => _plainRoleBadge.contains(playerNumber);

  void markPlainRoleBadge(int playerNumber) {
    _plainRoleBadge.add(playerNumber);
    notifyListeners();
  }

  /// The two players the Investigator looked into most recently, and
  /// which round - their icon shows on both of them the following day,
  /// same survive-one-day rule as the other day-carrying marks.
  List<int> _investigatorTargets = [];
  int? _investigatorAtRound;

  void setInvestigatorTargets(List<int> targets) {
    _investigatorTargets = targets;
    _investigatorAtRound = currentNight;
    notifyListeners();
  }

  bool isInvestigatedForDay(int playerNumber) =>
      _investigatorTargets.contains(playerNumber);

  /// The Thief can steal any role's *night* ability too (not just a
  /// day-action role) - e.g. stealing the Doctor's save. Unlike the
  /// day-role steal (which carries into tomorrow), this is used the same
  /// night: the stolen role's icon appears next to the Thief's, blinking,
  /// and the game master taps it then a target to apply that role's
  /// effect right now. Cleared automatically at the end of the night.
  RoleType? _stolenNightRoleType;
  int? _stolenNightRoleOriginalHolder;

  /// True once the stolen ability has actually been used on a target
  /// tonight. The icon stays visible next to the Thief (so the game
  /// master can see what was stolen and what happened with it) but goes
  /// dark/disabled - it does not disappear the instant it's used.
  bool _stolenNightRoleUsed = false;

  void setStolenNightRole(RoleType type, int originalHolder) {
    _stolenNightRoleType = type;
    _stolenNightRoleOriginalHolder = originalHolder;
    _stolenNightRoleUsed = false;
    notifyListeners();
  }

  RoleType? get stolenNightRoleType => _stolenNightRoleType;
  int? get stolenNightRoleOriginalHolder => _stolenNightRoleOriginalHolder;
  bool get stolenNightRoleUsed => _stolenNightRoleUsed;

  /// Marks the stolen ability as used without hiding its icon - it stays
  /// next to the Thief, shown as disabled/used, for the rest of the
  /// night. Actually clearing it happens automatically when the night
  /// ends (see [_resetNightMarks] and friends).
  void markStolenNightRoleUsed() {
    _stolenNightRoleUsed = true;
    notifyListeners();
  }

  /// Fully clears the stolen-role state. Used when the night ends /a new
  /// game or a new night starts - not when the ability is merely used
  /// (see [markStolenNightRoleUsed]).
  void consumeStolenNightRole() {
    _stolenNightRoleType = null;
    _stolenNightRoleOriginalHolder = null;
    _stolenNightRoleUsed = false;
    notifyListeners();
  }

  /// If the Thief targets a day-action role (Cowboy/Bomber/Terrorist) at
  /// night, the Thief takes over that role's day action the next day -
  /// the original holder can no longer use it. Tracked the same
  /// one-round-survives way as [_bartenderBlockedPlayer].
  int? _thiefStoleFromPlayer;
  int? _thiefPlayerNumber;
  int? _thiefStoleAtRound;

  void setThiefSteal(int thiefPlayerNumber, int stolenFromPlayer) {
    _thiefPlayerNumber = thiefPlayerNumber;
    _thiefStoleFromPlayer = stolenFromPlayer;
    _thiefStoleAtRound = currentNight;
    notifyListeners();
  }

  /// If [originalHolder]'s day action was stolen by the Thief the night
  /// before, returns the Thief's player number to act in their place -
  /// otherwise null (no theft in effect).
  int? dayActionDelegateFor(int originalHolder) =>
      _thiefStoleFromPlayer == originalHolder ? _thiefPlayerNumber : null;

  void consumeThiefSteal() {
    _thiefStoleFromPlayer = null;
    _thiefPlayerNumber = null;
    _thiefStoleAtRound = null;
    notifyListeners();
  }

  /// Votes cast against each player this round (for the Day screen's
  /// voting/lynch tally). Cleared along with the rest of the round's
  /// bookkeeping when the night ends.
  final Map<int, int> _votes = {};

  /// Players whose vote count has been explicitly confirmed this round
  /// (via the picker's Submit button) - tracked separately from the
  /// count itself, since "confirmed at 0" and "never touched" need to
  /// look different (yellow vs. white row) even though both read "0".
  final Set<int> _votedThisRound = {};

  int voteCountFor(int playerNumber) => _votes[playerNumber] ?? 0;

  bool hasVotedThisRound(int playerNumber) => _votedThisRound.contains(playerNumber);

  void confirmVote(int playerNumber) {
    _votedThisRound.add(playerNumber);
    notifyListeners();
  }

  void setVote(int playerNumber, int count) {
    if (count <= 0) {
      _votes.remove(playerNumber);
    } else {
      _votes[playerNumber] = count;
    }
    notifyListeners();
  }

  /// Clears all votes and confirmations cast so far this round, without
  /// touching anything else. Used when a day-action elimination (e.g.
  /// the Cowboy or Bomber) changes who's still in the game mid-vote,
  /// since the old tally and majority threshold no longer apply.
  void clearVotesThisRound() {
    _votes.clear();
    _votedThisRound.clear();
    notifyListeners();
  }

  /// The number of votes needed to eliminate a player this round: half of
  /// the *other* active players (i.e. not counting the nominee himself),
  /// rounded down, plus one. E.g. with 10 players active, a nominee needs
  /// 5 votes: (10 - 1) ~/ 2 + 1 = 5.
  int voteMajorityFor(int activePlayerCount) =>
      ((activePlayerCount - 1) ~/ 2) + 1;

  /// True if [playerNumber] currently has enough votes to be lynched,
  /// given [activePlayerCount] players still in the game.
  bool hasVoteMajority(int playerNumber, int activePlayerCount) =>
      voteCountFor(playerNumber) >= voteMajorityFor(activePlayerCount);

  /// Small emoji badges shown on a player's roster row for every action
  /// applied to them this round (day or night), in the order the game
  /// master applied them. Cleared along with the rest of the round's
  /// bookkeeping when the night ends.
  final Map<int, List<String>> _actionBadges = {};

  List<String> actionBadgesFor(int playerNumber) =>
      List.unmodifiable(_actionBadges[playerNumber] ?? const []);

  void addActionBadge(int playerNumber, String emoji) {
    (_actionBadges[playerNumber] ??= []).add(emoji);
    notifyListeners();
  }

  /// True once roles have been generated for the current game.
  bool get hasActiveGame => _assignments != null;

  int? get playerCount => _assignments?.length;

  /// The night currently in progress (1-based).
  int get currentNight => _removalsByNight.length;

  /// Removals grouped by night, e.g. `[[3, 7], [1]]` means players 3 and 7
  /// were removed on night 1, and player 1 on night 2. The last group may
  /// be empty if no one has been removed yet on the current night.
  List<List<int>> get removalsByNight =>
      List.unmodifiable(_removalsByNight.map(List<int>.unmodifiable));

  bool isRemoved(int playerNumber) =>
      _removalsByNight.any((night) => night.contains(playerNumber));

  /// Adds/removes [playerNumber] from wherever it currently is. New
  /// removals always go into the *current* (last) night's bucket.
  void toggleRemoved(int playerNumber) {
    for (final night in _removalsByNight) {
      if (night.remove(playerNumber)) {
        notifyListeners();
        return;
      }
    }
    _removalsByNight.last.add(playerNumber);
    notifyListeners();
  }

  /// Locks in the current night's results and starts a fresh bucket for
  /// the next night. Past nights remain visible in [removalsByNight].
  /// Snapshot of everything [endNight] is about to wipe, taken right
  /// before wiping it, so [undoEndNight] can put it all back. Cleared
  /// once undone, or once another night ends (only the most recent
  /// transition is undoable).
  _NightSnapshot? _lastSnapshot;

  bool get canUndoEndDay => _lastSnapshot != null;

  void endNight() {
    // A Bartender block or a Thief's stolen day-action that already
    // survived one full day unused is stale - clear it before it can
    // wrongly apply to a future day.
    if (_bartenderBlockedAtRound != null &&
        _bartenderBlockedAtRound! < currentNight) {
      _bartenderBlockedPlayer = null;
      _bartenderBlockedAtRound = null;
    }
    if (_thiefStoleAtRound != null && _thiefStoleAtRound! < currentNight) {
      _thiefStoleFromPlayer = null;
      _thiefPlayerNumber = null;
      _thiefStoleAtRound = null;
    }
    if (_natashaSilencedAtRound != null && _natashaSilencedAtRound! < currentNight) {
      _natashaSilencedPlayer = null;
      _natashaSilencedAtRound = null;
    }
    if (_investigatorAtRound != null && _investigatorAtRound! < currentNight) {
      _investigatorTargets = [];
      _investigatorAtRound = null;
    }
    _stolenNightRoleType = null;
    _stolenNightRoleOriginalHolder = null;
    _stolenNightRoleUsed = false;

    _lastSnapshot = _NightSnapshot(
      markColors: Map.of(_nightMarkColors),
      markLabels: Map.of(_nightMarkLabels),
      disabledRoles: Set.of(_disabledRolesTonight),
      actionBadges: {for (final e in _actionBadges.entries) e.key: List.of(e.value)},
      votes: Map.of(_votes),
      votedThisRound: Set.of(_votedThisRound),
      shotTonight: Set.of(_shotTonight),
      savedTonight: Set.of(_savedTonight),
      bartenderBlockedPlayer: _bartenderBlockedPlayer,
      bartenderBlockedAtRound: _bartenderBlockedAtRound,
      thiefStoleFromPlayer: _thiefStoleFromPlayer,
      thiefPlayerNumber: _thiefPlayerNumber,
      thiefStoleAtRound: _thiefStoleAtRound,
      roleActedOnTonight: Map.of(_roleActedOnTonight),
    );

    // Freeze this night into permanent history before wiping its
    // in-progress bookkeeping - the game master can look back at it
    // later even after the live screen has moved on.
    final marks = <NightMarkEntry>[
      for (final entry in _nightMarkLabels.entries)
        NightMarkEntry(
          playerNumber: entry.key,
          label: entry.value,
          color: _nightMarkColors[entry.key] ?? Colors.grey,
          actionEmojis: actionBadgesFor(entry.key),
        ),
    ];
    _history.add(
      NightRecord(
        night: currentNight,
        marks: marks,
        eliminated: List<int>.from(_removalsByNight.last),
        votes: Map.of(_votes),
      ),
    );

    _removalsByNight.add([]);
    _nightMarkColors.clear();
    _nightMarkLabels.clear();
    _disabledRolesTonight.clear();
    _actionBadges.clear();
    _votes.clear();
    _votedThisRound.clear();
    _shotTonight.clear();
    _savedTonight.clear();
    _roleActedOnTonight.clear();
    _psychoTarget = null;
    _psychoJudge = null;
    notifyListeners();
  }

  /// Reverses the most recent [endNight] call: restores the marks,
  /// votes, badges, and blocks it wiped, removes the fresh empty round it
  /// opened, and drops the history entry it just archived. Only the
  /// single most recent transition can be undone - once another night
  /// ends, or this is called once, there's nothing left to undo.
  void undoEndDay() {
    final snapshot = _lastSnapshot;
    if (snapshot == null) return;
    if (_removalsByNight.length > 1) _removalsByNight.removeLast();
    _nightMarkColors
      ..clear()
      ..addAll(snapshot.markColors);
    _nightMarkLabels
      ..clear()
      ..addAll(snapshot.markLabels);
    _disabledRolesTonight
      ..clear()
      ..addAll(snapshot.disabledRoles);
    _actionBadges
      ..clear()
      ..addAll(snapshot.actionBadges);
    _votes
      ..clear()
      ..addAll(snapshot.votes);
    _votedThisRound
      ..clear()
      ..addAll(snapshot.votedThisRound);
    _shotTonight
      ..clear()
      ..addAll(snapshot.shotTonight);
    _savedTonight
      ..clear()
      ..addAll(snapshot.savedTonight);
    _bartenderBlockedPlayer = snapshot.bartenderBlockedPlayer;
    _bartenderBlockedAtRound = snapshot.bartenderBlockedAtRound;
    _thiefStoleFromPlayer = snapshot.thiefStoleFromPlayer;
    _thiefPlayerNumber = snapshot.thiefPlayerNumber;
    _thiefStoleAtRound = snapshot.thiefStoleAtRound;
    _roleActedOnTonight
      ..clear()
      ..addAll(snapshot.roleActedOnTonight);
    if (_history.isNotEmpty) _history.removeLast();
    _lastSnapshot = null;
    notifyListeners();
  }

  /// Every past night's frozen record, oldest first - see [NightRecord].
  final List<NightRecord> _history = [];
  List<NightRecord> get history => List.unmodifiable(_history);

  /// Adds [playerNumber] to the current round's removal bucket if they
  /// aren't already removed. Unlike [toggleRemoved], this never restores
  /// a removed player back - used by day actions where a target should
  /// simply end up "out", not have their state flipped.
  void eliminate(int playerNumber) {
    if (isRemoved(playerNumber)) return;
    _removalsByNight.last.add(playerNumber);
    notifyListeners();
  }

  /// Swaps which role [playerA] and [playerB] hold. Used by the Full
  /// Roster screen to let the game master move roles between players.
  void swapRoles(int playerA, int playerB) {
    final assignments = _assignments;
    if (assignments == null) return;
    final tmp = assignments[playerA - 1];
    assignments[playerA - 1] = assignments[playerB - 1];
    assignments[playerB - 1] = tmp;
    notifyListeners();
  }

  /// Directly assigns [role] to [playerNumber] - used by the Full Roster
  /// screen to add/change/remove a player's role (including converting
  /// them to a plain Citizen or plain Mafia).
  void setRoleAt(int playerNumber, Role role) {
    final assignments = _assignments;
    if (assignments == null) return;
    assignments[playerNumber - 1] = role;
    notifyListeners();
  }

  /// Order-independent night-kill tracking, used by the Night Results
  /// resolution instead of relying only on which color a player's single
  /// mark happens to end up as (that can depend on which order the game
  /// master tapped things in). A player is only actually eliminated at
  /// the end of the night if they were shot AND not saved AND don't hold
  /// a shield/invincible role - regardless of the order the Godfather and
  /// Doctor were tapped in.
  final Set<int> _shotTonight = {};
  final Set<int> _savedTonight = {};

  void markShotTonight(int playerNumber) {
    _shotTonight.add(playerNumber);
    notifyListeners();
  }

  void markSavedTonight(int playerNumber) {
    _savedTonight.add(playerNumber);
    notifyListeners();
  }

  bool isShotTonight(int playerNumber) => _shotTonight.contains(playerNumber);
  bool isSavedTonight(int playerNumber) => _savedTonight.contains(playerNumber);

  Set<int> get shotTonight => Set.unmodifiable(_shotTonight);
  Set<int> get savedTonight => Set.unmodifiable(_savedTonight);

  /// Which roles have already used their one-per-game self-target act
  /// (Doctor/Priest/Natasha saving themselves). Unlike most per-night
  /// state, this is NOT cleared at the end of each night - it only
  /// resets when a whole new game starts.
  final Set<RoleType> _usedSelfTargetOnce = {};

  bool hasUsedSelfTarget(RoleType type) => _usedSelfTargetOnce.contains(type);

  void markSelfTargetUsed(RoleType type) {
    _usedSelfTargetOnce.add(type);
    notifyListeners();
  }

  Color? nightMarkColor(int playerNumber) => _nightMarkColors[playerNumber];
  String? nightMarkLabel(int playerNumber) => _nightMarkLabels[playerNumber];

  void setNightMark(int playerNumber, Color color, String label) {
    _nightMarkColors[playerNumber] = color;
    _nightMarkLabels[playerNumber] = label;
    notifyListeners();
  }

  void clearNightMark(int playerNumber) {
    _nightMarkColors.remove(playerNumber);
    _nightMarkLabels.remove(playerNumber);
    notifyListeners();
  }

  void clearAllNightMarks() {
    _nightMarkColors.clear();
    _nightMarkLabels.clear();
    _disabledRolesTonight.clear();
    notifyListeners();
  }

  /// Takes a finished, already-sized role pool (one entry per player,
  /// built by the setup screens from the game master's choices), shuffles
  /// it exactly once, and locks it in. [roleFor] will always return the
  /// same role for the same player number until [endGame] is called.
  void startGame(List<Role> pool) {
    _assignments = RoleGenerator.shuffled(pool);
    _removalsByNight
      ..clear()
      ..add([]);
    _nightMarkColors.clear();
    _nightMarkLabels.clear();
    _disabledRolesTonight.clear();
    _bartenderBlockedPlayer = null;
    _bartenderBlockedAtRound = null;
    _thiefStoleFromPlayer = null;
    _thiefPlayerNumber = null;
    _natashaSilencedPlayer = null;
    _natashaSilencedAtRound = null;
    _thiefStoleAtRound = null;
    _investigatorTargets = [];
    _investigatorAtRound = null;
    _stolenNightRoleType = null;
    _stolenNightRoleOriginalHolder = null;
    _stolenNightRoleUsed = false;
    _godfatherShieldUsed = false;
    _dayAbilitySpent.clear();
    _plainRoleBadge.clear();
    _actionBadges.clear();
    _votes.clear();
    _votedThisRound.clear();
    _shotTonight.clear();
    _savedTonight.clear();
    _roleActedOnTonight.clear();
    _psychoTarget = null;
    _psychoJudge = null;
    _usedSelfTargetOnce.clear();
    _history.clear();
    _lastSnapshot = null;
    notifyListeners();
  }

  /// Returns the fixed role for [playerNumber] (1-based).
  Role roleFor(int playerNumber) {
    final assignments = _assignments;
    if (assignments == null) {
      throw StateError('No active game: startGame() has not been called.');
    }
    return assignments[playerNumber - 1];
  }

  /// All roles currently in play, one per player - used to build the
  /// Night Actions icon toolbar (which only shows roles actually present).
  List<Role> get allAssignedRoles => List.unmodifiable(_assignments ?? []);

  /// Counts of still-active (not removed) players per team - used by the
  /// roster screen's live status header.
  Map<Team, int> remainingByTeam() {
    final assignments = _assignments;
    final result = <Team, int>{};
    if (assignments == null) return result;
    for (int i = 0; i < assignments.length; i++) {
      final playerNumber = i + 1;
      if (isRemoved(playerNumber)) continue;
      final team = assignments[i].team;
      result[team] = (result[team] ?? 0) + 1;
    }
    return result;
  }

  /// If an Independent-team role is alive and the remaining Mafia and
  /// Citizen counts are tied, the Independent wins. Returns null while no
  /// such condition is met.
  Team? get winner {
    final counts = remainingByTeam();
    final mafiaCount = counts[Team.mafia] ?? 0;
    final citizenCount = counts[Team.citizen] ?? 0;
    final independentCount = counts[Team.independent] ?? 0;
    if (independentCount > 0 && mafiaCount >= citizenCount && mafiaCount > 0) {
      return Team.independent;
    }
    return null;
  }

  /// Erases all assignments from memory. Called when "End Game" is
  /// pressed - this is the only thing that clears the night history.
  void endGame() {
    _assignments = null;
    _removalsByNight
      ..clear()
      ..add([]);
    _nightMarkColors.clear();
    _nightMarkLabels.clear();
    _disabledRolesTonight.clear();
    _bartenderBlockedPlayer = null;
    _bartenderBlockedAtRound = null;
    _thiefStoleFromPlayer = null;
    _thiefPlayerNumber = null;
    _natashaSilencedPlayer = null;
    _natashaSilencedAtRound = null;
    _thiefStoleAtRound = null;
    _investigatorTargets = [];
    _investigatorAtRound = null;
    _stolenNightRoleType = null;
    _stolenNightRoleOriginalHolder = null;
    _stolenNightRoleUsed = false;
    _godfatherShieldUsed = false;
    _dayAbilitySpent.clear();
    _plainRoleBadge.clear();
    _actionBadges.clear();
    _votes.clear();
    _votedThisRound.clear();
    _shotTonight.clear();
    _savedTonight.clear();
    _roleActedOnTonight.clear();
    _psychoTarget = null;
    _psychoJudge = null;
    _usedSelfTargetOnce.clear();
    _history.clear();
    _lastSnapshot = null;
    notifyListeners();
  }
}

/// Everything [GameState.endNight] wipes, captured right before it does -
/// see [GameState.undoEndDay].
class _NightSnapshot {
  final Map<int, Color> markColors;
  final Map<int, String> markLabels;
  final Set<RoleType> disabledRoles;
  final Map<int, List<String>> actionBadges;
  final Map<int, int> votes;
  final Set<int> votedThisRound;
  final Set<int> shotTonight;
  final Set<int> savedTonight;
  final int? bartenderBlockedPlayer;
  final int? bartenderBlockedAtRound;
  final int? thiefStoleFromPlayer;
  final int? thiefPlayerNumber;
  final int? thiefStoleAtRound;
  final Map<RoleType, int> roleActedOnTonight;

  _NightSnapshot({
    required this.markColors,
    required this.markLabels,
    required this.disabledRoles,
    required this.actionBadges,
    required this.votes,
    required this.votedThisRound,
    required this.shotTonight,
    required this.savedTonight,
    required this.bartenderBlockedPlayer,
    required this.bartenderBlockedAtRound,
    required this.thiefStoleFromPlayer,
    required this.thiefPlayerNumber,
    required this.thiefStoleAtRound,
    required this.roleActedOnTonight,
  });
}
