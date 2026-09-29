# BookWorm Architecture

## Product layers

### Client

The BookWorm application provides the reader experience, library browsing, PDF reading, reading progress, and administrator workflows.

### Cloud

The production architecture will use authenticated cloud services for user accounts, book metadata, secure PDF storage, reading progress, rewards, and administration.

### Reward system

The reward system is intended to connect verified rewarded-ad completions to eligible digital-book rewards. Advertising-provider compliance and explicit user consent are required before production launch.

## Repository organization

- `flutter_app/` — primary BookWorm application
- `python/` — Python utilities and backend-oriented experiments
- `javascript/` — JavaScript/TypeScript work
- `sql/` — database schemas and queries
- `web/` — HTML/CSS web demonstrations
- `java/` — Java examples
- `cpp/` — C/C++ examples
- `docs/` — project documentation

## Admin entrance

The current product design preserves the seven-tap `b.` logo gesture. It should only reveal the admin interface; actual authorization must be enforced by the backend.
