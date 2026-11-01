# Couple App Design Tokens

These are the initial semantic token conventions. Treat them as a starting point, not
as a finished brand system. The product should evolve them centrally rather than adding
random values inside individual screens.

## Token layers

Use three conceptual layers:

```text
Primitive tokens
      ↓
Semantic tokens
      ↓
Component tokens
```

### Primitive tokens

Raw building blocks such as a neutral ramp, accent ramp, spacing scale, or type scale.

### Semantic tokens

Meaningful decisions such as:

```text
color.surface.default
color.text.primary
color.text.secondary
color.action.primary
color.status.success
color.status.warning
color.status.error
color.relationship.accent
```

### Component tokens

Tokens scoped to a reusable component when necessary:

```text
button.height
button.radius
button.paddingHorizontal
card.radius
card.padding
calendar.dayCellSize
```

## Initial color architecture

The Couple App should not depend on a single “pink theme”. Use a neutral foundation and
an intentional relationship accent.

Example semantic palette structure:

```yaml
color:
  background:
    app: neutral.050
    elevated: neutral.000
    subtle: neutral.100
  surface:
    default: neutral.000
    muted: neutral.100
    selected: accent.050
  text:
    primary: neutral.900
    secondary: neutral.600
    tertiary: neutral.500
    inverse: neutral.000
  border:
    subtle: neutral.200
    default: neutral.300
  action:
    primary: accent.600
    primaryPressed: accent.700
    secondary: neutral.900
  status:
    success: green.600
    warning: amber.600
    error: red.600
    info: blue.600
  relationship:
    accent: accent.600
    accentSoft: accent.050
```

Exact values should be selected after product visual exploration and accessibility review.

## Typography

Prefer a small set of text roles instead of ad-hoc font sizes.

```yaml
typography:
  display:
    fontSize: 32
    lineHeight: 40
    weight: 700
  titleLarge:
    fontSize: 24
    lineHeight: 32
    weight: 700
  titleMedium:
    fontSize: 20
    lineHeight: 28
    weight: 650
  bodyLarge:
    fontSize: 17
    lineHeight: 24
    weight: 400
  bodyMedium:
    fontSize: 15
    lineHeight: 22
    weight: 400
  labelLarge:
    fontSize: 14
    lineHeight: 20
    weight: 600
  labelMedium:
    fontSize: 12
    lineHeight: 16
    weight: 600
  metadata:
    fontSize: 12
    lineHeight: 16
    weight: 500
```

Use platform-appropriate fonts and verify Vietnamese diacritics, numerals, and long labels.

## Spacing

Use a consistent base scale. A 4-point family is a useful starting point:

```text
space.0   = 0
space.1   = 4
space.2   = 8
space.3   = 12
space.4   = 16
space.5   = 20
space.6   = 24
space.7   = 28
space.8   = 32
space.10  = 40
space.12  = 48
space.16  = 64
```

Use semantic aliases when a value has a clear role:

```text
screen.horizontalPadding
card.padding
section.gap
list.itemGap
```

## Radius

Keep the family small:

```text
radius.none = 0
radius.sm   = 8
radius.md   = 12
radius.lg   = 16
radius.xl   = 24
radius.full = 999
```

Do not mix many unrelated radii.

## Elevation

Prefer subtle separation.

```text
elevation.none
 elevation.surface
 elevation.raised
 elevation.modal
```

Avoid using shadow depth as the primary information hierarchy mechanism.

## Motion

Motion should communicate cause and effect, state change, or hierarchy.

Suggested durations:

```text
motion.fast   = 120ms
motion.normal = 200ms
motion.slow   = 300ms
```

Use slower motion sparingly on mobile. Respect reduced-motion settings where applicable.

## Touch targets

Interactive controls should be comfortably tappable. Do not shrink controls just to
fit more content on one screen.

## Dark mode

Do not derive dark mode by blindly inverting colors. Define semantic roles that can map
to light and dark values while preserving contrast and hierarchy.

## Token naming rules

Prefer:

```text
color.text.primary
space.screen.horizontal
radius.card
motion.normal
```

Avoid:

```text
blueText2
pink16
padding17
randomGray
```

The name should communicate role, not merely appearance.
