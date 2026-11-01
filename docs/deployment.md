# Deployment plan

Phase 1 runs API and PostgreSQL locally. Production evolves to containerized ASP.NET Core, PostgreSQL (with PostGIS before Location), background workers, managed secrets, object storage, push credentials, and monitoring.

CI should run formatting, static analysis, unit tests, migration validation, and secret scanning. A production release cannot reuse development credentials or the local sample configuration.
