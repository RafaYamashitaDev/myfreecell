import 'board.dart';
import 'card.dart';
import 'foundation.dart';

/// A package-internal board position (GD-TERM-02).
///
/// A position is one free cell, one foundation slot, or one tableau column.
/// Free-cell and tableau indexes are zero-based, in the same order as [Board].
/// This type has no label, no one-based index, and no serialization.
sealed class Position {
  const Position();
}

/// One free cell, FC1 through FC4, as index 0 through 3.
final class FreeCellPosition extends Position {
  /// Creates the free cell at [index].
  ///
  /// [index] must be 0 through 3. Any other value throws [ArgumentError].
  FreeCellPosition(this.index) {
    if (index < 0 || index > 3) {
      throw ArgumentError.value(
        index,
        'index',
        'A free-cell index must be between 0 and 3',
      );
    }
  }

  /// Zero-based free-cell index. 0 is the first free cell.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is FreeCellPosition && other.index == index;

  @override
  int get hashCode => Object.hash(runtimeType, index);
}

/// One foundation slot, F1 through F4.
final class FoundationPosition extends Position {
  /// Creates the position of [slot].
  const FoundationPosition(this.slot);

  /// The fixed foundation slot.
  final FoundationSlot slot;

  @override
  bool operator ==(Object other) =>
      other is FoundationPosition && other.slot == slot;

  @override
  int get hashCode => Object.hash(runtimeType, slot);
}

/// One tableau column, T1 through T8, as index 0 through 7.
final class TableauPosition extends Position {
  /// Creates the tableau column at [index].
  ///
  /// [index] must be 0 through 7. Any other value throws [ArgumentError].
  TableauPosition(this.index) {
    if (index < 0 || index > 7) {
      throw ArgumentError.value(
        index,
        'index',
        'A tableau index must be between 0 and 7',
      );
    }
  }

  /// Zero-based tableau index. 0 is the first column.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is TableauPosition && other.index == index;

  @override
  int get hashCode => Object.hash(runtimeType, index);
}

/// The card exposed at [position] on [board], or null when none is exposed
/// (GD-TERM-04).
///
/// An occupied free cell exposes its card. A nonempty tableau column exposes
/// its last card, the shallowest card, because columns are deepest first. An
/// empty free cell, an empty column, and every foundation expose nothing.
///
/// This read does not modify [board].
Card? exposedCard(Board board, Position position) {
  return switch (position) {
    FreeCellPosition(:final index) => board.freeCells[index],
    TableauPosition(:final index) =>
      board.columns[index].isEmpty ? null : board.columns[index].last,
    FoundationPosition() => null,
  };
}
