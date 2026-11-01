# Authentication screens

## User job and navigation

Create an account or sign in to a private Couple App profile. A restored valid session opens the main shell. A failed network check offers retry, while an expired session returns to sign in. Sign out is available in **Thêm**.

## Hierarchy and anatomy

The page starts with the product message, then the name field (registration only), email, password, primary submit action, and a secondary mode switch. Errors appear near the form. The main shell remains behind the authentication gate until a session exists.

## States and behavior

- Loading: check secure storage and validate an existing token.
- Empty: email and password form; registration additionally asks for a display name.
- Invalid: field level validation for a missing name, malformed email, or short password.
- Submitting: primary button disabled with progress feedback.
- Server or network error: explanatory text and retry path.
- Success: save the token in platform secure storage and open the main shell.

The account password is never displayed or persisted locally. The API returns a public partner code after registration; this is presented on the dedicated partner screen.

## Design-system decisions

The screens reuse the Couple theme typography, semantic colors, `AppSpace`, Material text fields, and the established touch target size. The form scrolls within a constrained width for small phones, large text, keyboard insets, and wider layouts. No new shared component or token is needed for this first concrete use case.
