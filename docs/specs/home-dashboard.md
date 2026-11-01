# Screen Spec — Home Dashboard

## User job

Understand the shared day at a glance and enter the next useful action without hunting through modules.

## Implemented workspace milestone (November 2026)

Show the signed-in user's name and optional connected partner, never a sample name
or invented relationship duration. Summarize the authenticated workspace task list
(completed / total, explicitly all tasks) and events intersecting today's local
calendar date. Quick actions open the task/event editor; section actions select
their owning tab. One shared WorkspaceController updates all three screens after
a successful mutation. Pull-to-refresh and app resume refresh server data.

Reuse AppSurfaceCard, AppSectionHeader, AppStatePanel, AppSpace and theme colors.
The scrollable single-column layout uses wrapping action buttons and wrapping
titles for narrow displays/large text. Loading and errors replace summary counts
so an unavailable API is never represented as zero records. Empty data has an
explicit message and creation action. Sharing status is shown per event; the
location panel truthfully states that location sharing is not yet available.

## Context

Entry point is the first primary navigation destination after a user has joined a couple. Quick actions lead to Tasks, Calendar, Location, and Check-in; sections lead to their owning features.

## Information hierarchy

1. Couple identity and time together.
2. Today's schedule and task progress.
3. Explicit sharing status and only the partner information the current user is allowed to see.
4. Quick actions and lower-priority upcoming information.

## Screen anatomy

```text
HomeDashboard
├── Couple header
├── Today summary
│   ├── Event preview
│   └── Task progress
├── Privacy-aware partner status
├── Quick actions
└── Upcoming milestone
```

## Reused components

- AppSectionHeader
- AppCard
- AppEmptyState / AppErrorState / AppLoadingState

## States

- **Loading:** skeleton-like status cards, no false data.
- **Empty:** invite/complete-profile call to action where no couple exists; a useful zero-task message otherwise.
- **Error:** short recovery message and retry action.
- **Populated:** summary content only; no full task/event lists.
- **Permission:** location and cycle sections describe unavailable sharing or offer the owner a settings route.

## Navigation and interaction

Home is tab-root (predictive back does not exit a nested detail). Cards and quick actions are tappable with semantic labels and visible pressed feedback. Long titles ellipsize rather than overlap.

## Responsive and accessibility behavior

Content stays a single column on a narrow phone. Wider layouts increase horizontal padding and may show paired quick actions. It supports dynamic text scaling, 48dp targets, heading semantics, readable contrast, and text/status icons together rather than color-only meaning.

## Privacy / trust

Cycle data appears only when the owner enabled partner visibility; predicted dates always say “estimated”. Location always declares its sharing state; the dashboard never implies background sharing is active.

## Design-system decisions

Use semantic surface, text, relationship accent, and status tokens with the standard spacing/radius scale. The dashboard composes foundational components; it does not introduce a generic dashboard-card abstraction.
