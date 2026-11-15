/// The color of a suit.
enum CardColor { black, red }

/// A card suit, declared in GD-CARD-03 order.
///
/// The declaration order is deterministic and must stay consistent with the
/// canonical deck order of ADR-05.1.
enum Suit {
  clubs(CardColor.black),
  diamonds(CardColor.red),
  hearts(CardColor.red),
  spades(CardColor.black);

  const Suit(this.color);

  /// The color of this suit.
  final CardColor color;
}

/// A card rank, declared in ascending order from Ace through King.
enum Rank {
  ace(1),
  two(2),
  three(3),
  four(4),
  five(5),
  six(6),
  seven(7),
  eight(8),
  nine(9),
  ten(10),
  jack(11),
  queen(12),
  king(13);

  const Rank(this.value);

  /// The numeric value of this rank, from 1 for Ace through 13 for King.
  final int value;
}

/// An immutable playing card identified by its rank and suit.
final class Card {
  const Card(this.rank, this.suit);

  final Rank rank;
  final Suit suit;

  @override
  bool operator ==(Object other) =>
      other is Card && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);
}
