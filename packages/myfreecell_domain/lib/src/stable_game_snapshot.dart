import 'automatic_cascade.dart';
import 'board.dart';
import 'completion.dart';
import 'deal_identity.dart';
import 'game_status.dart';
import 'move_count.dart';
import 'shuffle_version.dart';

/// History-free stable content for one deal (GD-STATE-01 items 1 through 4).
///
/// This is not a complete game state: it has no history. It is not a
/// transition outcome, a serialized form, or a persistence schema.
///
/// [identity] and [shuffleVersion] are stored directly. There is no descriptor
/// and no check that they reproduce [board]. [board] must be stable.
/// [moveCount] is an `int`, not a move-count type. It must be non-negative and
/// at least the number of cards on the foundations, and it may be greater.
/// [status] is derived from [board].
final class StableGameSnapshot {
  /// Creates a stable snapshot.
  ///
  /// Rejects, in order:
  /// 1. a [moveCount] below 0, as [ArgumentError.value] named `moveCount`;
  /// 2. a [moveCount] below the number of cards on the foundations, as
  ///    [ArgumentError.value] named `moveCount`;
  /// 3. a [board] that is not stable, as [ArgumentError.value] named `board`,
  ///    with the supplied board as the invalid value.
  ///
  /// Message prose is not a compatibility contract. [identity] and
  /// [shuffleVersion] are stored as given. They are not compared with [board].
  factory StableGameSnapshot({
    required DealIdentity identity,
    required ShuffleVersion shuffleVersion,
    required Board board,
    required int moveCount,
  }) {
    if (moveCount < 0) {
      throw ArgumentError.value(
        moveCount,
        'moveCount',
        'A move count must not be negative',
      );
    }
    if (!moveCountCoversFoundationCards(moveCount, board.foundationLevels)) {
      throw ArgumentError.value(
        moveCount,
        'moveCount',
        'A move count must cover the cards already on the foundations',
      );
    }
    if (!isStableBoard(board)) {
      throw ArgumentError.value(
        board,
        'board',
        'A stable snapshot requires a board with no safe exposed card',
      );
    }
    return StableGameSnapshot._(identity, shuffleVersion, board, moveCount);
  }

  const StableGameSnapshot._(
    this.identity,
    this.shuffleVersion,
    this.board,
    this.moveCount,
  );

  /// The deal identity stored for this snapshot.
  final DealIdentity identity;

  /// The shuffle version stored for this snapshot.
  final ShuffleVersion shuffleVersion;

  /// The stable board. Retained directly because a board is immutable.
  final Board board;

  /// The move count. It may exceed the number of cards on the foundations.
  final int moveCount;

  /// [GameStatus.completed] when the foundations are complete, otherwise
  /// [GameStatus.inProgress].
  ///
  /// Derived from [board]. Not stored. Not part of equality.
  GameStatus get status => areFoundationsComplete(board.foundationLevels)
      ? GameStatus.completed
      : GameStatus.inProgress;

  @override
  bool operator ==(Object other) =>
      other is StableGameSnapshot &&
      other.identity == identity &&
      other.shuffleVersion == shuffleVersion &&
      other.board == board &&
      other.moveCount == moveCount;

  @override
  int get hashCode => Object.hash(identity, shuffleVersion, board, moveCount);
}
