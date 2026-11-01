# Tasks and calendar workspace

## User job and context

From the Tasks and Calendar tabs, users create, edit and remove personal records,
optionally share each record with their connected partner, and see saved changes
on Home. Tasks also support completion, priority, due dates and completion filters.
Calendar is an agenda ordered by start date, with upcoming/all filters.

## Hierarchy and anatomy

Each screen contains a heading, progress/context sentence, primary add button,
filter chips, then a list of cards. Cards show title first, followed by explicit
private/shared status and scheduling details. Task cards include a completion
checkbox; both card types expose labeled edit and delete buttons.

## Reused components and design decisions

Reuse AppSurfaceCard, AppStatePanel, Material form controls, theme typography and
colors, AppSpace spacing and AppRadius. Editors remain screen-local: each uses
an AlertDialog with scrollable content and a Form, plus cancel/save actions.
No new design-system component or visual tokens are introduced.

## States and interaction

- Loading: an AppStatePanel and disabled mutations until data arrives.
- Empty: explanatory copy; add button stays available.
- Error: clear connection/session feedback and retry; stale records are hidden.
- Populated: titles wrap, notes are optional, explicit private/shared labels.
- Saving: controls disabled; save failure preserves form values with inline error.
- Success: close editor after server confirmation and show a snackbar.
- Delete: confirmation names the record and warns if shared; only remove locally
  after server confirmation.
- Sharing: defaults to private; enable only with a connected partner; only the
  creator may change sharing. Partner can edit/delete already shared records.

## Responsive behavior and accessibility

Use vertical scrolling and Wrap for actions/filters, Expanded for titles, and no
fixed-height content. Dialogs scroll with keyboard insets and large text. Date/time
controls have visible labels; checkboxes and action buttons have semantic labels.
Shared/private/completed/priority states are communicated in words, not just color.
Navigation uses existing bottom tabs; back closes editors. Pull-to-refresh has a
visible refresh button alternative. Dates display in device local time and are
sent to the API in UTC. App content remains Vietnamese.

## Acceptance criteria

Persisted CRUD, authenticated requests, reload after session/partner changes,
private/shared controls, completion filters and date validation must work. Validate
formatting, static analysis, HTTP/controller tests, empty/error states and a small
screen with long titles/large text. Review with the Couple UI checklist.
