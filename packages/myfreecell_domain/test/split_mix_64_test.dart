import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/split_mix_64.dart';
import 'package:test/test.dart';

void main() {
  // Approved dual-Java oracle outputs (2026-11-21). The provenance is in
  // deal_vectors_test.dart. These literals are not derived from production.
  const referenceOutputs = <int, List<String>>{
    0: [
      'E220A8397B1DCDAF',
      '6E789E6AA1B965F4',
      '06C45D188009454F',
      'F88BB8A8724C81EC',
      '1B39896A51A8749B',
      '53CB9F0C747EA2EA',
      '2C829ABE1F4532E1',
      'C584133AC916AB3C',
    ],
    1: [
      '910A2DEC89025CC1',
      'BEEB8DA1658EEC67',
      'F893A2EEFB32555E',
      '71C18690EE42C90B',
      '71BB54D8D101B5B9',
      'C34D0BFF90150280',
      'E099EC6CD7363CA5',
      '85E7BB0F12278575',
    ],
    4294967295: [
      '73B13BA2AFF181C0',
      '612043051340D3B4',
      'EE4AC9FF47275E73',
      '12F4EEB73CED4B8E',
      'B71038B0D100930A',
      'FB51B8072C7589B4',
      '73C42195BDA03537',
      'BE65E3C14233697C',
    ],
    3141592653: [
      'A495DD9EF07BA543',
      '21089AB791C3BED9',
      '22AB321F5903E997',
      '6F4A1925ED971DC4',
      '3B17DF56D700BDE3',
      '099AB86863873A89',
      'CC923E197F8B33BE',
      '99475550F385E0B5',
    ],
  };

  // Renders an int bit pattern as 16 uppercase unsigned hexadecimal digits.
  String unsignedHex(int bits) {
    return BigInt.from(bits)
        .toUnsigned(64)
        .toRadixString(16)
        .toUpperCase()
        .padLeft(16, '0');
  }

  // The int bit pattern of an unsigned hexadecimal literal.
  int bitsOf(String hex) {
    return BigInt.parse(hex, radix: 16).toSigned(64).toInt();
  }

  List<int> firstOutputs(int identity, int count) {
    final generator = SplitMix64(DealIdentity(identity));
    return [for (var index = 0; index < count; index++) generator.nextRaw()];
  }

  group('test helpers', () {
    test('unsignedHex renders zero, all ones, and the top bit', () {
      expect(unsignedHex(0), '0000000000000000');
      expect(unsignedHex(-1), 'FFFFFFFFFFFFFFFF');
      expect(unsignedHex(0x7FFFFFFFFFFFFFFF), '7FFFFFFFFFFFFFFF');
      expect(unsignedHex(0x8000000000000000), '8000000000000000');
      expect(unsignedHex(255), '00000000000000FF');
    });

    test('bitsOf inverts unsignedHex for every reference output', () {
      for (final outputs in referenceOutputs.values) {
        for (final hex in outputs) {
          expect(unsignedHex(bitsOf(hex)), hex);
        }
      }
    });
  });

  group('SplitMix64 reference outputs (ADR-05.3, ADR-05.7, ADR-11.2)', () {
    test('the reference identities are 0, 1, 4294967295, and 3141592653', () {
      expect(referenceOutputs.keys, [0, 1, 4294967295, 3141592653]);
      for (final outputs in referenceOutputs.values) {
        expect(outputs, hasLength(8));
        for (final hex in outputs) {
          expect(hex, matches(RegExp(r'^[0-9A-F]{16}$')));
        }
      }
    });

    for (final MapEntry(key: identity, value: outputs)
        in referenceOutputs.entries) {
      test(
        'identity $identity yields the eight reference outputs in order',
        () {
          final actual = firstOutputs(identity, 8);

          expect([for (final bits in actual) unsignedHex(bits)], outputs);
          expect(actual, [for (final hex in outputs) bitsOf(hex)]);
        },
      );
    }

    test('the vectors include outputs with and without the top bit set', () {
      var topBitSet = 0;
      var topBitClear = 0;

      for (final MapEntry(key: identity, value: outputs)
          in referenceOutputs.entries) {
        final actual = firstOutputs(identity, 8);
        for (var index = 0; index < 8; index++) {
          final highDigit = int.parse(outputs[index][0], radix: 16);
          if (highDigit >= 8) {
            topBitSet++;
            expect(actual[index], isNegative, reason: outputs[index]);
          } else {
            topBitClear++;
            expect(actual[index], isNonNegative, reason: outputs[index]);
          }
        }
      }

      expect(topBitSet, 16);
      expect(topBitClear, 16);
    });

    test('separate generators for the same identity yield the same stream', () {
      for (final identity in referenceOutputs.keys) {
        expect(
          firstOutputs(identity, 64),
          firstOutputs(identity, 64),
          reason: '$identity',
        );
      }
    });

    test('interleaved generators advance independently', () {
      final first = SplitMix64(DealIdentity(1));
      final second = SplitMix64(DealIdentity(1));
      final outputs = referenceOutputs[1]!;

      expect(unsignedHex(first.nextRaw()), outputs[0]);
      expect(unsignedHex(first.nextRaw()), outputs[1]);
      expect(unsignedHex(second.nextRaw()), outputs[0]);
      expect(unsignedHex(first.nextRaw()), outputs[2]);
      expect(unsignedHex(second.nextRaw()), outputs[1]);
    });

    test('different identities yield different first outputs', () {
      final firsts = {
        for (final identity in referenceOutputs.keys)
          firstOutputs(identity, 1).single,
      };

      expect(firsts, hasLength(4));
    });
  });
}
