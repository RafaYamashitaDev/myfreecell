import 'package:myfreecell_domain/src/capacity.dart';
import 'package:test/test.dart';

void main() {
  // Hand-written oracle for empty free cells 0..4 (rows) and eligible empty
  // columns 0..7 (columns). These literals are not derived from production.
  const capacityByFreeCellsAndColumns = <List<int>>[
    [1, 2, 3, 4, 5, 6, 7, 8],
    [2, 3, 4, 5, 6, 7, 8, 9],
    [3, 4, 5, 6, 7, 8, 9, 10],
    [4, 5, 6, 7, 8, 9, 10, 11],
    [5, 6, 7, 8, 9, 10, 11, 12],
  ];

  int commonDoublingCapacity(int emptyFreeCells, int eligibleEmptyColumns) {
    return (emptyFreeCells + 1) * (1 << eligibleEmptyColumns);
  }

  Matcher negativeCountError(int invalidValue, String name) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', invalidValue)
        .having((error) => error.name, 'name', name)
        .having(
          (error) => error.message,
          'message',
          'A count of empty spaces must not be negative',
        );
  }

  group('movementCapacity literal grid (GD-CAP-02, GD-CAP-06)', () {
    test('the hand-written grid covers 1 through 12 and grows by one', () {
      expect(capacityByFreeCellsAndColumns, hasLength(5));

      final values = <int>{};
      for (var freeCells = 0; freeCells < 5; freeCells++) {
        expect(capacityByFreeCellsAndColumns[freeCells], hasLength(8));
        for (var columns = 0; columns < 8; columns++) {
          final value = capacityByFreeCellsAndColumns[freeCells][columns];
          expect(
            value,
            greaterThanOrEqualTo(1),
            reason: '($freeCells, $columns)',
          );
          values.add(value);
        }
      }

      expect(values, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12});

      for (var freeCells = 0; freeCells < 4; freeCells++) {
        for (var columns = 0; columns < 8; columns++) {
          expect(
            capacityByFreeCellsAndColumns[freeCells + 1][columns],
            capacityByFreeCellsAndColumns[freeCells][columns] + 1,
            reason: '($freeCells, $columns)',
          );
        }
      }

      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 7; columns++) {
          expect(
            capacityByFreeCellsAndColumns[freeCells][columns + 1],
            capacityByFreeCellsAndColumns[freeCells][columns] + 1,
            reason: '($freeCells, $columns)',
          );
        }
      }

      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 5; columns++) {
          expect(
            capacityByFreeCellsAndColumns[freeCells][columns],
            capacityByFreeCellsAndColumns[columns][freeCells],
            reason: '($freeCells, $columns)',
          );
        }
      }
    });

    test('every free-cell and column pair matches the hand-written value', () {
      var comparisons = 0;

      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 8; columns++) {
          comparisons++;
          expect(
            movementCapacity(
              emptyFreeCells: freeCells,
              eligibleEmptyColumns: columns,
            ),
            capacityByFreeCellsAndColumns[freeCells][columns],
            reason: '($freeCells, $columns)',
          );
        }
      }

      expect(comparisons, 40);
    });

    test('one more free cell or eligible column adds exactly one', () {
      for (var freeCells = 0; freeCells < 4; freeCells++) {
        for (var columns = 0; columns < 8; columns++) {
          expect(
            movementCapacity(
              emptyFreeCells: freeCells + 1,
              eligibleEmptyColumns: columns,
            ),
            movementCapacity(
                  emptyFreeCells: freeCells,
                  eligibleEmptyColumns: columns,
                ) +
                1,
            reason: '($freeCells, $columns)',
          );
        }
      }

      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 7; columns++) {
          expect(
            movementCapacity(
              emptyFreeCells: freeCells,
              eligibleEmptyColumns: columns + 1,
            ),
            movementCapacity(
                  emptyFreeCells: freeCells,
                  eligibleEmptyColumns: columns,
                ) +
                1,
            reason: '($freeCells, $columns)',
          );
        }
      }
    });

    test('swapping the two counts leaves capacity unchanged', () {
      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 8; columns++) {
          expect(
            movementCapacity(
              emptyFreeCells: freeCells,
              eligibleEmptyColumns: columns,
            ),
            movementCapacity(
              emptyFreeCells: columns,
              eligibleEmptyColumns: freeCells,
            ),
            reason: '($freeCells, $columns)',
          );
        }
      }
    });

    test('a single card never exceeds a grid capacity (GD-TEST-10)', () {
      const singleCard = 1;

      for (var freeCells = 0; freeCells < 5; freeCells++) {
        for (var columns = 0; columns < 8; columns++) {
          final capacity = movementCapacity(
            emptyFreeCells: freeCells,
            eligibleEmptyColumns: columns,
          );

          expect(
            capacity,
            greaterThanOrEqualTo(1),
            reason: '($freeCells, $columns)',
          );
          expect(
            singleCard,
            lessThanOrEqualTo(capacity),
            reason: '($freeCells, $columns)',
          );
        }
      }
    });
  });

  group('movementCapacity is the linear formula (GD-CAP-02)', () {
    test('(1, 1) is 3, which rejects the doubling result 4', () {
      expect(commonDoublingCapacity(1, 1), 4);
      expect(movementCapacity(emptyFreeCells: 1, eligibleEmptyColumns: 1), 3);
      expect(
        movementCapacity(emptyFreeCells: 1, eligibleEmptyColumns: 1),
        isNot(commonDoublingCapacity(1, 1)),
      );
    });

    test('(2, 2) is 5, which rejects the doubling result 12', () {
      expect(commonDoublingCapacity(2, 2), 12);
      expect(movementCapacity(emptyFreeCells: 2, eligibleEmptyColumns: 2), 5);
      expect(
        movementCapacity(emptyFreeCells: 2, eligibleEmptyColumns: 2),
        isNot(commonDoublingCapacity(2, 2)),
      );
    });
  });

  group(
    'movementCapacity worked examples (GD-CAP-02, GD-CAP-06, GD-TEST-09)',
    () {
      test('E02 two empty free cells and no empty columns has capacity 3', () {
        // E02
        expect(movementCapacity(emptyFreeCells: 2, eligibleEmptyColumns: 0), 3);
      });

      test('E03 an empty destination leaves one eligible column', () {
        // E03. The caller has already excluded the destination column.
        expect(movementCapacity(emptyFreeCells: 1, eligibleEmptyColumns: 1), 3);
      });

      test('E03 contrast: an empty destination has capacity 3 and a nonempty '
          'destination has capacity 4 (GD-TEST-09)', () {
        // E03
        final emptyDestination = movementCapacity(
          emptyFreeCells: 1,
          eligibleEmptyColumns: 1,
        );
        final nonemptyDestination = movementCapacity(
          emptyFreeCells: 1,
          eligibleEmptyColumns: 2,
        );

        expect(emptyDestination, 3);
        expect(nonemptyDestination, 4);
        expect(4, greaterThan(emptyDestination));
        expect(4, lessThanOrEqualTo(nonemptyDestination));
        expect(requiredAssistingSpaces(4), 3);
      });

      test('E04 one empty free cell and no empty columns has capacity 2', () {
        // E04
        expect(movementCapacity(emptyFreeCells: 1, eligibleEmptyColumns: 0), 2);
      });

      test('no empty spaces has capacity 1 (GD-CAP-06)', () {
        // E04 variant
        expect(movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 0), 1);
      });
    },
  );

  group('requiredAssistingSpaces (GD-CAP-05, GD-TEST-07)', () {
    test('lengths 1 through 4 require 0 through 3 assisting spaces', () {
      expect(requiredAssistingSpaces(1), 0);
      expect(requiredAssistingSpaces(2), 1);
      expect(requiredAssistingSpaces(3), 2);
      expect(requiredAssistingSpaces(4), 3);
    });

    test('E04 M = 4 requires N = 3, and the M = 2 variant requires N = 1', () {
      // E04
      expect(requiredAssistingSpaces(4), 3);
      // E04 variant
      expect(requiredAssistingSpaces(2), 1);
    });

    test('a 13-card sequence requires 12 assisting spaces', () {
      expect(requiredAssistingSpaces(13), 12);
    });

    test('N is the total required, not the shortfall from capacity', () {
      // E04 capacity is 2, so the shortfall for M = 4 would be 2.
      // E03 empty-destination capacity is 3, so that shortfall would be 1.
      final e04Capacity = movementCapacity(
        emptyFreeCells: 1,
        eligibleEmptyColumns: 0,
      );
      final e03Capacity = movementCapacity(
        emptyFreeCells: 1,
        eligibleEmptyColumns: 1,
      );
      const sequenceLength = 4;
      final assistingSpaces = requiredAssistingSpaces(sequenceLength);

      expect(e04Capacity, 2);
      expect(e03Capacity, 3);
      expect(assistingSpaces, 3);
      expect(assistingSpaces, isNot(sequenceLength - e04Capacity));
      expect(assistingSpaces, isNot(sequenceLength - e03Capacity));
    });
  });

  group('movementCapacity count precondition', () {
    test('a negative free-cell count names emptyFreeCells', () {
      expect(
        () => movementCapacity(emptyFreeCells: -1, eligibleEmptyColumns: 0),
        throwsA(negativeCountError(-1, 'emptyFreeCells')),
      );
    });

    test('a negative column count names eligibleEmptyColumns', () {
      expect(
        () => movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: -1),
        throwsA(negativeCountError(-1, 'eligibleEmptyColumns')),
      );
    });

    test('the free-cell check precedes the column check', () {
      expect(
        () => movementCapacity(emptyFreeCells: -1, eligibleEmptyColumns: -2),
        throwsA(negativeCountError(-1, 'emptyFreeCells')),
      );
    });

    test('zero and 1000 return normally', () {
      expect(
        () => movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 0),
        returnsNormally,
      );
      expect(
        () => movementCapacity(emptyFreeCells: 1000, eligibleEmptyColumns: 0),
        returnsNormally,
      );
      expect(
        () => movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 1000),
        returnsNormally,
      );
      expect(
        () =>
            movementCapacity(emptyFreeCells: 1000, eligibleEmptyColumns: 1000),
        returnsNormally,
      );
      expect(
        movementCapacity(emptyFreeCells: 1000, eligibleEmptyColumns: 0),
        movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 0) + 1000,
      );
      expect(
        movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 1000),
        movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 0) + 1000,
      );
      expect(
        movementCapacity(emptyFreeCells: 1000, eligibleEmptyColumns: 1000),
        movementCapacity(emptyFreeCells: 0, eligibleEmptyColumns: 0) + 2000,
      );
    });
  });

  group('requiredAssistingSpaces length precondition', () {
    test('lengths 0 and -1 throw ArgumentError.value', () {
      for (final length in [0, -1]) {
        expect(
          () => requiredAssistingSpaces(length),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.invalidValue, 'invalidValue', length)
                .having((error) => error.name, 'name', 'sequenceLength')
                .having(
                  (error) => error.message,
                  'message',
                  'A sequence length must be at least 1',
                ),
          ),
          reason: '$length',
        );
      }
    });
  });
}
