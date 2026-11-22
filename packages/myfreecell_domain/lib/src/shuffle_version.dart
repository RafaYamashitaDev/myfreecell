/// The closed set of supported shuffle-function versions (GD-DEAL-03,
/// ADR-05.5).
///
/// [number] is the persisted representation. The enum index and name are not.
enum ShuffleVersion {
  v1(1);

  const ShuffleVersion(this.number);

  /// The positive version number that identifies this version.
  final int number;

  /// The version used for new deals.
  static const ShuffleVersion current = ShuffleVersion.v1;

  /// The supported version identified by [number].
  ///
  /// A number below 1 is invalid. A positive number outside the supported set
  /// is unsupported. Both throw [ArgumentError] with no fallback.
  static ShuffleVersion fromNumber(int number) {
    if (number < 1) {
      throw ArgumentError.value(
        number,
        'number',
        'A shuffle version must be a positive integer',
      );
    }
    return switch (number) {
      1 => ShuffleVersion.v1,
      _ => throw ArgumentError.value(
        number,
        'number',
        'Unsupported shuffle version',
      ),
    };
  }
}
