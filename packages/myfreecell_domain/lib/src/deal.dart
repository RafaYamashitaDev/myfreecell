import 'card.dart';
import 'deal_identity.dart';
import 'shuffle_version.dart';
import 'split_mix_64.dart';

const List<Suit> _deckSuits = [
  Suit.clubs,
  Suit.diamonds,
  Suit.hearts,
  Suit.spades,
];

const List<Rank> _deckRanks = [
  Rank.ace,
  Rank.two,
  Rank.three,
  Rank.four,
  Rank.five,
  Rank.six,
  Rank.seven,
  Rank.eight,
  Rank.nine,
  Rank.ten,
  Rank.jack,
  Rank.queen,
  Rank.king,
];

/// The unshuffled deck of ADR-05.1, as an unmodifiable list.
///
/// The card at index suitIndex * 13 + rankIndex has suit Clubs, Diamonds,
/// Hearts, or Spades for suitIndex 0 through 3, and rank Ace through King for
/// rankIndex 0 through 12. This is not the foundation-slot order.
final List<Card> canonicalDeck = List<Card>.unmodifiable([
  for (final suit in _deckSuits)
    for (final rank in _deckRanks) Card(rank, suit),
]);

/// The version-1 descending Fisher–Yates shuffle of [canonicalDeck]
/// (ADR-05.4).
///
/// For i from 51 down to 1, j is a [boundedDraw] from [nextRaw] with bound
/// i + 1, and indices i and j are swapped. Index 0 of the unmodifiable result
/// is p1.
List<Card> shuffleCanonicalDeck(int Function() nextRaw) {
  final cards = List<Card>.of(canonicalDeck);
  for (var i = cards.length - 1; i >= 1; i--) {
    final j = boundedDraw(nextRaw, i + 1);
    final held = cards[i];
    cards[i] = cards[j];
    cards[j] = held;
  }
  return List<Card>.unmodifiable(cards);
}

/// The permutation P = (p1, ..., p52) for [identity] under [version]
/// (GD-DEAL-02, GD-DEAL-03).
///
/// Index 0 of the unmodifiable result is p1.
List<Card> dealPermutation(DealIdentity identity, ShuffleVersion version) {
  return switch (version) {
    ShuffleVersion.v1 => shuffleCanonicalDeck(SplitMix64(identity).nextRaw),
  };
}

/// The eight initial tableau columns dealt from [permutation] (GD-DEAL-06).
///
/// Card p_i goes to column T((i - 1) mod 8 + 1). Index 0 of the result is T1.
/// Each column lists its cards deepest first, so its last card is exposed.
/// The outer list and every column are unmodifiable. [permutation] is only
/// read.
///
/// Precondition: [permutation] has exactly 52 cards. Otherwise it throws
/// [ArgumentError]. Card uniqueness is the deal function's obligation
/// (GD-DEAL-02) and is not checked here.
List<List<Card>> initialColumns(List<Card> permutation) {
  if (permutation.length != 52) {
    throw ArgumentError.value(
      permutation,
      'permutation',
      'A deal permutation must contain exactly 52 cards',
    );
  }
  return List<List<Card>>.unmodifiable([
    for (var column = 0; column < 8; column++)
      List<Card>.unmodifiable([
        for (var index = column; index < 52; index += 8) permutation[index],
      ]),
  ]);
}
