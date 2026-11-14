# MyFreecell

MyFreecell is a standalone FreeCell solitaire game for mobile devices.

## Scope

- Standalone application; not part of any game collection.
- Android is the initial development, testing, and release target.
- Apple compatibility is intended in the future; iOS testing and release are deferred.
- No web version is in scope.
- No accounts, sign-in, personal data, backend services, or custom cloud synchronization.

## Status

The [product specification](docs/product/product-spec.md) and the [gameplay/domain specification](docs/gameplay/gameplay-domain-spec.md) remain approved.

[ADR-01](docs/architecture/adr-01-framework-and-platform-targets.md) through [ADR-05](docs/architecture/adr-05-deterministic-deal-generation.md) remain accepted. They are recorded in [`docs/architecture/`](docs/architecture/).

The Android-only Flutter scaffold now exists. It was generated with Flutter 3.47.9 stable, framework revision `c197ca5199e9ee5661e865596c9c07294dfab51c`, and bundled Dart 3.13.7. The private pure-Dart domain package exists at `packages/myfreecell_domain`.

Product implementation has not started. Generated Flutter and Dart demonstrations have been removed. The repository now contains a neutral application shell, and the domain package currently exports no public domain API. Landscape launch is configured for both directions with Android userLandscape and Flutter's pre-frame request; Android 16 and later may ignore that restriction on some large-screen, foldable, desktop-mode, and multi-window displays, which is not yet verified. Remaining deferred architecture decisions remain deferred.
