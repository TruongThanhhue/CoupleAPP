# Couple App

A private space for two people to organize shared life. The repository contains a Flutter mobile client, an ASP.NET Core API, and product/design documentation.

The account flow supports email/password registration, a personal connection code, partner invitations, explicit acceptance, cancellation, and sign out. Tasks and calendar events support authenticated PostgreSQL-backed create, edit and delete operations, with private-by-default sharing controls. The home screen summarizes the signed-in user's actual workspace.

Location, cycle tracking, memories, expenses, push reminders and external calendar integrations remain planned. This is a development build, not a production release.

See [local setup](docs/auth-and-partner-setup.md), [API status](docs/api.md), and the [implementation plan](docs/implementation-plan.md).
