# ADR-12: Package-internal positional board

Status: Accepted

Date: 2026-11-22

## Context

The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) separates a game state's board from its deal identity, move count, status, and history (GD-STATE-01). The board is FC1 to FC4, F1 to F4 with foundation levels, and T1 to T8 as ordered tableau columns. A foundation at level k holds Ace through rank k of its assigned suit, with no gaps (GD-STATE-03, GD-FND-01). Every stable state conserves the 52 cards (GD-INV-01), holds at most one card in each free cell (GD-INV-02), and keeps each foundation contiguous from Ace up to its level (GD-INV-03).

GD-DEAL-06 through GD-DEAL-08 fix the initial layout: empty free cells, foundations at level 0, and the permutation dealt into eight columns. Automatic foundation evaluation begins only after that layout exists (GD-DEAL-08). The layout before that cascade is not an Accepted New Deal state.

[ADR-03](adr-03-repository-structure-and-domain-isolation.md) places deterministic gameplay state in the pure-Dart domain and leaves state management deferred. [ADR-04](adr-04-dependency-admission-policy.md) admits no dependency through this decision. [ADR-05](adr-05-deterministic-deal-generation.md) defines deterministic deal generation. ADR-05.8 implements the permutation and the eight initial columns, and it explicitly introduces no board, layout, or state type and exports nothing. It leaves any board type and any public export deferred. [ADR-11](adr-11-testing-boundaries-and-verification-gates.md) keeps domain tests on the existing `package:test` runner, forbids a public export added only for tests, and leaves the GD-TEST-38 and GD-TEST-42 fixture seam deferred.

This decision records only the package-internal positional board. It does not decide application coordination or a public API.

## Decision

- `Board` is a package-internal, non-const `final class` in `packages/myfreecell_domain/lib/src/board.dart`. The public domain library does not export it.
- `Board` contains positional card state only:
  - `freeCells` is FC1 through FC4, each entry empty or one card;
  - `foundationLevels` is F1 through F4, each a level from 0 through 13;
  - `columns` is T1 through T8, and cards inside a column are deepest first.
- `Board` is not a complete game state. It has no deal identity, shuffle version, move count, status, or history.
- A `Board` may validly represent the pre-cascade dealt layout and an intermediate-cascade layout. Empty columns, gapped free cells, non-sequence-valid columns, an exposed safe card, and a foundation-only layout are valid when the board invariants hold.
- `Board` enforces only the approved board-level representation and conservation invariants. It checks, in this order:
  1. `freeCells` has exactly four entries;
  2. every `FoundationSlot` is present;
  3. every level is from 0 through 13, in `FoundationSlot.values` order;
  4. `columns` has exactly eight entries;
  5. every card is conserved exactly once.
- Conservation treats foundation level n as Ace through rank n of that slot's fixed suit. It observes implied foundation cards first, in `FoundationSlot.values` order and ascending `Rank.values` order, then occupied free cells from FC1 through FC4, then tableau columns from T1 through T8, deepest first. The first repeated card is a duplicate failure. The first canonical-deck card not observed is a missing-card failure. A count of 52 occurrences is not sufficient.
- Representation failures use `ArgumentError.value` with the parameter name. Conservation failures throw `ArgumentError` with no parameter name. The invalid value is the repeated or missing card.
- The constructor copies caller-provided collections, including every nested column, and stores unmodifiable collections. The exposed foundation map is in `FoundationSlot.values` order. Construction does not mutate its inputs.
- Equality is positional value equality, implemented without a dependency. Free-cell position, foundation levels in `FoundationSlot.values` order, tableau-column position, and card order within a column all participate. `hashCode` uses `Object.hash` and `Object.hashAll`.
- `dealtBoard` is the deterministic pre-cascade dealt board for a deal identity and shuffle version: four empty free cells, every foundation level 0, and columns from `initialColumns(dealPermutation(identity, version))`. It composes the approved deal functions. It does not change their vectors or compatibility behavior. It is not an Accepted New Deal state.
- The `Board` constructor is not the GD-TEST-38 or GD-TEST-42 fixture-seam decision. Those scenarios still require the seam left open by ADR-05 and ADR-11.
- No dependency, manifest, Flutter, persistence, restoration, transition, or public-export decision is made.

## Consequences

- Domain code can represent a conserved board before a game state, transition model, or persistence model exists.
- Pre-cascade and intermediate-cascade positions are representable. Cascade exhaustion is not required and is not performed.
- `dealtBoard` reuses the approved permutation and initial-column functions. Deterministic-deal vectors and compatibility behavior stay where ADR-05 put them.
- `Board` remains package-internal until a separate application-coordination and public-API decision. The Flutter application still reaches the domain only through the public barrel, which does not export `Board`.
- No package is added. No Flutter, Android, persistence, or restoration behavior changes.

## Deferred or not decided

All previously deferred boundaries remain deferred. This decision does not resolve them.

- Complete game state, including deal identity, shuffle version, move count, status, and history, and any `GameState` type.
- Application coordination and the public domain API, including whether `Board` is ever exported.
- Position, transfer, request, outcome, transition, snapshot, restoration, and persistence.
- Automatic cascade, move legality, New Deal, Restart, history, and gameplay UI.
- The GD-TEST-38 and GD-TEST-42 fixture seam, including its signature and file location. The `Board` constructor is not that seam.
- Any dependency, manifest, analyzer-configuration, or public-export change.
- State management and the transition API, as left open by ADR-03 and ADR-05.
- Every other deferral recorded in ADR-01 through ADR-05 and ADR-11.
