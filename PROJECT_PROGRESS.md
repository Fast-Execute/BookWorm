# BookWorm — Project Progress

> Live tracker for the BookWorm project. Percentages are updated only when functionality is actually implemented and verified.

## Overall roadmap

- [x] 01 — Foundation: repository initialized
- [ ] 02 — Library + PDF management
- [ ] 03 — Cloud storage + user accounts
- [ ] 04 — PDF reader
- [ ] 05 — Reading progress
- [ ] 06 — Rewarded ads
- [ ] 07 — Advertiser partnerships
- [ ] 08 — Admin + security
- [ ] 09 — Production launch

## Current progress

**Foundation + Supabase data foundation — 20% complete**

`████░░░░░░ 20%`

### Completed

- GitHub repository initialized
- Main branch created by the first commit
- Project README added
- Live progress tracker added
- Product roadmap documented
- Seven-tap `b.` admin-entry requirement recorded
- Supabase database schema drafted and committed
- `books` table defined with metadata and PDF object path
- `reading_progress` table defined
- Row Level Security policies defined for reader progress
- Supabase storage and security setup documented
- Multi-language project directories established

### Current engineering state

The Supabase integration is **schema-ready, not yet connected to a live Supabase project**. No credentials have been committed.

### Next milestone

**30% — Library + PDF management**

Target capabilities:

- Add books from the administrator interface
- Select PDF files from the administrator's computer
- Upload PDFs to a private Supabase Storage bucket
- Store book metadata in Supabase
- Display uploaded books in the library
- Add authenticated administrator permissions
- Test the complete upload-to-library flow

## Product rules

1. Keep the repository structured as the project grows.
2. Update this tracker whenever a milestone is genuinely completed.
3. Keep implementation separate from planning/documentation.
4. The seven-tap `b.` gesture is a hidden admin entrance, not a security mechanism.
5. Production admin access must use real authentication and authorization.
6. Rewarded-book mechanics must use a compliant rewarded-ad provider and verified completion events.
7. Never treat a planned feature as completed until it has been implemented and tested.
8. Never commit Supabase service-role keys, passwords, or other secrets.
