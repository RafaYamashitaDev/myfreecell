import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:test/test.dart';

void main() {
  // Native 64-bit integer extremes, written as bit patterns.
  const largestInt = 0x7FFFFFFFFFFFFFFF;
  const smallestInt = 0x8000000000000000;

  Matcher rangeError(int invalidValue) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', invalidValue)
        .having((error) => error.name, 'name', 'value')
        .having(
          (error) => error.message,
          'message',
          'A deal identity must be between 0 and 4294967295',
        );
  }

  group('DealIdentity range fails closed (ADR-05.2, ADR-05.7, ADR-11.2, '
      'GD-DEAL-01)', () {
    test('the bounds are 0 and 4294967295', () {
      expect(DealIdentity.min, 0);
      expect(DealIdentity.max, 4294967295);
    });

    test('the minimum, maximum, and interior values keep their value', () {
      for (final value in [
        0,
        1,
        2,
        65535,
        65536,
        2147483647,
        2147483648,
        3141592653,
        4294967294,
        4294967295,
      ]) {
        expect(DealIdentity(value).value, value, reason: '$value');
      }
    });

    test('-1 and 4294967296 throw without substitution', () {
      expect(() => DealIdentity(-1), throwsA(rangeError(-1)));
      expect(() => DealIdentity(4294967296), throwsA(rangeError(4294967296)));
    });

    test('the native integer extremes throw', () {
      expect(largestInt, greaterThan(0));
      expect(smallestInt, lessThan(0));
      expect(() => DealIdentity(largestInt), throwsA(rangeError(largestInt)));
      expect(() => DealIdentity(smallestInt), throwsA(rangeError(smallestInt)));
    });

    test('values just outside the range in either direction throw', () {
      for (final value in [-2, -4294967295, 4294967297, 8589934592]) {
        expect(() => DealIdentity(value), throwsA(rangeError(value)));
      }
    });
  });

  group('DealIdentity value equality (ADR-05.2)', () {
    test('separately constructed equal values are equal and share a '
        'hashCode', () {
      final first = DealIdentity(3141592653);
      final second = DealIdentity(3141592653);

      expect(identical(first, second), isFalse);
      expect(first == second, isTrue);
      expect(first.hashCode, second.hashCode);
    });

    test('different values are unequal', () {
      expect(DealIdentity(0) == DealIdentity(1), isFalse);
      expect(DealIdentity(4294967295) == DealIdentity(4294967294), isFalse);
    });

    test('an identity is unequal to its raw integer', () {
      final Object raw = 7;

      expect(DealIdentity(7) == raw, isFalse);
    });

    test('equal identities collapse as set elements', () {
      final set = {DealIdentity(1), DealIdentity(1), DealIdentity(0)};

      expect(set, hasLength(2));
    });
  });
}
