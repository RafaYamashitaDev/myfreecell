import 'package:myfreecell_domain/src/board.dart';
import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/deal.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/sequence.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:test/test.dart';

// Test-only deck and foundation mapping. Conservation checks must not read
// production canonicalDeck or FoundationSlot.suit.
const _ranks = <Rank>[
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

const _deckSuits = <Suit>[Suit.clubs, Suit.diamonds, Suit.hearts, Suit.spades];

const _slotSuits = <FoundationSlot, Suit>{
  FoundationSlot.f1: Suit.clubs,
  FoundationSlot.f2: Suit.hearts,
  FoundationSlot.f3: Suit.spades,
  FoundationSlot.f4: Suit.diamonds,
};

const _aceOfClubs = Card(Rank.ace, Suit.clubs);
const _twoOfClubs = Card(Rank.two, Suit.clubs);
const _aceOfDiamonds = Card(Rank.ace, Suit.diamonds);
const _aceOfHearts = Card(Rank.ace, Suit.hearts);
const _kingOfSpades = Card(Rank.king, Suit.spades);
const _queenOfSpades = Card(Rank.queen, Suit.spades);
const _twoOfDiamonds = Card(Rank.two, Suit.diamonds);

const _emptyFreeCells = <Card?>[null, null, null, null];

const _normativeIdentities = <int>[0, 1, 4294967295, 3141592653];

List<Card> _canonicalCards() => [
  for (final suit in _deckSuits)
    for (final rank in _ranks) Card(rank, suit),
];

Map<FoundationSlot, int> _levelsOf(int f1, int f2, int f3, int f4) {
  return {
    FoundationSlot.f1: f1,
    FoundationSlot.f2: f2,
    FoundationSlot.f3: f3,
    FoundationSlot.f4: f4,
  };
}

List<Card> _impliedCards(Map<FoundationSlot, int> levels) {
  final implied = <Card>[];
  for (final slot in FoundationSlot.values) {
    final suit = _slotSuits[slot]!;
    final level = levels[slot]!;
    for (var index = 0; index < level; index++) {
      implied.add(Card(_ranks[index], suit));
    }
  }
  return implied;
}

List<List<Card>> _emptyColumns() => [
  for (var index = 0; index < 8; index++) <Card>[],
];

List<List<Card>> _conservedColumns({
  required Map<FoundationSlot, int> levels,
  List<Card?> freeCells = _emptyFreeCells,
  List<List<Card>>? fixedColumns,
  int restColumn = 0,
}) {
  final placed = <Card>{
    ..._impliedCards(levels),
    ...freeCells.whereType<Card>(),
    for (final column in fixedColumns ?? const <List<Card>>[]) ...column,
  };
  final rest = [
    for (final card in _canonicalCards())
      if (!placed.contains(card)) card,
  ];
  final columns = _emptyColumns();
  if (fixedColumns != null) {
    for (var index = 0; index < fixedColumns.length && index < 8; index++) {
      columns[index] = [...fixedColumns[index]];
    }
  }
  columns[restColumn] = [...columns[restColumn], ...rest];
  return columns;
}

Board _board({
  List<Card?> freeCells = _emptyFreeCells,
  Map<FoundationSlot, int>? levels,
  List<List<Card>>? fixedColumns,
  int restColumn = 0,
}) {
  final resolvedLevels = levels ?? _levelsOf(0, 0, 0, 0);
  return Board(
    freeCells: freeCells,
    foundationLevels: resolvedLevels,
    columns: _conservedColumns(
      levels: resolvedLevels,
      freeCells: freeCells,
      fixedColumns: fixedColumns,
      restColumn: restColumn,
    ),
  );
}

Matcher _freeCellCountError(List<Card?> freeCells) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', same(freeCells))
      .having((error) => error.name, 'name', 'freeCells')
      .having(
        (error) => error.message,
        'message',
        'A board must have exactly 4 free cells',
      );
}

Matcher _missingSlotsError(Map<FoundationSlot, int> levels) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', same(levels))
      .having((error) => error.name, 'name', 'foundationLevels')
      .having(
        (error) => error.message,
        'message',
        'Foundation levels must contain all four slots',
      );
}

Matcher _levelRangeError(int level) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', level)
      .having((error) => error.name, 'name', 'level')
      .having(
        (error) => error.message,
        'message',
        'A foundation level must be between 0 and 13',
      );
}

Matcher _columnCountError(List<List<Card>> columns) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', same(columns))
      .having((error) => error.name, 'name', 'columns')
      .having(
        (error) => error.message,
        'message',
        'A board must have exactly 8 tableau columns',
      );
}

Matcher _duplicateCard(Card card) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', card)
      .having((error) => error.name, 'name', isNull)
      .having((error) => error.message, 'message', 'Duplicate card');
}

Matcher _duplicateFragment(Card card) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', card)
      .having((error) => error.message, 'message', contains('Duplicate card'));
}

Matcher _missingCard(Card card) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', card)
      .having((error) => error.name, 'name', isNull)
      .having((error) => error.message, 'message', 'Missing card');
}

void main() {
  group('Board validation (GD-INV-01, GD-INV-02, GD-INV-03)', () {
    test('free-cell counts other than 4 throw ArgumentError.value', () {
      for (final count in [0, 3, 5]) {
        final freeCells = List<Card?>.filled(count, null);
        expect(
          () => Board(
            freeCells: freeCells,
            foundationLevels: _levelsOf(0, 0, 0, 0),
            columns: _emptyColumns(),
          ),
          throwsA(_freeCellCountError(freeCells)),
          reason: '$count',
        );
      }
    });

    test('each missing foundation slot throws ArgumentError.value', () {
      final empty = <FoundationSlot, int>{};
      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: empty,
          columns: _emptyColumns(),
        ),
        throwsA(_missingSlotsError(empty)),
      );

      for (final omitted in FoundationSlot.values) {
        final levels = {
          for (final slot in FoundationSlot.values)
            if (slot != omitted) slot: 0,
        };
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: levels,
            columns: _emptyColumns(),
          ),
          throwsA(_missingSlotsError(levels)),
          reason: '$omitted',
        );
      }
    });

    test(
      'levels outside 0 through 13 throw in FoundationSlot.values order',
      () {
        for (final badSlot in FoundationSlot.values) {
          for (final badLevel in [-1, 14]) {
            final levels = {
              for (final slot in FoundationSlot.values)
                slot: slot == badSlot ? badLevel : 0,
            };
            expect(
              () => Board(
                freeCells: _emptyFreeCells,
                foundationLevels: levels,
                columns: _emptyColumns(),
              ),
              throwsA(_levelRangeError(badLevel)),
              reason: '$badSlot at $badLevel',
            );
          }
        }

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
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: highThenLow,
            columns: _emptyColumns(),
          ),
          throwsA(_levelRangeError(14)),
        );
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: lowThenHigh,
            columns: _emptyColumns(),
          ),
          throwsA(_levelRangeError(-1)),
        );
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: reverseInsertion,
            columns: _emptyColumns(),
          ),
          throwsA(_levelRangeError(14)),
        );
      },
    );

    test('column counts other than 8 throw ArgumentError.value', () {
      for (final count in [0, 7, 9]) {
        final columns = List<List<Card>>.generate(count, (_) => <Card>[]);
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: _levelsOf(0, 0, 0, 0),
            columns: columns,
          ),
          throwsA(_columnCountError(columns)),
          reason: '$count',
        );
      }
    });

    test('the first missing canonical-deck card is reported', () {
      final withoutKing = [
        for (final card in _canonicalCards())
          if (card != _kingOfSpades) card,
      ];
      expect(withoutKing, hasLength(51));
      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: _onlyFirstColumn(withoutKing),
        ),
        throwsA(_missingCard(_kingOfSpades)),
      );

      final withoutAces = [
        for (final card in _canonicalCards())
          if (card != _aceOfDiamonds && card != _aceOfHearts) card,
      ];
      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: _onlyFirstColumn(withoutAces),
        ),
        throwsA(_missingCard(_aceOfDiamonds)),
      );
    });

    test('the earlier repeated card within a column is the duplicate', () {
      final columns = _emptyColumns();
      columns[0] = [_aceOfClubs, _aceOfClubs, _twoOfClubs, _twoOfClubs];

      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: columns,
        ),
        throwsA(_duplicateCard(_aceOfClubs)),
      );
    });

    test('free-cell order precedes a later column duplicate', () {
      final columns = _emptyColumns();
      columns[0] = [_aceOfClubs, _aceOfClubs];

      expect(
        () => Board(
          freeCells: [_twoOfClubs, _twoOfClubs, _aceOfClubs, _aceOfClubs],
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: columns,
        ),
        throwsA(_duplicateCard(_twoOfClubs)),
      );
    });

    test('the earlier tableau column wins over a later column duplicate', () {
      final columns = _emptyColumns();
      columns[0] = [_aceOfClubs];
      columns[1] = [_aceOfClubs];
      columns[7] = [_twoOfClubs, _twoOfClubs];

      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: columns,
        ),
        throwsA(_duplicateCard(_aceOfClubs)),
      );
    });

    test(
      'an implied foundation card duplicated in a free cell fails first',
      () {
        final columns = _emptyColumns();
        columns[0] = [_twoOfClubs, _twoOfClubs];

        expect(
          () => Board(
            freeCells: [_aceOfClubs, null, null, null],
            foundationLevels: _levelsOf(1, 0, 0, 0),
            columns: columns,
          ),
          throwsA(_duplicateCard(_aceOfClubs)),
        );
      },
    );

    test('an implied foundation card duplicated in a tableau column is '
        'rejected', () {
      final levels = _levelsOf(1, 0, 0, 0);
      final columns = _conservedColumns(levels: levels);
      columns[0] = [_aceOfClubs, ...columns[0]];

      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: levels,
          columns: columns,
        ),
        throwsA(_duplicateFragment(_aceOfClubs)),
      );
    });

    test('a free-cell card duplicated in a tableau column is rejected', () {
      const freeCells = <Card?>[_aceOfHearts, null, null, null];
      final levels = _levelsOf(0, 0, 0, 0);
      final columns = _conservedColumns(levels: levels, freeCells: freeCells);
      columns[0] = [...columns[0], _aceOfHearts];

      expect(
        () => Board(
          freeCells: freeCells,
          foundationLevels: levels,
          columns: columns,
        ),
        throwsA(_duplicateFragment(_aceOfHearts)),
      );
    });

    test('52 occurrences with one duplicate and one missing card report the '
        'duplicate', () {
      final column = <Card>[
        _aceOfClubs,
        for (final card in _canonicalCards())
          if (card != _kingOfSpades) card,
      ];

      expect(column, hasLength(52));
      expect(column.toSet(), hasLength(51));
      expect(column.where((card) => card == _aceOfClubs), hasLength(2));
      expect(column.contains(_kingOfSpades), isFalse);

      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: _onlyFirstColumn(column),
        ),
        throwsA(_duplicateCard(_aceOfClubs)),
      );
    });

    test('a 53rd occurrence is a duplicate', () {
      final column = [..._canonicalCards(), _kingOfSpades];

      expect(column, hasLength(53));
      expect(
        () => Board(
          freeCells: _emptyFreeCells,
          foundationLevels: _levelsOf(0, 0, 0, 0),
          columns: _onlyFirstColumn(column),
        ),
        throwsA(_duplicateCard(_kingOfSpades)),
      );
    });

    test(
      'earlier validation stages win, including a combined-invalid board',
      () {
        final freeCells = List<Card?>.filled(3, null);
        final missingLevels = <FoundationSlot, int>{FoundationSlot.f1: -1};
        final shortColumns = List<List<Card>>.generate(
          7,
          (_) => <Card>[_aceOfClubs, _aceOfClubs],
        );
        expect(
          () => Board(
            freeCells: freeCells,
            foundationLevels: missingLevels,
            columns: shortColumns,
          ),
          throwsA(_freeCellCountError(freeCells)),
        );

        final missingLaterSlot = {
          FoundationSlot.f1: -1,
          FoundationSlot.f2: 0,
          FoundationSlot.f3: 14,
        };
        final nineColumns = List<List<Card>>.generate(9, (_) => <Card>[]);
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: missingLaterSlot,
            columns: nineColumns,
          ),
          throwsA(_missingSlotsError(missingLaterSlot)),
        );

        final reverseInvalidLevels = {
          FoundationSlot.f4: -1,
          FoundationSlot.f3: 14,
          FoundationSlot.f2: 0,
          FoundationSlot.f1: 0,
        };
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: reverseInvalidLevels,
            columns: nineColumns,
          ),
          throwsA(_levelRangeError(14)),
        );

        final sevenColumns = List<List<Card>>.generate(
          7,
          (_) => <Card>[_aceOfClubs],
        );
        expect(
          () => Board(
            freeCells: _emptyFreeCells,
            foundationLevels: _levelsOf(0, 0, 0, 0),
            columns: sevenColumns,
          ),
          throwsA(_columnCountError(sevenColumns)),
        );
      },
    );
  });

  group('Board accepts conserved positional states '
      '(GD-INV-01, GD-INV-02, GD-INV-03)', () {
    test(
      'empty columns are accepted when the other columns conserve the deck',
      () {
        final board = _board();

        expect(board.columns.first, hasLength(52));
        expect(board.columns.skip(1), everyElement(isEmpty));
        expect(board.freeCells, _emptyFreeCells);
        expect(board.foundationLevels.values, everyElement(0));
      },
    );

    test('gapped free cells keep their occupied and empty positions', () {
      const freeCells = <Card?>[_aceOfHearts, null, _twoOfDiamonds, null];
      final board = _board(freeCells: freeCells);

      expect(board.freeCells, freeCells);
      expect(
        board.columns.any((column) => column.contains(_aceOfHearts)),
        isFalse,
      );
      expect(
        board.columns.any((column) => column.contains(_twoOfDiamonds)),
        isFalse,
      );
    });

    test('nonzero foundation levels imply cards that are absent from live '
        'positions', () {
      final levels = _levelsOf(3, 1, 0, 5);
      final board = _board(levels: levels);
      final implied = _impliedCards(levels);

      expect(implied, hasLength(9));
      expect(board.foundationLevels[FoundationSlot.f1], 3);
      expect(board.foundationLevels[FoundationSlot.f2], 1);
      expect(board.foundationLevels[FoundationSlot.f3], 0);
      expect(board.foundationLevels[FoundationSlot.f4], 5);
      for (final card in implied) {
        expect(board.freeCells.contains(card), isFalse, reason: '$card');
        expect(
          board.columns.any((column) => column.contains(card)),
          isFalse,
          reason: '$card',
        );
      }
    });

    test(
      'all foundations at level 13 with empty live positions are accepted',
      () {
        final board = _board(levels: _levelsOf(13, 13, 13, 13));

        expect(board.freeCells, _emptyFreeCells);
        expect(board.columns, everyElement(isEmpty));
        expect(board.foundationLevels.values, everyElement(13));
      },
    );

    test('a pre-cascade layout may expose a safe Ace', () {
      final columns = _preCascadeColumns(
        exposed: _aceOfClubs,
        exposedColumn: 0,
      );
      final board = Board(
        freeCells: _emptyFreeCells,
        foundationLevels: _levelsOf(0, 0, 0, 0),
        columns: columns,
      );

      expect(board.freeCells, everyElement(isNull));
      expect(board.foundationLevels.values, everyElement(0));
      expect(
        [for (final column in board.columns) column.length],
        [7, 7, 7, 7, 6, 6, 6, 6],
      );
      expect(board.columns[0].last, _aceOfClubs);
      expect({for (final column in board.columns) ...column}, hasLength(52));
    });

    test('a non-sequence-valid column is accepted', () {
      final board = _board(
        fixedColumns: [
          [_kingOfSpades, _queenOfSpades],
        ],
      );

      expect(isValidSequence(board.columns[0]), isFalse);
      expect(board.columns[0].take(2), [_kingOfSpades, _queenOfSpades]);
    });
  });

  group('Board immutability', () {
    test('caller mutations after construction do not change the board', () {
      final freeCells = <Card?>[null, _aceOfClubs, null, null];
      final levels = <FoundationSlot, int>{
        FoundationSlot.f4: 0,
        FoundationSlot.f1: 0,
        FoundationSlot.f3: 0,
        FoundationSlot.f2: 0,
      };
      final nested = <Card>[
        for (final card in _canonicalCards())
          if (card != _aceOfClubs) card,
      ];
      final columns = <List<Card>>[
        nested,
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
      ];
      final board = Board(
        freeCells: freeCells,
        foundationLevels: levels,
        columns: columns,
      );
      final freeSnapshot = [...board.freeCells];
      final levelSnapshot = [
        for (final slot in FoundationSlot.values) board.foundationLevels[slot],
      ];
      final columnSnapshot = [
        for (final column in board.columns) [...column],
      ];

      freeCells[1] = _kingOfSpades;
      freeCells.clear();
      levels[FoundationSlot.f1] = 13;
      levels.remove(FoundationSlot.f2);
      nested
        ..removeAt(0)
        ..add(_aceOfClubs);
      columns[7] = <Card>[_aceOfClubs];
      columns.clear();

      expect(board.freeCells, freeSnapshot);
      expect([
        for (final slot in FoundationSlot.values) board.foundationLevels[slot],
      ], levelSnapshot);
      expect(board.columns, hasLength(8));
      for (var index = 0; index < columnSnapshot.length; index++) {
        expect(board.columns[index], columnSnapshot[index], reason: '$index');
      }
    });

    test('construction does not mutate its inputs', () {
      final freeCells = <Card?>[null, _aceOfClubs, null, null];
      final levels = <FoundationSlot, int>{
        FoundationSlot.f4: 0,
        FoundationSlot.f1: 0,
        FoundationSlot.f3: 0,
        FoundationSlot.f2: 0,
      };
      final nested = <Card>[
        for (final card in _canonicalCards())
          if (card != _aceOfClubs) card,
      ];
      final columns = <List<Card>>[
        nested,
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
        <Card>[],
      ];
      final freeBefore = [...freeCells];
      final levelBefore = [
        for (final entry in levels.entries) (entry.key, entry.value),
      ];
      final nestedBefore = [...nested];

      Board(freeCells: freeCells, foundationLevels: levels, columns: columns);

      expect(freeCells, freeBefore);
      expect([
        for (final entry in levels.entries) (entry.key, entry.value),
      ], levelBefore);
      expect(nested, nestedBefore);
      expect(identical(columns[0], nested), isTrue);
      expect(columns, hasLength(8));
    });

    test('outer free-cell, foundation, and tableau collections are '
        'unmodifiable', () {
      final board = _board(freeCells: const [_aceOfHearts, null, null, null]);

      expect(() => board.freeCells[0] = null, throwsUnsupportedError);
      expect(
        () => board.foundationLevels[FoundationSlot.f1] = 1,
        throwsUnsupportedError,
      );
      expect(() => board.columns[0] = board.columns[1], throwsUnsupportedError);
    });

    test('nested tableau columns are unmodifiable', () {
      final board = _board();

      expect(board.columns[0], isNotEmpty);
      expect(board.columns[1], isEmpty);
      expect(
        () => board.columns[0][0] = board.columns[0][1],
        throwsUnsupportedError,
      );
      expect(() => board.columns[1].add(_aceOfClubs), throwsUnsupportedError);
    });

    test('the exposed foundation map is in FoundationSlot.values order', () {
      final inserted = {
        FoundationSlot.f4: 1,
        FoundationSlot.f2: 0,
        FoundationSlot.f3: 4,
        FoundationSlot.f1: 2,
      };
      final board = _board(levels: inserted);

      expect(inserted.keys.toList(), [
        FoundationSlot.f4,
        FoundationSlot.f2,
        FoundationSlot.f3,
        FoundationSlot.f1,
      ]);
      expect(board.foundationLevels.keys.toList(), FoundationSlot.values);
      expect(board.foundationLevels.values.toList(), [2, 0, 4, 1]);
    });
  });

  group('Board equality and hashing', () {
    test('independent equal values are equal and have equal hashes', () {
      const freeCells = <Card?>[_aceOfHearts, null, _twoOfDiamonds, null];
      final levels = {
        FoundationSlot.f3: 1,
        FoundationSlot.f1: 2,
        FoundationSlot.f4: 0,
        FoundationSlot.f2: 0,
      };
      final first = _board(freeCells: freeCells, levels: levels);
      final second = _board(freeCells: freeCells, levels: levels);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('foundation map insertion order does not affect equality or hash', () {
      final forward = _board(
        levels: {
          FoundationSlot.f1: 2,
          FoundationSlot.f2: 0,
          FoundationSlot.f3: 0,
          FoundationSlot.f4: 0,
        },
      );
      final reversed = _board(
        levels: {
          FoundationSlot.f4: 0,
          FoundationSlot.f3: 0,
          FoundationSlot.f2: 0,
          FoundationSlot.f1: 2,
        },
      );

      expect(forward, reversed);
      expect(forward.hashCode, reversed.hashCode);
    });

    test('free-cell position affects equality', () {
      final firstOccupied = _board(
        freeCells: const [_aceOfClubs, _twoOfDiamonds, null, null],
      );
      final swapped = _board(
        freeCells: const [_twoOfDiamonds, _aceOfClubs, null, null],
      );

      expect(firstOccupied, isNot(swapped));
    });

    test('tableau-column position affects equality', () {
      final inFirstColumn = _board(
        fixedColumns: [
          [_aceOfClubs],
          const <Card>[],
        ],
      );
      final inSecondColumn = _board(
        fixedColumns: [
          const <Card>[],
          [_aceOfClubs],
        ],
        restColumn: 1,
      );

      expect(inFirstColumn, isNot(inSecondColumn));
    });

    test('order within a column affects equality', () {
      final forward = _board(
        fixedColumns: [
          [_aceOfClubs, _twoOfDiamonds],
        ],
      );
      final reversed = _board(
        fixedColumns: [
          [_twoOfDiamonds, _aceOfClubs],
        ],
      );

      expect(forward, isNot(reversed));
    });

    test('different positional content is unequal', () {
      final foundationsEmpty = _board();
      final aceOnFoundation = _board(levels: _levelsOf(1, 0, 0, 0));

      expect(foundationsEmpty, isNot(aceOnFoundation));
    });

    test('a board is not equal to a non-board', () {
      expect(_board() == Object(), isFalse);
    });
  });

  group('dealtBoard pre-cascade layout', () {
    test('normative identities deal empty free cells, zero foundations, and '
        'the initial columns (GD-TEST-02)', () {
      for (final value in _normativeIdentities) {
        final identity = DealIdentity(value);
        const version = ShuffleVersion.v1;
        final board = dealtBoard(identity, version);
        final cards = [for (final column in board.columns) ...column];

        expect(
          board.columns,
          initialColumns(dealPermutation(identity, version)),
          reason: '$value',
        );
        expect(board.freeCells, _emptyFreeCells, reason: '$value');
        expect(board.foundationLevels, {
          for (final slot in FoundationSlot.values) slot: 0,
        }, reason: '$value');
        expect(
          [for (final column in board.columns) column.length],
          [7, 7, 7, 7, 6, 6, 6, 6],
          reason: '$value',
        );
        expect(cards, hasLength(52), reason: '$value');
        expect(cards.toSet(), hasLength(52), reason: '$value');
        expect(
          () => board.freeCells[0] = null,
          throwsUnsupportedError,
          reason: '$value',
        );
        expect(
          () => board.foundationLevels[FoundationSlot.f1] = 1,
          throwsUnsupportedError,
          reason: '$value',
        );
        expect(
          () => board.columns[0] = board.columns[1],
          throwsUnsupportedError,
          reason: '$value',
        );
        expect(
          () => board.columns[0][0] = board.columns[0][1],
          throwsUnsupportedError,
          reason: '$value',
        );
      }
    });

    test('the same identity and version produce equal pre-cascade boards '
        '(GD-TEST-01)', () {
      for (final value in _normativeIdentities) {
        final first = dealtBoard(DealIdentity(value), ShuffleVersion.v1);
        final second = dealtBoard(DealIdentity(value), ShuffleVersion.v1);

        expect(first, second, reason: '$value');
        expect(first.hashCode, second.hashCode, reason: '$value');
      }
    });

    test('identities 0 and 1 do not produce equal boards', () {
      expect(
        dealtBoard(DealIdentity(0), ShuffleVersion.v1),
        isNot(dealtBoard(DealIdentity(1), ShuffleVersion.v1)),
      );
    });
  });
}

List<List<Card>> _onlyFirstColumn(List<Card> cards) {
  final columns = _emptyColumns();
  columns[0] = cards;
  return columns;
}

List<List<Card>> _preCascadeColumns({
  required Card exposed,
  required int exposedColumn,
}) {
  final deck = [
    for (final card in _canonicalCards())
      if (card != exposed) card,
  ];
  final columns = _emptyColumns();
  var cursor = 0;
  for (var column = 0; column < 8; column++) {
    final size = column < 4 ? 7 : 6;
    for (var depth = 0; depth < size; depth++) {
      final isExposed = column == exposedColumn && depth == size - 1;
      if (isExposed) {
        columns[column].add(exposed);
      } else {
        columns[column].add(deck[cursor]);
        cursor++;
      }
    }
  }
  return columns;
}
