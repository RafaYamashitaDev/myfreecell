# ADR-05: Deterministic deal generation, deal identity, and shuffle versioning

Status: Accepted

Date: 2026-11-14

## Context

The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) requires a deterministic function from a deal identity to exactly one permutation of the 52-card deck (GD-DEAL-02, GD-DEAL-03). It assigns the identity representation, the pseudo-random number generator, the seed representation, the shuffle procedure, and new-identity generation to architecture (GD-DEAL-01, GD-DEAL-04). The same identity under a fixed shuffle-function version must always produce the same permutation. Neither value is shown to or chosen by the player (GD-DEAL-01, GD-DEAL-03; product PERS-08).

[ADR-03](adr-03-repository-structure-and-domain-isolation.md) keeps the pure-Dart domain independent of Flutter, the clock, uncontrolled randomness, and storage. It permits the domain to own deterministic deal generation from an explicit deal identity and shuffle version, and it left the shuffle algorithm and version representation deferred. [ADR-04](adr-04-dependency-admission-policy.md) requires the domain package to start with no third-party production dependencies.

GD-DEAL-06 through GD-DEAL-08 already fix how a permutation becomes the initial layout. This decision does not change that layout. It adds no source, tests, or dependencies.

## Decision

### ADR-05.1 Canonical deck

- The unshuffled deck is suit-major in GD-CARD-03 suit order: Clubs, Diamonds, Hearts, Spades.
- Within each suit, ranks run from Ace through King.
- Canonical indices are 0 through 51. The index is `suitIndex * 13 + (rank - 1)`, with suitIndex 0 for Clubs, 1 for Diamonds, 2 for Hearts, and 3 for Spades, and with Ace as rank 1.
- The ranges are Clubs 0–12, Diamonds 13–25, Hearts 26–38, and Spades 39–51.
- This is the deck order only. It is not the foundation-slot order fixed by GD-FND-01.
- The shuffle starts from an array whose slot k holds the card at canonical index k.
- After shuffling, array index 0 is p1 and array index 51 is p52.
- p1 is the first card dealt. Under GD-DEAL-06 it is the deepest card of T1.

### ADR-05.2 Deal identity

- A deal identity is an integer in the inclusive range 0 through 4,294,967,295.
- Equality is by numeric value.
- A value outside that range is invalid and must not be accepted as a deal identity. No substitute identity is used.
- The Flutter application supplies the identity explicitly.
- The identity and the shuffle version are persisted as logically separate values. This is separation of the two values only. It does not select a schema, codec, or storage technology.
- GD-LIFE-01 compares deal-identity values only. It does not compare shuffle versions.
- For shuffle version 1, the identity's unsigned numeric value is the SplitMix64 initial state. There is no separate seed derivation or pre-mixing step.

### ADR-05.3 PRNG

- Shuffle version 1 uses SplitMix64, implemented in the domain package in pure Dart.
- The implementation is self-contained and adds no third-party runtime dependency.
- The initial 64-bit state equals the unsigned numeric value of the deal identity.
- There is no separate seed derivation or pre-mixing step. The only state advancement and mixing are the SplitMix64 operations below.
- Every arithmetic step is modulo 2^64. Every shift is a logical right shift.
- One output is produced as follows:
  1. `state ← (state + 0x9E3779B97F4A7C15) mod 2^64`
  2. `z ← state`
  3. `z ← ((z XOR (z >> 30)) × 0xBF58476D1CE4E5B9) mod 2^64`
  4. `z ← ((z XOR (z >> 27)) × 0x94D049BB133111EB) mod 2^64`
  5. `output ← z XOR (z >> 31)`
- These constants and operations are frozen for version 1 by the reference vectors required in ADR-05.7.
- Deterministic deal generation must not use `dart:math` `Random`, `List.shuffle`, `hashCode`, platform entropy, or any SDK-dependent random sequence.
- That prohibition applies to deterministic deal generation. Fresh-identity generation in the Flutter application is specified in ADR-05.6.

### ADR-05.4 Shuffle

- Version 1 shuffles the canonical deck with a descending in-place Fisher–Yates shuffle.
- `i` runs from 51 down to 1.
- For each `i`, the bound is `b = i + 1`.
- Draw an unsigned 64-bit value `r` from the next SplitMix64 output.
- Let `t = 2^64 mod b`.
- If `r < t`, reject `r`. The rejected output is consumed, so the generator has advanced. Draw again.
- Otherwise `j = r mod b`.
- Swap array indices `i` and `j`.
- The Dart implementation must preserve this unsigned 64-bit mathematical contract, including the comparison, the modulo, and `t`. The technique used to preserve it is not decided here.

### ADR-05.5 Versioning

- A shuffle version is a positive integer in the domain's closed set of supported versions.
- Version 1 is the only supported version. It covers the complete identity-to-permutation mapping in ADR-05.1 through ADR-05.4.
- GD-DEAL-06 through GD-DEAL-08 remain specification-fixed and outside the shuffle version. Changing that layout requires a revision of the gameplay/domain specification, not a new shuffle version.
- The domain owns the supported-version registry and exposes the current version for new deals.
- Restore and Restart use the stored shuffle version.
- An unknown, invalid, or unsupported version fails closed, with no fallback to another version or algorithm.
- Invalid means a version that is not a positive integer. Unknown or unsupported means a positive integer outside the supported set.
- A Restore candidate that cannot be reproduced because its version fails closed is not restorable (GD-LIFE-08).
- The first public release is the first MyFreecell build made generally available to end users through the Google Play production track.
- Local development builds, directly installed APKs, and Google Play internal, closed, and open testing builds are pre-release.
- Compatibility with pre-release saved games is not promised.
- Before the first public release, version 1 may be corrected only through explicit review and owner approval, with deliberate replacement of the affected golden vectors and development or test data.
- After the first public release, released version-1 behavior is immutable. A behavioral change requires a new shuffle version.
- A previously released version remains reproducible while persisted data may reference it.
- Retiring a released version requires a separate approved migration and compatibility decision.

### ADR-05.6 Ownership and fresh identities

- The pure-Dart domain owns deal-identity values, shuffle-version values, the supported-version registry, the current version, the canonical deck, deterministic deal reproduction, initial-layout creation from GD-DEAL-06 through GD-DEAL-08, reproducibility validation, Restart reproduction, and rejection of a new deal whose identity equals the current deal identity (GD-LIFE-01).
- The Flutter application owns fresh-identity generation. It supplies each identity explicitly, uses the domain's current version for a new deal, retries a rejected candidate, and owns persistence encoding and storage.
- Fresh-identity generation uses `Random.secure()` only.
- An unsigned 32-bit candidate is `(high16 << 16) | low16`, where `high16` and `low16` each come from `nextInt(65536)`.
- Fresh-identity generation must not use timestamps, counters, device identifiers, `hashCode`, an ordinary seeded `Random`, persisted PRNG state, or a third-party dependency.
- The application must exclude the current deal identity.
- The application must exclude the most recently completed deal identity.
- The cross-session source and retention of the most recently completed deal identity are deferred to a later persistence decision, provisionally ADR-08.
- Until that persistence decision is implemented, the complete product requirement is not yet implemented.
- The retry-loop structure and error handling for fresh-identity generation are not decided here.

### ADR-05.7 Verification

- SplitMix64 must be verified against independent reference outputs for seeds 0, 1, and 4,294,967,295, including consecutive outputs and high-bit values.
- Bounded draws must be tested for every bound from 2 through 52, including rejection consumption, threshold boundaries, range, and equivalence to the unsigned 64-bit contract.
- Complete permutation and initial-column golden vectors must be frozen for identities 0, 1, and 4,294,967,295, and for one ordinary interior identity.
- Golden values must be independently generated or checked, and the provenance of that check is recorded with the vectors.
- Invalid identities, and invalid, unknown, or unsupported versions, must be tested with no fallback.
- The smallest domain-internal or test-only fixture seam needed for GD-TEST-38 and GD-TEST-42 is permitted.
- That seam must not be a public custom-deal API, a dependency-injection framework, an interface hierarchy, a mocking package, or production configuration.
- Golden vectors are normative evidence for their shuffle version once they are frozen.
- Before the first public release, replacing a frozen version-1 vector is permitted only through an explicitly reviewed and owner-approved version-1 correction.
- After the first public release, a behavioral change requires a new shuffle version.
- The vectors belong with the domain package's conformance tests. Vector file names and the fixture-seam mechanism are not decided here.

### ADR-05.8 Version-1 implementation decisions (amendment, 2026-11-21)

This amendment records owner-approved implementation decisions for version 1. It settles, for version 1 only, the deal-identity and shuffle-version Dart type shapes, the version-registry API, the unsigned-arithmetic technique, the raw-output test seam, the vector format, and the ordinary interior identity. ADR-05.7 and ADR-11 had left those items open. The deferred list below now points here for them. It does not change ADR-05.1 through ADR-05.7.

- `DealIdentity` is a package-internal validating `final class` with value equality. A value outside 0 through 4,294,967,295 throws `ArgumentError`.
- `ShuffleVersion` is a package-internal enum. `ShuffleVersion.v1` has the explicit number 1, `current` is `v1`, and lookup by number fails closed with `ArgumentError`. A number below 1 is invalid. Any other positive number is unsupported. The persisted representation is the number, never the enum index or name. Version-to-algorithm dispatch is an exhaustive switch over the enum.
- SplitMix64 is a package-internal mutable class with private state and one raw-output method. It uses native Dart 64-bit `int` wraparound and `>>>` for every logical shift. This relies on the native targets of ADR-01. No `BigInt`, `dart:math`, or dependency is used in production.
- The bounded draw accepts bounds 2 through 52 only, the bounds the shuffle uses. Other bounds throw `ArgumentError`. With M = 2^63 − 1:
  - The threshold is `t = (2 * (M % b) + 2) % b`, because 2^64 = 2M + 2. This never forms 2^64.
  - Because 0 ≤ t < b ≤ 52, unsigned `r < t` holds exactly when `r >= 0 && r < t` on the signed bit pattern.
  - The unsigned remainder is `r % b` for a nonnegative bit pattern and `(r % b + t) % b` for a negative bit pattern, whose unsigned value is r + 2^64.
- The bounded draw and the Fisher–Yates shuffle take the raw-output source as a plain `int Function()`. That function parameter is the test seam for bounded-draw and Fisher–Yates conformance tests. It is not the fixture-layout seam for GD-TEST-38 and GD-TEST-42, which remains deferred. No public custom-deal API, injection framework, or diagnostics API is added.
- The deal output is an unmodifiable 52-card permutation p1 through p52. A separate function returns eight unmodifiable columns, T1 through T8, deepest card first, under GD-DEAL-06. No board, layout, or state type is introduced, and nothing is exported from the public domain library yet.
- The ordinary interior identity for the golden vectors is 3,141,592,653.
- The golden vectors were generated by two independently structured Java oracles: one using `long` overflow arithmetic and one using `BigInteger` modulo 2^64 throughout. Their complete outputs matched byte for byte. No normative identity hit a rejection. No Dart output was used. The provenance is recorded with the vectors.
- The vectors are Dart test constants in the domain package. Cards use compact codes such as `10H` and `AS`. Raw SplitMix64 outputs are 16-digit uppercase hexadecimal strings.
- Once this increment is approved and committed, the vectors are normative for version 1. Before the first public release, any version-1 correction requires explicit review and owner approval, as in ADR-05.5 and ADR-05.7.

## Consequences

- Deterministic deal generation adds no runtime dependency to the domain package.
- The domain owns deal generation from an explicit identity and shuffle version. ADR-03 permitted that ownership and left the algorithm deferred.
- A saved unfinished game depends on both the deal identity and the shuffle version. Their storage format remains deferred.
- No player-visible deal number or seed is introduced.
- The Flutter application generates fresh identities with `Random.secure()`. The domain remains independent of uncontrolled randomness.
- The application must exclude the most recently completed deal identity. The cross-session source and retention of that value are not decided here. Until the later persistence decision is implemented, the complete product requirement is not yet implemented.
- A released shuffle version remains reproducible while persisted data may reference it.

## Deferred or not decided

- Persistence format, codec, storage technology, and storage timing.
- The cross-session source and retention of the most recently completed deal identity, deferred to a later persistence decision, provisionally ADR-08.
- Dart type shapes, constructors, validation APIs, and result or error representations beyond those recorded in ADR-05.8. This includes any board, layout, or state type and any public export from the domain library. ADR-05.8 records the deal-identity and shuffle-version types, the version-registry API, the unsigned-arithmetic technique, the vector format, and the ordinary interior identity.
- The fixture-layout seam for GD-TEST-38 and GD-TEST-42, its signature, and its file location. The internal raw-output function parameters of ADR-05.8 are not that seam.
- New Deal, restoration, and application-coordination choices beyond those already decided in ADR-05.5 and ADR-05.6.
- State management and the transition API.
- Retry-loop structure and error handling for fresh-identity generation.
- Any later shuffle version, and any retirement or migration of a released version.
