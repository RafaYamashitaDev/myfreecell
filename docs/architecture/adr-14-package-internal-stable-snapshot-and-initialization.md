# ADR-14: Package-internal stable snapshot and initialization

Status: Accepted

Date: 2026-11-23

## Context

The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) defines a domain game state as a deal identity interpreted under its shuffle-function version, a board, a move count, a status of In progress or Completed, and a history (GD-STATE-01). A stable state has no transfer or cascade in progress and no safe exposed card (GD-TERM-13, GD-INV-06). In a stable state the move count is a non-negative integer at least as large as the number of cards on the foundations (GD-INV-05), and the status is Completed if and only if every foundation is at level 13 (GD-INV-04, GD-CMP-01). The initial move count is not a separate stored component. It is the number of automatic transfers in the cascade that runs after the dealt layout exists (GD-STATE-05, GD-DEAL-08, GD-CNT-02, GD-AUTO-10). That cascade can finish the deal. No special exception applies (GD-CMP-07).

History is still untyped. A complete `GameState` would include that history, so introducing one now would name a value the specification does not yet allow this package to hold. The value introduced here is history-free stable content. It is not a complete game state.

[ADR-12](adr-12-package-internal-positional-board.md) records the package-internal positional `Board` and `dealtBoard`, and it defers complete game state and snapshot. [ADR-13](adr-13-package-internal-positions-and-automatic-cascade.md) records positions and `automaticFoundationCascade`, and it defers a stable-board predicate, move count, and status. This decision narrows those deferrals. It does not modify ADR-12 or ADR-13.

[ADR-03](adr-03-repository-structure-and-domain-isolation.md) keeps this behavior in the pure-Dart domain. [ADR-04](adr-04-dependency-admission-policy.md) admits no dependency through this decision. [ADR-11](adr-11-testing-boundaries-and-verification-gates.md) keeps domain tests on `package:test` and forbids exporting an API only so tests can reach it.

## Decision

- `GameStatus` is a package-internal enum in `packages/myfreecell_domain/lib/src/game_status.dart` with exactly two values, `inProgress` and `completed`. There is no other lifecycle state. There is no persisted numeric or string representation. The enum index and the name are not compatibility contracts. Status is derived by `StableGameSnapshot`. It is not stored independently.
- `isStableBoard` is a package-internal predicate on `Board` in `automatic_cascade.dart`. It is `_nextAutomaticTransfer(board) == null`. It shares the existing scan and safety rule. It does not duplicate that scan, run the cascade, or modify `automaticFoundationCascade` or `_nextAutomaticTransfer`. It does not modify the board and it is not a general validator. The predicate is board-level only. It says nothing about move count, whether a transition is in progress, or a complete game state.
- `StableGameSnapshot` is a package-internal `final class` in `stable_game_snapshot.dart`. It is history-free stable content. It is not a complete `GameState`, a transition outcome, a serialized form, or a final persistence schema. It stores `DealIdentity identity`, `ShuffleVersion shuffleVersion`, `Board board`, and `int moveCount` directly. There is no descriptor, metadata wrapper, or move-count type. It stores no transfer evidence and no history. It does not check that the identity and version reproduce the board. The board, identity, and version are retained directly because they are immutable.
- Construction checks, in this order:
  1. `moveCount < 0` throws `ArgumentError.value` with the move count as the invalid value and the name `moveCount`;
  2. `moveCountCoversFoundationCards` returning false throws `ArgumentError.value` with the move count as the invalid value and the name `moveCount`;
  3. `isStableBoard(board)` returning false throws `ArgumentError.value` with the supplied board as the invalid value and the name `board`.
- Message prose is not a compatibility contract. The two move-count failures use different messages. A move count may be greater than the number of cards on the foundations.
- `status` is derived: `areFoundationsComplete(board.foundationLevels)` selects `GameStatus.completed`, and every other stable board selects `GameStatus.inProgress`. There is no stored completion flag, event, or indicator. Equality compares identity, shuffle version, board, and move count. It excludes derived status. `hashCode` uses `Object.hash` of those four fields.
- `InitialGameSnapshot` is a package-internal `final class` in `initial_game_snapshot.dart`. Its constructor is library-private. It stores a `StableGameSnapshot` and the ordered `AutomaticTransfer` list. The list is copied and exposed unmodifiable, so no mutable alias survives. Equality compares the snapshot and the transfers in order, with an explicit length check and an index loop. `hashCode` uses `Object.hash` and `Object.hashAll`. `InitialGameSnapshot` is not an Accepted result, a request result, a transition, a transaction, or a complete game state.
- `initialGameSnapshot(DealIdentity identity, ShuffleVersion version)` reproduces one initial snapshot. Both parameters are required and positional. The pipeline is exactly:
  1. `dealtBoard(identity, version)`;
  2. `automaticFoundationCascade` on that board;
  3. the move count is `cascade.transfers.length`;
  4. `StableGameSnapshot` with the supplied identity, the supplied version, `cascade.board`, and that count;
  5. `InitialGameSnapshot._` with that snapshot and `cascade.transfers`.
- The function does not read `ShuffleVersion.current`, draw random numbers, compare identities, classify Accepted or Invalid, initialize history, or build a pre-cascade snapshot with move count zero. It does not catch a validation failure. The resulting status may be `completed` when the cascade finishes the foundations. No special completion behavior is added.
- No dependency, manifest change, analyzer-configuration change, or public export is made. No Flutter or Android behavior is decided.

## Traceability

Fully advanced: none. This increment does not complete a specification item on its own.

Partially advanced:

- GD-STATE-01, items 1 through 4 only, as history-free stable content. History is absent, so the requirement is not complete.
- GD-STATE-05, initial-count derivation. The count is the initial cascade's transfer length. It is not a separately stored component.
- GD-INV-04, for this snapshot value. Derived status agrees with foundation completion.
- GD-INV-05, construction guard only. The move count is rejected when it is negative or below the foundation-card total.
- GD-INV-06 and GD-TERM-13, at board level, through `isStableBoard`.
- GD-DEAL-03, the deterministic identity-and-version value aspect. The same identity and explicit version reproduce the same initial snapshot.
- GD-DEAL-08, composition order only. The dealt layout is complete before the cascade runs.
- GD-LIFE-02, initial-state content only. No request, Accepted classification, or history clear is implemented.
- GD-CNT-02, the initial-cascade counting aspect. Each recorded automatic transfer contributes one to the initial move count.
- GD-AUTO-10, initial-count determinism for the initial cascade. Restart is not implemented.
- GD-CMP-01 and GD-CMP-07, status-value aspects only. A snapshot can derive `completed`. Completion is not reported.
- GD-TEST-27, the initial post-cascade stability aspect for the tested identities only.

Preserved, not newly claimed:

- GD-INV-01 through GD-INV-03, because the board is still built through `Board`.

Not claimed:

- Complete GD-STATE-01.
- GD-STATE-06 through GD-STATE-08.
- New Deal, Restart, Restore, history, and persistence.
- Completion reporting.
- GD-TEST-25.
- GD-TEST-42.
- GD-TEST-35 through GD-TEST-44.

## Consequences

- Domain code can hold a history-free stable snapshot and can reproduce the initial snapshot of a deal identity under an explicit shuffle version.
- `isStableBoard` and the cascade share one scan. Cascade order, rescan behavior, and transfer evidence are unchanged.
- The initial move count is the length of that first cascade. There is no pre-cascade snapshot whose count is zero.
- `GameStatus`, `StableGameSnapshot`, and `InitialGameSnapshot` stay package-internal. The public barrel still exports only the card vocabulary.
- ADR-12's deferral of complete game state is narrowed to this history-free snapshot, and the snapshot item in its deferred list is narrowed to this package-internal value. ADR-13's statement that no stable-board predicate is added, and its deferral of move count and status, are narrowed to `isStableBoard` and this snapshot. Neither ADR is modified. Their other deferrals remain deferred.
- No package is added. No Flutter, Android, persistence, or restoration behavior changes.

## Deferred or not decided

- A complete `GameState`, including typed history.
- New Deal requests and the Accepted and Invalid classifications. Restart. Restore.
- Deliberate moves, transition outcomes, and completion reporting.
- Undo, Redo, and any history entry or cursor.
- Restoration, persistence, and any serialized form or final persistence schema. `StableGameSnapshot` is not that schema.
- Gameplay UI and Flutter or Android behavior.
- Whether any of these types is ever exported.
- Every other deferral in ADR-01 through ADR-05 and ADR-11 through ADR-13 that this decision does not narrow.
