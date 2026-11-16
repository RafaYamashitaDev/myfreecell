import 'package:myfreecell_domain/myfreecell_domain.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/safety.dart';
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
  const ownSlotOfSuit = {
    Suit.clubs: FoundationSlot.f1,
    Suit.hearts: FoundationSlot.f2,
    Suit.spades: FoundationSlot.f3,
    Suit.diamonds: FoundationSlot.f4,
  };
  final allCards = [
    for (final rank in Rank.values)
      for (final suit in Suit.values) Card(rank, suit),
  ];
  const levels0to13 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  Map<FoundationSlot, int> levelsOf(int f1, int f2, int f3, int f4) {
    return {
      FoundationSlot.f1: f1,
      FoundationSlot.f2: f2,
      FoundationSlot.f3: f3,
      FoundationSlot.f4: f4,
    };
  }

  bool oracle(Card card, int l1, int l2, int l3, int l4) {
    final rankNumber = ranksAscending.indexOf(card.rank) + 1;
    final ownLevel = switch (ownSlotOfSuit[card.suit]!) {
      FoundationSlot.f1 => l1,
      FoundationSlot.f2 => l2,
      FoundationSlot.f3 => l3,
      FoundationSlot.f4 => l4,
    };

    return ownLevel == rankNumber - 1 &&
        l1 >= rankNumber - 1 &&
        l2 >= rankNumber - 1 &&
        l3 >= rankNumber - 1 &&
        l4 >= rankNumber - 1;
  }

  group(
    'hasSafeFoundationLevels exhaustive oracle (GD-AUTO-02 conditions 2 and 3)',
    () {
      test('every valid four-level combination matches the oracle and '
          'implies entry', () {
        var evaluations = 0;
        var mismatches = 0;
        var violations = 0;
        final mismatchSamples = <String>[];
        final violationSamples = <String>[];

        for (final l1 in levels0to13) {
          for (final l2 in levels0to13) {
            for (final l3 in levels0to13) {
              for (final l4 in levels0to13) {
                final levels = levelsOf(l1, l2, l3, l4);

                for (final card in allCards) {
                  evaluations++;
                  final actual = hasSafeFoundationLevels(card, levels);
                  if (actual != oracle(card, l1, l2, l3, l4)) {
                    mismatches++;
                    if (mismatchSamples.length < 10) {
                      mismatchSamples.add(
                        '${card.rank} ${card.suit} at ($l1, $l2, $l3, $l4)',
                      );
                    }
                  }
                  if (actual) {
                    final ownSlot = ownSlotOfSuit[card.suit]!;
                    if (!canEnterFoundation(card, ownSlot, levels[ownSlot]!)) {
                      violations++;
                      if (violationSamples.length < 10) {
                        violationSamples.add(
                          '${card.rank} ${card.suit} at ($l1, $l2, $l3, $l4)',
                        );
                      }
                    }
                  }
                }
              }
            }
          }
        }

        expect(evaluations, 1997632);
        expect(mismatches, 0, reason: mismatchSamples.join('\n'));
        expect(violations, 0, reason: violationSamples.join('\n'));
      });
    },
  );

  group('hasSafeFoundationLevels rank-by-rank pattern (GD-AUTO-02 conditions 2 '
      'and 3; supports GD-AUTO-03)', () {
    test('own slot at R - 1 has the hand-derived true count for each rank', () {
      const expectedTrueCounts = <int>[
        2744,
        2197,
        1728,
        1331,
        1000,
        729,
        512,
        343,
        216,
        125,
        64,
        27,
        8,
      ];
      var totalTrue = 0;

      for (final card in allCards) {
        final rankNumber = ranksAscending.indexOf(card.rank) + 1;
        final ownSlot = ownSlotOfSuit[card.suit]!;
        var trueCount = 0;

        for (final a in levels0to13) {
          for (final b in levels0to13) {
            for (final c in levels0to13) {
              final levels = switch (ownSlot) {
                FoundationSlot.f1 => levelsOf(rankNumber - 1, a, b, c),
                FoundationSlot.f2 => levelsOf(a, rankNumber - 1, b, c),
                FoundationSlot.f3 => levelsOf(a, b, rankNumber - 1, c),
                FoundationSlot.f4 => levelsOf(a, b, c, rankNumber - 1),
              };
              if (hasSafeFoundationLevels(card, levels)) {
                trueCount++;
              }
            }
          }
        }

        expect(
          trueCount,
          expectedTrueCounts[rankNumber - 1],
          reason: '${card.rank} ${card.suit}',
        );
        totalTrue += trueCount;
      }

      expect(totalTrue, 44096);
    });

    test('the all-zero map is true for exactly the four Aces', () {
      final safe = {
        for (final card in allCards)
          if (hasSafeFoundationLevels(card, levelsOf(0, 0, 0, 0))) card,
      };

      expect(safe, {
        const Card(Rank.ace, Suit.clubs),
        const Card(Rank.ace, Suit.diamonds),
        const Card(Rank.ace, Suit.hearts),
        const Card(Rank.ace, Suit.spades),
      });
    });

    test('all slots at R - 1 are safe, and one other slot at R - 2 is not', () {
      for (final rank in ranksAscending.skip(1)) {
        final rankNumber = ranksAscending.indexOf(rank) + 1;
        final minimum = rankNumber - 1;

        for (final suit in Suit.values) {
          final card = Card(rank, suit);
          final ownSlot = ownSlotOfSuit[suit]!;

          expect(
            hasSafeFoundationLevels(
              card,
              levelsOf(minimum, minimum, minimum, minimum),
            ),
            isTrue,
            reason: '$rank $suit',
          );

          for (final dropped in FoundationSlot.values) {
            if (dropped == ownSlot) {
              continue;
            }

            final levels = switch (dropped) {
              FoundationSlot.f1 => levelsOf(
                minimum - 1,
                minimum,
                minimum,
                minimum,
              ),
              FoundationSlot.f2 => levelsOf(
                minimum,
                minimum - 1,
                minimum,
                minimum,
              ),
              FoundationSlot.f3 => levelsOf(
                minimum,
                minimum,
                minimum - 1,
                minimum,
              ),
              FoundationSlot.f4 => levelsOf(
                minimum,
                minimum,
                minimum,
                minimum - 1,
              ),
            };

            expect(
              hasSafeFoundationLevels(card, levels),
              isFalse,
              reason: '$rank $suit with $dropped at ${minimum - 1}',
            );
          }
        }
      }
    });
  });

  group('hasSafeFoundationLevels condition boundaries (GD-AUTO-02 conditions 2 '
      'and 3)', () {
    test('own slot at R - 2, R - 1, and R with every other slot at 13', () {
      for (final card in allCards) {
        final rankNumber = ranksAscending.indexOf(card.rank) + 1;
        final ownSlot = ownSlotOfSuit[card.suit]!;

        Map<FoundationSlot, int> ownAt(int ownLevel) {
          return switch (ownSlot) {
            FoundationSlot.f1 => levelsOf(ownLevel, 13, 13, 13),
            FoundationSlot.f2 => levelsOf(13, ownLevel, 13, 13),
            FoundationSlot.f3 => levelsOf(13, 13, ownLevel, 13),
            FoundationSlot.f4 => levelsOf(13, 13, 13, ownLevel),
          };
        }

        if (rankNumber >= 2) {
          expect(
            hasSafeFoundationLevels(card, ownAt(rankNumber - 2)),
            isFalse,
            reason: '${card.rank} ${card.suit} own at ${rankNumber - 2}',
          );
        }

        expect(
          hasSafeFoundationLevels(card, ownAt(rankNumber - 1)),
          isTrue,
          reason: '${card.rank} ${card.suit} own at ${rankNumber - 1}',
        );
        expect(
          hasSafeFoundationLevels(card, ownAt(rankNumber)),
          isFalse,
          reason: '${card.rank} ${card.suit} own at $rankNumber',
        );
      }
    });

    test('another slot from 0 through R - 2 is unsafe and R - 1 is safe', () {
      for (final card in allCards) {
        final rankNumber = ranksAscending.indexOf(card.rank) + 1;
        final ownSlot = ownSlotOfSuit[card.suit]!;

        Map<FoundationSlot, int> withOther(FoundationSlot other, int level) {
          int valueFor(FoundationSlot slot) {
            if (slot == other) {
              return level;
            }
            if (slot == ownSlot) {
              return rankNumber - 1;
            }
            return 13;
          }

          return levelsOf(
            valueFor(FoundationSlot.f1),
            valueFor(FoundationSlot.f2),
            valueFor(FoundationSlot.f3),
            valueFor(FoundationSlot.f4),
          );
        }

        for (final other in FoundationSlot.values) {
          if (other == ownSlot) {
            continue;
          }

          for (var level = 0; level <= rankNumber - 2; level++) {
            expect(
              hasSafeFoundationLevels(card, withOther(other, level)),
              isFalse,
              reason: '${card.rank} ${card.suit} $other at $level',
            );
          }

          expect(
            hasSafeFoundationLevels(card, withOther(other, rankNumber - 1)),
            isTrue,
            reason: '${card.rank} ${card.suit} $other at ${rankNumber - 1}',
          );
        }
      }
    });
  });

  group('hasSafeFoundationLevels implies canEnterFoundation (GD-AUTO-02 '
      'condition 2)', () {
    test('E08 4C may enter and is not safe', () {
      // E08
      final levels = levelsOf(3, 1, 1, 1);
      const card = Card(Rank.four, Suit.clubs);
      final ownSlot = ownSlotOfSuit[card.suit]!;

      expect(canEnterFoundation(card, ownSlot, levels[ownSlot]!), isTrue);
      expect(hasSafeFoundationLevels(card, levels), isFalse);
    });
  });

  group(
    'hasSafeFoundationLevels worked examples (GD-AUTO-02 conditions 2 and 3)',
    () {
      test('E08 4C is not safe at (3, 1, 1, 1)', () {
        // E08
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.four, Suit.clubs),
            levelsOf(3, 1, 1, 1),
          ),
          isFalse,
        );
      });

      test('E09 safe Aces, then 2D and 5S stay unsafe', () {
        // E09
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.ace, Suit.hearts),
            levelsOf(0, 0, 0, 0),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.ace, Suit.clubs),
            levelsOf(0, 1, 0, 0),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.ace, Suit.spades),
            levelsOf(1, 1, 0, 0),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.diamonds),
            levelsOf(1, 1, 1, 0),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.five, Suit.spades),
            levelsOf(1, 1, 1, 0),
          ),
          isFalse,
        );
      });

      test('E10 2C is unsafe until every foundation is at least 1', () {
        // E10
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.clubs),
            levelsOf(1, 1, 1, 0),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.clubs),
            levelsOf(1, 1, 1, 1),
          ),
          isTrue,
        );
      });

      test('E11 2S and 2D are safe at 1, and 2D stays safe when F3 rises', () {
        // E11
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.spades),
            levelsOf(1, 1, 1, 1),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.diamonds),
            levelsOf(1, 1, 1, 1),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.diamonds),
            levelsOf(1, 1, 2, 1),
          ),
          isTrue,
        );
      });

      test('E12 cascade safety at the recorded foundation levels', () {
        // E12
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.clubs),
            levelsOf(1, 1, 1, 0),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.ace, Suit.diamonds),
            levelsOf(1, 1, 1, 0),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.hearts),
            levelsOf(1, 1, 1, 0),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.clubs),
            levelsOf(1, 1, 1, 1),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.two, Suit.hearts),
            levelsOf(2, 1, 1, 1),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.hearts),
            levelsOf(2, 1, 1, 1),
          ),
          isFalse,
        );

        final threesBlocked = levelsOf(2, 2, 1, 1);
        for (final suit in Suit.values) {
          expect(
            hasSafeFoundationLevels(Card(Rank.three, suit), threesBlocked),
            isFalse,
            reason: '$suit',
          );
        }
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.hearts),
            threesBlocked,
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.seven, Suit.diamonds),
            threesBlocked,
          ),
          isFalse,
        );
      });

      test('E15 KD and KS are unsafe until the recorded levels rise', () {
        // E15
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.diamonds),
            levelsOf(13, 13, 11, 12),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.spades),
            levelsOf(13, 13, 11, 12),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.queen, Suit.spades),
            levelsOf(13, 13, 11, 13),
          ),
          isTrue,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.spades),
            levelsOf(13, 13, 11, 13),
          ),
          isFalse,
        );
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.king, Suit.spades),
            levelsOf(13, 13, 12, 13),
          ),
          isTrue,
        );
      });

      test('E15 QS at (13, 13, 11, 12) is true because exposure is not '
          'evaluated', () {
        // E15
        expect(
          hasSafeFoundationLevels(
            const Card(Rank.queen, Suit.spades),
            levelsOf(13, 13, 11, 12),
          ),
          isTrue,
        );
      });
    },
  );

  group('hasSafeFoundationLevels levels precondition', () {
    test('each missing slot, and the empty map, throw for every card', () {
      final maps = <Map<FoundationSlot, int>>[
        {},
        for (final missing in FoundationSlot.values)
          {
            for (final slot in FoundationSlot.values)
              if (slot != missing) slot: 0,
          },
      ];

      expect(maps, hasLength(5));

      for (final levels in maps) {
        for (final card in allCards) {
          expect(
            () => hasSafeFoundationLevels(card, levels),
            throwsA(
              isA<ArgumentError>()
                  .having(
                    (error) => error.invalidValue,
                    'invalidValue',
                    same(levels),
                  )
                  .having((error) => error.name, 'name', 'levels')
                  .having(
                    (error) => error.message,
                    'message',
                    'Foundation levels must contain all four slots',
                  ),
            ),
            reason: '${card.rank} ${card.suit}',
          );
        }
      }
    });

    test('level -1 or 14 in any slot throws for every card', () {
      for (final badSlot in FoundationSlot.values) {
        for (final badLevel in [-1, 14]) {
          final levels = switch (badSlot) {
            FoundationSlot.f1 => levelsOf(badLevel, 0, 0, 0),
            FoundationSlot.f2 => levelsOf(0, badLevel, 0, 0),
            FoundationSlot.f3 => levelsOf(0, 0, badLevel, 0),
            FoundationSlot.f4 => levelsOf(0, 0, 0, badLevel),
          };

          for (final card in allCards) {
            expect(
              () => hasSafeFoundationLevels(card, levels),
              throwsA(
                isA<ArgumentError>()
                    .having(
                      (error) => error.invalidValue,
                      'invalidValue',
                      badLevel,
                    )
                    .having((error) => error.name, 'name', 'level')
                    .having(
                      (error) => error.message,
                      'message',
                      'A foundation level must be between 0 and 13',
                    ),
              ),
              reason: '${card.rank} ${card.suit} $badSlot at $badLevel',
            );
          }
        }
      }
    });

    test('completeness precedes range, in FoundationSlot.values order', () {
      final missingTail = {FoundationSlot.f1: -1};
      final highThenLow = {
        FoundationSlot.f1: 14,
        FoundationSlot.f2: -1,
        FoundationSlot.f3: 0,
        FoundationSlot.f4: 0,
      };
      final lowThenHigh = {
        FoundationSlot.f1: 0,
        FoundationSlot.f2: -1,
        FoundationSlot.f3: 14,
        FoundationSlot.f4: 0,
      };
      final reverseInsertion = {
        FoundationSlot.f4: -1,
        FoundationSlot.f3: 14,
        FoundationSlot.f2: 0,
        FoundationSlot.f1: 0,
      };

      expect(reverseInsertion.keys.toList(), [
        FoundationSlot.f4,
        FoundationSlot.f3,
        FoundationSlot.f2,
        FoundationSlot.f1,
      ]);

      for (final card in allCards) {
        expect(
          () => hasSafeFoundationLevels(card, missingTail),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (error) => error.invalidValue,
                  'invalidValue',
                  same(missingTail),
                )
                .having((error) => error.name, 'name', 'levels')
                .having(
                  (error) => error.message,
                  'message',
                  'Foundation levels must contain all four slots',
                ),
          ),
          reason: '${card.rank} ${card.suit}',
        );
        expect(
          () => hasSafeFoundationLevels(card, highThenLow),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue', 14)
                .having((error) => error.name, 'name', 'level')
                .having(
                  (error) => error.message,
                  'message',
                  'A foundation level must be between 0 and 13',
                ),
          ),
          reason: '${card.rank} ${card.suit}',
        );
        expect(
          () => hasSafeFoundationLevels(card, lowThenHigh),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue', -1)
                .having((error) => error.name, 'name', 'level')
                .having(
                  (error) => error.message,
                  'message',
                  'A foundation level must be between 0 and 13',
                ),
          ),
          reason: '${card.rank} ${card.suit}',
        );
        expect(
          () => hasSafeFoundationLevels(card, reverseInsertion),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue', 14)
                .having((error) => error.name, 'name', 'level')
                .having(
                  (error) => error.message,
                  'message',
                  'A foundation level must be between 0 and 13',
                ),
          ),
          reason: '${card.rank} ${card.suit}',
        );
      }
    });

    test('levels 0 and 13 return normally for every card', () {
      var maps = 0;

      for (final l1 in [0, 13]) {
        for (final l2 in [0, 13]) {
          for (final l3 in [0, 13]) {
            for (final l4 in [0, 13]) {
              maps++;
              final levels = levelsOf(l1, l2, l3, l4);

              for (final card in allCards) {
                expect(
                  () => hasSafeFoundationLevels(card, levels),
                  returnsNormally,
                  reason: '${card.rank} ${card.suit} ($l1, $l2, $l3, $l4)',
                );
              }
            }
          }
        }
      }

      expect(maps, 16);
    });
  });

  group('hasSafeFoundationLevels input map', () {
    test('unmodifiable maps return a true result and a false result', () {
      expect(
        hasSafeFoundationLevels(
          const Card(Rank.ace, Suit.clubs),
          Map<FoundationSlot, int>.unmodifiable(levelsOf(0, 0, 0, 0)),
        ),
        isTrue,
      );
      expect(
        hasSafeFoundationLevels(
          const Card(Rank.four, Suit.clubs),
          Map<FoundationSlot, int>.unmodifiable(levelsOf(3, 1, 1, 1)),
        ),
        isFalse,
      );
    });

    test('a mutable map keeps its entries and key order', () {
      final levels = <FoundationSlot, int>{
        FoundationSlot.f4: 0,
        FoundationSlot.f3: 0,
        FoundationSlot.f2: 0,
        FoundationSlot.f1: 0,
      };

      var snapshot = Map<FoundationSlot, int>.of(levels);
      var keyOrder = levels.keys.toList();
      expect(
        hasSafeFoundationLevels(const Card(Rank.ace, Suit.clubs), levels),
        isTrue,
      );
      expect(levels, snapshot);
      expect(levels.keys.toList(), keyOrder);

      levels[FoundationSlot.f1] = 3;
      levels[FoundationSlot.f2] = 1;
      levels[FoundationSlot.f3] = 1;
      levels[FoundationSlot.f4] = 1;
      snapshot = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      expect(
        hasSafeFoundationLevels(const Card(Rank.four, Suit.clubs), levels),
        isFalse,
      );
      expect(levels, snapshot);
      expect(levels.keys.toList(), keyOrder);

      levels[FoundationSlot.f1] = 14;
      snapshot = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      expect(
        () => hasSafeFoundationLevels(const Card(Rank.ace, Suit.clubs), levels),
        throwsArgumentError,
      );
      expect(levels, snapshot);
      expect(levels.keys.toList(), keyOrder);
    });
  });
}
