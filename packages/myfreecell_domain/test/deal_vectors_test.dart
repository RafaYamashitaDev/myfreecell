// Normative shuffle-version-1 golden vectors (ADR-05.7, ADR-05.8).
//
// Provenance:
// - Generated 2026-11-21 at repository checkpoint
//   a4af1d6288669839ad104f7c3b4f9d227ff5663c.
// - Governing source: ADR-05, with GD-DEAL-06 and GD-DEAL-07 for the layout.
// - Identities: 0, 1, 4294967295, and 3141592653.
// - Primary oracle: Java long state with overflow arithmetic, >>>,
//   Long.compareUnsigned, and Long.remainderUnsigned.
// - Secondary oracle: full BigInteger SplitMix64, threshold, remainder,
//   shuffle, and layout, reduced modulo 2^64 after every operation.
// - Runtime: Oracle Java 1.8.0_341. Compiler: javac 25.0.4 with --release 8.
// - Both complete outputs matched byte for byte.
// - No normative identity encountered a rejection. Each consumed 51 raw
//   outputs.
// - No Dart implementation or Dart-derived output was used. No online source
//   or random library was used.
// - These vectors are normative for shuffle version 1 once this increment is
//   approved and committed. Before the first public release, a version-1
//   correction requires owner approval (ADR-05.5).
//
// Approved SHA-256 fingerprints, recorded as audit metadata. Dart core
// libraries have no SHA-256, so these tests do not recompute them. The
// permutation input is the `permutation` string. The column input is the
// `columns` strings joined with '|'.
// - 0: permutation
//   5108d49026e5a3323c56e09bea907e6224d42adfa0481aaf3c3934bec83657bc,
//   columns 914297983f06acca9c4eb290ed91a8948e7b4c9821f7ff98160214ecc2d5adb0
// - 1: permutation
//   ccea50bda33b8ba66d63fbdc1f6f5fe72ebc3dd9b1a4f449e50c5865ac4cf1be,
//   columns 0f776b908ef8f2c10c4fcde160c4b878679ee54ed6cb1eebd0e1c092f2e3f0a9
// - 4294967295: permutation
//   e2e0dbde87a4ccd143a6b187394c8dda49067c688cea856bbd7417b573a90001,
//   columns 6de4d15180077758abb652dcabf33f42ff6e39420959ada84e4ba905e3524179
// - 3141592653: permutation
//   12d9c32d741ca5bef4912008f57b7b0a3f7a14b02e5e4cb75581c165c5674c71,
//   columns fd889791cc789b2b2fb8d1263892d1fe295dac1bcb960d86bf036f8624f69c33

import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/deal.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
import 'package:myfreecell_domain/src/split_mix_64.dart';
import 'package:test/test.dart';

/// One approved golden vector. Columns are T1 to T8, deepest card first.
class GoldenDeal {
  const GoldenDeal({
    required this.identity,
    required this.raws,
    required this.permutation,
    required this.columns,
  });

  final int identity;
  final List<String> raws;
  final String permutation;
  final List<String> columns;
}

const goldenDeals = [
  GoldenDeal(
    identity: 0,
    raws: [
      'E220A8397B1DCDAF',
      '6E789E6AA1B965F4',
      '06C45D188009454F',
      'F88BB8A8724C81EC',
      '1B39896A51A8749B',
      '53CB9F0C747EA2EA',
      '2C829ABE1F4532E1',
      'C584133AC916AB3C',
    ],
    permutation: '8S,JH,9C,2S,2D,QD,6S,10C,3D,AC,JC,7C,9H,8C,QS,KH,5H,2C,3H,5C,AH,6C,4S,10D,5D,8H,8D,AD,QH,10S,QC,JD,3S,4D,2H,9D,3C,KD,AS,7S,9S,7D,JS,6H,KS,4C,7H,5S,6D,4H,KC,10H',
    columns: [
      '8S,3D,5H,5D,3S,9S,6D',
      'JH,AC,2C,8H,4D,7D,4H',
      '9C,JC,3H,8D,2H,JS,KC',
      '2S,7C,5C,AD,9D,6H,10H',
      '2D,9H,AH,QH,3C,KS',
      'QD,8C,6C,10S,KD,4C',
      '6S,QS,4S,QC,AS,7H',
      '10C,KH,10D,JD,7S,5S',
    ],
  ),
  GoldenDeal(
    identity: 1,
    raws: [
      '910A2DEC89025CC1',
      'BEEB8DA1658EEC67',
      'F893A2EEFB32555E',
      '71C18690EE42C90B',
      '71BB54D8D101B5B9',
      'C34D0BFF90150280',
      'E099EC6CD7363CA5',
      '85E7BB0F12278575',
    ],
    permutation: '7D,9C,4D,8H,8D,5S,JD,6D,9S,JC,5D,KD,3C,2D,JH,5H,7H,4H,2C,AD,6S,KC,KH,10H,10S,JS,10D,8S,QC,4S,6C,7C,AS,5C,AH,KS,6H,QS,QH,QD,9D,3D,3S,AC,4C,2H,8C,10C,3H,2S,9H,7S',
    columns: [
      '7D,9S,7H,10S,AS,9D,3H',
      '9C,JC,4H,JS,5C,3D,2S',
      '4D,5D,2C,10D,AH,3S,9H',
      '8H,KD,AD,8S,KS,AC,7S',
      '8D,3C,6S,QC,6H,4C',
      '5S,2D,KC,4S,QS,2H',
      'JD,JH,KH,6C,QH,8C',
      '6D,5H,10H,7C,QD,10C',
    ],
  ),
  GoldenDeal(
    identity: 4294967295,
    raws: [
      '73B13BA2AFF181C0',
      '612043051340D3B4',
      'EE4AC9FF47275E73',
      '12F4EEB73CED4B8E',
      'B71038B0D100930A',
      'FB51B8072C7589B4',
      '73C42195BDA03537',
      'BE65E3C14233697C',
    ],
    permutation: '6H,2D,8H,3S,10C,5S,4H,QC,3C,JC,8C,5H,JS,KD,7S,9H,4D,5D,3D,AD,JD,KS,AC,4S,7C,8D,9C,2C,9D,2H,2S,JH,QS,6C,6D,9S,KH,AS,4C,6S,7H,8S,5C,QD,10S,10H,7D,AH,10D,QH,KC,3H',
    columns: [
      '6H,3C,4D,7C,QS,7H,10D',
      '2D,JC,5D,8D,6C,8S,QH',
      '8H,8C,3D,9C,6D,5C,KC',
      '3S,5H,AD,2C,9S,QD,3H',
      '10C,JS,JD,9D,KH,10S',
      '5S,KD,KS,2H,AS,10H',
      '4H,7S,AC,2S,4C,7D',
      'QC,9H,4S,JH,6S,AH',
    ],
  ),
  GoldenDeal(
    identity: 3141592653,
    raws: [
      'A495DD9EF07BA543',
      '21089AB791C3BED9',
      '22AB321F5903E997',
      '6F4A1925ED971DC4',
      '3B17DF56D700BDE3',
      '099AB86863873A89',
      'CC923E197F8B33BE',
      '99475550F385E0B5',
    ],
    permutation: 'AC,5S,JH,KD,AD,5D,3H,JC,8S,10C,7C,JS,10S,QD,4S,AH,AS,2C,7H,JD,7S,4D,8D,8H,9H,QC,KS,9C,5H,5C,2D,6C,2H,QS,3C,6S,4H,9D,7D,10D,KC,6H,QH,2S,3D,6D,KH,10H,3S,8C,4C,9S',
    columns: [
      'AC,8S,AS,9H,2H,KC,3S',
      '5S,10C,2C,QC,QS,6H,8C',
      'JH,7C,7H,KS,3C,QH,4C',
      'KD,JS,JD,9C,6S,2S,9S',
      'AD,10S,7S,5H,4H,3D',
      '5D,QD,4D,5C,9D,6D',
      '3H,4S,8D,2D,7D,KH',
      'JC,AH,8H,6C,10D,10H',
    ],
  ),
];

// Test-only card-code parser and renderer. They do not use production deck
// indexing.
const _suitByLetter = {
  'C': Suit.clubs,
  'D': Suit.diamonds,
  'H': Suit.hearts,
  'S': Suit.spades,
};

const _rankByToken = {
  'A': Rank.ace,
  '2': Rank.two,
  '3': Rank.three,
  '4': Rank.four,
  '5': Rank.five,
  '6': Rank.six,
  '7': Rank.seven,
  '8': Rank.eight,
  '9': Rank.nine,
  '10': Rank.ten,
  'J': Rank.jack,
  'Q': Rank.queen,
  'K': Rank.king,
};

Card parseCard(String code) {
  final suit = _suitByLetter[code.substring(code.length - 1)];
  final rank = _rankByToken[code.substring(0, code.length - 1)];
  if (suit == null || rank == null) {
    throw FormatException('Not a card code', code);
  }
  return Card(rank, suit);
}

List<Card> parseCards(String codes) => [
  for (final code in codes.split(',')) parseCard(code),
];

String renderCard(Card card) {
  final rank = _rankByToken.entries.singleWhere(
    (entry) => entry.value == card.rank,
  );
  final suit = _suitByLetter.entries.singleWhere(
    (entry) => entry.value == card.suit,
  );
  return '${rank.key}${suit.key}';
}

String renderCards(List<Card> cards) => cards.map(renderCard).join(',');

String unsignedHex(int bits) {
  return BigInt.from(bits)
      .toUnsigned(64)
      .toRadixString(16)
      .toUpperCase()
      .padLeft(16, '0');
}

void main() {
  final two64 = BigInt.one << 64;
  final allCards = {
    for (final suit in _suitByLetter.values)
      for (final rank in _rankByToken.values) Card(rank, suit),
  };

  group('golden fixtures and provenance are complete and self-consistent '
      '(ADR-05.7, ADR-11.2)', () {
    test('the identities are 0, 1, 4294967295, and 3141592653', () {
      expect(
        [for (final deal in goldenDeals) deal.identity],
        [0, 1, 4294967295, 3141592653],
      );
    });

    for (final deal in goldenDeals) {
      test('identity ${deal.identity} has 8 raws, 52 unique cards, and 8 '
          'columns', () {
        expect(deal.raws, hasLength(8));
        for (final hex in deal.raws) {
          expect(hex, matches(RegExp(r'^[0-9A-F]{16}$')));
        }

        final permutation = parseCards(deal.permutation);
        expect(permutation, hasLength(52));
        expect(permutation.toSet(), allCards);
        expect(renderCards(permutation), deal.permutation);

        expect(deal.columns, hasLength(8));
        expect(
          [for (final column in deal.columns) parseCards(column).length],
          [7, 7, 7, 7, 6, 6, 6, 6],
        );
        for (final column in deal.columns) {
          expect(renderCards(parseCards(column)), column);
        }
        final fingerprintInput = deal.columns.join('|');
        expect(fingerprintInput, isNot(contains(' ')));
        expect('|'.allMatches(fingerprintInput), hasLength(7));
      });

      test('identity ${deal.identity} columns follow GD-DEAL-06 from its '
          'permutation', () {
        final permutation = parseCards(deal.permutation);
        final columns = [for (final column in deal.columns) parseCards(column)];
        for (var i = 1; i <= 52; i++) {
          expect(
            columns[(i - 1) % 8][(i - 1) ~/ 8],
            permutation[i - 1],
            reason: 'p$i',
          );
        }
      });
    }

    test('the four fixture permutations are pairwise distinct', () {
      // Fixture sanity evidence, not a product guarantee.
      expect({for (final deal in goldenDeals) deal.permutation}, hasLength(4));
    });
  });

  group('normative deal vectors (ADR-05.7, ADR-11.2, GD-DEAL-02, GD-DEAL-03, '
      'GD-DEAL-06)', () {
    for (final deal in goldenDeals) {
      test('identity ${deal.identity} yields the approved permutation '
          '(GD-TEST-01, permutation portion)', () {
        final permutation = dealPermutation(
          DealIdentity(deal.identity),
          ShuffleVersion.v1,
        );

        expect(permutation, parseCards(deal.permutation));
        expect(renderCards(permutation), deal.permutation);
      });

      test('identity ${deal.identity} yields the approved columns (GD-TEST-01, '
          'tableau-column portion; GD-TEST-03)', () {
        final columns = initialColumns(
          dealPermutation(DealIdentity(deal.identity), ShuffleVersion.v1),
        );

        expect(columns, [
          for (final column in deal.columns) parseCards(column),
        ]);
        expect(columns.map(renderCards).join('|'), deal.columns.join('|'));
      });

      test('identity ${deal.identity} consumes exactly 51 raw outputs with no '
          'rejection, starting with the approved raws', () {
        final generator = SplitMix64(DealIdentity(deal.identity));
        final consumed = <int>[];
        int countingSource() {
          final raw = generator.nextRaw();
          consumed.add(raw);
          return raw;
        }

        final permutation = shuffleCanonicalDeck(countingSource);

        expect(consumed, hasLength(51));
        expect([
          for (final raw in consumed.take(8)) unsignedHex(raw),
        ], deal.raws);
        for (var step = 0; step < 51; step++) {
          final bound = 52 - step;
          final threshold = two64 % BigInt.from(bound);
          expect(
            BigInt.from(consumed[step]).toUnsigned(64) >= threshold,
            isTrue,
            reason: 'step $step bound $bound',
          );
        }
        expect(permutation, parseCards(deal.permutation));
      });

      test('identity ${deal.identity} is reproduced by repeated calls '
          '(GD-TEST-01, permutation portion)', () {
        expect(
          dealPermutation(DealIdentity(deal.identity), ShuffleVersion.current),
          dealPermutation(
            DealIdentity(deal.identity),
            ShuffleVersion.fromNumber(1),
          ),
        );
      });
    }

    test('the four production permutations are pairwise distinct', () {
      // Fixture sanity evidence, not a product guarantee.
      final rendered = {
        for (final deal in goldenDeals)
          renderCards(
            dealPermutation(DealIdentity(deal.identity), ShuffleVersion.v1),
          ),
      };

      expect(rendered, hasLength(4));
    });
  });
}
