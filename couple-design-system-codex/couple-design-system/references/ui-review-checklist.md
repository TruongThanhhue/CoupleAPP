# Couple App UI Review Checklist

Use this as a definition-of-done checklist for substantial UI work.

## A. Product clarity

- [ ] The screen has one obvious primary job.
- [ ] The most important information is visually dominant.
- [ ] Primary and secondary actions are clearly differentiated.
- [ ] Navigation context is understandable.
- [ ] Important privacy/sharing status is visible when relevant.

## B. Design-system consistency

- [ ] Existing components were checked before creating new ones.
- [ ] Existing patterns were reused where appropriate.
- [ ] Semantic design tokens are used instead of avoidable literals.
- [ ] Typography roles are consistent.
- [ ] Spacing follows the established scale.
- [ ] Corner radii and elevation are consistent.
- [ ] Icons follow the same visual family.

## C. States

- [ ] Default state is defined.
- [ ] Pressed/active feedback exists where useful.
- [ ] Disabled state is defined where relevant.
- [ ] Loading state is defined where data may be asynchronous.
- [ ] Empty state is defined where collections may be empty.
- [ ] Error state is defined where operations can fail.
- [ ] Success/completed state is defined where relevant.
- [ ] Permission/consent state is handled where relevant.

## D. Content resilience

- [ ] Long titles do not break the layout.
- [ ] Missing data has a sensible fallback.
- [ ] Dynamic dates/numbers/currency fit.
- [ ] Vietnamese text and diacritics render correctly.
- [ ] Large font/text scaling is considered.
- [ ] The UI still works with real, not placeholder, content.

## E. Responsive behavior

- [ ] Small phone width checked.
- [ ] Larger phone width checked.
- [ ] Landscape behavior considered where relevant.
- [ ] Keyboard/inset behavior considered where relevant.
- [ ] Bottom sheets/dialogs do not overflow.
- [ ] Maps/calendars/lists degrade gracefully in constrained space.

## F. Accessibility

- [ ] Interactive elements expose useful semantics.
- [ ] Labels are meaningful without visual context.
- [ ] Color is not the only way state is communicated.
- [ ] Contrast is acceptable.
- [ ] Touch targets are comfortably usable.
- [ ] Focus order is sensible where keyboard/navigation applies.
- [ ] Reduced-motion behavior is considered.

## G. Interaction quality

- [ ] Taps have clear feedback.
- [ ] Destructive actions require appropriate confirmation.
- [ ] Swipe/drag gestures have a non-gesture alternative when needed.
- [ ] Navigation transitions preserve context.
- [ ] Motion is purposeful rather than decorative.

## H. Sensitive features

For cycle tracking:

- [ ] Predictions are presented as estimates.
- [ ] Recorded vs predicted information is visually distinct.
- [ ] Sharing controls are explicit.
- [ ] The user can change privacy settings easily.

For location:

- [ ] Sharing status is always understandable.
- [ ] Start/stop controls are obvious.
- [ ] Current vs historical location is distinguished.
- [ ] Background sharing does not appear to be silently enabled.

For Google integrations:

- [ ] Connection status is visible.
- [ ] Sync errors are understandable.
- [ ] Disconnect/revoke action is discoverable.

## I. Engineering quality

- [ ] `dart format` / project formatter passes.
- [ ] `flutter analyze` passes.
- [ ] Relevant tests pass.
- [ ] No avoidable duplicated widgets were introduced.
- [ ] Public component API is minimal and understandable.
- [ ] No unrelated refactor was mixed into the change.

## J. Visual polish

- [ ] Alignment is intentional.
- [ ] Baselines feel consistent.
- [ ] Hierarchy remains clear at a glance.
- [ ] Empty space is purposeful.
- [ ] Borders/shadows are restrained.
- [ ] Visual emphasis matches user importance.
- [ ] The screen feels like Couple App rather than a default component library demo.
