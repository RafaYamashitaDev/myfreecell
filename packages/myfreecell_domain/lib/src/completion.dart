import 'foundation.dart';

/// Implements the foundation-level completion condition under GD-CMP-01.
///
/// [levels] is complete when every [FoundationSlot] is at level 13.
///
/// This supports transfer-triggered detection under GD-CMP-02, but the caller
/// remains responsible for invoking it after each transfer.
///
/// This advances only the foundation-side condition of GD-INV-04. It does not
/// set status, produce an outcome, report a completion event, count moves, or
/// perform a transfer.
///
/// Precondition: [levels] contains every [FoundationSlot] and each level is
/// between 0 and 13. Otherwise it throws [ArgumentError].
bool areFoundationsComplete(Map<FoundationSlot, int> levels) {
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

  for (final slot in FoundationSlot.values) {
    if (levels[slot]! != 13) {
      return false;
    }
  }

  return true;
}
