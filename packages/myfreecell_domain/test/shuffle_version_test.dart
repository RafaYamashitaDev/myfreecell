import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:test/test.dart';

void main() {
  Matcher versionError(int invalidValue, String message) {
    return isA<ArgumentError>()
        .having((error) => error.invalidValue, 'invalidValue', invalidValue)
        .having((error) => error.name, 'name', 'number')
        .having((error) => error.message, 'message', message);
  }

  Matcher invalidError(int number) {
    return versionError(number, 'A shuffle version must be a positive integer');
  }

  Matcher unsupportedError(int number) {
    return versionError(number, 'Unsupported shuffle version');
  }

  group('ShuffleVersion supported set (ADR-05.5, GD-DEAL-03)', () {
    test('version 1 is the only supported version', () {
      expect(ShuffleVersion.values, [ShuffleVersion.v1]);
    });

    test('v1 is persisted as the number 1', () {
      expect(ShuffleVersion.v1.number, 1);
    });

    test('the current version is v1', () {
      expect(ShuffleVersion.current, same(ShuffleVersion.v1));
      expect(ShuffleVersion.current.number, 1);
    });

    test('the persisted number is not the enum index', () {
      expect(ShuffleVersion.v1.index, 0);
      expect(ShuffleVersion.v1.number, isNot(ShuffleVersion.v1.index));
    });
  });

  group('ShuffleVersion.fromNumber fails closed (ADR-05.5, ADR-05.7, '
      'ADR-11.2)', () {
    test('1 resolves to v1', () {
      expect(ShuffleVersion.fromNumber(1), same(ShuffleVersion.v1));
    });

    test('lookup round-trips every supported number', () {
      for (final version in ShuffleVersion.values) {
        expect(ShuffleVersion.fromNumber(version.number), same(version));
      }
    });

    test('0, -1, and the smallest native integer are invalid', () {
      for (final number in [0, -1, 0x8000000000000000]) {
        expect(
          () => ShuffleVersion.fromNumber(number),
          throwsA(invalidError(number)),
          reason: '$number',
        );
      }
    });

    test('2 and large positive numbers are unsupported, with no fallback to '
        'v1', () {
      for (final number in [2, 3, 1000000, 0x7FFFFFFFFFFFFFFF]) {
        expect(
          () => ShuffleVersion.fromNumber(number),
          throwsA(unsupportedError(number)),
          reason: '$number',
        );
      }
    });

    test('invalid and unsupported messages differ', () {
      Object? invalid;
      Object? unsupported;
      try {
        ShuffleVersion.fromNumber(0);
      } on ArgumentError catch (error) {
        invalid = error.message;
      }
      try {
        ShuffleVersion.fromNumber(2);
      } on ArgumentError catch (error) {
        unsupported = error.message;
      }

      expect(invalid, isNotNull);
      expect(unsupported, isNotNull);
      expect(invalid, isNot(unsupported));
    });
  });
}
