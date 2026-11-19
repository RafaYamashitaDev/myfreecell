import 'foundation.dart';

/// Whether [moveCount] is at least the number of cards on the foundations
/// (GD-INV-05).
///
/// That number is the sum of the four foundation levels. A negative
/// [moveCount] returns false and does not throw.
///
/// This checks only the GD-INV-05 move-count bound. It does not check other
/// Section 19 invariants. It does not check the Completed status. It does not
/// count moves.
///
/// It only evaluates the invariant. It does not set or update a move count,
/// evaluate status, or compare with a completion result.
///
/// Precondition: [levels] contains every [FoundationSlot] and each level is
/// between 0 and 13. Otherwise it throws [ArgumentError].
bool moveCountCoversFoundationCards(
  int moveCount,
  Map<FoundationSlot, int> levels,
) {
  for (final slot in FoundationSlot.values) {
    if (!levels.containsKey(slot)) {
      throw ArgumentError.value(
        levels,
        'levels',
        'Foundation levels must contain all four slots',
      );
    }
  }

  for (final slot in FoundationSlot.values) {
    final level = levels[slot]!;
    if (level < 0 || level > 13) {
      throw ArgumentError.value(
        level,
        'level',
        'A foundation level must be between 0 and 13',
      );
    }
  }

  var foundationCards = 0;
  for (final slot in FoundationSlot.values) {
    foundationCards += levels[slot]!;
  }

  return moveCount >= foundationCards;
}
