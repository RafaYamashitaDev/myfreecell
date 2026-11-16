import 'package:myfreecell_domain/myfreecell_domain.dart';
import 'package:myfreecell_domain/src/foundation.dart';
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
  const expectedSlotSuits = {
    FoundationSlot.f1: Suit.clubs,
    FoundationSlot.f2: Suit.hearts,
    FoundationSlot.f3: Suit.spades,
    FoundationSlot.f4: Suit.diamonds,
  };
  final allCards = [
    for (final rank in Rank.values)
      for (final suit in Suit.values) Card(rank, suit),
  ];
  const levels = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  bool expectedEntry(Card card, FoundationSlot slot, int level) {
    return expectedSlotSuits[slot] == card.suit &&
        ranksAscending.indexOf(card.rank) == level;
  }

  group('GD-FND-01 fixed slot order and suit assignment', () {
    test('FoundationSlot.values is exactly f1, f2, f3, f4', () {
      expect(FoundationSlot.values, [
        FoundationSlot.f1,
        FoundationSlot.f2,
        FoundationSlot.f3,
        FoundationSlot.f4,
      ]);
    });

    test('each slot suit equals its fixed assignment', () {
      for (final slot in FoundationSlot.values) {
        expect(slot.suit, expectedSlotSuits[slot], reason: '$slot');
      }
    });

    test('every suit has exactly one slot', () {
      final suits = {for (final slot in FoundationSlot.values) slot.suit};

      expect(suits, Suit.values.toSet());
      expect(suits, hasLength(4));
    });

    test('slot suit order is not the canonical deck order', () {
      expect([
        for (final slot in FoundationSlot.values) slot.suit,
      ], isNot(Suit.values));
    });
  });

  group('canEnterFoundation entry rule (GD-FND-02)', () {
    test('all 52 x 4 x 14 combinations match the independent entry rule', () {
      var combinations = 0;

      for (final card in allCards) {
        for (final slot in FoundationSlot.values) {
          for (final level in levels) {
            combinations++;
            expect(
              canEnterFoundation(card, slot, level),
              expectedEntry(card, slot, level),
              reason: '${card.rank} ${card.suit} on $slot at level $level',
            );
          }
        }
      }

      expect(combinations, 2912);
    });

    test('exactly 52 combinations are accepted', () {
      var accepted = 0;

      for (final card in allCards) {
        for (final slot in FoundationSlot.values) {
          for (final level in levels) {
            if (canEnterFoundation(card, slot, level)) {
              accepted++;
            }
          }
        }
      }

      expect(accepted, 52);
    });

    test('each card is accepted by exactly its own slot at level rank - 1', () {
      for (final card in allCards) {
        final accepted = [
          for (final slot in FoundationSlot.values)
            for (final level in levels)
              if (canEnterFoundation(card, slot, level)) (slot, level),
        ];
        final expectedSlot = expectedSlotSuits.entries
            .singleWhere((entry) => entry.value == card.suit)
            .key;

        expect(accepted, [
          (expectedSlot, ranksAscending.indexOf(card.rank)),
        ], reason: '${card.rank} ${card.suit}');
      }
    });

    test('level 0 accepts exactly each slot\'s own Ace', () {
      for (final slot in FoundationSlot.values) {
        final accepted = {
          for (final card in allCards)
            if (canEnterFoundation(card, slot, 0)) card,
        };

        expect(accepted, {
          Card(Rank.ace, expectedSlotSuits[slot]!),
        }, reason: '$slot');
      }
    });

    test('each King is accepted only by its slot at level 12', () {
      for (final suit in Suit.values) {
        final king = Card(Rank.king, suit);
        final accepted = [
          for (final slot in FoundationSlot.values)
            for (final level in levels)
              if (canEnterFoundation(king, slot, level)) (slot, level),
        ];
        final expectedSlot = expectedSlotSuits.entries
            .singleWhere((entry) => entry.value == suit)
            .key;

        expect(accepted, [(expectedSlot, 12)], reason: '${king.rank} $suit');
      }
    });

    test('level 13 accepts no card on any slot', () {
      for (final card in allCards) {
        for (final slot in FoundationSlot.values) {
          expect(
            canEnterFoundation(card, slot, 13),
            isFalse,
            reason: '${card.rank} ${card.suit} on $slot',
          );
        }
      }
    });

    test('a wrong suit at the correct level is rejected', () {
      expect(
        canEnterFoundation(Card(Rank.five, Suit.hearts), FoundationSlot.f1, 4),
        isFalse,
      );
    });

    test('a same-color wrong suit at the correct level is rejected', () {
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.spades), FoundationSlot.f1, 0),
        isFalse,
      );
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.diamonds), FoundationSlot.f2, 0),
        isFalse,
      );
      expect(
        canEnterFoundation(Card(Rank.seven, Suit.clubs), FoundationSlot.f3, 6),
        isFalse,
      );
      expect(
        canEnterFoundation(Card(Rank.seven, Suit.hearts), FoundationSlot.f4, 6),
        isFalse,
      );
    });

    test('the same suit at level R is a duplicate and is rejected', () {
      expect(
        canEnterFoundation(Card(Rank.four, Suit.clubs), FoundationSlot.f1, 4),
        isFalse,
      );
    });

    test('the same suit at level R - 2 is a gap and is rejected', () {
      expect(
        canEnterFoundation(Card(Rank.four, Suit.clubs), FoundationSlot.f1, 2),
        isFalse,
      );
    });

    test('the same suit at level R - 1 is accepted', () {
      expect(
        canEnterFoundation(Card(Rank.four, Suit.clubs), FoundationSlot.f1, 3),
        isTrue,
      );
    });
  });

  group('canEnterFoundation worked examples (GD-FND-02)', () {
    test('E06 rejects 6H and accepts 4H on F2 at level 3', () {
      // E06
      expect(
        canEnterFoundation(Card(Rank.six, Suit.hearts), FoundationSlot.f2, 3),
        isFalse,
      );
      expect(
        canEnterFoundation(Card(Rank.four, Suit.hearts), FoundationSlot.f2, 3),
        isTrue,
      );
    });

    test('E07 rejects 5D and accepts 4D on F4 at level 3', () {
      // E07
      expect(
        canEnterFoundation(
          Card(Rank.five, Suit.diamonds),
          FoundationSlot.f4,
          3,
        ),
        isFalse,
      );
      expect(
        canEnterFoundation(
          Card(Rank.four, Suit.diamonds),
          FoundationSlot.f4,
          3,
        ),
        isTrue,
      );
    });

    test('E08 accepts 4C on F1 at level 3', () {
      // E08
      expect(
        canEnterFoundation(Card(Rank.four, Suit.clubs), FoundationSlot.f1, 3),
        isTrue,
      );
    });

    test('E09 accepts the three Aces at level 0 and rejects 2D', () {
      // E09
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.hearts), FoundationSlot.f2, 0),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.clubs), FoundationSlot.f1, 0),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.spades), FoundationSlot.f3, 0),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.two, Suit.diamonds), FoundationSlot.f4, 0),
        isFalse,
      );
    });

    test('E12 accepts AD at level 0, then 2C and 2H at level 1', () {
      // E12
      expect(
        canEnterFoundation(Card(Rank.ace, Suit.diamonds), FoundationSlot.f4, 0),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.two, Suit.clubs), FoundationSlot.f1, 1),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.two, Suit.hearts), FoundationSlot.f2, 1),
        isTrue,
      );
    });

    test('E15 accepts the finishing cards and rejects level 13', () {
      // E15
      expect(
        canEnterFoundation(
          Card(Rank.king, Suit.diamonds),
          FoundationSlot.f4,
          12,
        ),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.king, Suit.spades), FoundationSlot.f3, 11),
        isFalse,
      );
      expect(
        canEnterFoundation(
          Card(Rank.queen, Suit.spades),
          FoundationSlot.f3,
          11,
        ),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.king, Suit.spades), FoundationSlot.f3, 12),
        isTrue,
      );
      expect(
        canEnterFoundation(Card(Rank.king, Suit.clubs), FoundationSlot.f1, 13),
        isFalse,
      );
      expect(
        canEnterFoundation(Card(Rank.king, Suit.hearts), FoundationSlot.f2, 13),
        isFalse,
      );
    });
  });

  group('canEnterFoundation level precondition', () {
    test('levels -1 and 14 throw ArgumentError with the level, name, and '
        'message', () {
      for (final level in [-1, 14]) {
        expect(
          () => canEnterFoundation(
            Card(Rank.ace, Suit.clubs),
            FoundationSlot.f1,
            level,
          ),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue', level)
                .having((error) => error.name, 'name', 'level')
                .having(
                  (error) => error.message,
                  'message',
                  'A foundation level must be between 0 and 13',
                ),
          ),
          reason: '$level',
        );
      }
    });

    test('levels -1 and 14 throw ArgumentError for every card and slot', () {
      for (final level in [-1, 14]) {
        for (final card in allCards) {
          for (final slot in FoundationSlot.values) {
            expect(
              () => canEnterFoundation(card, slot, level),
              throwsArgumentError,
              reason: '${card.rank} ${card.suit} on $slot at level $level',
            );
          }
        }
      }
    });

    test('levels 0 and 13 never throw for any card and slot', () {
      for (final card in allCards) {
        for (final slot in FoundationSlot.values) {
          for (final level in [0, 13]) {
            expect(
              () => canEnterFoundation(card, slot, level),
              returnsNormally,
              reason: '${card.rank} ${card.suit} on $slot at level $level',
            );
          }
        }
      }
    });
  });
}
