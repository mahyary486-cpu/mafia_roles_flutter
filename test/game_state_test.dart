import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

import 'package:mafia_roles/constants/role_data.dart';
import 'package:mafia_roles/logic/game_state.dart';
import 'package:mafia_roles/models/role.dart';
import 'package:mafia_roles/models/role_type.dart';
import 'package:mafia_roles/models/team.dart';

/// Builds a simple pool: [citizens] plain Citizens + [mafia] plain
/// Mafia + one of each role in [named] (any team). Good enough for
/// tests that only care about counts/behavior, not who ends up where -
/// startGame() shuffles player order randomly, so tests that need to
/// know which player has which role look it up afterwards instead of
/// assuming a position.
List<Role> _pool({
  int citizens = 0,
  int mafia = 0,
  List<RoleType> named = const [],
}) {
  return [
    for (var i = 0; i < citizens; i++) RoleData.all[RoleType.citizen]!,
    for (var i = 0; i < mafia; i++) RoleData.all[RoleType.mafia]!,
    for (final type in named) RoleData.all[type]!,
  ];
}

/// Finds the (1-based) player number holding [type] after startGame().
int _findPlayer(GameState gs, RoleType type) {
  final all = gs.allAssignedRoles;
  for (var i = 0; i < all.length; i++) {
    if (all[i].type == type) return i + 1;
  }
  throw StateError('No player holds $type');
}

void main() {
  group('startGame / roleFor', () {
    test('assigns exactly one role per player, in some order', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 3, mafia: 2));
      expect(gs.playerCount, 5);
      expect(gs.hasActiveGame, isTrue);
      // Every player number 1..5 resolves to a role without throwing.
      for (var n = 1; n <= 5; n++) {
        expect(gs.roleFor(n), isNotNull);
      }
    });

    test('roleFor throws before startGame is called', () {
      final gs = GameState();
      expect(() => gs.roleFor(1), throwsStateError);
    });

    test('the same pool composition survives the shuffle', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 4, mafia: 2, named: [RoleType.doctor]));
      final teams = gs.allAssignedRoles.map((r) => r.team).toList();
      expect(teams.where((t) => t == Team.citizen).length, 5); // 4 + doctor
      expect(teams.where((t) => t == Team.mafia).length, 2);
    });
  });

  group('elimination', () {
    test('toggleRemoved marks then un-marks a player', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      expect(gs.isRemoved(2), isFalse);
      gs.toggleRemoved(2);
      expect(gs.isRemoved(2), isTrue);
      gs.toggleRemoved(2);
      expect(gs.isRemoved(2), isFalse);
    });

    test('eliminate is one-way and idempotent', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.eliminate(3);
      expect(gs.isRemoved(3), isTrue);
      // Calling it again on an already-removed player must not throw
      // or double-add them to the removals list.
      gs.eliminate(3);
      expect(gs.removalsByNight.last.where((n) => n == 3).length, 1);
    });

    test('removalsByNight buckets by the night they happened in', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 6));
      gs.eliminate(1);
      gs.endNight(); // night 1 closes, night 2 begins
      gs.eliminate(2);
      expect(gs.removalsByNight[0], [1]);
      expect(gs.removalsByNight[1], [2]);
      expect(gs.currentNight, 2);
    });
  });

  group('voting', () {
    test('voteMajorityFor is half the others, rounded down, plus one', () {
      final gs = GameState();
      // 10 active players -> needs (10-1)~/2 + 1 = 5
      expect(gs.voteMajorityFor(10), 5);
      // 7 active players -> (7-1)~/2 + 1 = 4
      expect(gs.voteMajorityFor(7), 4);
      // 2 active players -> (2-1)~/2 + 1 = 1
      expect(gs.voteMajorityFor(2), 1);
    });

    test('hasVoteMajority compares the live count against the threshold', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 10));
      gs.setVote(4, 5);
      expect(gs.hasVoteMajority(4, 10), isTrue);
      gs.setVote(4, 4);
      expect(gs.hasVoteMajority(4, 10), isFalse);
    });

    test('confirmVote and hasVotedThisRound are tracked separately from the count', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      expect(gs.hasVotedThisRound(1), isFalse);
      gs.setVote(1, 0); // confirmed at zero votes
      gs.confirmVote(1);
      expect(gs.hasVotedThisRound(1), isTrue);
      expect(gs.voteCountFor(1), 0);
    });

    test('clearVotesThisRound wipes both the tally and the confirmations', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.setVote(2, 3);
      gs.confirmVote(2);
      gs.clearVotesThisRound();
      expect(gs.voteCountFor(2), 0);
      expect(gs.hasVotedThisRound(2), isFalse);
    });

    test('endNight also clears the round\'s votes', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.setVote(2, 3);
      gs.confirmVote(2);
      gs.endNight();
      expect(gs.voteCountFor(2), 0);
      expect(gs.hasVotedThisRound(2), isFalse);
    });
  });

  group('night marks, badges, and end-of-night cleanup', () {
    test('setNightMark / clearNightMark round-trip', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.setNightMark(1, const Color(0xFFFF0000), 'Shot');
      expect(gs.nightMarkLabel(1), 'Shot');
      gs.clearNightMark(1);
      expect(gs.nightMarkLabel(1), isNull);
    });

    test('endNight clears in-progress marks and badges but keeps eliminations', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.eliminate(1);
      gs.setNightMark(2, const Color(0xFF00FF00), 'Saved');
      gs.addActionBadge(2, '🩺');
      gs.endNight();
      expect(gs.isRemoved(1), isTrue); // eliminations persist
      expect(gs.nightMarkLabel(2), isNull); // marks don't
      expect(gs.actionBadgesFor(2), isEmpty); // badges don't
    });

    test('endNight archives the night into history', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.eliminate(3);
      gs.setNightMark(3, const Color(0xFFFF0000), 'Shot and killed');
      gs.endNight();
      expect(gs.history, hasLength(1));
      expect(gs.history.first.night, 1);
      expect(gs.history.first.eliminated, [3]);
      expect(gs.history.first.marks.single.label, 'Shot and killed');
    });

    test('undoEndDay restores exactly what the last endNight wiped', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.setNightMark(1, const Color(0xFFFF0000), 'Shot');
      gs.addActionBadge(1, '🔫');
      expect(gs.canUndoEndDay, isFalse);
      gs.endNight();
      expect(gs.canUndoEndDay, isTrue);
      expect(gs.currentNight, 2);
      gs.undoEndDay();
      expect(gs.currentNight, 1);
      expect(gs.nightMarkLabel(1), 'Shot');
      expect(gs.actionBadgesFor(1), ['🔫']);
      expect(gs.history, isEmpty);
    });
  });

  group('shot/saved resolution (order-independent)', () {
    test('a player who is shot and never saved is tracked as shot', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.markShotTonight(1);
      expect(gs.isShotTonight(1), isTrue);
      expect(gs.isSavedTonight(1), isFalse);
    });

    test('marking saved after shot still reflects both, regardless of order', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5));
      gs.markShotTonight(1);
      gs.markSavedTonight(1);
      expect(gs.isShotTonight(1), isTrue);
      expect(gs.isSavedTonight(1), isTrue);
    });
  });

  group('Thief stealing a day-action role', () {
    test('dayActionDelegateFor returns the Thief only for the player he stole from', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.thief]));
      final thief = _findPlayer(gs, RoleType.thief);
      gs.setThiefSteal(thief, 3);
      expect(gs.dayActionDelegateFor(3), thief);
      expect(gs.dayActionDelegateFor(4), isNull);
    });

    test('consumeThiefSteal clears the delegation', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.thief]));
      final thief = _findPlayer(gs, RoleType.thief);
      gs.setThiefSteal(thief, 3);
      gs.consumeThiefSteal();
      expect(gs.dayActionDelegateFor(3), isNull);
    });

    test('a stolen day-action survives exactly one night before going stale', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.thief]));
      final thief = _findPlayer(gs, RoleType.thief);
      gs.setThiefSteal(thief, 3); // stolen on night 1
      gs.endNight(); // night 2 begins - still valid for today's day
      expect(gs.dayActionDelegateFor(3), thief);
      gs.endNight(); // a second night passes unused - now stale
      expect(gs.dayActionDelegateFor(3), isNull);
    });
  });

  group('stolen night-role ability', () {
    test('setStolenNightRole / markStolenNightRoleUsed / consumeStolenNightRole', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.doctor]));
      gs.setStolenNightRole(RoleType.doctor, 3);
      expect(gs.stolenNightRoleType, RoleType.doctor);
      expect(gs.stolenNightRoleUsed, isFalse);
      gs.markStolenNightRoleUsed();
      expect(gs.stolenNightRoleUsed, isTrue);
      // The icon is still there (stays visible, just used) until
      // explicitly consumed or the night ends.
      expect(gs.stolenNightRoleType, RoleType.doctor);
      gs.consumeStolenNightRole();
      expect(gs.stolenNightRoleType, isNull);
    });

    test('endNight also clears any unstolen stolen-role state', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.doctor]));
      gs.setStolenNightRole(RoleType.doctor, 3);
      gs.endNight();
      expect(gs.stolenNightRoleType, isNull);
    });
  });

  group('win conditions', () {
    test('no winner while nobody is independent', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 4, mafia: 4));
      expect(gs.winner, isNull);
    });

    test('Independent wins once mafia count catches up to citizen count', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 3, mafia: 2, named: [RoleType.killer]));
      // 4 citizens (3 + killer is independent, not citizen) vs 2 mafia -
      // no winner yet.
      expect(gs.winner, isNull);
      // Eliminate citizens until mafia (2) >= citizens (1 left).
      final citizensAlive = <int>[];
      for (var n = 1; n <= gs.playerCount!; n++) {
        if (gs.roleFor(n).team == Team.citizen) citizensAlive.add(n);
      }
      // Eliminate all but one citizen: 3 citizens -> eliminate 2.
      gs.eliminate(citizensAlive[0]);
      gs.eliminate(citizensAlive[1]);
      expect(gs.winner, Team.independent);
    });

    test('an eliminated Independent no longer counts toward the win check', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 1, mafia: 2, named: [RoleType.killer]));
      final killer = _findPlayer(gs, RoleType.killer);
      // 1 citizen vs 2 mafia already satisfies mafia >= citizen.
      expect(gs.winner, Team.independent);
      gs.eliminate(killer);
      expect(gs.winner, isNull);
    });
  });

  group('day-ability-spent / plain-role badge (Thief substitution bookkeeping)', () {
    test('markDayAbilitySpent is global and permanent for the game', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.cowboy]));
      expect(gs.isDayAbilitySpent(RoleType.cowboy), isFalse);
      gs.markDayAbilitySpent(RoleType.cowboy);
      expect(gs.isDayAbilitySpent(RoleType.cowboy), isTrue);
      // Unlike per-night state, this must NOT be cleared by endNight.
      gs.endNight();
      expect(gs.isDayAbilitySpent(RoleType.cowboy), isTrue);
    });

    test('plain-role badge persists across nights until the game ends', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.cowboy]));
      final cowboy = _findPlayer(gs, RoleType.cowboy);
      gs.markPlainRoleBadge(cowboy);
      expect(gs.hasPlainRoleBadge(cowboy), isTrue);
      gs.endNight();
      expect(gs.hasPlainRoleBadge(cowboy), isTrue);
    });
  });

  group('Simple Mode toggle', () {
    test('defaults to on (algorithms run automatically)', () {
      final gs = GameState();
      expect(gs.abilitiesAutoExecuted, isTrue);
    });

    test('can be switched off and back on', () {
      final gs = GameState();
      gs.setAbilitiesAutoExecuted(false);
      expect(gs.abilitiesAutoExecuted, isFalse);
      gs.setAbilitiesAutoExecuted(true);
      expect(gs.abilitiesAutoExecuted, isTrue);
    });
  });

  group('endGame', () {
    test('wipes assignments, history, and every round-scoped flag', () {
      final gs = GameState();
      gs.startGame(_pool(citizens: 5, named: [RoleType.doctor]));
      gs.eliminate(1);
      gs.markDayAbilitySpent(RoleType.cowboy);
      gs.endNight();
      gs.endGame();
      expect(gs.hasActiveGame, isFalse);
      expect(gs.playerCount, isNull);
      expect(gs.history, isEmpty);
      expect(gs.currentNight, 1);
      expect(gs.isDayAbilitySpent(RoleType.cowboy), isFalse);
    });
  });
}
