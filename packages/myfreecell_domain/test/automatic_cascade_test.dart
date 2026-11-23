import 'package:myfreecell_domain/src/automatic_cascade.dart';
import 'package:myfreecell_domain/src/board.dart';
import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/completion.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/position.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:test/test.dart';

// Test-local deck and foundation table. The filler and the oracles do not
// read production canonicalDeck or FoundationSlot.suit.
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

const _foundationSuits = <Suit>[
  Suit.clubs,
  Suit.hearts,
  Suit.spades,
  Suit.diamonds,
];

const _emptyFreeCells = <Card?>[null, null, null, null];

const _dealtIdentities = <int>[0, 1, 4294967295, 3141592653];

const _aceOfClubs = Card(Rank.ace, Suit.clubs);
const _aceOfDiamonds = Card(Rank.ace, Suit.diamonds);
const _aceOfHearts = Card(Rank.ace, Suit.hearts);
const _aceOfSpades = Card(Rank.ace, Suit.spades);
const _twoOfClubs = Card(Rank.two, Suit.clubs);
const _twoOfDiamonds = Card(Rank.two, Suit.diamonds);
const _twoOfHearts = Card(Rank.two, Suit.hearts);
const _twoOfSpades = Card(Rank.two, Suit.spades);
const _threeOfClubs = Card(Rank.three, Suit.clubs);
const _fourOfClubs = Card(Rank.four, Suit.clubs);
const _fiveOfSpades = Card(Rank.five, Suit.spades);
const _sevenOfDiamonds = Card(Rank.seven, Suit.diamonds);
const _nineOfSpades = Card(Rank.nine, Suit.spades);
const _tenOfHearts = Card(Rank.ten, Suit.hearts);
const _queenOfSpades = Card(Rank.queen, Suit.spades);
const _kingOfClubs = Card(Rank.king, Suit.clubs);
const _kingOfDiamonds = Card(Rank.king, Suit.diamonds);
const _kingOfHearts = Card(Rank.king, Suit.hearts);
const _kingOfSpades = Card(Rank.king, Suit.spades);

List<Card> _canonicalCards() => [
  for (final suit in _deckSuits)
    for (final rank in _ranks) Card(rank, suit),
];

List<Card> _suitMajor(List<Suit> suits) => [
  for (final suit in suits)
    for (final rank in _ranks) Card(rank, suit),
];

FoundationSlot _slotFor(Suit suit) => switch (suit) {
  Suit.clubs => FoundationSlot.f1,
  Suit.hearts => FoundationSlot.f2,
  Suit.spades => FoundationSlot.f3,
  Suit.diamonds => FoundationSlot.f4,
};

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

/// Builds a conserved board.
///
/// Specified column cards stay in their given order, so the last specified
/// card stays exposed. Cards that the example does not place are buried under
/// [buryColumn], deeper than that column's specified cards.
Board _board({
  List<Card?> freeCells = _emptyFreeCells,
  Map<FoundationSlot, int>? levels,
  List<List<Card>> columns = const <List<Card>>[],
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

Board _buriedKing() => _board(
  columns: const [
    [_kingOfClubs],
  ],
);

AutomaticTransfer _to(Position source, FoundationSlot slot, Card card) {
  return AutomaticTransfer(
    source: source,
    destination: FoundationPosition(slot),
    card: card,
  );
}

/// Test-local safety for an already exposed card. This is GD-AUTO-02
/// conditions 2 and 3, using the test-local slot table and rank list.
bool _safe(Card card, Map<FoundationSlot, int> levels) {
  final rankNumber = _ranks.indexOf(card.rank) + 1;
  if (levels[_slotFor(card.suit)] != rankNumber - 1) {
    return false;
  }
  for (final slot in FoundationSlot.values) {
    if (levels[slot]! < rankNumber - 1) {
      return false;
    }
  }
  return true;
}

/// Test-local stability oracle. It does not call the cascade or production
/// safety.
void _expectStable(Board board) {
  for (var index = 0; index < board.freeCells.length; index++) {
    final card = board.freeCells[index];
    if (card != null) {
      expect(
        _safe(card, board.foundationLevels),
        isFalse,
        reason: 'free cell $index',
      );
    }
  }
  for (var index = 0; index < board.columns.length; index++) {
    final column = board.columns[index];
    if (column.isNotEmpty) {
      expect(
        _safe(column.last, board.foundationLevels),
        isFalse,
        reason: 'column $index',
      );
    }
  }
}

/// Boolean form of [_expectStable]. It does not call the cascade or
/// production safety.
bool _oracleStable(Board board) {
  for (var index = 0; index < board.freeCells.length; index++) {
    final card = board.freeCells[index];
    if (card != null && _safe(card, board.foundationLevels)) {
      return false;
    }
  }
  for (var index = 0; index < board.columns.length; index++) {
    final column = board.columns[index];
    if (column.isNotEmpty && _safe(column.last, board.foundationLevels)) {
      return false;
    }
  }
  return true;
}

void _expectConserved(Board board) {
  final seen = <Card>[
    ..._impliedCards(board.foundationLevels),
    ...board.freeCells.whereType<Card>(),
    for (final column in board.columns) ...column,
  ];
  expect(seen, hasLength(52));
  expect(seen.toSet(), hasLength(52));
  expect(seen.toSet(), _canonicalCards().toSet());
}

void Function() _watch(Board board) {
  final freeCells = board.freeCells;
  final levels = board.foundationLevels;
  final columns = board.columns;
  final nested = <List<Card>>[for (final column in columns) column];
  final freeCopy = <Card?>[...freeCells];
  final levelCopy = <int?>[
    for (final slot in FoundationSlot.values) levels[slot],
  ];
  final columnCopy = <List<Card>>[
    for (final column in columns) <Card>[...column],
  ];
  return () {
    expect(identical(board.freeCells, freeCells), isTrue);
    expect(identical(board.foundationLevels, levels), isTrue);
    expect(identical(board.columns, columns), isTrue);
    expect(board.freeCells, freeCopy);
    expect([
      for (final slot in FoundationSlot.values) board.foundationLevels[slot],
    ], levelCopy);
    for (var index = 0; index < nested.length; index++) {
      expect(
        identical(board.columns[index], nested[index]),
        isTrue,
        reason: 'column $index',
      );
      expect(board.columns[index], columnCopy[index], reason: 'column $index');
    }
  };
}

void _expectEvidenceAgrees(Board start, AutomaticCascadeResult result) {
  final freeCells = <Card?>[...start.freeCells];
  final columns = <List<Card>>[
    for (final column in start.columns) [...column],
  ];
  final levels = <FoundationSlot, int>{
    for (final slot in FoundationSlot.values)
      slot: start.foundationLevels[slot]!,
  };

  for (final transfer in result.transfers) {
    final exposed = switch (transfer.source) {
      FreeCellPosition(:final index) => freeCells[index],
      TableauPosition(:final index) =>
        columns[index].isEmpty ? null : columns[index].last,
      FoundationPosition() => null,
    };
    expect(
      exposed,
      transfer.card,
      reason: '${transfer.card.rank} ${transfer.card.suit}',
    );
    expect(
      _safe(transfer.card, levels),
      isTrue,
      reason: '${transfer.card.rank}',
    );
    expect(
      transfer.destination,
      FoundationPosition(_slotFor(transfer.card.suit)),
    );
    final destination = transfer.destination.slot;
    final previous = <FoundationSlot, int>{
      for (final slot in FoundationSlot.values) slot: levels[slot]!,
    };
    expect(previous[destination], _ranks.indexOf(transfer.card.rank));

    switch (transfer.source) {
      case FreeCellPosition(:final index):
        freeCells[index] = null;
      case TableauPosition(:final index):
        columns[index].removeLast();
      case FoundationPosition():
        fail('A reported cascade source is a foundation');
    }

    levels[destination] = previous[destination]! + 1;
    for (final slot in FoundationSlot.values) {
      expect(
        levels[slot],
        slot == destination ? previous[slot]! + 1 : previous[slot],
        reason: '$slot',
      );
    }
  }

  expect(result.board.freeCells, freeCells);
  expect(
    [
      for (final slot in FoundationSlot.values)
        result.board.foundationLevels[slot],
    ],
    [for (final slot in FoundationSlot.values) levels[slot]],
  );
  for (var index = 0; index < columns.length; index++) {
    expect(
      result.board.columns[index],
      columns[index],
      reason: 'column $index',
    );
  }
}

AutomaticCascadeResult _check({
  required Board input,
  required List<AutomaticTransfer> transfers,
  required Board finalBoard,
}) {
  final untouched = _watch(input);
  final result = automaticFoundationCascade(input);
  untouched();
  expect(result.transfers, transfers);
  expect(result.transfers.length, lessThanOrEqualTo(52));
  expect(result.board, finalBoard);
  _expectStable(result.board);
  _expectConserved(input);
  _expectConserved(result.board);
  _expectEvidenceAgrees(input, result);
  return result;
}

void main() {
  group('AutomaticTransfer evidence (GD-TERM-10)', () {
    test('stores the source, foundation destination, and card', () {
      final transfer = _to(
        FreeCellPosition(2),
        FoundationSlot.f3,
        _twoOfSpades,
      );

      expect(transfer.source, FreeCellPosition(2));
      expect(transfer.destination.slot, FoundationSlot.f3);
      expect(transfer.card, _twoOfSpades);
    });

    test('equal transfers are equal and hash alike', () {
      final first = _to(TableauPosition(6), FoundationSlot.f2, _aceOfHearts);
      final second = _to(TableauPosition(6), FoundationSlot.f2, _aceOfHearts);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('source, destination, and card each participate in inequality', () {
      final transfer = _to(FreeCellPosition(0), FoundationSlot.f1, _aceOfClubs);

      expect(
        transfer,
        isNot(_to(FreeCellPosition(1), FoundationSlot.f1, _aceOfClubs)),
      );
      expect(
        transfer,
        isNot(_to(TableauPosition(0), FoundationSlot.f1, _aceOfClubs)),
      );
      expect(
        transfer,
        isNot(_to(FreeCellPosition(0), FoundationSlot.f4, _aceOfClubs)),
      );
      expect(
        transfer,
        isNot(_to(FreeCellPosition(0), FoundationSlot.f1, _twoOfClubs)),
      );
      expect(transfer == Object(), isFalse);
    });

    test('destination has static type FoundationPosition', () {
      final transfer = _to(FreeCellPosition(0), FoundationSlot.f1, _aceOfClubs);
      final FoundationPosition destination = transfer.destination;

      expect(destination, isA<FoundationPosition>());
      expect(destination.slot, FoundationSlot.f1);
    });

    test('construction performs no legality check', () {
      final transfer = AutomaticTransfer(
        source: const FoundationPosition(FoundationSlot.f1),
        destination: const FoundationPosition(FoundationSlot.f2),
        card: _kingOfSpades,
      );

      expect(transfer.source, const FoundationPosition(FoundationSlot.f1));
      expect(transfer.destination.slot, FoundationSlot.f2);
      expect(transfer.card, _kingOfSpades);
    });
  });

  group('AutomaticCascadeResult', () {
    final clubs = _to(FreeCellPosition(0), FoundationSlot.f1, _aceOfClubs);
    final hearts = _to(TableauPosition(1), FoundationSlot.f2, _aceOfHearts);
    final spades = _to(TableauPosition(1), FoundationSlot.f3, _aceOfSpades);

    test('copies transfers and keeps no mutable alias', () {
      final board = _buriedKing();
      final supplied = <AutomaticTransfer>[clubs];
      final result = AutomaticCascadeResult(board: board, transfers: supplied);

      supplied.add(hearts);
      supplied[0] = hearts;

      expect(identical(result.transfers, supplied), isFalse);
      expect(result.transfers, [clubs]);
    });

    test('transfers reject add and indexed assignment', () {
      final result = AutomaticCascadeResult(
        board: _buriedKing(),
        transfers: [clubs, hearts],
      );

      expect(() => result.transfers.add(spades), throwsUnsupportedError);
      expect(() => result.transfers[0] = spades, throwsUnsupportedError);
      expect(result.transfers, [clubs, hearts]);
    });

    test('equal results are equal and hash alike', () {
      final first = AutomaticCascadeResult(
        board: _buriedKing(),
        transfers: [clubs, hearts],
      );
      final second = AutomaticCascadeResult(
        board: _buriedKing(),
        transfers: [clubs, hearts],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(
        AutomaticCascadeResult(board: _buriedKing(), transfers: const []),
        AutomaticCascadeResult(
          board: _buriedKing(),
          transfers: <AutomaticTransfer>[],
        ),
      );
    });

    test(
      'board, order, length, and elements each participate in inequality',
      () {
        final board = _buriedKing();
        final result = AutomaticCascadeResult(
          board: board,
          transfers: [clubs, hearts],
        );
        final otherBoard = _board(
          levels: _levels(1, 0, 0, 0),
          columns: const [
            [_kingOfClubs],
          ],
        );

        expect(
          result,
          isNot(
            AutomaticCascadeResult(
              board: otherBoard,
              transfers: [clubs, hearts],
            ),
          ),
        );
        expect(
          result,
          isNot(
            AutomaticCascadeResult(board: board, transfers: [hearts, clubs]),
          ),
        );
        expect(
          result,
          isNot(AutomaticCascadeResult(board: board, transfers: [clubs])),
        );
        expect(
          result,
          isNot(
            AutomaticCascadeResult(board: board, transfers: [clubs, spades]),
          ),
        );
        expect(result == Object(), isFalse);
      },
    );

    test(
      'construction does not require the transfers to produce the board',
      () {
        final board = _buriedKing();
        final result = AutomaticCascadeResult(
          board: board,
          transfers: [
            AutomaticTransfer(
              source: const FoundationPosition(FoundationSlot.f3),
              destination: const FoundationPosition(FoundationSlot.f1),
              card: _aceOfHearts,
            ),
          ],
        );

        expect(result.board, board);
        expect(result.transfers.single.card, _aceOfHearts);
      },
    );
  });

  group('automaticFoundationCascade (GD-AUTO-07, GD-AUTO-08, GD-TERM-11)', () {
    test('a stable input is unchanged and returns no transfers', () {
      final input = _buriedKing();

      _check(input: input, transfers: const [], finalBoard: input);
    });

    test('a complete input returns no transfers', () {
      final input = _board(levels: _levels(13, 13, 13, 13));

      _check(input: input, transfers: const [], finalBoard: input);
    });

    test('moves one eligible free-cell card', () {
      final input = _board(
        freeCells: const [null, _aceOfHearts, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      );
      final finalBoard = _board(
        levels: _levels(0, 1, 0, 0),
        columns: const [
          [_kingOfClubs],
        ],
      );

      _check(
        input: input,
        transfers: [_to(FreeCellPosition(1), FoundationSlot.f2, _aceOfHearts)],
        finalBoard: finalBoard,
      );
    });

    test('moves one eligible tableau card', () {
      final input = _board(
        columns: const [
          [_kingOfClubs],
          [],
          [],
          [],
          [],
          [_aceOfDiamonds],
        ],
      );
      final finalBoard = _board(
        levels: _levels(0, 0, 0, 1),
        columns: const [
          [_kingOfClubs],
        ],
      );

      _check(
        input: input,
        transfers: [_to(TableauPosition(5), FoundationSlot.f4, _aceOfDiamonds)],
        finalBoard: finalBoard,
      );
    });

    test('FC1 through FC4 priority sends each suit to its fixed slot '
        '(GD-TEST-23 automatic Ace destination aspect)', () {
      final input = _board(
        freeCells: const [
          _aceOfDiamonds,
          _aceOfClubs,
          _aceOfSpades,
          _aceOfHearts,
        ],
        columns: const [
          [_kingOfClubs],
        ],
      );
      final finalBoard = _board(
        levels: _levels(1, 1, 1, 1),
        columns: const [
          [_kingOfClubs],
        ],
      );

      _check(
        input: input,
        transfers: [
          _to(FreeCellPosition(0), FoundationSlot.f4, _aceOfDiamonds),
          _to(FreeCellPosition(1), FoundationSlot.f1, _aceOfClubs),
          _to(FreeCellPosition(2), FoundationSlot.f3, _aceOfSpades),
          _to(FreeCellPosition(3), FoundationSlot.f2, _aceOfHearts),
        ],
        finalBoard: finalBoard,
      );
    });

    test('a safe free cell is selected before a safe tableau card', () {
      final input = _board(
        freeCells: const [null, null, null, _aceOfSpades],
        columns: const [
          [_aceOfClubs],
          [_kingOfClubs],
        ],
        buryColumn: 1,
      );
      final finalBoard = _board(
        levels: _levels(1, 0, 1, 0),
        columns: const [
          [],
          [_kingOfClubs],
        ],
        buryColumn: 1,
      );

      _check(
        input: input,
        transfers: [
          _to(FreeCellPosition(3), FoundationSlot.f3, _aceOfSpades),
          _to(TableauPosition(0), FoundationSlot.f1, _aceOfClubs),
        ],
        finalBoard: finalBoard,
      );
    });

    test('T1 through T8 priority follows column order', () {
      final input = _board(
        columns: const [
          [_aceOfDiamonds],
          [_aceOfSpades],
          [_kingOfClubs],
          [],
          [_aceOfHearts],
          [],
          [],
          [_aceOfClubs],
        ],
        buryColumn: 2,
      );
      final finalBoard = _board(
        levels: _levels(1, 1, 1, 1),
        columns: const [
          [],
          [],
          [_kingOfClubs],
        ],
        buryColumn: 2,
      );

      _check(
        input: input,
        transfers: [
          _to(TableauPosition(0), FoundationSlot.f4, _aceOfDiamonds),
          _to(TableauPosition(1), FoundationSlot.f3, _aceOfSpades),
          _to(TableauPosition(4), FoundationSlot.f2, _aceOfHearts),
          _to(TableauPosition(7), FoundationSlot.f1, _aceOfClubs),
        ],
        finalBoard: finalBoard,
      );
    });

    test('restarts at FC1 after each transfer and records that order', () {
      // AD is the only card that is safe at the start. After it moves, 2C,
      // 2H, and 2S all become safe. Restarting at FC1 takes 2C, then 2H,
      // before the later column's 2S.
      final input = _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 1, 1, 0),
        columns: [
          <Card>[_twoOfHearts],
          <Card>[_kingOfClubs],
          <Card>[],
          <Card>[_aceOfDiamonds],
          <Card>[],
          <Card>[],
          <Card>[_twoOfSpades],
        ],
        buryColumn: 1,
      );
      final finalBoard = _board(
        levels: _levels(2, 2, 2, 1),
        columns: [
          <Card>[],
          <Card>[_kingOfClubs],
        ],
        buryColumn: 1,
      );

      _check(
        input: input,
        transfers: [
          _to(TableauPosition(3), FoundationSlot.f4, _aceOfDiamonds),
          _to(FreeCellPosition(0), FoundationSlot.f1, _twoOfClubs),
          _to(TableauPosition(0), FoundationSlot.f2, _twoOfHearts),
          _to(TableauPosition(6), FoundationSlot.f3, _twoOfSpades),
        ],
        finalBoard: finalBoard,
      );
    });

    test('a newly exposed card is taken before a later exposed safe card', () {
      final input = _board(
        columns: [
          <Card>[_kingOfClubs],
          <Card>[_aceOfClubs, _aceOfHearts],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[_aceOfSpades],
        ],
        buryColumn: 0,
      );
      final finalBoard = _board(
        levels: _levels(1, 1, 1, 0),
        columns: const [
          [_kingOfClubs],
        ],
      );

      _check(
        input: input,
        transfers: [
          _to(TableauPosition(1), FoundationSlot.f2, _aceOfHearts),
          _to(TableauPosition(1), FoundationSlot.f1, _aceOfClubs),
          _to(TableauPosition(6), FoundationSlot.f3, _aceOfSpades),
        ],
        finalBoard: finalBoard,
      );
    });

    test('an already exposed card moves once the preceding transfer makes it '
        'safe', () {
      final input = _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 1, 1, 0),
        columns: [
          <Card>[_kingOfClubs],
          <Card>[],
          <Card>[],
          <Card>[_aceOfDiamonds],
        ],
      );
      expect(_safe(_twoOfClubs, input.foundationLevels), isFalse);
      expect(input.freeCells.first, _twoOfClubs);
      final finalBoard = _board(
        levels: _levels(2, 1, 1, 1),
        columns: const [
          [_kingOfClubs],
        ],
      );

      _check(
        input: input,
        transfers: [
          _to(TableauPosition(3), FoundationSlot.f4, _aceOfDiamonds),
          _to(FreeCellPosition(0), FoundationSlot.f1, _twoOfClubs),
        ],
        finalBoard: finalBoard,
      );
    });

    test('an unsafe exposed card remains after another card moves', () {
      final input = _board(
        freeCells: const [_aceOfHearts, null, null, null],
        columns: const [
          [],
          [],
          [_fourOfClubs],
        ],
        buryColumn: 2,
      );
      final finalBoard = _board(
        levels: _levels(0, 1, 0, 0),
        columns: const [
          [],
          [],
          [_fourOfClubs],
        ],
        buryColumn: 2,
      );

      final result = _check(
        input: input,
        transfers: [_to(FreeCellPosition(0), FoundationSlot.f2, _aceOfHearts)],
        finalBoard: finalBoard,
      );

      expect(result.board.columns[2].last, _fourOfClubs);
      expect(_safe(_fourOfClubs, result.board.foundationLevels), isFalse);
    });

    test('separately equal boards produce equal cascades', () {
      final first = _board(
        freeCells: const [null, _aceOfHearts, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      );
      final second = _board(
        freeCells: const [null, _aceOfHearts, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      );
      expect(first, second);

      final left = automaticFoundationCascade(first);
      final right = automaticFoundationCascade(second);

      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });
  });

  group('worked examples, narrow portions only', () {
    test('E08 stable portion: 4C remains (GD-TEST-24 stable aspect)', () {
      final input = _board(
        levels: _levels(3, 1, 1, 1),
        columns: const [
          [],
          [],
          [_fourOfClubs],
        ],
        buryColumn: 2,
      );

      final result = _check(
        input: input,
        transfers: const [],
        finalBoard: input,
      );

      expect(result.board.columns[2].last, _fourOfClubs);
    });

    test('E09 order only is AH, AC, AS (GD-TEST-25 order aspect)', () {
      // Order aspect only. Move count and history are not claimed.
      final input = _board(
        columns: [
          <Card>[],
          <Card>[_fiveOfSpades, _aceOfClubs, _aceOfHearts],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[_twoOfDiamonds, _aceOfSpades],
        ],
        buryColumn: 1,
      );
      final finalBoard = _board(
        levels: _levels(1, 1, 1, 0),
        columns: [
          <Card>[],
          <Card>[_fiveOfSpades],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[],
          <Card>[_twoOfDiamonds],
        ],
        buryColumn: 1,
      );

      final result = _check(
        input: input,
        transfers: [
          _to(TableauPosition(1), FoundationSlot.f2, _aceOfHearts),
          _to(TableauPosition(1), FoundationSlot.f1, _aceOfClubs),
          _to(TableauPosition(6), FoundationSlot.f3, _aceOfSpades),
        ],
        finalBoard: finalBoard,
      );

      expect(
        [for (final transfer in result.transfers) transfer.card],
        [_aceOfHearts, _aceOfClubs, _aceOfSpades],
      );
    });

    test('E10 stable portion: 2C remains while diamonds are at 0', () {
      final input = _board(
        levels: _levels(1, 1, 1, 0),
        columns: const [
          [],
          [],
          [],
          [_twoOfClubs],
        ],
        buryColumn: 3,
      );

      final result = _check(
        input: input,
        transfers: const [],
        finalBoard: input,
      );

      expect(result.board.columns[3].last, _twoOfClubs);
      expect(_safe(_twoOfClubs, result.board.foundationLevels), isFalse);
    });

    test(
      'derived from E10: 2C cascades once every foundation is at least 1',
      () {
        // Derived fixture. The authoritative E10 portion is the stable board
        // above. Here AD is already on its foundation, and KC stays exposed so
        // the filler remains buried.
        final input = _board(
          levels: _levels(1, 1, 1, 1),
          columns: const [
            [_kingOfClubs],
            [],
            [],
            [_twoOfClubs],
          ],
        );
        final finalBoard = _board(
          levels: _levels(2, 1, 1, 1),
          columns: const [
            [_kingOfClubs],
          ],
        );

        _check(
          input: input,
          transfers: [_to(TableauPosition(3), FoundationSlot.f1, _twoOfClubs)],
          finalBoard: finalBoard,
        );
      },
    );

    test('E11 order only is 2S then 2D (GD-TEST-26 order aspect)', () {
      // Order aspect only. Move count is not claimed.
      final input = _board(
        freeCells: const [null, null, _twoOfSpades, null],
        levels: _levels(1, 1, 1, 1),
        columns: const [
          [_threeOfClubs, _twoOfDiamonds],
        ],
      );
      final finalBoard = _board(
        levels: _levels(1, 1, 2, 2),
        columns: const [
          [_threeOfClubs],
        ],
      );

      final result = _check(
        input: input,
        transfers: [
          _to(FreeCellPosition(2), FoundationSlot.f3, _twoOfSpades),
          _to(TableauPosition(0), FoundationSlot.f4, _twoOfDiamonds),
        ],
        finalBoard: finalBoard,
      );

      expect(
        [for (final transfer in result.transfers) transfer.card],
        [_twoOfSpades, _twoOfDiamonds],
      );
    });

    test('E12 cascade portion only is AD, 2C, 2H', () {
      // The board is the position after 9S has been placed on T5. The
      // deliberate move, move count, and history are not claimed.
      final input = _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 1, 1, 0),
        columns: [
          <Card>[],
          <Card>[],
          <Card>[_kingOfHearts, _aceOfDiamonds],
          <Card>[],
          <Card>[_tenOfHearts, _nineOfSpades],
          <Card>[_sevenOfDiamonds, _twoOfHearts],
        ],
        buryColumn: 2,
      );
      final finalBoard = _board(
        levels: _levels(2, 2, 1, 1),
        columns: [
          <Card>[],
          <Card>[],
          <Card>[_kingOfHearts],
          <Card>[],
          <Card>[_tenOfHearts, _nineOfSpades],
          <Card>[_sevenOfDiamonds],
        ],
        buryColumn: 2,
      );

      final result = _check(
        input: input,
        transfers: [
          _to(TableauPosition(2), FoundationSlot.f4, _aceOfDiamonds),
          _to(FreeCellPosition(0), FoundationSlot.f1, _twoOfClubs),
          _to(TableauPosition(5), FoundationSlot.f2, _twoOfHearts),
        ],
        finalBoard: finalBoard,
      );

      expect(
        [for (final transfer in result.transfers) transfer.card],
        [_aceOfDiamonds, _twoOfClubs, _twoOfHearts],
      );
    });

    test('E15 stable portion has no cascade', () {
      final input = _board(
        levels: _levels(13, 13, 11, 12),
        columns: const [
          [],
          [_queenOfSpades, _kingOfDiamonds],
          [],
          [],
          [_kingOfSpades],
        ],
      );

      final result = _check(
        input: input,
        transfers: const [],
        finalBoard: input,
      );

      expect(result.board.columns[1], const [_queenOfSpades, _kingOfDiamonds]);
      expect(result.board.columns[4], const [_kingOfSpades]);
    });

    test('E15 cascade portion only is QS then KS, with KS last', () {
      // The board is the position after KD has entered F4. The tap, move
      // count, status, and completion reporting are not claimed.
      final input = _board(
        levels: _levels(13, 13, 11, 13),
        columns: const [
          [],
          [_queenOfSpades],
          [],
          [],
          [_kingOfSpades],
        ],
      );
      final finalBoard = _board(levels: _levels(13, 13, 13, 13));

      final result = _check(
        input: input,
        transfers: [
          _to(TableauPosition(1), FoundationSlot.f3, _queenOfSpades),
          _to(TableauPosition(4), FoundationSlot.f3, _kingOfSpades),
        ],
        finalBoard: finalBoard,
      );

      final running = <FoundationSlot, int>{
        for (final slot in FoundationSlot.values)
          slot: input.foundationLevels[slot]!,
      };
      for (var index = 0; index < result.transfers.length; index++) {
        final slot = result.transfers[index].destination.slot;
        running[slot] = running[slot]! + 1;
        final total = running.values.reduce((left, right) => left + right);
        if (index == result.transfers.length - 1) {
          expect(result.transfers[index].card, _kingOfSpades);
          expect(total, 52);
        } else {
          expect(total, lessThan(52));
        }
      }
    });
  });

  group('dealt-board cascade properties', () {
    Board dealt(int value) {
      return dealtBoard(DealIdentity(value), ShuffleVersion.v1);
    }

    test('separately equal dealt boards produce equal cascades', () {
      for (final value in _dealtIdentities) {
        final first = dealt(value);
        final second = dealt(value);
        final copy = Board(
          freeCells: [...first.freeCells],
          foundationLevels: {
            for (final slot in FoundationSlot.values)
              slot: first.foundationLevels[slot]!,
          },
          columns: [
            for (final column in first.columns) [...column],
          ],
        );
        expect(first, second, reason: '$value');
        expect(first, copy, reason: '$value');

        final result = automaticFoundationCascade(first);
        expect(result, automaticFoundationCascade(second), reason: '$value');
        expect(result, automaticFoundationCascade(copy), reason: '$value');
        expect(
          result.hashCode,
          automaticFoundationCascade(second).hashCode,
          reason: '$value',
        );
      }
    });

    test('normative identities satisfy cascade properties and do not fix a '
        'sequence', () {
      for (final value in _dealtIdentities) {
        final input = dealt(value);
        expect(
          [
            for (final slot in FoundationSlot.values)
              input.foundationLevels[slot],
          ],
          [0, 0, 0, 0],
          reason: '$value',
        );
        final untouched = _watch(input);
        final result = automaticFoundationCascade(input);
        untouched();

        _expectStable(result.board);
        _expectConserved(input);
        _expectConserved(result.board);
        _expectEvidenceAgrees(input, result);

        final foundationTotal = result.board.foundationLevels.values.reduce(
          (left, right) => left + right,
        );
        expect(result.transfers, hasLength(foundationTotal), reason: '$value');
        expect(
          result.transfers.length,
          lessThanOrEqualTo(52),
          reason: '$value',
        );
      }
    });
  });

  group('maximum cascade (GD-AUTO-09)', () {
    test('52 hand-derived transfers end with every foundation at 13', () {
      // Rank by rank, and within a rank T1 diamonds, T2 spades, T3 hearts,
      // T4 clubs. After a column's card of this rank moves, the next rank is
      // exposed and is not safe until the other three suits of this rank have
      // moved. The order is therefore not suit-major.
      const columnSuits = <Suit>[
        Suit.diamonds,
        Suit.spades,
        Suit.hearts,
        Suit.clubs,
      ];
      final input = _board(
        columns: [
          for (final suit in columnSuits)
            <Card>[
              for (var index = _ranks.length - 1; index >= 0; index--)
                Card(_ranks[index], suit),
            ],
        ],
      );
      final expected = <AutomaticTransfer>[
        for (final rank in _ranks)
          for (var column = 0; column < columnSuits.length; column++)
            _to(
              TableauPosition(column),
              _slotFor(columnSuits[column]),
              Card(rank, columnSuits[column]),
            ),
      ];
      final expectedCards = [for (final transfer in expected) transfer.card];
      expect(expectedCards, hasLength(52));
      expect(expectedCards.toSet(), _canonicalCards().toSet());
      expect(expectedCards, isNot(_suitMajor(_deckSuits)));
      expect(expectedCards, isNot(_suitMajor(_foundationSuits)));
      expect(expectedCards.first, _aceOfDiamonds);
      expect(expectedCards[1], _aceOfSpades);
      expect(expectedCards[2], _aceOfHearts);
      expect(expectedCards[3], _aceOfClubs);
      expect(expectedCards[4], _twoOfDiamonds);
      expect(expectedCards.last, _kingOfClubs);
      expect(input.columns[0].first, _kingOfDiamonds);
      expect(input.columns[0].last, _aceOfDiamonds);
      expect(input.columns[3].first, _kingOfClubs);
      expect(input.columns[3].last, _aceOfClubs);

      final result = _check(
        input: input,
        transfers: expected,
        finalBoard: _board(levels: _levels(13, 13, 13, 13)),
      );
      final actualCards = [
        for (final transfer in result.transfers) transfer.card,
      ];

      expect(actualCards, isNot(_suitMajor(_deckSuits)));
      expect(actualCards, isNot(_suitMajor(_foundationSuits)));
      expect(result.transfers, hasLength(52));
      for (final slot in FoundationSlot.values) {
        expect(result.board.foundationLevels[slot], 13, reason: '$slot');
      }
      // Foundation-level property only. This does not report a completion
      // outcome.
      expect(areFoundationsComplete(result.board.foundationLevels), isTrue);

      final running = <FoundationSlot, int>{
        for (final slot in FoundationSlot.values) slot: 0,
      };
      for (var index = 0; index < result.transfers.length; index++) {
        final slot = result.transfers[index].destination.slot;
        running[slot] = running[slot]! + 1;
        final total = running.values.reduce((left, right) => left + right);
        if (index == result.transfers.length - 1) {
          expect(result.transfers[index].card, _kingOfClubs);
          expect(total, 52);
        } else {
          expect(total, lessThan(52));
        }
      }
    });
  });

  group('isStableBoard (GD-INV-06, GD-TERM-13)', () {
    Map<String, Board> handBuilt() => {
      'buried king': _buriedKing(),
      'complete': _board(levels: _levels(13, 13, 13, 13)),
      'free-cell ace': _board(
        freeCells: const [null, _aceOfHearts, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      ),
      'tableau ace': _board(
        columns: const [
          [_kingOfClubs],
          [],
          [],
          [],
          [],
          [_aceOfDiamonds],
        ],
      ),
      'unsafe two, own suit': _board(
        freeCells: const [_twoOfClubs, null, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      ),
      'unsafe two, other foundation': _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 0, 0, 0),
        columns: const [
          [_kingOfClubs],
        ],
      ),
      'buried ace': _board(
        columns: const [
          [_aceOfClubs, _kingOfClubs],
        ],
      ),
      'free-cell two': _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 1, 1, 1),
        columns: const [
          [_kingOfClubs],
        ],
      ),
      'E15 stable portion': _board(
        levels: _levels(13, 13, 11, 12),
        columns: const [
          [],
          [_queenOfSpades, _kingOfDiamonds],
          [],
          [],
          [_kingOfSpades],
        ],
      ),
      'four free-cell aces': _board(
        freeCells: const [
          _aceOfDiamonds,
          _aceOfClubs,
          _aceOfSpades,
          _aceOfHearts,
        ],
        columns: const [
          [_kingOfClubs],
        ],
      ),
    };

    List<Board> dealtBoards() => [
      for (final value in _dealtIdentities)
        dealtBoard(DealIdentity(value), ShuffleVersion.v1),
    ];

    void expectOracleAgrees(Board board, String reason) {
      final stable = isStableBoard(board);
      expect(stable, _oracleStable(board), reason: reason);
      // [_expectStable] asserts the same rule and cannot return a boolean.
      // It is available only when the board is stable.
      if (stable) {
        _expectStable(board);
      }
    }

    test('a stable incomplete board returns true', () {
      final board = _buriedKing();

      expect(isStableBoard(board), isTrue);
      _expectStable(board);
    });

    test('a complete board returns true', () {
      final board = _board(levels: _levels(13, 13, 13, 13));

      expect(isStableBoard(board), isTrue);
      _expectStable(board);
    });

    test('an eligible exposed free-cell card returns false', () {
      final board = _board(
        freeCells: const [null, _aceOfHearts, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      );

      expect(board.freeCells[1], _aceOfHearts);
      expect(_safe(_aceOfHearts, board.foundationLevels), isTrue);
      expect(isStableBoard(board), isFalse);
      expect(_oracleStable(board), isFalse);
    });

    test('an eligible exposed tableau card returns false', () {
      final board = _board(
        columns: const [
          [_kingOfClubs],
          [],
          [],
          [],
          [],
          [_aceOfDiamonds],
        ],
      );

      expect(board.columns[5].last, _aceOfDiamonds);
      expect(_safe(_aceOfDiamonds, board.foundationLevels), isTrue);
      expect(isStableBoard(board), isFalse);
      expect(_oracleStable(board), isFalse);
    });

    test('an exposed but unsafe card remains stable', () {
      final ownSuit = _board(
        freeCells: const [_twoOfClubs, null, null, null],
        columns: const [
          [_kingOfClubs],
        ],
      );
      expect(ownSuit.freeCells.first, _twoOfClubs);
      expect(_safe(_twoOfClubs, ownSuit.foundationLevels), isFalse);
      expect(isStableBoard(ownSuit), isTrue);
      _expectStable(ownSuit);

      final otherFoundation = _board(
        freeCells: const [_twoOfClubs, null, null, null],
        levels: _levels(1, 0, 0, 0),
        columns: const [
          [_kingOfClubs],
        ],
      );
      expect(otherFoundation.freeCells.first, _twoOfClubs);
      expect(_safe(_twoOfClubs, otherFoundation.foundationLevels), isFalse);
      expect(isStableBoard(otherFoundation), isTrue);
      _expectStable(otherFoundation);
    });

    test('a safe card buried under another card remains stable', () {
      final board = _board(
        columns: const [
          [_aceOfClubs, _kingOfClubs],
        ],
      );
      final column = board.columns.first;

      expect(column.last, _kingOfClubs);
      expect(column[column.length - 2], _aceOfClubs);
      expect(_safe(_aceOfClubs, board.foundationLevels), isTrue);
      expect(_safe(_kingOfClubs, board.foundationLevels), isFalse);
      expect(isStableBoard(board), isTrue);
      _expectStable(board);
    });

    test('agrees with whether the cascade has no transfers', () {
      for (final entry in handBuilt().entries) {
        expect(
          isStableBoard(entry.value),
          automaticFoundationCascade(entry.value).transfers.isEmpty,
          reason: entry.key,
        );
      }
      for (final value in _dealtIdentities) {
        final board = dealtBoard(DealIdentity(value), ShuffleVersion.v1);
        expect(
          isStableBoard(board),
          automaticFoundationCascade(board).transfers.isEmpty,
          reason: '$value',
        );
      }
    });

    test('agrees with the test-local stability oracle', () {
      for (final entry in handBuilt().entries) {
        expectOracleAgrees(entry.value, entry.key);
      }
      for (final value in _dealtIdentities) {
        expectOracleAgrees(
          dealtBoard(DealIdentity(value), ShuffleVersion.v1),
          '$value',
        );
      }
    });

    test('post-cascade boards for the normative identities are stable', () {
      for (final value in _dealtIdentities) {
        final board = automaticFoundationCascade(
          dealtBoard(DealIdentity(value), ShuffleVersion.v1),
        ).board;

        expect(isStableBoard(board), isTrue, reason: '$value');
        _expectStable(board);
        expect(_oracleStable(board), isTrue, reason: '$value');
      }
    });

    test('does not modify its input', () {
      final boards = [
        ...handBuilt().values,
        ...dealtBoards(),
        for (final value in _dealtIdentities)
          automaticFoundationCascade(
            dealtBoard(DealIdentity(value), ShuffleVersion.v1),
          ).board,
      ];
      for (final board in boards) {
        final untouched = _watch(board);
        isStableBoard(board);
        untouched();
      }
    });
  });
}
