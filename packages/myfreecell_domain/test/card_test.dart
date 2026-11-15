import 'package:myfreecell_domain/myfreecell_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GD-CARD-01 deck uniqueness', () {
    test('every rank and suit combination constructs a card that reads back '
        'its rank and suit', () {
      for (final rank in Rank.values) {
        for (final suit in Suit.values) {
          final card = Card(rank, suit);

          expect(card.rank, same(rank));
          expect(card.suit, same(suit));
        }
      }
    });

    test('all combinations form exactly 52 distinct cards', () {
      final cards = {
        for (final rank in Rank.values)
          for (final suit in Suit.values) Card(rank, suit),
      };

      expect(cards, hasLength(52));
    });
  });

  group('GD-CARD-02 ranks', () {
    test('Rank.values is exactly Ace through King in ascending order', () {
      expect(Rank.values, [
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
      ]);
    });

    test('each rank has its approved numeric value', () {
      const expected = {
        Rank.ace: 1,
        Rank.two: 2,
        Rank.three: 3,
        Rank.four: 4,
        Rank.five: 5,
        Rank.six: 6,
        Rank.seven: 7,
        Rank.eight: 8,
        Rank.nine: 9,
        Rank.ten: 10,
        Rank.jack: 11,
        Rank.queen: 12,
        Rank.king: 13,
      };

      for (final MapEntry(key: rank, value: value) in expected.entries) {
        expect(rank.value, value, reason: '$rank');
      }
    });
  });

  group('GD-CARD-03 suits', () {
    test('Suit.values is exactly clubs, diamonds, hearts, spades in that '
        'deterministic order', () {
      expect(Suit.values, [
        Suit.clubs,
        Suit.diamonds,
        Suit.hearts,
        Suit.spades,
      ]);
    });
  });

  group('GD-CARD-04 colors', () {
    test('CardColor.values is exactly black and red', () {
      expect(CardColor.values, [CardColor.black, CardColor.red]);
    });

    test('clubs and spades are black', () {
      expect(Suit.clubs.color, CardColor.black);
      expect(Suit.spades.color, CardColor.black);
    });

    test('diamonds and hearts are red', () {
      expect(Suit.diamonds.color, CardColor.red);
      expect(Suit.hearts.color, CardColor.red);
    });
  });

  group('GD-CARD-05 alternating colors', () {
    const alternatingPairs = {
      (Suit.clubs, Suit.diamonds),
      (Suit.clubs, Suit.hearts),
      (Suit.spades, Suit.diamonds),
      (Suit.spades, Suit.hearts),
      (Suit.diamonds, Suit.clubs),
      (Suit.hearts, Suit.clubs),
      (Suit.diamonds, Suit.spades),
      (Suit.hearts, Suit.spades),
    };

    const sameColorPairs = {
      (Suit.clubs, Suit.clubs),
      (Suit.clubs, Suit.spades),
      (Suit.spades, Suit.clubs),
      (Suit.spades, Suit.spades),
      (Suit.diamonds, Suit.diamonds),
      (Suit.diamonds, Suit.hearts),
      (Suit.hearts, Suit.diamonds),
      (Suit.hearts, Suit.hearts),
    };

    test('the expected pairs cover all 16 ordered suit pairs exactly once', () {
      expect(alternatingPairs.intersection(sameColorPairs), isEmpty);
      expect(alternatingPairs.union(sameColorPairs), hasLength(16));
    });

    test('red and black pairs, in either order, alternate', () {
      for (final (first, second) in alternatingPairs) {
        expect(first.color != second.color, isTrue, reason: '$first $second');
      }
    });

    test('same-color pairs do not alternate', () {
      for (final (first, second) in sameColorPairs) {
        expect(first.color != second.color, isFalse, reason: '$first $second');
      }
    });
  });

  group('Card value equality (GD-CARD-01, GD-INV-01)', () {
    test('separately constructed cards with the same rank and suit are equal '
        'and share a hashCode', () {
      final first = Card(Rank.ten, Suit.hearts);
      final second = Card(Rank.ten, Suit.hearts);

      expect(identical(first, second), isFalse);
      expect(first == second, isTrue);
      expect(first.hashCode, second.hashCode);
    });

    test('cards differing only by rank are unequal', () {
      expect(
        Card(Rank.ten, Suit.hearts) == Card(Rank.nine, Suit.hearts),
        isFalse,
      );
    });

    test('cards differing only by suit are unequal', () {
      expect(
        Card(Rank.ten, Suit.hearts) == Card(Rank.ten, Suit.diamonds),
        isFalse,
      );
    });

    test('a card is unequal to a non-card object', () {
      final Object other = (Rank.ten, Suit.hearts);

      expect(Card(Rank.ten, Suit.hearts) == other, isFalse);
    });

    test('duplicate cards collapse as set elements and map keys', () {
      final set = {
        Card(Rank.queen, Suit.spades),
        Card(Rank.queen, Suit.spades),
        Card(Rank.ace, Suit.clubs),
      };
      final map = {
        Card(Rank.queen, Suit.spades): 1,
        Card(Rank.queen, Suit.spades): 2,
      };

      expect(set, hasLength(2));
      expect(map, hasLength(1));
      expect(map[Card(Rank.queen, Suit.spades)], 2);
    });
  });
}
