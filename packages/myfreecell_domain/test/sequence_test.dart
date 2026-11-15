import 'package:myfreecell_domain/myfreecell_domain.dart';
import 'package:myfreecell_domain/src/sequence.dart';
import 'package:test/test.dart';

void main() {
  const ranksAscending = [
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
  const redSuits = {Suit.diamonds, Suit.hearts};
  final allCards = [
    for (final rank in Rank.values)
      for (final suit in Suit.values) Card(rank, suit),
  ];

  bool expectedFit(Card card, Card target) {
    return ranksAscending.indexOf(target.rank) -
                ranksAscending.indexOf(card.rank) ==
            1 &&
        redSuits.contains(card.suit) != redSuits.contains(target.suit);
  }

  group('GD-SEQ-01 one-card sequences', () {
    test('every one of the 52 one-card lists is a valid sequence', () {
      for (final card in allCards) {
        expect(isValidSequence([card]), isTrue, reason: '$card');
      }
    });
  });

  group(
    'fitsOnto pair relation (GD-SEQ-02, GD-CARD-05; supports the GD-MOVE-07 '
    'rank and color conditions)',
    () {
      test(
        'all 52 x 52 ordered pairs match the independently derived rule',
        () {
          for (final card in allCards) {
            for (final target in allCards) {
              expect(
                fitsOnto(card, target),
                expectedFit(card, target),
                reason: '$card onto $target',
              );
            }
          }
        },
      );

      test('exactly 96 ordered pairs fit', () {
        var fitCount = 0;

        for (final card in allCards) {
          for (final target in allCards) {
            if (fitsOnto(card, target)) {
              fitCount++;
            }
          }
        }

        expect(fitCount, 96);
      });

      test('no card fits onto an Ace', () {
        const aces = [
          Card(Rank.ace, Suit.clubs),
          Card(Rank.ace, Suit.diamonds),
          Card(Rank.ace, Suit.hearts),
          Card(Rank.ace, Suit.spades),
        ];

        for (final ace in aces) {
          for (final card in allCards) {
            expect(fitsOnto(card, ace), isFalse, reason: '$card onto $ace');
          }
        }
      });

      test('hand-listed targets accept exactly the expected cards', () {
        final expectedAccepted = {
          Card(Rank.ten, Suit.spades): {
            Card(Rank.nine, Suit.diamonds),
            Card(Rank.nine, Suit.hearts),
          },
          Card(Rank.two, Suit.clubs): {
            Card(Rank.ace, Suit.diamonds),
            Card(Rank.ace, Suit.hearts),
          },
          Card(Rank.king, Suit.diamonds): {
            Card(Rank.queen, Suit.clubs),
            Card(Rank.queen, Suit.spades),
          },
          Card(Rank.ace, Suit.hearts): <Card>{},
        };

        for (final MapEntry(key: target, value: accepted)
            in expectedAccepted.entries) {
          expect(
            {
              for (final card in allCards)
                if (fitsOnto(card, target)) card,
            },
            accepted,
            reason: '$target',
          );
        }
      });

      test('a same-color card one rank lower does not fit', () {
        expect(
          fitsOnto(Card(Rank.nine, Suit.clubs), Card(Rank.ten, Suit.spades)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.nine, Suit.diamonds), Card(Rank.ten, Suit.hearts)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.nine, Suit.hearts), Card(Rank.ten, Suit.spades)),
          isTrue,
        );
      });

      test('an opposite-color card of the same rank does not fit', () {
        expect(
          fitsOnto(Card(Rank.ten, Suit.hearts), Card(Rank.ten, Suit.spades)),
          isFalse,
        );
      });

      test('an opposite-color card two ranks lower does not fit', () {
        expect(
          fitsOnto(Card(Rank.eight, Suit.hearts), Card(Rank.ten, Suit.spades)),
          isFalse,
        );
      });

      test('reversed order, one rank higher, does not fit', () {
        expect(
          fitsOnto(Card(Rank.ten, Suit.spades), Card(Rank.nine, Suit.hearts)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.nine, Suit.hearts), Card(Rank.ten, Suit.spades)),
          isTrue,
        );
      });

      test('King and Ace do not wrap around in either direction', () {
        expect(
          fitsOnto(Card(Rank.king, Suit.hearts), Card(Rank.ace, Suit.spades)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.ace, Suit.spades), Card(Rank.king, Suit.hearts)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.king, Suit.diamonds), Card(Rank.ace, Suit.clubs)),
          isFalse,
        );
        expect(
          fitsOnto(Card(Rank.ace, Suit.clubs), Card(Rank.king, Suit.diamonds)),
          isFalse,
        );
      });

      test('worked-example heads fit their destination exposed cards', () {
        // E01
        expect(
          fitsOnto(Card(Rank.eight, Suit.spades), Card(Rank.nine, Suit.hearts)),
          isTrue,
        );
        // E02
        expect(
          fitsOnto(Card(Rank.nine, Suit.clubs), Card(Rank.ten, Suit.diamonds)),
          isTrue,
        );
        // E04
        expect(
          fitsOnto(Card(Rank.ten, Suit.spades), Card(Rank.jack, Suit.diamonds)),
          isTrue,
        );
        // E06
        expect(
          fitsOnto(Card(Rank.six, Suit.hearts), Card(Rank.seven, Suit.clubs)),
          isTrue,
        );
        expect(
          fitsOnto(Card(Rank.six, Suit.hearts), Card(Rank.seven, Suit.spades)),
          isTrue,
        );
        // E12
        expect(
          fitsOnto(Card(Rank.nine, Suit.spades), Card(Rank.ten, Suit.hearts)),
          isTrue,
        );
      });
    },
  );

  group('isValidSequence complete-list validation (GD-SEQ-02, GD-SEQ-03)', () {
    test('a two-card descending alternating list is valid and its reverse is '
        'not', () {
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
        ]),
        isTrue,
      );
      expect(
        isValidSequence([
          Card(Rank.nine, Suit.hearts),
          Card(Rank.ten, Suit.spades),
        ]),
        isFalse,
      );
    });

    test('worked-example tails E02, E03, and E04 are valid', () {
      // E02
      expect(
        isValidSequence(
          List.unmodifiable([
            Card(Rank.nine, Suit.clubs),
            Card(Rank.eight, Suit.hearts),
            Card(Rank.seven, Suit.spades),
          ]),
        ),
        isTrue,
      );
      // E03
      expect(
        isValidSequence([
          Card(Rank.eight, Suit.diamonds),
          Card(Rank.seven, Suit.clubs),
          Card(Rank.six, Suit.hearts),
        ]),
        isTrue,
      );
      // E04
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.clubs),
          Card(Rank.seven, Suit.diamonds),
        ]),
        isTrue,
      );
    });

    test('E05 fails at the middle pair although its prefix and suffix are '
        'valid', () {
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.diamonds),
          Card(Rank.seven, Suit.clubs),
        ]),
        isFalse,
      );
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
        ]),
        isTrue,
      );
      expect(
        isValidSequence([
          Card(Rank.eight, Suit.diamonds),
          Card(Rank.seven, Suit.clubs),
        ]),
        isTrue,
      );
    });

    test('a failure at the first pair invalidates the whole list', () {
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.hearts),
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.clubs),
          Card(Rank.seven, Suit.diamonds),
        ]),
        isFalse,
      );
      expect(
        isValidSequence([
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.clubs),
          Card(Rank.seven, Suit.diamonds),
        ]),
        isTrue,
      );
    });

    test('a failure at the last pair invalidates the whole list', () {
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.clubs),
          Card(Rank.seven, Suit.spades),
        ]),
        isFalse,
      );
      expect(
        isValidSequence([
          Card(Rank.ten, Suit.spades),
          Card(Rank.nine, Suit.hearts),
          Card(Rank.eight, Suit.clubs),
        ]),
        isTrue,
      );
    });

    test('a 13-card King-to-Ace alternating sequence is valid', () {
      final sequence = [
        Card(Rank.king, Suit.spades),
        Card(Rank.queen, Suit.hearts),
        Card(Rank.jack, Suit.clubs),
        Card(Rank.ten, Suit.diamonds),
        Card(Rank.nine, Suit.spades),
        Card(Rank.eight, Suit.hearts),
        Card(Rank.seven, Suit.clubs),
        Card(Rank.six, Suit.diamonds),
        Card(Rank.five, Suit.spades),
        Card(Rank.four, Suit.hearts),
        Card(Rank.three, Suit.clubs),
        Card(Rank.two, Suit.diamonds),
        Card(Rank.ace, Suit.spades),
      ];

      expect(isValidSequence(sequence), isTrue);
      expect(isValidSequence(sequence.reversed.toList()), isFalse);
    });
  });

  group('isValidSequence empty-list API precondition', () {
    test('throws ArgumentError.value identifying the cards argument and the '
        'one-card minimum', () {
      final empty = <Card>[];

      expect(
        () => isValidSequence(empty),
        throwsA(
          isA<ArgumentError>()
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                same(empty),
              )
              .having((error) => error.name, 'name', 'cards')
              .having(
                (error) => error.message,
                'message',
                'A tableau sequence must contain at least one card',
              ),
        ),
      );
    });
  });
}
