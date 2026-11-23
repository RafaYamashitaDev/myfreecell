import 'package:myfreecell_domain/src/automatic_cascade.dart';
import 'package:myfreecell_domain/src/board.dart';
import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/foundation.dart';
import 'package:myfreecell_domain/src/game_status.dart';
import 'package:myfreecell_domain/src/initial_game_snapshot.dart';
import 'package:myfreecell_domain/src/position.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:test/test.dart';

// The four normative identities. Transfer counts and statuses are derived,
// not frozen.
const _identities = <int>[0, 1, 4294967295, 3141592653];

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

FoundationSlot _slotFor(Suit suit) => switch (suit) {
  Suit.clubs => FoundationSlot.f1,
  Suit.hearts => FoundationSlot.f2,
  Suit.spades => FoundationSlot.f3,
  Suit.diamonds => FoundationSlot.f4,
};

/// Test-local safety for an exposed card. Conditions 2 and 3 of GD-AUTO-02.
bool _locallySafe(Card card, Map<FoundationSlot, int> levels) {
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

/// Test-local stability. It does not call the cascade or production safety.
bool _locallyStable(Board board) {
  for (final card in board.freeCells) {
    if (card != null && _locallySafe(card, board.foundationLevels)) {
      return false;
    }
  }
  for (final column in board.columns) {
    if (column.isNotEmpty &&
        _locallySafe(column.last, board.foundationLevels)) {
      return false;
    }
  }
  return true;
}

int _foundationTotal(Board board) {
  var total = 0;
  for (final slot in FoundationSlot.values) {
    total += board.foundationLevels[slot]!;
  }
  return total;
}

GameStatus _statusFromTotal(int total) =>
    total == 52 ? GameStatus.completed : GameStatus.inProgress;

bool _sameTransfers(InitialGameSnapshot left, InitialGameSnapshot right) {
  if (left.transfers.length != right.transfers.length) {
    return false;
  }
  for (var index = 0; index < left.transfers.length; index++) {
    if (left.transfers[index] != right.transfers[index]) {
      return false;
    }
  }
  return true;
}

bool _fullValueDiffers(InitialGameSnapshot left, InitialGameSnapshot right) {
  final leftState = left.state;
  final rightState = right.state;
  return leftState.identity != rightState.identity ||
      leftState.shuffleVersion != rightState.shuffleVersion ||
      leftState.board != rightState.board ||
      leftState.moveCount != rightState.moveCount ||
      !_sameTransfers(left, right);
}

void main() {
  group('initialGameSnapshot', () {
    test('two calls are equal, hash alike, and are distinct objects', () {
      for (final value in _identities) {
        final identity = DealIdentity(value);
        final first = initialGameSnapshot(identity, ShuffleVersion.v1);
        final second = initialGameSnapshot(identity, ShuffleVersion.v1);

        expect(first, second, reason: '$value');
        expect(first.hashCode, second.hashCode, reason: '$value');
        expect(identical(first, second), isFalse, reason: '$value');
      }
    });

    test('the board and transfers reproduce the cascade', () {
      for (final value in _identities) {
        final identity = DealIdentity(value);
        final result = initialGameSnapshot(identity, ShuffleVersion.v1);
        final cascade = automaticFoundationCascade(
          dealtBoard(identity, ShuffleVersion.v1),
        );

        expect(result.state.board, cascade.board, reason: '$value');
        expect(
          result.transfers.length,
          cascade.transfers.length,
          reason: '$value',
        );
        for (var index = 0; index < cascade.transfers.length; index++) {
          expect(
            result.transfers[index],
            cascade.transfers[index],
            reason: '$value index $index',
          );
        }
      }
    });

    test('move count is the transfer length and the foundation total', () {
      for (final value in _identities) {
        final result = initialGameSnapshot(
          DealIdentity(value),
          ShuffleVersion.v1,
        );

        expect(
          result.state.moveCount,
          result.transfers.length,
          reason: '$value',
        );
        expect(
          result.state.moveCount,
          _foundationTotal(result.state.board),
          reason: '$value',
        );
      }
    });

    test('the board is stable and the local oracle agrees', () {
      for (final value in _identities) {
        final result = initialGameSnapshot(
          DealIdentity(value),
          ShuffleVersion.v1,
        );

        expect(isStableBoard(result.state.board), isTrue, reason: '$value');
        expect(_locallyStable(result.state.board), isTrue, reason: '$value');
      }
    });

    test('identity and the supplied shuffle version are retained', () {
      for (final value in _identities) {
        final identity = DealIdentity(value);
        final result = initialGameSnapshot(identity, ShuffleVersion.v1);

        expect(identical(result.state.identity, identity), isTrue);
        expect(result.state.identity.value, value, reason: '$value');
        expect(result.state.shuffleVersion, ShuffleVersion.v1);
      }
    });

    test('status agrees with the local foundation total', () {
      for (final value in _identities) {
        final result = initialGameSnapshot(
          DealIdentity(value),
          ShuffleVersion.v1,
        );
        final total = _foundationTotal(result.state.board);

        expect(result.state.status, _statusFromTotal(total), reason: '$value');
      }
    });

    test('transfers are unmodifiable and distinct across calls', () {
      final probe = AutomaticTransfer(
        source: FreeCellPosition(0),
        destination: const FoundationPosition(FoundationSlot.f1),
        card: const Card(Rank.ace, Suit.clubs),
      );

      for (final value in _identities) {
        final identity = DealIdentity(value);
        final first = initialGameSnapshot(identity, ShuffleVersion.v1);
        final second = initialGameSnapshot(identity, ShuffleVersion.v1);
        final before = [for (final transfer in first.transfers) transfer];

        expect(
          () => first.transfers.add(probe),
          throwsUnsupportedError,
          reason: '$value',
        );
        if (first.transfers.isNotEmpty) {
          expect(
            () => first.transfers[0] = probe,
            throwsUnsupportedError,
            reason: '$value',
          );
        }
        expect(first.transfers, before, reason: '$value');
        expect(
          identical(first.transfers, second.transfers),
          isFalse,
          reason: '$value',
        );
      }
    });

    test('different identities are unequal when the full values differ', () {
      final results = [
        for (final value in _identities)
          initialGameSnapshot(DealIdentity(value), ShuffleVersion.v1),
      ];

      var compared = 0;
      for (var left = 0; left < results.length; left++) {
        for (var right = left + 1; right < results.length; right++) {
          compared++;
          if (_fullValueDiffers(results[left], results[right])) {
            expect(results[left], isNot(results[right]));
          } else {
            expect(results[left], results[right]);
          }
        }
      }

      expect(compared, 6);
      expect(results.toSet().length, greaterThan(1));
    });
  });
}
