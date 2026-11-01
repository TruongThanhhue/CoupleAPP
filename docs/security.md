# Security baseline

- Do not commit populated `.env` files, keys, passwords, OAuth secrets, refresh tokens, or private locations.
- Authenticate every protected endpoint; authorize against the current couple membership and specific resource ownership.
- Use short-lived access tokens, refresh rotation, password hashing, validation, rate limits, and audit logs.
- Encrypt OAuth credentials at rest and redact them from logs.
- Treat cycle data and location history as sensitive. Privacy controls in the client describe consent but never replace server authorization.
- Location is off by default. Active sharing, expiry, recipient, and stop control must be visible in the product.
