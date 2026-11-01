# Design System Methodology

## 1. Discover

Goal: determine whether a UI idea should become part of the design system and understand
its actual product context.

Checklist:

- Who uses it?
- What user problem does it solve?
- Is the problem repeated?
- Does an existing component already solve it?
- What behaviors are shared?
- What is unique to this feature?
- What platforms and contexts are involved?
- What states and content variations exist?

Output:

```text
Decision: reuse / extend / create local / create system component
Scope: what is included
Non-goals: what is intentionally omitted
```

## 2. Specify

Turn the idea into a precise contract before implementation.

Minimum specification:

- purpose
- anatomy
- properties
- variants
- states
- behavior
- content guidance
- accessibility
- responsive behavior
- tokens
- examples

## 3. Design

Compose the UI using existing system decisions.

Rules:

- choose tokens before raw values
- reuse patterns before inventing new ones
- make hierarchy visible through typography/space rather than decoration
- define state behavior, not just default appearance

## 4. Build

Translate the specification into Flutter.

Rules:

- use small, composable widgets
- preserve a stable public API
- avoid duplicating business logic in UI
- keep state management consistent with the project architecture
- use theme/token primitives where possible

## 5. Review

Review both the component and the context in which it is used.

Check:

- visual hierarchy
- alignment
- spacing
- token usage
- state coverage
- accessibility
- responsiveness
- long-content resilience
- composability
- platform conventions

## 6. Refine

Fix root causes. When the same visual problem appears in multiple places, update the
shared token/component/pattern instead of adding screen-specific exceptions.

## When to create a new token

Create a token when a design decision is:

- reused or likely to be reused
- semantically meaningful
- part of the product's visual language
- likely to change centrally later

Do not create a token for every one-off measurement.

## When to create a component

Create a reusable component when at least one of these is true:

- the behavior repeats
- the anatomy repeats
- the states repeat
- the same semantics appear in multiple screens
- central maintenance would provide clear value

Keep product-specific compositions as screen-level patterns when they do not yet have
real reuse.
