# ADR-11: Testing boundaries and domain verification gates

Status: Accepted

Date: 2026-11-14

## Context

The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) requires `GD-TEST-01` through `GD-TEST-44` to be verifiable from domain inputs and outputs alone. Those identifiers are stable traceability references. The specification does not choose test files, runners, or code organization.

[ADR-03](adr-03-repository-structure-and-domain-isolation.md) assigns deterministic conformance tests to the pure-Dart domain package. That package has no Flutter dependency. This ADR requires the domain tests to run without Flutter. The Flutter application owns presentation and application coordination. [ADR-04](adr-04-dependency-admission-policy.md) prefers the existing Dart and Flutter test capabilities and admits no package through this decision. [ADR-05.7](adr-05-deterministic-deal-generation.md) requires the SplitMix64 reference checks, bounded-draw checks, golden vectors, provenance, and fail-closed behavior. ADR-05 explicitly places the vectors with the domain package's conformance tests. This ADR places the complete deterministic deal-generation evidence in the domain test boundary. ADR-05 permits the smallest seam for `GD-TEST-38` and `GD-TEST-42` and leaves the fixture-seam mechanism and vector file names undecided. [ADR-01](adr-01-framework-and-platform-targets.md) deferred testing details.

This ADR establishes testing boundaries and verification gates. It does not design future domain APIs, fixtures, or individual scenario implementations. The public domain library exports no API yet, so the visibility rule is fixed before the first export.

## Decision

### ADR-11.1 Testing boundaries and API visibility

- Domain-focused tests and `GD-TEST-*` conformance tests live under `packages/myfreecell_domain/test/`.
- They use the existing `package:test` runner and must not import Flutter.
- Domain-package tests may access unexported implementation code under `packages/myfreecell_domain/lib/src/` when direct deterministic verification is necessary.
- `lib/src` is package-internal by architecture. Dart does not enforce this boundary against direct imports from another package.
- The Flutter application and its tests may import the domain only through `package:myfreecell_domain/myfreecell_domain.dart`.
- The public barrel must not export anything solely to make testing easier.
- Do not publicly expose SplitMix64 state or raw outputs, bounded-draw helpers, arbitrary permutation or initial-layout injection, test fixtures, custom-deal functionality, or test-only flags or configuration.
- A domain concept may be public when normal application coordination genuinely requires it. The restriction applies to test-only exports.
- Focused domain tests may directly exercise unexported implementation pieces needed to verify ADR-05, including SplitMix64 reference outputs, unsigned 64-bit behavior, rejection thresholds, bounded draws, and Fisher–Yates permutation generation.
- The smallest package-internal permutation or initial-layout seam for `GD-TEST-38` and `GD-TEST-42` is approved in principle.
- That seam is deferred until it is required. Its signature and file location remain undecided.
- Production New Deal must always use the approved shuffle.
- The seam must not be exported through the public barrel.
- The seam must not introduce an interface hierarchy, a dependency-injection framework, a mocking package, a global test switch, a public custom-deal API, or production configuration.
- Flutter widget tests remain under the root `test/` directory and use `flutter_test`.
- Flutter widget tests cover presentation and application coordination. They are not authoritative evidence for `GD-TEST-*` or ADR-05 golden vectors.
- Device integration tests and automated evidence for `AC-01` through `AC-24` remain deferred until the corresponding application behavior exists.
- No dependency change is approved. Retain the existing `package:test` and Flutter SDK `flutter_test` capabilities.
- Add no mocking, snapshot, property-testing, code-generation, or additional testing-framework package.
- All domain tests must be reproducible.
- A future randomized sequence test, including `GD-TEST-43`, must use an explicit fixed seed recorded in the test.
- The generator, sequence count, and shrinking strategy remain undecided. That deferral does not approve a property-testing package.

### ADR-11.2 Per-increment verification gate

- A gameplay-domain implementation increment is complete only when formatting passes for every Dart file changed by the increment.
- Domain analysis must pass with no diagnostics by running `dart analyze` from `packages/myfreecell_domain`.
- All domain tests must pass by running `dart test` from `packages/myfreecell_domain`.
- Each increment includes focused tests for every rule, invariant, algorithm, validation condition, and failure case that it implements.
- Applicable `GD-TEST-*` identifiers appear in relevant test descriptions or groups for traceability.
- An increment does not need to implement unrelated future `GD-TEST-*` scenarios.
- `GD-TEST-01` through `GD-TEST-44` collectively gate completion of the gameplay domain as a whole.
- The deterministic deal-generation increment additionally includes all ADR-05.7 evidence. This list is additional to the general per-increment test obligation above:
  - independent SplitMix64 reference checks;
  - bounded-draw tests for bounds 2 through 52;
  - complete permutation and initial-column vectors for the approved four-identity set: identities 0, 1, and 4,294,967,295, plus one ordinary interior identity, whose concrete value is not chosen here;
  - recorded independent provenance;
  - invalid identity and version behavior;
  - no unsupported-version fallback.
- If an increment changes the public domain API or behavior used by the Flutter application, `flutter analyze` and `flutter test` run from the repository root.
- A pure-domain increment does not by itself require an Android APK build.
- An Android build is required only when production Flutter application files change, Android files change, dependencies or build configuration change, a broader integration or release checkpoint is reached, or independent review identifies a concrete integration risk.
- A root test-only change does not by itself require an Android build.
- No numeric code-coverage threshold is established. Tests must demonstrate approved behavior and meaningful failure paths.
- Before commit, an independent read-only review verifies authorized scope, test-to-requirement traceability, public API discipline, deterministic behavior, and the absence of unauthorized dependencies or architecture changes.

## Consequences

- Domain conformance evidence runs without Flutter. Widget tests do not replace it.
- `lib/src` is package-internal by architecture. The Dart language does not enforce that boundary against a direct import from another package. This ADR makes no analyzer-configuration decision.
- Public domain exports are not added solely for tests. Production New Deal keeps the approved shuffle when the later seam exists.
- A domain increment carries tests for the rules it implements. The full `GD-TEST-01` through `GD-TEST-44` suite gates the completed gameplay domain.
- The deal-generation increment carries the ADR-05.7 evidence, including provenance recorded with the vectors. It does not select the ordinary interior identity.
- A pure-domain increment does not by itself require an Android APK build. An Android build is required only when production Flutter application files change, Android files change, dependencies or build configuration change, a broader integration or release checkpoint is reached, or independent review identifies a concrete integration risk. A root test-only change does not by itself require an Android build.
- No package is added, and no coverage threshold is created.
- A future randomized sequence test, including `GD-TEST-43`, stays reproducible through a fixed seed recorded in the test.

## Deferred or not decided

- The signature and file location of the `GD-TEST-38` and `GD-TEST-42` seam, and any addition of that seam before those scenarios are implemented.
- The `GD-TEST-43` generator, sequence count, and shrinking strategy. This does not approve a property-testing package.
- Device integration tests and automated evidence for `AC-01` through `AC-24`.
- Test file names, group structure, and how many `GD-TEST-*` identifiers share a test.
- Golden-vector and reference-output format, where the provenance note is written, and the concrete ordinary interior identity. Those remain where ADR-05 left them.
- Unexported library names used for direct ADR-05 checks.
- How a future partial worked example is completed to a 52-card state.
- Formatter flags, analyzer flags, and the invocation used to show that formatting passes.
- Who performs the independent read-only review.
- Coverage services, CI, `integration_test`, and any additional package.
