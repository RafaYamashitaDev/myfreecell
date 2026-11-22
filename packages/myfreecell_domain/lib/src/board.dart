import 'card.dart';
import 'deal.dart';
import 'deal_identity.dart';
import 'foundation.dart';
import 'shuffle_version.dart';

/// Positional FreeCell board state, the board component of GD-STATE-01.
///
/// [freeCells] is FC1 through FC4. A null entry is an empty cell.
/// [foundationLevels] is F1 through F4. The exposed map is in
/// [FoundationSlot.values] order. Level n implies Ace through rank n of that
/// slot's fixed suit, with no gaps (GD-STATE-03, GD-INV-03).
/// [columns] is T1 through T8. Each column lists its cards deepest first.
///
/// This is positional card state only. It is not a game state: it has no deal
/// identity, shuffle version, move count, status, or history.
///
/// Equality compares free-cell position, foundation levels in
/// [FoundationSlot.values] order, tableau-column position, and card order
/// within each column.
///
/// The constructor checks free-cell count, foundation representation, column
/// count, and card conservation (GD-INV-01, GD-INV-02, GD-INV-03). It does not
/// check cascade exhaustion, sequence validity, move count, status,
/// restoration, or deal reproducibility.
final class Board {
  /// Creates a board from positional card state.
  ///
  /// Caller collections are snapshotted before validation, including every
  /// nested column. Those snapshots are the values checked and the values
  /// stored, so later changes to the inputs are not visible here.
  ///
  /// Throws [ArgumentError] when the position counts, foundation
  /// representation, or card conservation do not hold.
  factory Board({
    required List<Card?> freeCells,
    required Map<FoundationSlot, int> foundationLevels,
    required List<List<Card>> columns,
  }) {
    final freeCellSnapshot = List<Card?>.unmodifiable(freeCells);
    final levelSnapshot = Map<FoundationSlot, int>.unmodifiable({
      for (final slot in FoundationSlot.values)
        if (foundationLevels.containsKey(slot)) slot: foundationLevels[slot]!,
    });
    final columnSnapshot = List<List<Card>>.unmodifiable([
      for (final column in columns) List<Card>.unmodifiable(column),
    ]);

    if (freeCellSnapshot.length != 4) {
      throw ArgumentError.value(
        freeCells,
        'freeCells',
        'A board must have exactly 4 free cells',
      );
    }

    for (final slot in FoundationSlot.values) {
      if (!levelSnapshot.containsKey(slot)) {
        throw ArgumentError.value(
          foundationLevels,
          'foundationLevels',
          'Foundation levels must contain all four slots',
        );
      }
    }

    for (final slot in FoundationSlot.values) {
      final level = levelSnapshot[slot]!;
      if (level < 0 || level > 13) {
        throw ArgumentError.value(
          level,
          'level',
          'A foundation level must be between 0 and 13',
        );
      }
    }

    if (columnSnapshot.length != 8) {
      throw ArgumentError.value(
        columns,
        'columns',
        'A board must have exactly 8 tableau columns',
      );
    }

    _requireConservation(freeCellSnapshot, levelSnapshot, columnSnapshot);

    return Board._(freeCellSnapshot, levelSnapshot, columnSnapshot);
  }

  Board._(this.freeCells, this.foundationLevels, this.columns);

  /// FC1 through FC4. Null is an empty cell.
  final List<Card?> freeCells;

  /// F1 through F4 levels, exposed in [FoundationSlot.values] order.
  final Map<FoundationSlot, int> foundationLevels;

  /// T1 through T8. Cards inside a column are deepest first.
  final List<List<Card>> columns;

  @override
  bool operator ==(Object other) {
    if (other is! Board) {
      return false;
    }

    if (freeCells.length != other.freeCells.length) {
      return false;
    }
    for (var index = 0; index < freeCells.length; index++) {
      if (freeCells[index] != other.freeCells[index]) {
        return false;
      }
    }

    for (final slot in FoundationSlot.values) {
      if (foundationLevels[slot] != other.foundationLevels[slot]) {
        return false;
      }
    }

    if (columns.length != other.columns.length) {
      return false;
    }
    for (var index = 0; index < columns.length; index++) {
      final column = columns[index];
      final otherColumn = other.columns[index];
      if (column.length != otherColumn.length) {
        return false;
      }
      for (var depth = 0; depth < column.length; depth++) {
        if (column[depth] != otherColumn[depth]) {
          return false;
        }
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(freeCells),
    Object.hashAll([
      for (final slot in FoundationSlot.values) foundationLevels[slot],
    ]),
    Object.hashAll([for (final column in columns) Object.hashAll(column)]),
  );
}

/// The pre-cascade dealt board for [identity] under [version] (GD-DEAL-06,
/// GD-DEAL-08).
///
/// Free cells are empty, every foundation level is 0, and the tableau is
/// [initialColumns] of [dealPermutation]. Automatic cascade has not run. This
/// is not an Accepted New Deal state.
Board dealtBoard(DealIdentity identity, ShuffleVersion version) {
  return Board(
    freeCells: List<Card?>.filled(4, null),
    foundationLevels: const {
      FoundationSlot.f1: 0,
      FoundationSlot.f2: 0,
      FoundationSlot.f3: 0,
      FoundationSlot.f4: 0,
    },
    columns: initialColumns(dealPermutation(identity, version)),
  );
}

/// Rejects the first repeated card, then the first unseen [canonicalDeck] card.
///
/// Observation order is implied foundation cards in [FoundationSlot.values] and
/// ascending [Rank.values] order, then occupied free cells from FC1 through
/// FC4, then T1 through T8 deepest first. A total of 52 occurrences is not
/// sufficient.
void _requireConservation(
  List<Card?> freeCells,
  Map<FoundationSlot, int> foundationLevels,
  List<List<Card>> columns,
) {
  final seen = <Card>{};

  void observe(Card card) {
    if (!seen.add(card)) {
      throw ArgumentError.value(card, null, 'Duplicate card');
    }
  }

  for (final slot in FoundationSlot.values) {
    final level = foundationLevels[slot]!;
    for (final rank in Rank.values.take(level)) {
      observe(Card(rank, slot.suit));
    }
  }

  for (final card in freeCells) {
    if (card != null) {
      observe(card);
    }
  }

  for (final column in columns) {
    for (final card in column) {
      observe(card);
    }
  }

  for (final card in canonicalDeck) {
    if (!seen.contains(card)) {
      throw ArgumentError.value(card, null, 'Missing card');
    }
  }
}
