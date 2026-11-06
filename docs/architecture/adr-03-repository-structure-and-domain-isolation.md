# ADR-03: Repository structure and domain isolation

Status: Accepted

Date: 2026-11-06

## Context

Deterministic FreeCell rules must stay independent of Flutter, the clock, uncontrolled randomness, and storage. The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) owns rules, outcomes, invariants, and persistence eligibility. It leaves deal-identity generation mechanics, storage format, storage timing, and code organization to architecture. Player-facing outcomes remain in the [product specification](../product/product-spec.md).

## Decision

- Keep one repository.
- Place one Flutter application package at the repository root.
- Place one private pure-Dart package at `packages/myfreecell_domain`.
- Dependency direction is only from the Flutter application to the domain package.
- The domain package has no Flutter dependency.
- The domain owns deterministic gameplay state, rules, outcomes, invariants, completion detection, Undo and Redo history, restoration validation, and domain conformance tests.
- The Flutter application owns presentation, animation, application coordination, navigation, lifecycle, active-time measurement, persistence encoding and storage, sound, localization, and platform integration.
- Time, deal identity, and other environmental values are supplied explicitly where required.
- The domain must be independent of uncontrolled randomness. It may later own deterministic deal generation from explicit deal identity and shuffle-version inputs.
- Domain outputs may describe semantic transfers but must not contain coordinates, animation durations, curves, gestures, widget identifiers, or other presentation details.
- Do not add other internal packages, a generalized game engine, a monorepo-management tool, or a package-publishing workflow during scaffolding.

## Consequences

- Domain conformance tests can run without Flutter.
- The application supplies time, deal identity, and other environmental inputs the domain needs.
- Presentation details stay in the Flutter application.
- Scaffolding does not introduce further packages, a game engine, a monorepo tool, or a publishing workflow.

## Deferred or not decided

Shuffle algorithm and version representation, persistence format, state management, and navigation mechanism remain deferred.
