import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/move_count.dart';
import 'package:test/test.dart';

void main() {
  const levels0to13 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

  Map<FoundationSlot, int> levelsOf(int f1, int f2, int f3, int f4) {
    return {
      FoundationSlot.f1: f1,
      FoundationSlot.f2: f2,
      FoundationSlot.f3: f3,
      FoundationSlot.f4: f4,
    };
  }

  // GD-STATE-03: level k holds Ace through rank k of the slot's suit.
  // The length is a card count. It is not a sum of the levels.
  Set<Card> foundationCards(int l1, int l2, int l3, int l4) {
    final bySlot = [l1, l2, l3, l4];
    return {
      for (var index = 0; index < FoundationSlot.values.length; index++)
        for (final rank in Rank.values.take(bySlot[index]))
          Card(rank, FoundationSlot.values[index].suit),
    };
  }

  bool covers(int moveCount, int foundationCardCount) {
    return moveCount >= 0 && moveCount >= foundationCardCount;
  }

  Matcher missingSlotsError(Map<FoundationSlot, int> levels) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', same(levels))
        .having((error) => error.name, 'name', 'levels')
        .having(
          (error) => error.message,
          'message',
          'Foundation levels must contain all four slots',
        );
  }

  Matcher levelRangeError(int level) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', level)
        .having((error) => error.name, 'name', 'level')
        .having(
          (error) => error.message,
          'message',
          'A foundation level must be between 0 and 13',
        );
  }

  group('moveCountCoversFoundationCards exhaustive card-set oracle (GD-INV-05; '
      'supports GD-LIFE-08 and GD-TEST-36)', () {
    test('levels (1, 1, 1, 0) are the aces AC, AH, and AS', () {
      expect(foundationCards(1, 1, 1, 0), {
        const Card(Rank.ace, Suit.clubs),
        const Card(Rank.ace, Suit.hearts),
        const Card(Rank.ace, Suit.spades),
      });
    });

    test('every valid four-level tuple matches the card-set count', () {
      var evaluations = 0;
      var mismatches = 0;
      var belowBoundCases = 0;
      var belowBoundPasses = 0;
      int? emptyCount;
      int? fullCount;
      final mismatchSamples = <String>[];

      for (final l1 in levels0to13) {
        for (final l2 in levels0to13) {
          for (final l3 in levels0to13) {
            for (final l4 in levels0to13) {
              final n = foundationCards(l1, l2, l3, l4).length;
              final levels = levelsOf(l1, l2, l3, l4);
              if (l1 == 0 && l2 == 0 && l3 == 0 && l4 == 0) {
                emptyCount = n;
              }
              if (l1 == 13 && l2 == 13 && l3 == 13 && l4 == 13) {
                fullCount = n;
              }
              if (n > 0) {
                belowBoundCases++;
                if (moveCountCoversFoundationCards(n - 1, levels)) {
                  belowBoundPasses++;
                }
              }

              for (final moveCount in [(-1), 0, n - 1, n, n + 1, n + 100]) {
                evaluations++;
                final actual = moveCountCoversFoundationCards(
                  moveCount,
                  levels,
                );
                if (actual != covers(moveCount, n)) {
                  mismatches++;
                  if (mismatchSamples.length < 5) {
                    mismatchSamples.add(
                      '($l1, $l2, $l3, $l4) moveCount=$moveCount',
                    );
                  }
                }
              }
            }
          }
        }
      }

      expect(evaluations, 230496);
      expect(mismatches, 0, reason: mismatchSamples.join('\n'));
      expect(belowBoundCases, 38415);
      expect(belowBoundPasses, 0);
      expect(emptyCount, 0);
      expect(fullCount, 52);
    });
  });

  group('moveCountCoversFoundationCards worked examples (GD-INV-05; '
      'supports GD-LIFE-08 and GD-TEST-36)', () {
    test('E09 levels (1, 1, 1, 0) are true at 3 and false at 2', () {
      // E09
      final levels = levelsOf(1, 1, 1, 0);

      expect(moveCountCoversFoundationCards(3, levels), isTrue);
      expect(moveCountCoversFoundationCards(2, levels), isFalse);
    });

    test('E12 S0 levels (1, 1, 1, 0) are true at 20', () {
      // E12 S0
      expect(moveCountCoversFoundationCards(20, levelsOf(1, 1, 1, 0)), isTrue);
    });

    test('E12 S1 levels (2, 2, 1, 1) are true at 24 and 6, and false at 5', () {
      // E12 S1
      final levels = levelsOf(2, 2, 1, 1);

      expect(moveCountCoversFoundationCards(24, levels), isTrue);
      expect(moveCountCoversFoundationCards(6, levels), isTrue);
      expect(moveCountCoversFoundationCards(5, levels), isFalse);
    });

    test('E15 levels (13, 13, 11, 12) are true at 140 and false at 48', () {
      // E15
      final levels = levelsOf(13, 13, 11, 12);

      expect(moveCountCoversFoundationCards(140, levels), isTrue);
      expect(moveCountCoversFoundationCards(48, levels), isFalse);
    });

    test('completed levels (13, 13, 13, 13) are true at 143 and 52, and false '
        'at 51', () {
      // E15 final count, and the GD-TEST-42 boundary of 52.
      final levels = levelsOf(13, 13, 13, 13);

      expect(moveCountCoversFoundationCards(143, levels), isTrue);
      expect(moveCountCoversFoundationCards(52, levels), isTrue);
      expect(moveCountCoversFoundationCards(51, levels), isFalse);
    });

    test('E08 levels (3, 1, 1, 1) are true at 6 and false at 5', () {
      // E08
      final levels = levelsOf(3, 1, 1, 1);

      expect(moveCountCoversFoundationCards(6, levels), isTrue);
      expect(moveCountCoversFoundationCards(5, levels), isFalse);
    });
  });

  group('moveCountCoversFoundationCards levels precondition (GD-INV-05)', () {
    test('an empty map and each missing slot throw', () {
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
        expect(
          () => moveCountCoversFoundationCards(0, levels),
          throwsA(missingSlotsError(levels)),
          reason: '${levels.keys.toList()}',
        );
      }
    });

    test('level -1 or 14 in any slot throws', () {
      for (final badSlot in FoundationSlot.values) {
        for (final badLevel in [-1, 14]) {
          final levels = switch (badSlot) {
            FoundationSlot.f1 => levelsOf(badLevel, 0, 0, 0),
            FoundationSlot.f2 => levelsOf(0, badLevel, 0, 0),
            FoundationSlot.f3 => levelsOf(0, 0, badLevel, 0),
            FoundationSlot.f4 => levelsOf(0, 0, 0, badLevel),
          };

          expect(
            () => moveCountCoversFoundationCards(0, levels),
            throwsA(levelRangeError(badLevel)),
            reason: '$badSlot at $badLevel',
          );
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
      expect(
        () => moveCountCoversFoundationCards(0, missingTail),
        throwsA(missingSlotsError(missingTail)),
      );
      expect(
        () => moveCountCoversFoundationCards(0, highThenLow),
        throwsA(levelRangeError(14)),
      );
      expect(
        () => moveCountCoversFoundationCards(0, lowThenHigh),
        throwsA(levelRangeError(-1)),
      );
      expect(
        () => moveCountCoversFoundationCards(0, reverseInsertion),
        throwsA(levelRangeError(14)),
      );
    });

    test('a levels error precedes a negative move count', () {
      final empty = <FoundationSlot, int>{};
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

      expect(
        () => moveCountCoversFoundationCards(-1, empty),
        throwsA(missingSlotsError(empty)),
      );
      expect(
        () => moveCountCoversFoundationCards(-1, missingTail),
        throwsA(missingSlotsError(missingTail)),
      );
      expect(
        () => moveCountCoversFoundationCards(-1, highThenLow),
        throwsA(levelRangeError(14)),
      );
      expect(
        () => moveCountCoversFoundationCards(-1, lowThenHigh),
        throwsA(levelRangeError(-1)),
      );
      expect(moveCountCoversFoundationCards(-1, levelsOf(0, 0, 0, 0)), isFalse);
    });

    test('levels 0 and 13 return normally', () {
      var maps = 0;

      for (final l1 in [0, 13]) {
        for (final l2 in [0, 13]) {
          for (final l3 in [0, 13]) {
            for (final l4 in [0, 13]) {
              maps++;
              expect(
                () =>
                    moveCountCoversFoundationCards(0, levelsOf(l1, l2, l3, l4)),
                returnsNormally,
                reason: '($l1, $l2, $l3, $l4)',
              );
              expect(
                () => moveCountCoversFoundationCards(
                  -1,
                  levelsOf(l1, l2, l3, l4),
                ),
                returnsNormally,
                reason: '($l1, $l2, $l3, $l4) negative',
              );
            }
          }
        }
      }

      expect(maps, 16);
    });
  });

  group('moveCountCoversFoundationCards input map (GD-INV-05)', () {
    test('an unmodifiable map returns a true result and a false result', () {
      expect(
        moveCountCoversFoundationCards(
          3,
          Map<FoundationSlot, int>.unmodifiable(levelsOf(1, 1, 1, 0)),
        ),
        isTrue,
      );
      expect(
        moveCountCoversFoundationCards(
          2,
          Map<FoundationSlot, int>.unmodifiable(levelsOf(1, 1, 1, 0)),
        ),
        isFalse,
      );
    });

    test('a mutable map keeps its entries, values, and key order', () {
      final levels = <FoundationSlot, int>{
        FoundationSlot.f4: 1,
        FoundationSlot.f3: 1,
        FoundationSlot.f2: 1,
        FoundationSlot.f1: 1,
      };

      var entries = Map<FoundationSlot, int>.of(levels);
      var keyOrder = levels.keys.toList();
      var values = levels.values.toList();
      expect(moveCountCoversFoundationCards(4, levels), isTrue);
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);

      levels[FoundationSlot.f4] = 0;
      entries = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      values = levels.values.toList();
      expect(moveCountCoversFoundationCards(2, levels), isFalse);
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);

      levels[FoundationSlot.f1] = 14;
      entries = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      values = levels.values.toList();
      expect(
        () => moveCountCoversFoundationCards(100, levels),
        throwsArgumentError,
      );
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);
    });
  });
}
