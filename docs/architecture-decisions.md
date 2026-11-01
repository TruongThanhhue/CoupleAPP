# Architecture decisions

## ADR-001 — Start as a modular monolith

**Decision:** Build one ASP.NET Core deployment with Domain, Application, Infrastructure, and API boundaries; keep modules internally cohesive.

**Reasoning:** The MVP requires reliable cross-module authorization and transactions. Separate services would add deployment and operational complexity before a load or team boundary justifies it.

## ADR-002 — Flutter client is feature-oriented and token-driven

**Decision:** Place screen code in feature folders while keeping routing, theming, API boundaries, and shared primitives in `core/`.

**Reasoning:** It aligns the mobile implementation with product modules, enables consistent design tokens, and avoids a monolithic UI layer.

## ADR-003 — Internal data remains authoritative

**Decision:** Tasks and events are first created in Couple App's data model. Google APIs are synchronization adapters, not core domain dependencies.

**Reasoning:** Shared two-person data needs consistent authorization and must work when providers are unavailable or disconnected.

## ADR-004 — Sensitive sharing is explicit and server-enforced

**Decision:** Cycle sharing, location sharing, retention, and time-limited location sessions are permissions evaluated by the server; UI makes current state visible.

**Reasoning:** Client code cannot be trusted as an authorization boundary and sensitive data requires clear user agency.

## ADR-005 — Use a deterministic first cycle prediction

**Decision:** Start with an explainable historical-interval average and persist prediction/actual outcomes for later evaluation.

**Reasoning:** This is auditable, understandable, and avoids medical overclaiming while preserving an upgrade path.

## ADR-006 — Target available .NET 9 during scaffolding

**Decision:** Bootstrap server projects on `net9.0` because SDK 9.0.318 is present. Upgrade to ASP.NET Core 10 only once that SDK is installed and compatibility is validated.

**Reasoning:** A project should remain runnable on the supplied development machine rather than declare an unavailable target.
