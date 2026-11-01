# Design system foundation

## Product direction

Couple App uses a calm, intimate, premium visual system: warm neutral foundations, an intentional muted relationship accent, strong hierarchy, soft surfaces, and restrained motion. It avoids a generic Material appearance, decorative card overload, and a pink-only dating-app aesthetic.

## Token layers

```text
Primitive values → semantic roles → component tokens
```

Concrete primitive values live only in the Flutter theme. Screens use semantic roles such as `surfaceDefault`, `textPrimary`, `relationshipAccent`, `actionPrimary`, and status colors. Component values are named only where the component needs a reusable decision.

## Initial component inventory

| Component | Purpose | States |
| --- | --- | --- |
| AppButton | Main, secondary, and destructive actions | default, pressed, disabled, loading |
| AppIconButton | Compact navigational or contextual action | default, pressed, disabled |
| AppCard | Surface with a purposeful grouping | default, selected, interactive |
| AppAvatar | Identifies a couple member | image, initials, unavailable |
| AppSectionHeader | Names and optionally links a dashboard section | default, action available |
| AppLoadingState | Communicates fetching state | skeleton/indeterminate |
| AppEmptyState | Explains absent content and offers next action | default, action available |
| AppErrorState | Explains recoverable failure | retry, offline |

Product cards are introduced when a real screen needs them; the first expected examples are task, event, cycle summary, and location status. Each component must document anatomy, variants, behavior, semantics, touch target, content rules, and token dependencies before it is generalized.

## Layout and responsive rules

- Mobile-first with safe areas and scrollable content.
- Use the 4-point spacing scale; screen padding and section gaps are semantic aliases.
- Support small phones, large phones, dynamic text, dark mode, and Vietnamese diacritics.
- Prefer adaptive presentation over fixed dimensions. Larger layouts may widen content and change column count, but must not hide privacy information.

## Sensitive information rules

Cycle estimates are explicitly framed as estimates, never medical advice or contraception guidance. Sharing is visibly opt-in. Location status always says whether sharing is active and provides a stop action. Status must never rely solely on color.

## Review standard

Every substantial screen is checked against the bundled Couple UI review checklist for hierarchy, states, resilience, responsive behavior, semantics, contrast, interaction feedback, privacy, and engineering quality.
