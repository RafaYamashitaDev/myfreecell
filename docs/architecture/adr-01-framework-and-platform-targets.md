# ADR-01: Application framework and platform targets

Status: Accepted

Date: 2026-11-06

## Context

MyFreecell is a standalone FreeCell mobile application. Android is the immediate development, testing, and initial Play Store target. Future Apple compatibility is intended, while iOS testing and App Store publication are deferred. No web application is in scope.

The [product specification](../product/product-spec.md) and the [gameplay/domain specification](../gameplay/gameplay-domain-spec.md) are approved. Neither selects an implementation technology.

## Decision

- Use Flutter with Dart.
- Generate and maintain the Android platform target initially.
- Do not generate or maintain web, Windows, macOS, or Linux targets.
- Defer iOS development, testing, and publication.
- Preserve reasonable source-level compatibility for adding iOS later.
- Runtime plugins should support Android and iOS unless an explicit exception is reviewed and approved.
- No specific runtime package is approved by this decision.

## Consequences

- When scaffolding is approved, the application will be a Flutter Android app.
- iOS remains outside version-one acceptance.
- A runtime plugin that does not support both Android and iOS needs an explicit reviewed exception.
- Package admission is governed by [ADR-04](adr-04-dependency-admission-policy.md).

## Deferred or not decided

- No specific runtime package is approved.
- State management, persistence, navigation, rendering, sound, testing details, and iOS project generation remain deferred.
