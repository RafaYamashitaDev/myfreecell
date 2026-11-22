import 'deal_identity.dart';

/// The SplitMix64 generator for shuffle version 1 (ADR-05.3).
///
/// The state and every output are unsigned 64-bit values held as native Dart
/// `int` bit patterns. A value with the top bit set is negative as an `int`.
/// Native `int` addition and multiplication wrap modulo 2^64, and `>>>` is
/// the logical right shift. This relies on the native targets of ADR-01.
final class SplitMix64 {
  /// Creates a generator whose initial state is the value of [identity].
  ///
  /// There is no seed derivation or pre-mixing step.
  SplitMix64(DealIdentity identity) : _state = identity.value;

  static const int _gamma = 0x9E3779B97F4A7C15;
  static const int _mix1 = 0xBF58476D1CE4E5B9;
  static const int _mix2 = 0x94D049BB133111EB;

  int _state;

  /// Advances the state and returns the next raw 64-bit output.
  int nextRaw() {
    _state += _gamma;
    var z = _state;
    z = (z ^ (z >>> 30)) * _mix1;
    z = (z ^ (z >>> 27)) * _mix2;
    return z ^ (z >>> 31);
  }
}

/// 2^63 - 1, the largest native `int`.
const int _maxSignedInt = 0x7FFFFFFFFFFFFFFF;

/// The rejection threshold t = 2^64 mod [bound] (ADR-05.4).
///
/// 2^64 = 2 * (2^63 - 1) + 2, so t = (2 * ((2^63 - 1) mod b) + 2) mod b.
/// No intermediate value exceeds 2 * 51 + 2.
///
/// Precondition: [bound] is between 2 and 52. Otherwise it throws
/// [ArgumentError].
int rejectionThreshold(int bound) {
  _checkBound(bound);
  return (2 * (_maxSignedInt % bound) + 2) % bound;
}

/// An unbiased draw in 0 inclusive through [bound] exclusive (ADR-05.4).
///
/// Each call to [nextRaw] yields one unsigned 64-bit value r as an `int` bit
/// pattern. If r < t, where t is [rejectionThreshold], r is rejected and
/// another value is drawn. Rejected values are consumed. An accepted r yields
/// r mod b in unsigned arithmetic.
///
/// Because 0 <= t < b <= 52, unsigned r < t holds exactly when the bit pattern
/// is nonnegative and below t. A negative bit pattern is at least 2^63
/// unsigned. Its unsigned value is r + 2^64, so its unsigned remainder is
/// (r % b + t) % b. Dart `%` is never negative for a positive divisor.
///
/// Bounds are limited to 2 through 52, the bounds used by the version-1
/// shuffle. That keeps every intermediate sum small.
///
/// Precondition: [bound] is between 2 and 52. Otherwise it throws
/// [ArgumentError] before [nextRaw] is called.
int boundedDraw(int Function() nextRaw, int bound) {
  final threshold = rejectionThreshold(bound);
  while (true) {
    final raw = nextRaw();
    if (raw >= 0 && raw < threshold) {
      continue;
    }
    if (raw >= 0) {
      return raw % bound;
    }
    return (raw % bound + threshold) % bound;
  }
}

void _checkBound(int bound) {
  if (bound < 2 || bound > 52) {
    throw ArgumentError.value(
      bound,
      'bound',
      'A draw bound must be between 2 and 52',
    );
  }
}
