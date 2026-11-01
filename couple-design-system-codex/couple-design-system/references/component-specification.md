# Component Specification Guide

A reusable component specification should allow another designer/developer to understand
and implement the component without guessing at its important behavior.

## Required sections

1. Purpose
2. Usage / non-usage
3. Anatomy
4. Properties / API
5. Variants
6. States
7. Layout & spacing
8. Content guidance
9. Behavior / interaction
10. Accessibility
11. Responsive behavior
12. Tokens
13. Composition examples
14. Open questions / edge cases

## Anatomy notation

Use a tree:

```text
TaskCard
├── Leading
│   └── Checkbox
├── Main
│   ├── Title
│   ├── Metadata
│   └── DueDate
└── Trailing
    └── AssigneeAvatar
```

## Properties

Describe only properties that should be controlled by a component consumer.
Avoid exposing implementation details.

Example:

```text
TaskCard(
  title,
  dueDate,
  assignee,
  status,
  priority,
  onCompleted,
  onTap,
)
```

## Variants vs states

Variant = a meaningful configuration that changes the component's role or structure.

Examples:

```text
TaskCard: personal / shared / partner
```

State = the component's current interaction/data condition.

Examples:

```text
TaskCard: default / pressed / completed / disabled / loading
```

Do not create variants for every state.

## State matrix

For each interaction-heavy component, produce a compact matrix:

| Variant | Default | Pressed | Disabled | Loading | Error | Selected |
|---|---|---|---|---|---|---|
| Primary | ✓ | ✓ | ✓ | ✓ | – | – |
| Secondary | ✓ | ✓ | ✓ | – | – | ✓ |

Only include states that make sense for the component.

## Content resilience

Test:

- very short titles
- long titles
- missing metadata
- long localized dates
- large numbers/currency
- missing avatar
- multiple assignees where applicable

## Accessibility

Document:

- semantic role
- accessible label
- value/state announcement
- focus behavior
- keyboard behavior where relevant
- reduced motion behavior
- contrast expectations

## Flutter implementation guidance

Prefer:

- `const` constructors where possible
- composable widgets
- semantic wrappers where needed
- theme/token access instead of hard-coded values
- stable callback names
- clear nullability semantics

Avoid:

- huge monolithic `build()` methods
- UI duplication across screens
- business logic hidden in purely visual components
- magic numbers that bypass the token system
