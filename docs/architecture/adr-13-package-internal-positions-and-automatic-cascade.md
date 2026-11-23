# ADR-13: Package-internal positions and automatic cascade

Status: Accepted

Date: 2026-11-22

## Context

The [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) defines a position as one free cell, one foundation slot, or one tableau column (GD-TERM-02). An exposed card is the card in an occupied free cell or the last card of a nonempty tableau column. Foundation cards are never exposed (GD-TERM-04). A card is safe only when it is exposed and the foundation levels meet GD-AUTO-02. Automatic evaluation scans FC1 through FC4 and then T1 through T8, transfers the first safe exposed card onto its foundation, and begins again from FC1 until a complete scan finds none (GD-AUTO-07, GD-AUTO-08). The ordered series of those transfers is one cascade (GD-TERM-11). The same starting board must produce the same cards in the same order (GD-AUTO-10, for cards and order).

[ADR-12](adr-12-package-internal-positional-board.md) introduced the package-internal positional `Board` and deferred position, transfer, and automatic cascade. This decision narrows that position and automatic-cascade deferral. It does not edit ADR-12. It does not decide a general transfer, a transition outcome, move counting, completion, game state, or application coordination.

[ADR-03](adr-03-repository-structure-and-domain-isolation.md) keeps this behavior in the pure-Dart domain. [ADR-04](adr-04-dependency-admission-policy.md) admits no dependency through this decision. [ADR-11](adr-11-testing-boundaries-and-verification-gates.md) keeps domain tests on `package:test` and forbids exporting an API only so tests can reach it.

## Decision

- `Position` is a package-internal sealed family in `packages/myfreecell_domain/lib/src/position.dart`. The public domain library does not export it.
- `FreeCellPosition` holds a zero-based index from 0 through 3. `TableauPosition` holds a zero-based index from 0 through 7. An index outside that range throws `ArgumentError.value` with the name `index`. Message prose is not a compatibility contract.
- `FoundationPosition` holds a `FoundationSlot`. It adds no suit of its own.
- Equality is variant-specific and positional. `hashCode` matches equality. There is no shared indexed-position type, label, one-based index, serialization, UI concept, or none variant.
- `exposedCard` reads a `Board` by exhaustive dispatch. An occupied free cell returns its card. An empty free cell returns null. A nonempty tableau column returns its last card, because columns are deepest first. An empty column returns null. Every foundation returns null, whatever its level. The read does not modify the board.
- `AutomaticTransfer` is immutable evidence of one automatic single-card move onto a foundation: a source `Position`, a `FoundationPosition` destination, and a `Card`. It is not a general `Transfer`. It stores no before or after board, no automatic-or-manual flag, and no card sequence. Its constructor does not read a board and does not judge legality.
- `AutomaticCascadeResult` stores the resulting `Board` and the ordered `AutomaticTransfer` list. The list is copied and exposed unmodifiable. Equality compares the board and the transfers in order, and `hashCode` matches that comparison. Construction does not require the transfers to have produced the board. The result is not a completion outcome, a move count, a status, or a transition type.
- `automaticFoundationCascade` is iterative. It scans free-cell indexes 0 through 3 and then tableau indexes 0 through 7, calling `exposedCard` for every inspected position. It selects the first exposed card for which `hasSafeFoundationLevels` is true, finds the one `FoundationSlot` whose `FoundationSlot.suit` equals the card's suit, and records an `AutomaticTransfer`. It does not use enum indexes as a suit-to-slot map and it does not depend on `Map` or `Set` iteration order.
- Each selected card is removed from its source, that destination level is incremented by one, and the next board is built with fresh collections through the validating `Board` factory. The input board and the collections it owns are not modified. The scan then starts again at free cell 0. A complete scan that finds no eligible card stops the cascade. The function returns that stable board and the ordered transfers.
- The private application step clears a `FreeCellPosition` and removes the last card of a `TableauPosition`. Its exhaustive `FoundationPosition` branch throws `StateError`. The cascade never selects a foundation source. The throw is defensive internal failure handling, not a gameplay rejection.
- A stable input, including an input whose foundations are already complete, returns an equal board and no transfers. No termination counter, stable-board predicate, unchecked `Board` constructor, or general application API is added.
- No dependency, manifest change, analyzer-configuration change, or public export is made.

## Traceability

Fully advanced at this boundary:

- GD-TERM-02, as the sealed position family.
- GD-TERM-04, as `exposedCard`.
- GD-AUTO-02 at board level, by testing exposure here and reusing `hasSafeFoundationLevels` for the foundation conditions.
- GD-AUTO-09. Each recorded step moves one conserved card onto a foundation, and the scan stops when no safe exposed card remains, so a cascade records at most 52 transfers. There is no separate termination counter.
- GD-TERM-11, as the ordered automatic transfers produced from one board.

Partially advanced:

- GD-TERM-10, as automatic-transfer evidence, without move counting or a general transfer model.
- GD-TERM-13 and GD-INV-06 at board level only. The resulting board has no safe exposed card. A full domain stable state also requires the rest of game state and that no transition is in progress.
- GD-AUTO-06, destination aspect only. Move counting is not implemented.
- GD-AUTO-07, except move counting.
- GD-AUTO-08, one-card step aspect only. The ordered list is recorded here. It is not a transition outcome.
- GD-AUTO-10, cards and order only. Move count and Restart are not implemented.
- GD-FND-05, automatic aspect only.
- Preservation of GD-INV-01 through GD-INV-03, because every next board is rebuilt through `Board`.
- GD-TEST-23, automatic Ace destination aspect only.
- GD-TEST-24, stable aspect only.
- GD-TEST-25 and GD-TEST-26, order aspects only.

Not claimed:

- GD-TERM-05 through GD-TERM-08.
- GD-AUTO-03 through GD-AUTO-05.
- GD-DEAL-08.
- GD-CNT-*.
- GD-INV-04 and GD-INV-05.
- GD-CMP-*.
- GD-TEST-27, GD-TEST-28, GD-TEST-29, GD-TEST-39, GD-TEST-42, and GD-TEST-43.
- New Deal, history, restoration, Undo, Redo, persistence, public coordination, and general transfer behavior.

## Consequences

- Domain code can name a free cell, foundation slot, or tableau column and can run a deterministic automatic foundation cascade on a `Board`.
- The cascade returns a board with no safe exposed card, plus the ordered single-card evidence that produced it. It does not count moves, set a status, or report completion.
- `Board`, `Position`, and the cascade stay package-internal. The public barrel still exports only the card vocabulary.
- ADR-12's deferral of position and automatic cascade is narrowed by this decision. ADR-12 is unchanged. The other deferrals recorded there remain deferred.
- No package is added. No Flutter, Android, persistence, or restoration behavior changes.

## Deferred or not decided

- A general `Transfer`, deliberate transfer, request, outcome, and transition model.
- Any board mutation or transfer application outside this cascade.
- Move count, status, completion outcome, and any `GameState`.
- New Deal coordination, Restart, history, Undo, Redo, restoration, and persistence.
- Gameplay UI and Flutter behavior.
- Whether any of these types is ever exported.
- The GD-TEST-38 and GD-TEST-42 fixture seam.
- Every other deferral in ADR-01 through ADR-05, ADR-11, and ADR-12 that this decision does not narrow.
