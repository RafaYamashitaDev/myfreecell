import 'package:myfreecell_domain/src/split_mix_64.dart';
import 'package:test/test.dart';

/// A raw-output source that returns scripted values in order and counts them.
class ScriptedSource {
  ScriptedSource(this.values);

  final List<int> values;
  int consumed = 0;

  int next() {
    if (consumed >= values.length) {
      fail('The scripted source is exhausted after $consumed values');
    }
    return values[consumed++];
  }
}

void main() {
  final two64 = BigInt.one << 64;
  final bounds = [for (var bound = 2; bound <= 52; bound++) bound];

  // Independent BigInt arithmetic. None of these values come from production.
  BigInt unsigned(int bits) => BigInt.from(bits).toUnsigned(64);
  int bitsOf(BigInt value) => value.toSigned(64).toInt();
  BigInt thresholdOf(int bound) => two64 % BigInt.from(bound);
  bool rejects(int bits, int bound) => unsigned(bits) < thresholdOf(bound);
  int residueOf(int bits, int bound) =>
      (unsigned(bits) % BigInt.from(bound)).toInt();

  const maxSigned = 0x7FFFFFFFFFFFFFFF;
  const unsigned2to63 = 0x8000000000000000;
  const unsignedMax = -1;

  Matcher boundError(int bound) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', bound)
        .having((error) => error.name, 'name', 'bound')
        .having(
          (error) => error.message,
          'message',
          'A draw bound must be between 2 and 52',
        );
  }

  group('test helpers', () {
    test('unsigned bit patterns map to the expected BigInt values', () {
      expect(unsigned(0), BigInt.zero);
      expect(unsigned(maxSigned), (BigInt.one << 63) - BigInt.one);
      expect(unsigned(unsigned2to63), BigInt.one << 63);
      expect(unsigned(unsignedMax), two64 - BigInt.one);
      expect(bitsOf(two64 - BigInt.one), -1);
    });

    test('the scripted source counts values and fails when exhausted', () {
      final source = ScriptedSource([5, 6]);

      expect(source.next(), 5);
      expect(source.next(), 6);
      expect(source.consumed, 2);
      expect(source.next, throwsA(isA<TestFailure>()));
    });
  });

  group('rejectionThreshold for bounds 2 through 52 (ADR-05.4, ADR-05.7, '
      'ADR-11.2)', () {
    test('every bound 2 through 52 matches 2^64 mod b in BigInt', () {
      for (final bound in bounds) {
        expect(
          rejectionThreshold(bound),
          thresholdOf(bound).toInt(),
          reason: '$bound',
        );
      }
    });

    test('powers of two have threshold 0 and other bounds do not', () {
      const powersOfTwo = {2, 4, 8, 16, 32};
      for (final bound in bounds) {
        final threshold = rejectionThreshold(bound);
        if (powersOfTwo.contains(bound)) {
          expect(threshold, 0, reason: '$bound');
        } else {
          expect(threshold, greaterThan(0), reason: '$bound');
        }
        expect(threshold, lessThan(bound), reason: '$bound');
      }
    });

    test('selected thresholds match hand-computed values', () {
      expect(rejectionThreshold(3), 1);
      expect(rejectionThreshold(5), 1);
      expect(rejectionThreshold(10), 6);
      expect(rejectionThreshold(38), 36);
      expect(rejectionThreshold(43), 41);
      expect(rejectionThreshold(52), 16);
    });
  });

  group('boundedDraw edge values for every bound 2 through 52 (ADR-05.4, '
      'ADR-05.7, ADR-11.2)', () {
    test('t - 1 is rejected and consumed, then the next value is used', () {
      var checked = 0;
      for (final bound in bounds) {
        final threshold = thresholdOf(bound).toInt();
        if (threshold == 0) {
          continue;
        }
        checked++;
        expect(rejects(threshold - 1, bound), isTrue);
        final source = ScriptedSource([threshold - 1, maxSigned]);

        expect(
          boundedDraw(source.next, bound),
          residueOf(maxSigned, bound),
          reason: '$bound',
        );
        expect(source.consumed, 2, reason: '$bound');
      }
      expect(checked, 46);
    });

    test('t is accepted on the first value', () {
      for (final bound in bounds) {
        final threshold = thresholdOf(bound).toInt();
        expect(rejects(threshold, bound), isFalse);
        final source = ScriptedSource([threshold]);

        expect(boundedDraw(source.next, bound), threshold, reason: '$bound');
        expect(source.consumed, 1, reason: '$bound');
      }
    });

    test('0 is accepted as 0 only when t is 0, and rejected otherwise', () {
      for (final bound in bounds) {
        final source = ScriptedSource([0, bound + 7]);
        final result = boundedDraw(source.next, bound);
        if (thresholdOf(bound) == BigInt.zero) {
          expect(result, 0, reason: '$bound');
          expect(source.consumed, 1, reason: '$bound');
        } else {
          expect(result, residueOf(bound + 7, bound), reason: '$bound');
          expect(source.consumed, 2, reason: '$bound');
        }
      }
    });

    test('2^63 - 1, unsigned 2^63, and unsigned 2^64 - 1 match the unsigned '
        'BigInt remainder', () {
      for (final bound in bounds) {
        for (final bits in [maxSigned, unsigned2to63, unsignedMax]) {
          expect(rejects(bits, bound), isFalse);
          final source = ScriptedSource([bits]);
          final result = boundedDraw(source.next, bound);

          expect(result, residueOf(bits, bound), reason: '$bound $bits');
          expect(result, inInclusiveRange(0, bound - 1));
          expect(source.consumed, 1, reason: '$bound $bits');
        }
      }
    });

    test('a negative bit pattern is not the signed remainder', () {
      // Unsigned 2^64 - 1 mod 10 is 5. The signed -1 mod 10 would be 9.
      expect(boundedDraw(ScriptedSource([unsignedMax]).next, 10), 5);
      expect(residueOf(unsignedMax, 10), 5);
      expect(unsignedMax % 10, 9);
    });

    test('a deterministic sweep of 256 values matches the BigInt oracle', () {
      // Test-only 64-bit LCG in BigInt, unrelated to SplitMix64.
      final multiplier = BigInt.parse('6364136223846793005');
      final increment = BigInt.parse('1442695040888963407');
      var state = BigInt.zero;
      final values = <int>[];
      for (var index = 0; index < 256; index++) {
        state = (state * multiplier + increment) % two64;
        values.add(bitsOf(state));
      }
      expect(values.where((bits) => bits < 0), isNotEmpty);
      expect(values.where((bits) => bits >= 0), isNotEmpty);

      for (final bound in bounds) {
        for (final bits in values) {
          if (rejects(bits, bound)) {
            continue;
          }
          final source = ScriptedSource([bits]);
          final result = boundedDraw(source.next, bound);

          expect(result, residueOf(bits, bound), reason: '$bound $bits');
          expect(result, inInclusiveRange(0, bound - 1));
          expect(source.consumed, 1);
        }
      }
    });
  });

  group('boundedDraw multiple rejections for bounds 2 through 52 (ADR-05.4, '
      'ADR-05.7, ADR-11.2)', () {
    test('every rejected value is consumed before one accepted value', () {
      var checked = 0;
      for (final bound in bounds) {
        final threshold = thresholdOf(bound).toInt();
        if (threshold == 0) {
          continue;
        }
        checked++;
        final rejected = [0, threshold - 1, threshold ~/ 2, 0, threshold - 1];
        for (final bits in rejected) {
          expect(rejects(bits, bound), isTrue, reason: '$bound $bits');
        }
        final source = ScriptedSource([...rejected, unsigned2to63, 99]);

        expect(
          boundedDraw(source.next, bound),
          residueOf(unsigned2to63, bound),
          reason: '$bound',
        );
        expect(source.consumed, 6, reason: '$bound');
      }
      expect(checked, 46);
    });

    test('a power-of-two bound never rejects, so 0 is accepted at once', () {
      for (final bound in [2, 4, 8, 16, 32]) {
        final source = ScriptedSource([0, 0, 0]);

        expect(boundedDraw(source.next, bound), 0);
        expect(source.consumed, 1);
      }
    });

    test('successive draws continue from the next unconsumed value', () {
      // Bound 52 has threshold 16. Bound 51 has threshold 1.
      final source = ScriptedSource([15, 0, 52 * 3 + 7, 0, 51 * 2 + 4]);

      expect(boundedDraw(source.next, 52), 7);
      expect(source.consumed, 3);
      expect(boundedDraw(source.next, 51), 4);
      expect(source.consumed, 5);
    });
  });

  group('boundedDraw bound precondition fails closed outside 2 through 52 '
      '(ADR-05.4, ADR-05.7, ADR-11.2)', () {
    test('bounds below 2 and above 52 throw before any value is drawn', () {
      for (final bound in [1, 0, -1, 53, 64, maxSigned, unsigned2to63]) {
        final source = ScriptedSource([0x123456789]);

        expect(
          () => boundedDraw(source.next, bound),
          throwsA(boundError(bound)),
          reason: '$bound',
        );
        expect(
          () => rejectionThreshold(bound),
          throwsA(boundError(bound)),
          reason: '$bound',
        );
        expect(source.consumed, 0, reason: '$bound');
      }
    });

    test('bounds 2 and 52 return normally', () {
      expect(boundedDraw(ScriptedSource([3]).next, 2), 1);
      expect(boundedDraw(ScriptedSource([16]).next, 52), 16);
    });
  });
}
