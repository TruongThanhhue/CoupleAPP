# Component Spec — AppStatePanel

## Purpose

Make loading, empty, and recoverable-error situations understandable and actionable without each screen inventing a different pattern.

## Use when

- A feature's primary content is awaiting data, empty, or unavailable after a recoverable failure.

## Do not use when

- A small inline field validation message or a transient confirmation is needed.

## Anatomy

```text
AppStatePanel
├── Status icon or progress indicator
├── Title
├── Supporting message
└── Optional action
```

## API / properties

| Property | Type | Required | Default | Description |
| --- | --- | ---: | --- | --- |
| state | `AppStateKind` | Yes | — | loading, empty, error, permission |
| title | `String` | Yes | — | Primary explanation |
| message | `String?` | No | null | Short supporting guidance |
| actionLabel | `String?` | No | null | Label for recovery/action |
| onAction | `VoidCallback?` | No | null | Action callback; required with label |

## Variants and states

| State | Visual behavior | Interaction behavior |
| --- | --- | --- |
| Loading | Progress indicator, no action | Non-interactive |
| Empty | Calm neutral icon | Optional creation action |
| Error | Error icon plus direct recovery | Optional retry |
| Permission | Informative icon and privacy copy | Optional settings action |

## Layout, content, and behavior

The panel has standard card padding, centers its content, wraps long Vietnamese copy, and keeps its action at least 48dp high. It exposes title, current state, and action label to assistive technology; it does not rely on its color or icon alone.

## Tokens

Semantic surface/text/status tokens, `space.4–6`, `radius.lg`, standard button dimensions, and `motion.normal` for non-essential state transitions.

## Composition

Used by Home dashboard, Tasks, Calendar, and privacy-aware Location/Cycle screens.
