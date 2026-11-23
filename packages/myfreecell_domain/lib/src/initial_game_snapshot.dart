import 'automatic_cascade.dart';
import 'board.dart';
import 'deal_identity.dart';
import 'shuffle_version.dart';
import 'stable_game_snapshot.dart';

/// The stable snapshot and ordered automatic transfers of one initialization.
///
/// This is not an Accepted result, a request result, a transition, a
/// transaction, or a complete game state. Construction copies [transfers] and
/// does not check that those transfers produced [state].
final class InitialGameSnapshot {
  InitialGameSnapshot._(this.state, List<AutomaticTransfer> transfers)
    : transfers = List<AutomaticTransfer>.unmodifiable(transfers);

  /// The stable snapshot after the initial cascade.
  final StableGameSnapshot state;

  /// The ordered automatic transfers supplied for this initialization.
  final List<AutomaticTransfer> transfers;

  @override
  bool operator ==(Object other) {
    if (other is! InitialGameSnapshot) {
      return false;
    }
    if (state != other.state) {
      return false;
    }
    if (transfers.length != other.transfers.length) {
      return false;
    }
    for (var index = 0; index < transfers.length; index++) {
      if (transfers[index] != other.transfers[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(state, Object.hashAll(transfers));
}

/// Reproduces the initial stable snapshot for [identity] under [version].
///
/// The pipeline is:
/// 1. [dealtBoard] for [identity] and [version];
/// 2. [automaticFoundationCascade] on that board;
/// 3. the move count is the number of cascade transfers;
/// 4. a [StableGameSnapshot] of [identity], [version], the cascade board, and
///    that count;
/// 5. this result, holding that snapshot and the cascade transfers.
///
/// [version] is required. This does not read [ShuffleVersion.current], draw
/// random numbers, compare identities, classify Accepted or Invalid, or build
/// history. It does not build a pre-cascade snapshot with move count zero.
/// A failure inside the snapshot check propagates; it is not caught.
///
/// The resulting status may be completed when the cascade finishes the
/// foundations. There is no separate completion behavior.
InitialGameSnapshot initialGameSnapshot(
  DealIdentity identity,
  ShuffleVersion version,
) {
  final cascade = automaticFoundationCascade(dealtBoard(identity, version));
  final state = StableGameSnapshot(
    identity: identity,
    shuffleVersion: version,
    board: cascade.board,
    moveCount: cascade.transfers.length,
  );
  return InitialGameSnapshot._(state, cascade.transfers);
}
