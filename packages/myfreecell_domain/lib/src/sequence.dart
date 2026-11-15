import 'card.dart';

/// Whether [card], placed onto [target], is one rank lower and the two cards
/// have alternating colors (GD-SEQ-02, GD-CARD-05).
///
/// This pair relation supports the GD-MOVE-07 rank and color conditions.
bool fitsOnto(Card card, Card target) {
  return card.rank.value + 1 == target.rank.value &&
      card.suit.color != target.suit.color;
}

/// Whether [cards] is a valid sequence in tableau order, deepest card first
/// (GD-SEQ-01, GD-SEQ-02, GD-SEQ-03).
///
/// Precondition: [cards] contains at least one card. An empty list throws
/// [ArgumentError].
bool isValidSequence(List<Card> cards) {
  if (cards.isEmpty) {
    throw ArgumentError.value(
      cards,
      'cards',
      'A tableau sequence must contain at least one card',
    );
  }

  for (var index = 1; index < cards.length; index++) {
    if (!fitsOnto(cards[index], cards[index - 1])) {
      return false;
    }
  }

  return true;
}
