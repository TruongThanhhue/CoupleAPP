# Couple App — AGENTS.md

This repository uses the `couple-design-system` skill for UI/UX and Flutter frontend work.

## UI source of truth

For interface work, prefer this order of authority:

1. Existing Couple App design tokens and components
2. Product requirements and established screen patterns
3. `couple-design-system` skill
4. Nathan Curtis / EightShapes methodology references bundled with the skill
5. Flutter platform conventions and accessibility guidance

Do not invent a new visual language for an individual screen.

## UI implementation rules

- Reuse existing components before creating new ones.
- Use semantic design tokens instead of arbitrary color/spacing/radius values.
- Define component anatomy, variants, states, behavior, and accessibility before implementing reusable components.
- Keep screen-specific composition separate from reusable component definitions.
- Support loading, empty, error, disabled, and success states where applicable.
- Check long text and missing data rather than assuming ideal content.
- Consider Android and iOS interaction conventions.
- Keep sensitive features such as cycle tracking and location sharing explicit about privacy and sharing status.

## Design-system changes

If a requested change appears to affect multiple screens:

1. Check whether the change belongs in tokens.
2. Check whether it belongs in a reusable component.
3. Check whether it belongs in a shared pattern.
4. Only then patch individual screens.

Avoid adding a generalized abstraction until there is a concrete reuse case.

## Validation

Before declaring a UI feature complete:

- run `dart format` or the project's formatter
- run `flutter analyze`
- run relevant tests
- inspect a real device/emulator layout when available
- apply the Couple UI review checklist

When a visual change is substantial, report:

- what changed
- which tokens/components were reused or added
- which states were covered
- what validation was performed
