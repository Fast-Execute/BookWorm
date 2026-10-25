# Cloudflare integration plan

## Goal

Add Cloudflare to BookWorm where it provides a concrete security, reliability, or performance benefit. Keep the existing Flutter + Supabase architecture working while adding services incrementally.

## Proposed responsibilities

- **Flutter:** reader app, admin UI, PDF rendering, and user interactions.
- **Supabase Auth:** identity and sessions.
- **Supabase Postgres:** books, admin membership, and reading progress.
- **Supabase Storage:** private PDF objects in the existing `books` bucket.
- **Cloudflare DNS / proxy / WAF:** custom-domain DNS and edge protection for domains that are actually hosted or proxied through Cloudflare.
- **Cloudflare Workers (optional later):** narrowly scoped edge endpoints for public catalogue caching, abuse-resistant public APIs, or integration glue where the need is demonstrated.
- **GitHub Actions:** automated Flutter analysis and tests.

## Security rules

1. Keep the Supabase `books` bucket private. Do not make PDF files public to make Cloudflare caching easier.
2. Never put a Supabase service-role key, Cloudflare API token, or other server secret in Flutter code, a public repository, or a `NEXT_PUBLIC_` / `VITE_` / Flutter compile-time client setting.
3. The Flutter app may use the Supabase publishable/anon client key; authorization must be enforced by Supabase Auth, Row Level Security, and Storage policies.
4. A Worker must not act as an unrestricted proxy to Supabase. If a Worker is added, validate inputs, limit methods and paths, apply rate limits where appropriate, and preserve user authorization for private data.
5. Do not cache authenticated responses, reading progress, admin responses, or private PDF bytes at a shared edge cache. Public catalogue caching is a separate, explicit design decision.
6. Cloudflare is not a replacement for Supabase database authorization. DNS/WAF settings do not make a database or Storage bucket private by themselves.
7. Keep secrets in the Cloudflare dashboard / Worker secrets and GitHub Actions secrets as appropriate. Rotate any secret accidentally committed.

## Rollout plan

### Phase 1 — keep the app secure and working

- Finish the PDF upload validation and in-app reader changes.
- Keep private PDFs in Supabase Storage.
- Verify admin-only upload and database/storage policies before changing production configuration.
- Run Flutter CI and resolve failures before merging.

### Phase 2 — domain and edge protection (when a domain is available)

- Add the domain to Cloudflare and verify DNS records before changing nameservers.
- Proxy only web endpoints that Cloudflare is intended to protect; preserve the correct TLS mode and origin configuration.
- Enable appropriate baseline security settings and review false positives.
- Document rollback steps before DNS changes.

### Phase 3 — add a Worker only for a defined requirement

Potential use cases:
- cache a public, non-personal catalogue response;
- provide a small edge endpoint for a future public website;
- apply application-specific rate limits or input validation.

Before shipping a Worker, document its routes, authentication model, allowed origins, rate limits, logging, secrets, and tests. Do not route private PDF downloads through a Worker unless there is a clear need and a reviewed authorization design.

## Not yet configured

This document is an architecture plan only. It does not create a Cloudflare account, change DNS/nameservers, deploy a Worker, configure WAF rules, change Supabase policies, or change Storage settings. Those actions require the relevant account/domain access and a deliberate rollout.
