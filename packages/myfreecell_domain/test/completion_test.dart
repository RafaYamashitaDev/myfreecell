import 'package:myfreecell_domain/src/completion.dart';
import 'package:myfreecell_domain/src/foundation.dart';
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

  bool sumIsFullDeck(int l1, int l2, int l3, int l4) {
    return l1 + l2 + l3 + l4 == 52;
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

  group('areFoundationsComplete exhaustive oracle (GD-CMP-01)', () {
    test('every valid four-level tuple matches the sum of 52', () {
      var evaluations = 0;
      var mismatches = 0;
      var trueCount = 0;
      (int, int, int, int)? trueTuple;
      final mismatchSamples = <String>[];

      for (final l1 in levels0to13) {
        for (final l2 in levels0to13) {
          for (final l3 in levels0to13) {
            for (final l4 in levels0to13) {
              evaluations++;
              final actual = areFoundationsComplete(levelsOf(l1, l2, l3, l4));
              if (actual != sumIsFullDeck(l1, l2, l3, l4)) {
                mismatches++;
                if (mismatchSamples.length < 5) {
                  mismatchSamples.add('($l1, $l2, $l3, $l4)');
                }
              }
              if (actual) {
                trueCount++;
                trueTuple = (l1, l2, l3, l4);
              }
            }
          }
        }
      }

      expect(evaluations, 38416);
      expect(mismatches, 0, reason: mismatchSamples.join('\n'));
      expect(trueCount, 1);
      expect(trueTuple, (13, 13, 13, 13));
    });
  });

  group('areFoundationsComplete foundation levels (GD-CMP-01, GD-CMP-02, '
      'GD-INV-04)', () {
    test('all four levels at 13 are complete', () {
      expect(areFoundationsComplete(levelsOf(13, 13, 13, 13)), isTrue);
    });

    test('all four levels at 0 are not complete', () {
      expect(areFoundationsComplete(levelsOf(0, 0, 0, 0)), isFalse);
    });

    test('E15 pre-state (13, 13, 11, 12) is not complete', () {
      // E15 foundation levels before the later transfers.
      expect(areFoundationsComplete(levelsOf(13, 13, 11, 12)), isFalse);
    });

    test('one slot at 12 with the other three at 13 is not complete', () {
      final shortBySlot = {
        FoundationSlot.f1: levelsOf(12, 13, 13, 13),
        FoundationSlot.f2: levelsOf(13, 12, 13, 13),
        FoundationSlot.f3: levelsOf(13, 13, 12, 13),
        FoundationSlot.f4: levelsOf(13, 13, 13, 12),
      };

      for (final slot in FoundationSlot.values) {
        expect(
          areFoundationsComplete(shortBySlot[slot]!),
          isFalse,
          reason: '$slot',
        );
      }
    });

    test(
      'the same slot levels agree in forward and reverse insertion order',
      () {
        final forwardComplete = levelsOf(13, 13, 13, 13);
        final reverseComplete = {
          FoundationSlot.f4: 13,
          FoundationSlot.f3: 13,
          FoundationSlot.f2: 13,
          FoundationSlot.f1: 13,
        };
        final forwardE15 = levelsOf(13, 13, 11, 12);
        final reverseE15 = {
          FoundationSlot.f4: 12,
          FoundationSlot.f3: 11,
          FoundationSlot.f2: 13,
          FoundationSlot.f1: 13,
        };
        final forwardShort = levelsOf(13, 12, 13, 13);
        final scrambledShort = {
          FoundationSlot.f2: 12,
          FoundationSlot.f4: 13,
          FoundationSlot.f1: 13,
          FoundationSlot.f3: 13,
        };

        expect(reverseComplete.keys.toList(), [
          FoundationSlot.f4,
          FoundationSlot.f3,
          FoundationSlot.f2,
          FoundationSlot.f1,
        ]);
        expect(
          areFoundationsComplete(reverseComplete),
          areFoundationsComplete(forwardComplete),
        );
        expect(areFoundationsComplete(reverseComplete), isTrue);
        expect(
          areFoundationsComplete(reverseE15),
          areFoundationsComplete(forwardE15),
        );
        expect(areFoundationsComplete(reverseE15), isFalse);
        expect(scrambledShort.keys.toList(), [
          FoundationSlot.f2,
          FoundationSlot.f4,
          FoundationSlot.f1,
          FoundationSlot.f3,
        ]);
        expect(
          areFoundationsComplete(scrambledShort),
          areFoundationsComplete(forwardShort),
        );
      },
    );
  });

  group('areFoundationsComplete levels precondition', () {
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
          () => areFoundationsComplete(levels),
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
            () => areFoundationsComplete(levels),
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
        () => areFoundationsComplete(missingTail),
        throwsA(missingSlotsError(missingTail)),
      );
      expect(
        () => areFoundationsComplete(highThenLow),
        throwsA(levelRangeError(14)),
      );
      expect(
        () => areFoundationsComplete(lowThenHigh),
        throwsA(levelRangeError(-1)),
      );
      expect(
        () => areFoundationsComplete(reverseInsertion),
        throwsA(levelRangeError(14)),
      );
    });

    test('levels 0 and 13 return normally', () {
      var maps = 0;

      for (final l1 in [0, 13]) {
        for (final l2 in [0, 13]) {
          for (final l3 in [0, 13]) {
            for (final l4 in [0, 13]) {
              maps++;
              expect(
                () => areFoundationsComplete(levelsOf(l1, l2, l3, l4)),
                returnsNormally,
                reason: '($l1, $l2, $l3, $l4)',
              );
            }
          }
        }
      }

      expect(maps, 16);
    });
  });

  group('areFoundationsComplete input map', () {
    test('an unmodifiable map returns a true result and a false result', () {
      expect(
        areFoundationsComplete(
          Map<FoundationSlot, int>.unmodifiable(levelsOf(13, 13, 13, 13)),
        ),
        isTrue,
      );
      expect(
        areFoundationsComplete(
          Map<FoundationSlot, int>.unmodifiable(levelsOf(13, 13, 11, 12)),
        ),
        isFalse,
      );
    });

    test('a mutable map keeps its entries, values, and key order', () {
      final levels = <FoundationSlot, int>{
        FoundationSlot.f4: 13,
        FoundationSlot.f3: 13,
        FoundationSlot.f2: 13,
        FoundationSlot.f1: 13,
      };

      var entries = Map<FoundationSlot, int>.of(levels);
      var keyOrder = levels.keys.toList();
      var values = levels.values.toList();
      expect(areFoundationsComplete(levels), isTrue);
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);

      levels[FoundationSlot.f3] = 11;
      levels[FoundationSlot.f4] = 12;
      entries = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      values = levels.values.toList();
      expect(areFoundationsComplete(levels), isFalse);
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);

      levels[FoundationSlot.f1] = 14;
      entries = Map<FoundationSlot, int>.of(levels);
      keyOrder = levels.keys.toList();
      values = levels.values.toList();
      expect(() => areFoundationsComplete(levels), throwsArgumentError);
      expect(levels, entries);
      expect(levels.keys.toList(), keyOrder);
      expect(levels.values.toList(), values);
    });
  });
}
