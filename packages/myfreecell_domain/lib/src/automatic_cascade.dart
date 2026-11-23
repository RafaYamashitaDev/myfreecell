import 'board.dart';
import 'card.dart';
import 'foundation.dart';
import 'position.dart';
import 'safety.dart';

/// Evidence of one automatic foundation transfer (GD-TERM-10).
///
/// This records the source position, the fixed foundation destination, and the
/// single card. It is not a general transfer: it has no before or after board,
/// no manual flag, and no card sequence.
///
/// The constructor stores those values. It does not read a [Board] and it does
/// not decide whether the transfer is legal.
final class AutomaticTransfer {
  /// Records [card] moving from [source] to [destination].
  const AutomaticTransfer({
    required this.source,
    required this.destination,
    required this.card,
  });

  /// The free cell or tableau column the card left.
  final Position source;

  /// The foundation position the card entered.
  final FoundationPosition destination;

  /// The card that moved.
  final Card card;

  @override
  bool operator ==(Object other) =>
      other is AutomaticTransfer &&
      other.source == source &&
      other.destination == destination &&
      other.card == card;

  @override
  int get hashCode => Object.hash(source, destination, card);
}

/// The board and ordered automatic transfers from one cascade (GD-TERM-11).
///
/// [transfers] is a defensive copy exposed as an unmodifiable list. Equality
/// compares [board] and that list in order.
///
/// This is the result of [automaticFoundationCascade] only. It is not a
/// completion outcome, a move count, a status, or a game-state transition.
/// Construction does not check that [transfers] produced [board].
final class AutomaticCascadeResult {
  /// Stores [board] and a defensive copy of [transfers].
  AutomaticCascadeResult({
    required this.board,
    required List<AutomaticTransfer> transfers,
  }) : transfers = List<AutomaticTransfer>.unmodifiable(transfers);

  /// The board after every recorded transfer.
  final Board board;

  /// The automatic transfers, in application order.
  final List<AutomaticTransfer> transfers;

  @override
  bool operator ==(Object other) {
    if (other is! AutomaticCascadeResult) {
      return false;
    }
    if (board != other.board) {
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
  int get hashCode => Object.hash(board, Object.hashAll(transfers));
}

/// Runs one deterministic automatic foundation cascade on [board]
/// (GD-AUTO-07, GD-AUTO-08, GD-TERM-11).
///
/// The scan visits free-cell indexes 0 through 3, then tableau indexes 0
/// through 7, using [exposedCard]. The first exposed card for which
/// [hasSafeFoundationLevels] is true moves to the foundation slot whose
/// [FoundationSlot.suit] equals the card's suit. The scan then starts again at
/// free cell 0. It stops when a complete scan finds no such card.
///
/// Each step removes that one card and increments that one foundation level,
/// then rebuilds a [Board] through its validating constructor. [board] and the
/// collections it owns are not modified. Foundations are not sources.
///
/// A board that is already stable, including a board whose foundations are
/// complete, returns that board and no transfers.
AutomaticCascadeResult automaticFoundationCascade(Board board) {
  var current = board;
  final transfers = <AutomaticTransfer>[];
  var next = _nextAutomaticTransfer(current);
  while (next != null) {
    transfers.add(next);
    current = _boardAfterAutomaticTransfer(current, next);
    next = _nextAutomaticTransfer(current);
  }
  return AutomaticCascadeResult(board: current, transfers: transfers);
}

AutomaticTransfer? _nextAutomaticTransfer(Board board) {
  for (var index = 0; index < 4; index++) {
    final position = FreeCellPosition(index);
    final card = exposedCard(board, position);
    if (card != null && hasSafeFoundationLevels(card, board.foundationLevels)) {
      return AutomaticTransfer(
        source: position,
        destination: FoundationPosition(_foundationSlotFor(card.suit)),
        card: card,
      );
    }
  }

  for (var index = 0; index < 8; index++) {
    final position = TableauPosition(index);
    final card = exposedCard(board, position);
    if (card != null && hasSafeFoundationLevels(card, board.foundationLevels)) {
      return AutomaticTransfer(
        source: position,
        destination: FoundationPosition(_foundationSlotFor(card.suit)),
        card: card,
      );
    }
  }

  return null;
}

FoundationSlot _foundationSlotFor(Suit suit) {
  for (final slot in FoundationSlot.values) {
    if (slot.suit == suit) {
      return slot;
    }
  }
  throw StateError('No foundation slot is assigned to $suit');
}

/// Rebuilds [board] with [transfer] applied.
///
/// Copies every collection first. A foundation source throws [StateError].
/// That throw is defensive internal failure handling: this cascade never
/// selects a foundation source, and the throw is not a gameplay rejection.
Board _boardAfterAutomaticTransfer(Board board, AutomaticTransfer transfer) {
  final freeCells = <Card?>[for (final card in board.freeCells) card];
  final columns = <List<Card>>[
    for (final column in board.columns) <Card>[...column],
  ];

  switch (transfer.source) {
    case FreeCellPosition(:final index):
      freeCells[index] = null;
    case TableauPosition(:final index):
      columns[index].removeLast();
    case FoundationPosition():
      throw StateError('Automatic cascade cannot transfer from a foundation');
  }

  final levels = <FoundationSlot, int>{
    for (final slot in FoundationSlot.values)
      slot: board.foundationLevels[slot]!,
  };
  final destination = transfer.destination.slot;
  levels[destination] = levels[destination]! + 1;

  return Board(
    freeCells: freeCells,
    foundationLevels: levels,
    columns: columns,
  );
}
