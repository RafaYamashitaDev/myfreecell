import 'package:myfreecell_domain/src/board.dart';
import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/position.dart';
import 'package:test/test.dart';

// Test-local deck and foundation table. Fixtures do not read production
// canonicalDeck or FoundationSlot.suit.
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

const _emptyFreeCells = <Card?>[null, null, null, null];

const _fourOfHearts = Card(Rank.four, Suit.hearts);
const _sixOfSpades = Card(Rank.six, Suit.spades);
const _fourOfClubs = Card(Rank.four, Suit.clubs);
const _queenOfClubs = Card(Rank.queen, Suit.clubs);
const _kingOfHearts = Card(Rank.king, Suit.hearts);
const _kingOfClubs = Card(Rank.king, Suit.clubs);

List<Card> _canonicalCards() => [
  for (final suit in _deckSuits)
    for (final rank in _ranks) Card(rank, suit),
];

Suit _suitFor(FoundationSlot slot) => switch (slot) {
  FoundationSlot.f1 => Suit.clubs,
  FoundationSlot.f2 => Suit.hearts,
  FoundationSlot.f3 => Suit.spades,
  FoundationSlot.f4 => Suit.diamonds,
};

Map<FoundationSlot, int> _levels(int f1, int f2, int f3, int f4) => {
  FoundationSlot.f1: f1,
  FoundationSlot.f2: f2,
  FoundationSlot.f3: f3,
  FoundationSlot.f4: f4,
};

List<Card> _impliedCards(Map<FoundationSlot, int> levels) {
  final implied = <Card>[];
  for (final slot in FoundationSlot.values) {
    final suit = _suitFor(slot);
    final level = levels[slot]!;
    for (var index = 0; index < level; index++) {
      implied.add(Card(_ranks[index], suit));
    }
  }
  return implied;
}

Board _board({
  List<Card?> freeCells = _emptyFreeCells,
  Map<FoundationSlot, int>? levels,
  List<List<Card>> columns = const [],
  int buryColumn = 0,
}) {
  final resolvedLevels = levels ?? _levels(0, 0, 0, 0);
  final specified = List<List<Card>>.generate(8, (_) => <Card>[]);
  for (var index = 0; index < columns.length; index++) {
    specified[index] = [...columns[index]];
  }
  final placed = <Card>{
    ..._impliedCards(resolvedLevels),
    ...freeCells.whereType<Card>(),
    for (final column in specified) ...column,
  };
  final rest = <Card>[
    for (final card in _canonicalCards())
      if (!placed.contains(card)) card,
  ];
  if (rest.isNotEmpty && specified[buryColumn].isEmpty) {
    throw StateError(
      'Remainder cards would become exposed in column $buryColumn',
    );
  }
  return Board(
    freeCells: freeCells,
    foundationLevels: resolvedLevels,
    columns: [
      for (var index = 0; index < 8; index++)
        index == buryColumn
            ? <Card>[...rest, ...specified[index]]
            : <Card>[...specified[index]],
    ],
  );
}

Matcher _indexError(int index) {
  return isA<ArgumentError>()
      .having((error) => error.name, 'name', 'index')
      .having((error) => error.invalidValue, 'invalidValue', index);
}

String _variant(Position position) => switch (position) {
  FreeCellPosition() => 'free cell',
  FoundationPosition() => 'foundation',
  TableauPosition() => 'tableau',
};

Board _exposureBoard() {
  return _board(
    freeCells: const [_fourOfHearts, null, _sixOfSpades, null],
    levels: _levels(3, 0, 1, 13),
    columns: const [
      [_kingOfHearts, _fourOfClubs],
      [_queenOfClubs],
      [],
      [],
      [],
      [],
      [],
      [_kingOfClubs],
    ],
    buryColumn: 7,
  );
}

void main() {
  group('Position indexes (GD-TERM-02)', () {
    test('free-cell indexes 0 through 3 are accepted', () {
      for (var index = 0; index <= 3; index++) {
        expect(FreeCellPosition(index).index, index, reason: '$index');
      }
    });

    test('tableau indexes 0 through 7 are accepted', () {
      for (var index = 0; index <= 7; index++) {
        expect(TableauPosition(index).index, index, reason: '$index');
      }
    });

    test('invalid free-cell indexes throw ArgumentError.value', () {
      for (final index in [-1, 4, 7, 8]) {
        expect(
          () => FreeCellPosition(index),
          throwsA(_indexError(index)),
          reason: '$index',
        );
      }
    });

    test('invalid tableau indexes throw ArgumentError.value', () {
      for (final index in [-1, 8, 9]) {
        expect(
          () => TableauPosition(index),
          throwsA(_indexError(index)),
          reason: '$index',
        );
      }
    });
  });

  group('Position equality (GD-TERM-02)', () {
    test('equal free-cell positions are equal and hash alike', () {
      expect(FreeCellPosition(0), FreeCellPosition(0));
      expect(FreeCellPosition(3), FreeCellPosition(3));
      expect(FreeCellPosition(2).hashCode, FreeCellPosition(2).hashCode);
      expect(FreeCellPosition(0), isNot(FreeCellPosition(1)));
    });

    test('equal tableau positions are equal and hash alike', () {
      expect(TableauPosition(0), TableauPosition(0));
      expect(TableauPosition(7), TableauPosition(7));
      expect(TableauPosition(4).hashCode, TableauPosition(4).hashCode);
      expect(TableauPosition(6), isNot(TableauPosition(7)));
    });

    test('each foundation slot is equal only to itself', () {
      for (final slot in FoundationSlot.values) {
        final position = FoundationPosition(slot);
        expect(position.slot, slot, reason: '$slot');
        expect(position, FoundationPosition(slot), reason: '$slot');
        expect(position.hashCode, FoundationPosition(slot).hashCode);
      }

      expect(
        FoundationPosition(FoundationSlot.f1),
        isNot(FoundationPosition(FoundationSlot.f2)),
      );
      expect(
        const FoundationPosition(FoundationSlot.f3),
        FoundationPosition(FoundationSlot.f3),
      );
    });

    test('equality does not cross position variants', () {
      final positions = <Position>[
        FreeCellPosition(0),
        TableauPosition(0),
        FoundationPosition(FoundationSlot.f1),
      ];

      expect(positions.toSet(), hasLength(3));
      expect(FreeCellPosition(1), isNot(TableauPosition(1)));
      expect(FreeCellPosition(0), isNot(FoundationPosition(FoundationSlot.f1)));
      expect(TableauPosition(0), isNot(FoundationPosition(FoundationSlot.f1)));
      expect(FreeCellPosition(0) == Object(), isFalse);
      expect(TableauPosition(0) == Object(), isFalse);
      expect(FoundationPosition(FoundationSlot.f4) == Object(), isFalse);
    });

    test('the sealed hierarchy is the three position variants', () {
      final positions = <Position>[
        FreeCellPosition(1),
        FoundationPosition(FoundationSlot.f3),
        TableauPosition(7),
      ];

      expect(
        [for (final position in positions) _variant(position)],
        ['free cell', 'foundation', 'tableau'],
      );
      expect(positions.map((position) => position.runtimeType).toSet(), {
        FreeCellPosition,
        FoundationPosition,
        TableauPosition,
      });
    });
  });

  group('exposedCard (GD-TERM-04)', () {
    test(
      'occupied free cells return their cards and empty cells return null',
      () {
        final board = _exposureBoard();

        expect(exposedCard(board, FreeCellPosition(0)), _fourOfHearts);
        expect(exposedCard(board, FreeCellPosition(1)), isNull);
        expect(exposedCard(board, FreeCellPosition(2)), _sixOfSpades);
        expect(exposedCard(board, FreeCellPosition(3)), isNull);
      },
    );

    test('a nonempty column exposes its last card because columns are '
        'deepest first', () {
      final board = _exposureBoard();

      expect(board.columns[0], const [_kingOfHearts, _fourOfClubs]);
      expect(board.columns[0].first, _kingOfHearts);
      expect(exposedCard(board, TableauPosition(0)), _fourOfClubs);
      expect(exposedCard(board, TableauPosition(0)), isNot(_kingOfHearts));
    });

    test('a one-card column exposes that card', () {
      final board = _exposureBoard();

      expect(board.columns[1], const [_queenOfClubs]);
      expect(exposedCard(board, TableauPosition(1)), _queenOfClubs);
    });

    test('an empty column exposes nothing', () {
      final board = _exposureBoard();

      expect(board.columns[2], isEmpty);
      expect(exposedCard(board, TableauPosition(2)), isNull);
      expect(exposedCard(board, TableauPosition(6)), isNull);
    });

    test('foundations expose nothing, including nonzero levels', () {
      final board = _exposureBoard();

      expect(
        [
          for (final slot in FoundationSlot.values)
            board.foundationLevels[slot],
        ],
        [3, 0, 1, 13],
      );
      for (final slot in FoundationSlot.values) {
        expect(
          exposedCard(board, FoundationPosition(slot)),
          isNull,
          reason: '$slot',
        );
      }
    });

    test('exposedCard does not alter the board', () {
      final board = _exposureBoard();
      final twin = _exposureBoard();
      final freeCells = board.freeCells;
      final levels = board.foundationLevels;
      final columns = board.columns;
      final nested = [for (final column in columns) column];

      final positions = <Position>[
        for (var index = 0; index < 4; index++) FreeCellPosition(index),
        for (final slot in FoundationSlot.values) FoundationPosition(slot),
        for (var index = 0; index < 8; index++) TableauPosition(index),
      ];
      for (final position in positions) {
        exposedCard(board, position);
      }

      expect(identical(board.freeCells, freeCells), isTrue);
      expect(identical(board.foundationLevels, levels), isTrue);
      expect(identical(board.columns, columns), isTrue);
      for (var index = 0; index < nested.length; index++) {
        expect(identical(board.columns[index], nested[index]), isTrue);
      }
      expect(board, twin);
    });
  });
}
