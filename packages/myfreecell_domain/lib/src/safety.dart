import 'card.dart';
import 'foundation.dart';

/// Whether the foundation [levels] make [card] safe under GD-AUTO-02
/// conditions 2 and 3.
///
/// The caller must ensure [card] is exposed (GD-AUTO-02 condition 1).
///
/// Precondition: [levels] contains every [FoundationSlot] and each level is
/// between 0 and 13. Otherwise it throws [ArgumentError].
bool hasSafeFoundationLevels(Card card, Map<FoundationSlot, int> levels) {
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

  final ownSlot = FoundationSlot.values.singleWhere(
    (slot) => slot.suit == card.suit,
  );

  return canEnterFoundation(card, ownSlot, levels[ownSlot]!) &&
      FoundationSlot.values.every(
        (slot) => levels[slot]! >= card.rank.value - 1,
      );
}
