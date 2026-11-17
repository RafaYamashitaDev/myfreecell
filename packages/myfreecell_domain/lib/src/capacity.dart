/// Linear movement-capacity arithmetic under GD-CAP-02 and GD-CAP-06.
///
/// Capacity is [emptyFreeCells] + [eligibleEmptyColumns] + 1. Valid counts
/// always yield a capacity of at least 1.
///
/// The caller supplies both counts from the state before the transfer
/// (GD-CAP-01). [eligibleEmptyColumns] must exclude the destination column
/// (GD-CAP-03). The source column is never counted (GD-CAP-04). Those caller
/// obligations are not checked here.
///
/// Precondition: [emptyFreeCells] and [eligibleEmptyColumns] are each at
/// least 0. A negative count throws [ArgumentError]. [emptyFreeCells] is
/// validated first.
int movementCapacity({
  required int emptyFreeCells,
  required int eligibleEmptyColumns,
}) {
  if (emptyFreeCells < 0) {
    throw ArgumentError.value(
      emptyFreeCells,
      'emptyFreeCells',
      'A count of empty spaces must not be negative',
    );
  }

  if (eligibleEmptyColumns < 0) {
    throw ArgumentError.value(
      eligibleEmptyColumns,
      'eligibleEmptyColumns',
      'A count of empty spaces must not be negative',
    );
  }

  return emptyFreeCells + eligibleEmptyColumns + 1;
}

/// Total assisting spaces required for a sequence of [sequenceLength] cards,
/// N = M - 1 (GD-CAP-05).
///
/// The result is the total required, not the shortfall from current capacity.
///
/// Precondition: [sequenceLength] is at least 1. A smaller value throws
/// [ArgumentError].
int requiredAssistingSpaces(int sequenceLength) {
  if (sequenceLength < 1) {
    throw ArgumentError.value(
      sequenceLength,
      'sequenceLength',
      'A sequence length must be at least 1',
    );
  }

  return sequenceLength - 1;
}
