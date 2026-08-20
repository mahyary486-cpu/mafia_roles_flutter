/// Pure seating-circle math, kept separate from any widget so it can be
/// unit tested directly without spinning up the whole Day screen.
///
/// Used by the Bomber's day action: whoever he "sits next to" and one of
/// their two circular seat-neighbors are eliminated together with him.
library;

/// Returns the seat [delta] positions away from [seat] in a circular
/// table of [total] numbered seats (1-based, wrapping around both ends).
///
/// Examples with total=15: seatNeighbor(15, 1, 15) == 1 (wraps forward
/// past the last seat back to the first); seatNeighbor(1, -1, 15) == 15
/// (wraps backward past the first seat to the last).
int seatNeighbor(int seat, int delta, int total) {
  if (total <= 0) return seat;
  return ((seat - 1 + delta) % total + total) % total + 1;
}

/// Walks outward from [seat] in [direction] (+1 or -1) around a
/// circular table of [total] seats, skipping any seat for which
/// [isRemoved] returns true, until it finds one still in the game.
/// Returns null if nobody else is left (a full circle with no hits).
///
/// Used by the Bomber: when the seat right next to his first target is
/// already empty (e.g. it was his own seat, or someone eliminated
/// earlier that day), the next real neighbor further out is the one
/// that matters, not the empty seat itself.
int? nearestAliveSeat(
  int seat,
  int direction,
  int total,
  bool Function(int seat) isRemoved,
) {
  if (total <= 0) return null;
  var candidate = seat;
  for (int i = 0; i < total; i++) {
    candidate = seatNeighbor(candidate, direction, total);
    if (candidate == seat) return null;
    if (!isRemoved(candidate)) return candidate;
  }
  return null;
}
