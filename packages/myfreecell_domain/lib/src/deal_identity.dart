/// An internal deal identity (GD-DEAL-01, ADR-05.2).
///
/// The value is an integer from [min] through [max] inclusive. For shuffle
/// version 1, it is the initial SplitMix64 state, with no pre-mixing.
/// Equality is by numeric value.
final class DealIdentity {
  /// Creates an identity from [value].
  ///
  /// A value outside [min] through [max] throws [ArgumentError]. No substitute
  /// identity is used.
  DealIdentity(int value) : value = _validated(value);

  /// The smallest valid identity.
  static const int min = 0;

  /// The largest valid identity, 4,294,967,295.
  static const int max = 0xFFFFFFFF;

  /// The numeric value of this identity.
  final int value;

  static int _validated(int value) {
    if (value < min || value > max) {
      throw ArgumentError.value(
        value,
        'value',
        'A deal identity must be between 0 and 4294967295',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is DealIdentity && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
