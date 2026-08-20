import 'package:flutter_test/flutter_test.dart';

import 'package:mafia_roles/logic/seating.dart';

void main() {
  group('seatNeighbor', () {
    test('simple forward and backward steps stay in range', () {
      expect(seatNeighbor(5, 1, 15), 6);
      expect(seatNeighbor(5, -1, 15), 4);
    });

    test('steps forward past the last seat wrap to seat 1', () {
      // This is the exact case that broke the Bomber: target seat 15's
      // "next" neighbor must wrap around to seat 1, not seat 16 or 0.
      expect(seatNeighbor(15, 1, 15), 1);
    });

    test('steps backward past seat 1 wrap to the last seat', () {
      expect(seatNeighbor(1, -1, 15), 15);
    });

    test('works for any table size, not just 15', () {
      expect(seatNeighbor(3, 1, 3), 1);
      expect(seatNeighbor(1, -1, 3), 3);
      expect(seatNeighbor(10, 1, 10), 1);
    });

    test('a total of zero returns the original seat instead of throwing', () {
      expect(seatNeighbor(5, 1, 0), 5);
      expect(seatNeighbor(5, -1, 0), 5);
    });
  });

  group('nearestAliveSeat', () {
    test('finds the immediate neighbor when nobody is removed', () {
      bool isRemoved(int n) => false;
      expect(nearestAliveSeat(10, -1, 15, isRemoved), 9);
      expect(nearestAliveSeat(10, 1, 15, isRemoved), 11);
    });

    test(
        "skips past already-eliminated seats to find the real neighbor "
        "(the exact Bomber scenario: seat 5 and the actor's own seat 4 "
        "are already gone, target is seat 6)", () {
      final removed = {4, 5, 6};
      bool isRemoved(int n) => removed.contains(n);
      // Going backward from 6: 5 (gone), 4 (gone), 3 (alive) -> 3.
      expect(nearestAliveSeat(6, -1, 15, isRemoved), 3);
      // Going forward from 6: 7 (alive) -> 7.
      expect(nearestAliveSeat(6, 1, 15, isRemoved), 7);
    });

    test('wraps around the table when skipping removed seats', () {
      final removed = {15, 1};
      bool isRemoved(int n) => removed.contains(n);
      // Going forward from 14: 15 (gone), 1 (gone), 2 (alive) -> 2.
      expect(nearestAliveSeat(14, 1, 15, isRemoved), 2);
    });

    test('returns null when nobody else is left in the game', () {
      bool isRemoved(int n) => n != 6;
      expect(nearestAliveSeat(6, 1, 15, isRemoved), isNull);
      expect(nearestAliveSeat(6, -1, 15, isRemoved), isNull);
    });
  });
}
