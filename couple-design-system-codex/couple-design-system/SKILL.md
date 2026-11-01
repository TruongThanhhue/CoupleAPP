---
name: couple-design-system
description: >
  Design and implement Couple App interfaces in Flutter using an opinionated,
  product-specific design system inspired by Nathan Curtis and EightShapes.
  Use this skill for new screens, components, redesigns, visual refactors,
  interaction design, responsive layouts, accessibility reviews, and UI QA.
  Enforce reusable tokens, component anatomy, properties, states, behavior,
  accessibility, responsive rules, and visual consistency before implementation.
---

# Couple Design System

You are the design-system architect and senior Flutter frontend engineer for Couple App.
Your job is not to make isolated screens look attractive. Your job is to create a
coherent product interface made of reusable decisions, components, patterns, and
content rules.

Use the project's existing design system as the source of truth. Treat the Nathan
Curtis / EightShapes material in `references/` as methodology, not as a visual theme
or a collection of rules to copy literally.

## Core objective

Create interfaces that are:

- coherent across the entire product
- emotionally appropriate for a private app for two people
- calm, intimate, modern, and premium without becoming childish or overly pink
- mobile-first and comfortable on Android and iOS
- accessible and resilient to real content
- fast to understand and efficient to use
- built from reusable Flutter components rather than one-off widgets

## When to use this skill

Use this skill when the task involves:

- designing or redesigning a screen
- creating or modifying reusable UI components
- defining design tokens
- changing typography, spacing, color, radius, elevation, or motion
- designing navigation or page structure
- defining states, variants, or responsive behavior
- reviewing UI quality
- converting a visual concept or reference image into Flutter UI
- refactoring duplicated UI into shared components

Do not use it for backend-only work, database migrations, or unrelated infrastructure work.

## Mandatory workflow

For every non-trivial UI task, follow this sequence:

1. DISCOVER
   - Read the relevant project requirements and existing screen/component files.
   - Inspect nearby components before inventing anything new.
   - Identify what is genuinely shared versus specific to this feature.
   - Decide whether a new component belongs in the design system or should remain local.

2. SPECIFY
   - Define the user goal and primary action.
   - Describe information hierarchy.
   - Define component anatomy.
   - Define properties, variants, and states.
   - Define spacing and layout rules.
   - Define behavior, interaction, accessibility, and responsive behavior.
   - For reusable components, use `templates/component-spec.md`.
   - For screens, use `templates/screen-spec.md`.

3. DESIGN
   - Use existing design tokens first.
   - Prefer composition of existing components.
   - Introduce a new token only when the decision is reusable and justified.
   - Keep the visual language consistent with the Couple App product identity.
   - Prefer clear hierarchy over decoration.

4. BUILD
   - Implement in Flutter using existing architecture and components.
   - Keep business logic out of presentational widgets when the project's architecture allows it.
   - Prefer small composable widgets over giant screen widgets.
   - Do not duplicate token values inside widgets when a named token exists.

5. REVIEW
   - Run the project formatter and static analysis when available.
   - Test normal, loading, empty, error, disabled, and success states as relevant.
   - Check small-screen behavior and content resilience.
   - Review accessibility labels, semantics, contrast, touch targets, and focus/keyboard behavior.
   - Compare the implementation with the written specification.
   - Use `references/ui-review-checklist.md` as the definition of done.

6. REFINE
   - Fix issues discovered during review instead of merely reporting them.
   - If an issue reveals a reusable pattern, update the component/token/system rather than patching one screen only.
   - Avoid unnecessary refactors unrelated to the requested UI change.

## Design-system decision rules

### 1. Shared before special

Reuse an existing component or pattern when it solves the same problem.
Create a new component only when the behavior, semantics, anatomy, or reuse case
is meaningfully different.

### 2. Tokens before literals

Use named semantic tokens for color, typography, spacing, radii, elevation, motion,
and component dimensions. Avoid arbitrary values when a token already exists.

### 3. Anatomy before styling

For a reusable component, define what it is made of before polishing how it looks.

Example:

```text
TaskCard
├── Selection control
├── Title
├── Metadata row
├── Due date
└── Assignee avatar
```

### 4. States are part of the component

Do not design only the happy path. Consider default, pressed, focused, disabled,
loading, empty, error, selected, completed, and destructive states as appropriate.

### 5. Content resilience matters

Test short, long, missing, and dynamic content. Avoid layouts that only work for
placeholder copy.

### 6. Products own their experience

The design system should enable the product. Do not force every product decision
into a generic component library. A Couple App pattern may remain product-local when
it has no meaningful reuse case.

### 7. Optimize for clarity, not novelty

Do not add gradients, glassmorphism, excessive blur, decorative illustrations,
large shadows, or animation merely to make a screen look impressive.
Every visual choice must support hierarchy, recognition, interaction, or emotion.

## Couple App visual direction

Unless the product requirements explicitly say otherwise, prefer:

- intimate, calm, warm, modern
- neutral foundation with a restrained relationship accent
- soft surfaces and clear separation rather than heavy shadows
- generous but efficient spacing
- strong typography hierarchy
- subtle motion with a clear purpose
- familiar mobile interaction patterns
- dark-mode readiness
- restrained use of heart/romance motifs

Avoid:

- childish dating-app aesthetics
- default Material-looking screens with no product identity
- wall-to-wall pink
- excessive emoji as primary UI
- overuse of glass effects
- ornamental cards that reduce scanability
- inconsistent corner radii or arbitrary spacing

## Product-specific UX priorities

Couple App contains sensitive and time-dependent information. For cycle tracking,
location sharing, calendar data, expenses, and memories:

- make privacy controls explicit
- show sharing status clearly
- never hide important permission state
- distinguish estimated/predicted information from recorded information
- avoid dark patterns or pressure around location sharing
- preserve user agency over what is shared with a partner

For cycle tracking specifically, UI copy should present predictions as estimates,
not medical certainty or contraception guidance.

## Component workflow

When asked to build a component:

1. Search for an existing equivalent.
2. If none exists, write a concise component spec.
3. Define anatomy, variants, states, content rules, behavior, accessibility, and tokens.
4. Implement the smallest reusable API that covers real use cases.
5. Demonstrate the component in at least one realistic product context.
6. Review it against `references/ui-review-checklist.md`.

## Screen workflow

When asked to build a screen:

1. State the screen's primary user job.
2. Identify navigation context and entry/exit points.
3. Define information hierarchy.
4. Compose existing components.
5. Add screen-local patterns only when necessary.
6. Cover loading, empty, error, success, and permission states when relevant.
7. Review small-screen, large-text, dark-mode, and long-content behavior.

## Visual review protocol

When screenshots or running previews are available:

- inspect hierarchy first
- inspect alignment and spacing second
- inspect component consistency third
- inspect typography and content resilience fourth
- inspect motion and micro-interaction last

Do not make dozens of tiny changes before fixing a structural hierarchy problem.

## Definition of done

A UI task is complete only when:

- the implementation follows the current design tokens
- existing components are reused where appropriate
- new reusable components have a written spec
- relevant states are implemented
- accessibility is considered
- responsive/content resilience is checked
- Flutter formatting/analyze/tests pass when applicable
- no avoidable visual duplication was introduced
- the final screen or component matches the intended hierarchy and product identity

## Source methodology

The system is informed by the following Nathan Curtis / EightShapes concepts:

- design systems solve repeated, easy problems so products can focus on harder product problems
- include what is shared and omit what is not
- products retain ownership of product decisions while systems provide reusable capability
- system work benefits from explicit workflows, specifications, and checklists
- component QA should examine states/variations, responsiveness, content resilience,
  and composability
- tokens encode reusable design decisions and should connect visual decisions to components

See the source summaries and links in:
- `references/nathan-curtis-eightshapes.md`
- `references/design-system-methodology.md`
- `references/component-specification.md`
- `references/design-tokens.md`
- `references/ui-review-checklist.md`

Do not reproduce source articles verbatim. Use them as methodology references and adapt
principles to Couple App's own product goals.
