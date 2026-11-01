# Nathan Curtis / EightShapes — Research Reference

This document is a distilled methodology reference for AI-assisted design work.
It is intentionally paraphrased rather than copied from the source articles.

## Why this research is included

Nathan Curtis, founder of EightShapes, writes extensively about design-system strategy,
component specification, tokens, documentation, workflows, and QA. The aim here is not
to imitate a particular visual style. The aim is to teach Codex a way of making and
maintaining interface decisions systematically.

## Core principles to apply

### Systems solve repeated, easy problems

Repeated interface problems should be solved once and made reusable where reuse creates
real value. This lets product work spend more attention on unique user problems.

### Include what is shared; omit what is not

A polished UI is not automatically a design-system component. Promote an element into
the system when there is meaningful reuse, consistency, or maintenance value. Keep
feature-specific solutions local when their behavior is genuinely unique.

### Products keep ownership

A design system supports product teams; it should not take ownership of product strategy,
feature priority, or every customer journey decision.

### Documentation is part of the system

A component is more usable when its purpose, anatomy, options, states, behavior, and
examples are easy to understand. Good documentation reduces ambiguity for designers
and developers.

### Specifications make implementation predictable

A reusable component should describe more than its final screenshot. Document structure,
properties, states, behavior, layout, accessibility, motion, and token relationships.

### QA is a system activity

Review should consider state coverage, responsive behavior, content resilience, and
composition—not only pixel-level appearance.

### Workflow creates consistency

Use a repeatable sequence for system work. The EightShapes material commonly frames
this as discovery, design, build, documentation, and publication. For Couple App,
implementation is also followed by explicit review and refinement.

## Applying the principles to Couple App

| EightShapes idea | Couple App interpretation |
|---|---|
| Shared problems | Task cards, avatars, buttons, calendar cells, sheets, navigation |
| Product-specific solutions | Cycle prediction summary, couple home composition, live location status |
| Product ownership | Product decisions stay in requirements, not hidden inside generic widgets |
| Specification | Every reusable Couple component gets anatomy/props/states/behavior/accessibility |
| QA | Review all relevant states, content lengths, devices, permissions, and dark mode |
| Workflow | Discover → Specify → Design → Build → Review → Refine |

## Important boundary

Do not treat Nathan Curtis's writings as a license to over-engineer. The methodology
should make the product easier to build and change. If an abstraction increases
complexity without a concrete reuse or consistency benefit, keep the solution local.

## Primary sources

1. Nathan Curtis, “Principles of Design Systems” (EightShapes).
   https://eightshapes.com/articles/principles-of-designing-systems/

2. Nathan Curtis, “Defining Design Systems” (EightShapes).
   https://eightshapes.com/articles/defining-design-systems/

3. Nathan Curtis, “Design System Features, Step by Step” (EightShapes).
   https://eightshapes.com/articles/design-system-features-step-by-step/

4. Nathan Curtis, “Design System Subtasks, by Step” (EightShapes).
   https://eightshapes.com/articles/design-system-subtasks-by-step/

5. Nathan Curtis, “Tokens in Design Systems” (EightShapes).
   https://eightshapes.com/articles/tokens-in-design-systems/

6. Nathan Curtis, “Documenting Components” (EightShapes).
   https://eightshapes.com/articles/documenting-components/

7. Nathan Curtis, “Component QA in Design Systems” (EightShapes).
   https://eightshapes.com/articles/component-qa-in-design-systems/

8. Nathan Curtis, “Reference Designs for Systems” (EightShapes).
   https://eightshapes.com/articles/reference-designs-for-systems/

## Usage rule

Use these sources for methodology and terminology. Do not quote or reproduce large
passages. The project's own design decisions remain the source of truth.
