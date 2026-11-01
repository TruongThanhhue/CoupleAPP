# Profile and partner disconnect

## User job and entry points

From More, open Profile to update a display name and read the immutable personal
connection code. From Partner Connection, deliberately end the current connection.

## Anatomy and hierarchy

Profile: app bar, personal-code card, name form, save button, inline status/retry.
Partner: existing code/invitations plus a connected-partner card and a secondary
disconnect action. A scrollable confirmation names the captured partner and
explains data ownership before submitting that partner's code to the API.

## Reuse and behavior

Reuse AppSurfaceCard, AppSpace, theme typography/colors and Material form/dialog
controls. No new design tokens or generic components. More listens to the session
so saved names are reflected immediately. Successful saves show a snackbar;
errors preserve entered text. Loading/saving disables conflicting actions. Back
navigation is blocked only while saving. Empty/whitespace names are rejected;
trimmed names are limited to 80 characters. The personal code is not editable.

## Privacy

Disconnect keeps each person's own tasks/events and makes formerly shared items
private. Reconnecting does not restore old sharing. The confirmation captures the
partner code so a delayed confirmation cannot disconnect a different partner.
The screen clears cached invitations after disconnect and ignores requests from
an obsolete login session. Cancelling the dialog performs no API action.

## Responsive and accessible states

Scrollable forms/dialogs, wrapping text/actions, labeled fields/buttons and
standard touch targets support small phones, landscape, keyboard and large text.
Loading, empty/no-partner, error/retry, saving/disabled and success states are
explicit in Vietnamese; color is not the sole state indicator. Verify validation,
failed/successful saving, cancelled/confirmed disconnect and large text layout.
