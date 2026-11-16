import 'card.dart';

/// A foundation slot, declared in GD-FND-01 order from F1 to F4.
///
/// The declaration order is normative. It is not the canonical deck order of
/// [Suit].
enum FoundationSlot {
  f1(Suit.clubs),
  f2(Suit.hearts),
  f3(Suit.spades),
  f4(Suit.diamonds);

  const FoundationSlot(this.suit);

  /// The suit permanently assigned to this slot.
  final Suit suit;
}

/// Whether [card] may enter [slot] when the slot is at foundation [level]
/// (GD-FND-02).
///
/// Precondition: [level] is between 0 and 13. Any other value throws
/// [ArgumentError].
bool canEnterFoundation(Card card, FoundationSlot slot, int level) {
  if (level < 0 || level > 13) {
    throw ArgumentError.value(
      level,
      'level',
      'A foundation level must be between 0 and 13',
    );
  }

  return card.suit == slot.suit && level == card.rank.value - 1;
}
