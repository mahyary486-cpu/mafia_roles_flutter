import 'dart:math';

import '../models/role.dart';

/// Pure utility for securely shuffling a finished role pool.
///
/// Unlike the old fixed-table version, role *composition* is no longer
/// baked in here - the game master builds the pool (mafia count, citizen
/// count, which named roles, any custom roles) on the setup screens, and
/// this class only handles the one thing that must be provably fair and
/// random: the shuffle.
class RoleGenerator {
  RoleGenerator._();

  /// Returns a new, securely shuffled copy of [pool]. The input list is
  /// not modified. Shuffling happens exactly once, here, at generation
  /// time - the caller (GameState) keeps the result fixed until the game
  /// ends.
  static List<Role> shuffled(List<Role> pool) {
    final copy = List<Role>.of(pool);
    _secureShuffle(copy);
    return copy;
  }

  /// Fisher-Yates shuffle using a cryptographically secure random source.
  static void _secureShuffle<T>(List<T> list) {
    final random = Random.secure();
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}
