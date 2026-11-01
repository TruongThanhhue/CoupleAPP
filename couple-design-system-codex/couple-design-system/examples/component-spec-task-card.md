# Example — TaskCard

## Purpose

Represent a task in the shared Couple Planner while making ownership, completion,
and due date immediately scannable.

## Anatomy

```text
TaskCard
├── Leading checkbox
├── Content
│   ├── Title
│   ├── Metadata
│   └── Due date
└── Trailing assignee avatar
```

## Variants

- Personal
- Partner
- Shared

## States

- Default
- Pressed
- Completed
- Disabled
- Loading
- Overdue

## Design-system intent

The card is reusable because task presentation repeats across Home, Tasks, and Calendar
contexts. The screen decides grouping and surrounding composition; the card owns its
internal anatomy and interaction feedback.

## Content resilience

A long task title should wrap or truncate according to the product's established content
rules without pushing the due date or checkbox off-screen.

## Accessibility example

The semantics should communicate the title, completion state, assignee, and due state in
a concise, useful order rather than reading decorative elements first.
