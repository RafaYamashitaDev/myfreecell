import 'package:myfreecell_domain/src/board.dart';
import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/game_status.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:myfreecell_domain/src/stable_game_snapshot.dart';
import 'package:test/test.dart';

// Local fixtures. They do not read production canonicalDeck.
const _kingOfClubs = Card(Rank.king, Suit.clubs);
const _aceOfHearts = Card(Rank.ace, Suit.hearts);
const _twoOfClubs = Card(Rank.two, Suit.clubs);
const _queenOfSpades = Card(Rank.queen, Suit.spades);
const _kingOfSpades = Card(Rank.king, Suit.spades);

Map<FoundationSlot, int> _levels(int f1, int f2, int f3, int f4) => {
  FoundationSlot.f1: f1,
  FoundationSlot.f2: f2,
  FoundationSlot.f3: f3,
  FoundationSlot.f4: f4,
};

List<Card> _canonical() => [
  for (final suit in Suit.values)
    for (final rank in Rank.values) Card(rank, suit),
];

List<Card> _implied(Map<FoundationSlot, int> levels) {
  final implied = <Card>[];
  for (final slot in FoundationSlot.values) {
    for (final rank in Rank.values.take(levels[slot]!)) {
      implied.add(Card(rank, slot.suit));
    }
  }
  return implied;
}

/// Builds a conserved board. Remainder cards are buried under [buryColumn].
Board _board({
  List<Card?> freeCells = const [null, null, null, null],
  Map<FoundationSlot, int>? levels,
  List<List<Card>> columns = const [],
  int buryColumn = 0,
}) {
  final resolved = levels ?? _levels(0, 0, 0, 0);
  final specified = List<List<Card>>.generate(8, (_) => <Card>[]);
  for (var index = 0; index < columns.length; index++) {
    specified[index] = [...columns[index]];
  }
  final placed = <Card>{
    ..._implied(resolved),
    ...freeCells.whereType<Card>(),
    for (final column in specified) ...column,
  };
  final rest = <Card>[
    for (final card in _canonical())
      if (!placed.contains(card)) card,
  ];
  if (rest.isNotEmpty && specified[buryColumn].isEmpty) {
    throw StateError(
      'Remainder cards would become exposed in column $buryColumn',
    );
  }
  return Board(
    freeCells: freeCells,
    foundationLevels: resolved,
    columns: [
      for (var index = 0; index < 8; index++)
        index == buryColumn
            ? <Card>[...rest, ...specified[index]]
            : <Card>[...specified[index]],
    ],
  );
}

int _foundationTotal(Board board) {
  var total = 0;
  for (final slot in FoundationSlot.values) {
    total += board.foundationLevels[slot]!;
  }
  return total;
}

GameStatus _statusFromBoard(Board board) => _foundationTotal(board) == 52
    ? GameStatus.completed
    : GameStatus.inProgress;

Board _stableZero() => _board(
  columns: const [
    [_kingOfClubs],
  ],
);

Board _stableSix() => _board(
  levels: _levels(2, 1, 0, 3),
  columns: const [
    [_kingOfClubs],
  ],
);

Board _complete() => _board(levels: _levels(13, 13, 13, 13));

Board _unstableZero() => _board(
  freeCells: const [null, null, _aceOfHearts, null],
  columns: const [
    [_kingOfClubs],
  ],
);

Board _unstableFour() => _board(
  freeCells: const [_twoOfClubs, null, null, null],
  levels: _levels(1, 1, 1, 1),
  columns: const [
    [_kingOfClubs],
  ],
);

/// Spades at 11, with the queen buried under the king. Foundation total 50.
Board _stableFifty() => _board(
  levels: _levels(13, 13, 11, 13),
  columns: const [
    [],
    [],
    [],
    [],
    [_queenOfSpades, _kingOfSpades],
  ],
);

/// The conserved shape of foundation total 51: one exposed king.
Board _unstableFiftyOne() => _board(
  levels: _levels(13, 13, 12, 13),
  columns: const [
    [_kingOfSpades],
  ],
);

StableGameSnapshot _snapshot(
  Board board,
  int moveCount, {
  DealIdentity? identity,
}) {
  return StableGameSnapshot(
    identity: identity ?? DealIdentity(0),
    shuffleVersion: ShuffleVersion.v1,
    board: board,
    moveCount: moveCount,
  );
}

Matcher _moveCountError(int moveCount) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', moveCount)
      .having((error) => error.name, 'name', 'moveCount');
}

Matcher _boardError(Board board) {
  return isA<ArgumentError>()
      .having((error) => error.invalidValue, 'invalidValue', same(board))
      .having((error) => error.name, 'name', 'board');
}

void main() {
  group('GameStatus', () {
    test('values are inProgress then completed', () {
      expect(GameStatus.values, [GameStatus.inProgress, GameStatus.completed]);
    });
  });

  group('StableGameSnapshot validation', () {
    test('a negative move count is rejected', () {
      final board = _stableZero();

      expect(() => _snapshot(board, -1), throwsA(_moveCountError(-1)));
    });

    test('a move count below the foundation total is rejected', () {
      final board = _stableSix();
      expect(_foundationTotal(board), 6);

      expect(() => _snapshot(board, 5), throwsA(_moveCountError(5)));
    });

    test('an unstable board is rejected', () {
      final board = _unstableZero();

      expect(() => _snapshot(board, 0), throwsA(_boardError(board)));
    });

    test('an unstable board and a negative count report moveCount', () {
      final board = _unstableFour();

      expect(() => _snapshot(board, -1), throwsA(_moveCountError(-1)));
    });

    test('an unstable board and a below-total count report moveCount', () {
      final board = _unstableFour();
      expect(_foundationTotal(board), 4);

      expect(() => _snapshot(board, 3), throwsA(_moveCountError(3)));
    });

    test('an unstable board and a sufficient count report the board', () {
      final board = _unstableFour();

      expect(() => _snapshot(board, 4), throwsA(_boardError(board)));
    });

    test('foundation total 51 is an exposed safe king and is rejected', () {
      // Three foundations at 13 and one at 12 leave that suit's king as the
      // only off-foundation card. The king is exposed and safe, so this total
      // cannot be a stable snapshot.
      final board = _unstableFiftyOne();
      expect(_foundationTotal(board), 51);

      expect(() => _snapshot(board, 51), throwsA(_boardError(board)));
    });
  });

  group('StableGameSnapshot acceptance', () {
    test('a count equal to the foundation total is accepted', () {
      final board = _stableSix();

      expect(_snapshot(board, 6).moveCount, 6);
    });

    test('a count above the foundation total is accepted', () {
      final board = _stableSix();

      expect(_snapshot(board, 7).moveCount, 7);
    });

    test('a count of zero on a stable zero-foundation board is accepted', () {
      final board = _stableZero();
      expect(_foundationTotal(board), 0);

      expect(_snapshot(board, 0).moveCount, 0);
    });

    test('a complete board accepts a count of 52', () {
      final board = _complete();
      expect(_foundationTotal(board), 52);

      expect(_snapshot(board, 52).moveCount, 52);
    });

    test('a complete board accepts a count greater than 52', () {
      expect(_snapshot(_complete(), 53).moveCount, 53);
    });
  });

  group('StableGameSnapshot status', () {
    test('a stable incomplete board is in progress', () {
      expect(_snapshot(_stableZero(), 0).status, GameStatus.inProgress);
      expect(_snapshot(_stableSix(), 6).status, GameStatus.inProgress);
    });

    test('a stable board with foundation total 50 is in progress', () {
      // Foundation total 51 is not stable. See the validation group. Total 50
      // keeps the queen of spades buried under its king, with spades at 11.
      final board = _stableFifty();
      expect(_foundationTotal(board), 50);

      expect(_snapshot(board, 50).status, GameStatus.inProgress);
    });

    test('a complete board is completed', () {
      expect(_snapshot(_complete(), 52).status, GameStatus.completed);
      expect(_snapshot(_complete(), 60).status, GameStatus.completed);
    });

    test('status is derived from the board', () {
      final board = _stableSix();
      final low = _snapshot(board, 6);
      final high = _snapshot(board, 20);

      expect(low.status, GameStatus.inProgress);
      expect(high.status, low.status);
      expect(low.status, _statusFromBoard(board));
      expect(low, isNot(high));

      final complete = _complete();
      final done = _snapshot(complete, 52);
      final later = _snapshot(complete, 80);
      expect(done.status, GameStatus.completed);
      expect(later.status, done.status);
      expect(done.status, _statusFromBoard(complete));
      expect(done.status, isNot(low.status));
    });
  });

  group('StableGameSnapshot retention', () {
    test('identity, version, board, and move count are retained', () {
      final identity = DealIdentity(42);
      final board = _stableZero();
      const version = ShuffleVersion.v1;
      final snapshot = StableGameSnapshot(
        identity: identity,
        shuffleVersion: version,
        board: board,
        moveCount: 0,
      );

      expect(identical(snapshot.identity, identity), isTrue);
      expect(identical(snapshot.shuffleVersion, version), isTrue);
      expect(identical(snapshot.board, board), isTrue);
      expect(snapshot.moveCount, 0);
    });
  });

  group('StableGameSnapshot equality', () {
    test('separately constructed equal snapshots are equal and hash alike', () {
      final first = _snapshot(_stableSix(), 6, identity: DealIdentity(4));
      final second = _snapshot(_stableSix(), 6, identity: DealIdentity(4));

      expect(identical(first, second), isFalse);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.status, second.status);
    });

    test('identity, board, and move count each participate in inequality', () {
      final board = _stableSix();
      final snapshot = _snapshot(board, 6, identity: DealIdentity(4));

      expect(snapshot, isNot(_snapshot(board, 6, identity: DealIdentity(5))));
      expect(
        snapshot,
        isNot(_snapshot(_stableZero(), 6, identity: DealIdentity(4))),
      );
      expect(snapshot, isNot(_snapshot(board, 7, identity: DealIdentity(4))));

      final complete = _snapshot(_complete(), 52, identity: DealIdentity(4));
      final open = _snapshot(_stableZero(), 52, identity: DealIdentity(4));
      expect(complete.identity, open.identity);
      expect(complete.shuffleVersion, open.shuffleVersion);
      expect(complete.moveCount, open.moveCount);
      expect(complete, isNot(open));
      expect(snapshot == Object(), isFalse);
      // ShuffleVersion has only v1, so an unequal version is not representable.
    });
  });
}
