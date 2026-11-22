import 'package:myfreecell_domain/src/card.dart';
import 'package:myfreecell_domain/src/deal.dart';
import 'package:myfreecell_domain/src/deal_identity.dart';
import 'package:myfreecell_domain/src/shuffle_version.dart';
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

// Test-only card-code parser. It does not use production deck indexing.
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

void main() {
  final two64 = BigInt.one << 64;

  // 1000003 is a prime above 52, so b * 1000003 + k has residue k modulo b.
  const spread = 1000003;
  final descendingBounds = [for (var bound = 52; bound >= 2; bound--) bound];

  // Hand-written canonical order (ADR-05.1).
  const canonicalCodes =
      'AC,2C,3C,4C,5C,6C,7C,8C,9C,10C,JC,QC,KC,'
      'AD,2D,3D,4D,5D,6D,7D,8D,9D,10D,JD,QD,KD,'
      'AH,2H,3H,4H,5H,6H,7H,8H,9H,10H,JH,QH,KH,'
      'AS,2S,3S,4S,5S,6S,7S,8S,9S,10S,JS,QS,KS';

  // Independent test model of the version-1 shuffle. It takes its bound
  // sequence explicitly and uses BigInt for the unsigned threshold and
  // remainder.
  List<Card> modelShuffle(List<int> raws, List<int> boundSequence) {
    final cards = parseCards(canonicalCodes);
    var cursor = 0;
    var position = 51;
    for (final bound in boundSequence) {
      final big = BigInt.from(bound);
      final threshold = two64 % big;
      while (true) {
        final raw = BigInt.from(raws[cursor++]).toUnsigned(64);
        if (raw < threshold) {
          continue;
        }
        final j = (raw % big).toInt();
        final held = cards[position];
        cards[position] = cards[j];
        cards[j] = held;
        break;
      }
      position--;
    }
    return cards;
  }

  // 51 raw values from a test-only BigInt LCG, unrelated to SplitMix64.
  List<int> sweepRaws() {
    final multiplier = BigInt.parse('6364136223846793005');
    final increment = BigInt.parse('1442695040888963407');
    var state = BigInt.from(12345);
    final raws = <int>[];
    for (final bound in descendingBounds) {
      while (true) {
        state = (state * multiplier + increment) % two64;
        if (state >= two64 % BigInt.from(bound)) {
          raws.add(state.toSigned(64).toInt());
          break;
        }
      }
    }
    return raws;
  }

  group('canonical deck (ADR-05.1, ADR-05.7, ADR-11.2, GD-CARD-01)', () {
    test('index anchors match the hand-written expectations', () {
      const anchors = {
        0: 'AC',
        9: '10C',
        12: 'KC',
        13: 'AD',
        22: '10D',
        25: 'KD',
        26: 'AH',
        35: '10H',
        38: 'KH',
        39: 'AS',
        48: '10S',
        51: 'KS',
      };

      for (final MapEntry(key: index, value: code) in anchors.entries) {
        expect(canonicalDeck[index], parseCard(code), reason: '$index');
      }
    });

    test('the full order matches the hand-written canonical codes', () {
      expect(canonicalDeck, parseCards(canonicalCodes));
    });

    test('index suitIndex * 13 + rankIndex has the expected suit and rank', () {
      const suits = [Suit.clubs, Suit.diamonds, Suit.hearts, Suit.spades];
      for (var suitIndex = 0; suitIndex < 4; suitIndex++) {
        for (var rankIndex = 0; rankIndex < 13; rankIndex++) {
          final card = canonicalDeck[suitIndex * 13 + rankIndex];
          expect(card.suit, suits[suitIndex]);
          expect(card.rank.value, rankIndex + 1);
        }
      }
    });

    test('the deck has 52 distinct cards', () {
      expect(canonicalDeck, hasLength(52));
      expect(canonicalDeck.toSet(), hasLength(52));
    });

    test('the deck cannot be mutated', () {
      expect(() => canonicalDeck[0] = parseCard('KS'), throwsUnsupportedError);
      expect(() => canonicalDeck.add(parseCard('AC')), throwsUnsupportedError);
      expect(() => canonicalDeck.removeLast(), throwsUnsupportedError);
      expect(canonicalDeck.clear, throwsUnsupportedError);
      expect(canonicalDeck, parseCards(canonicalCodes));
    });
  });

  group('shuffleCanonicalDeck descending Fisher–Yates (ADR-05.4, ADR-05.7, '
      'ADR-11.2, GD-DEAL-02)', () {
    test('draws with j == i at every step return the canonical order', () {
      final source = ScriptedSource([
        for (final bound in descendingBounds) bound * spread + bound - 1,
      ]);

      expect(shuffleCanonicalDeck(source.next), parseCards(canonicalCodes));
      expect(source.consumed, 51);
    });

    test('draws with j == 0 at every step rotate the deck left by one', () {
      // Hand-derived: step i swaps index i with index 0, so index 0 ends at
      // canonical index 1, index k ends at k + 1, and index 51 ends at AC.
      const rotated =
          '2C,3C,4C,5C,6C,7C,8C,9C,10C,JC,QC,KC,'
          'AD,2D,3D,4D,5D,6D,7D,8D,9D,10D,JD,QD,KD,'
          'AH,2H,3H,4H,5H,6H,7H,8H,9H,10H,JH,QH,KH,'
          'AS,2S,3S,4S,5S,6S,7S,8S,9S,10S,JS,QS,KS,AC';
      final source = ScriptedSource([
        for (final bound in descendingBounds) bound * spread,
      ]);

      expect(shuffleCanonicalDeck(source.next), parseCards(rotated));
      expect(source.consumed, 51);
    });

    test('the requested bounds are 52, 51, ..., 2 in that order', () {
      final raws = sweepRaws();
      final ascending = [for (var bound = 2; bound <= 52; bound++) bound];
      final offByOne = [for (var bound = 51; bound >= 1; bound--) bound];
      final source = ScriptedSource(raws);
      final shuffled = shuffleCanonicalDeck(source.next);

      expect(descendingBounds, hasLength(51));
      expect(descendingBounds.first, 52);
      expect(descendingBounds.last, 2);
      expect(source.consumed, 51);
      expect(shuffled, modelShuffle(raws, descendingBounds));
      expect(shuffled, isNot(modelShuffle(raws, ascending)));
      expect(shuffled, isNot(modelShuffle(raws, offByOne)));
    });

    test('a rejection consumes one extra value and shifts later draws', () {
      // Bound 10 is requested at i = 9, the 43rd draw, and has threshold 6.
      // The value 5 is rejected there.
      final raws = sweepRaws();
      const at = 52 - 10;
      final withRejection = [...raws.take(at), 5, ...raws.skip(at)];
      final plain = ScriptedSource(raws);
      final rejecting = ScriptedSource(withRejection);

      final expected = shuffleCanonicalDeck(plain.next);
      final actual = shuffleCanonicalDeck(rejecting.next);

      expect(plain.consumed, 51);
      expect(rejecting.consumed, 52);
      expect(actual, expected);
      expect(actual, modelShuffle(withRejection, descendingBounds));
    });

    test('a rejection at the first draw is consumed before index 51 moves', () {
      // Bound 52 has threshold 16.
      final raws = sweepRaws();
      final source = ScriptedSource([15, 0, ...raws]);

      expect(
        shuffleCanonicalDeck(source.next),
        modelShuffle(raws, descendingBounds),
      );
      expect(source.consumed, 53);
    });

    test('the result has 52 unique canonical cards and is unmodifiable', () {
      final shuffled = shuffleCanonicalDeck(ScriptedSource(sweepRaws()).next);

      expect(shuffled, hasLength(52));
      expect(shuffled.toSet(), canonicalDeck.toSet());
      expect(shuffled, isNot(canonicalDeck));
      expect(() => shuffled[0] = shuffled[1], throwsUnsupportedError);
      expect(() => shuffled.add(shuffled[0]), throwsUnsupportedError);
    });

    test('shuffling leaves the canonical deck unchanged', () {
      shuffleCanonicalDeck(ScriptedSource(sweepRaws()).next);

      expect(canonicalDeck, parseCards(canonicalCodes));
    });
  });

  group('dealPermutation (GD-DEAL-02, GD-DEAL-03, ADR-05.5)', () {
    final identities = [0, 1, 4294967295, 3141592653, 2147483648];

    test('version 1 is the SplitMix64 shuffle seeded by the identity', () {
      for (final value in identities) {
        final identity = DealIdentity(value);

        expect(
          dealPermutation(identity, ShuffleVersion.v1),
          shuffleCanonicalDeck(SplitMix64(identity).nextRaw),
          reason: '$value',
        );
      }
    });

    test('equal identities and versions give equal permutations (GD-TEST-01, '
        'permutation portion)', () {
      for (final value in identities) {
        expect(
          dealPermutation(DealIdentity(value), ShuffleVersion.current),
          dealPermutation(DealIdentity(value), ShuffleVersion.fromNumber(1)),
          reason: '$value',
        );
      }
    });

    test('each permutation has 52 unique canonical cards', () {
      for (final value in identities) {
        final permutation = dealPermutation(
          DealIdentity(value),
          ShuffleVersion.v1,
        );

        expect(permutation, hasLength(52));
        expect(permutation.toSet(), canonicalDeck.toSet(), reason: '$value');
      }
    });

    test('the permutation is unmodifiable', () {
      final permutation = dealPermutation(DealIdentity(0), ShuffleVersion.v1);

      expect(() => permutation[0] = permutation[1], throwsUnsupportedError);
      expect(permutation.clear, throwsUnsupportedError);
    });
  });

  group('initialColumns tableau columns (GD-DEAL-06, GD-DEAL-07)', () {
    // Hand-derived from GD-DEAL-06 applied to the canonical order.
    const canonicalColumns = [
      'AC,9C,4D,QD,7H,2S,10S',
      '2C,10C,5D,KD,8H,3S,JS',
      '3C,JC,6D,AH,9H,4S,QS',
      '4C,QC,7D,2H,10H,5S,KS',
      '5C,KC,8D,3H,JH,6S',
      '6C,AD,9D,4H,QH,7S',
      '7C,2D,10D,5H,KH,8S',
      '8C,3D,JD,6H,AS,9S',
    ];

    final permutations = <String, List<Card>>{
      'canonical': parseCards(canonicalCodes),
      'sweep': shuffleCanonicalDeck(ScriptedSource(sweepRaws()).next),
      'identity 1': dealPermutation(DealIdentity(1), ShuffleVersion.v1),
    };

    test('the canonical order deals into the hand-derived columns '
        '(GD-TEST-03)', () {
      expect(initialColumns(parseCards(canonicalCodes)), [
        for (final column in canonicalColumns) parseCards(column),
      ]);
    });

    test('the columns hold 52 distinct cards in sizes 7, 7, 7, 7, 6, 6, 6, 6 '
        '(GD-TEST-02, tableau-column portion only)', () {
      for (final MapEntry(key: name, value: permutation)
          in permutations.entries) {
        final columns = initialColumns(permutation);
        expect(
          [for (final column in columns) column.length],
          [7, 7, 7, 7, 6, 6, 6, 6],
          reason: name,
        );
        expect(
          {for (final column in columns) ...column},
          parseCards(canonicalCodes).toSet(),
          reason: name,
        );
      }
    });

    test('p_i is in column T((i - 1) mod 8 + 1) at depth (i - 1) ~/ 8 '
        '(GD-TEST-03)', () {
      for (final MapEntry(key: name, value: permutation)
          in permutations.entries) {
        final columns = initialColumns(permutation);
        for (var i = 1; i <= 52; i++) {
          expect(
            columns[(i - 1) % 8][(i - 1) ~/ 8],
            permutation[i - 1],
            reason: '$name p$i',
          );
        }
      }
    });

    test('p1 is the deepest card of T1', () {
      for (final permutation in permutations.values) {
        expect(initialColumns(permutation)[0][0], permutation[0]);
      }
    });

    test('reading the columns by deal round reconstructs p1 through p52 '
        '(GD-TEST-03)', () {
      for (final MapEntry(key: name, value: permutation)
          in permutations.entries) {
        final columns = initialColumns(permutation);
        final rounds = [
          for (var depth = 0; depth < 7; depth++)
            for (final column in columns)
              if (depth < column.length) column[depth],
        ];

        expect(rounds, permutation, reason: name);
      }
    });

    test('exposed cards are p49 to p52 on T1 to T4 and p45 to p48 on T5 to '
        'T8 (GD-DEAL-07, GD-TEST-03)', () {
      for (final MapEntry(key: name, value: permutation)
          in permutations.entries) {
        final exposed = [
          for (final column in initialColumns(permutation)) column.last,
        ];

        expect(exposed, [
          permutation[48],
          permutation[49],
          permutation[50],
          permutation[51],
          permutation[44],
          permutation[45],
          permutation[46],
          permutation[47],
        ], reason: name);
      }
    });

    test('the outer list and every column are unmodifiable', () {
      final columns = initialColumns(parseCards(canonicalCodes));

      expect(() => columns[0] = columns[1], throwsUnsupportedError);
      expect(() => columns.add(<Card>[]), throwsUnsupportedError);
      for (final column in columns) {
        expect(() => column[0] = column[1], throwsUnsupportedError);
        expect(() => column.add(column[0]), throwsUnsupportedError);
      }
    });

    test('the input is not mutated and later input changes are not seen', () {
      final input = parseCards(canonicalCodes);
      final columns = initialColumns(input);

      expect(input, parseCards(canonicalCodes));
      input[0] = parseCard('KS');
      input[8] = parseCard('KS');

      expect(columns, [
        for (final column in canonicalColumns) parseCards(column),
      ]);
    });

    test('a permutation of 0, 51, or 53 cards throws', () {
      final deck = parseCards(canonicalCodes);
      for (final permutation in [
        <Card>[],
        deck.sublist(0, 51),
        [...deck, deck[0]],
      ]) {
        expect(
          () => initialColumns(permutation),
          throwsA(
            isA<ArgumentError>()
                .having(
                  (error) => error.invalidValue,
                  'invalidValue',
                  same(permutation),
                )
                .having((error) => error.name, 'name', 'permutation')
                .having(
                  (error) => error.message,
                  'message',
                  'A deal permutation must contain exactly 52 cards',
                ),
          ),
          reason: '${permutation.length}',
        );
      }
    });
  });
}
