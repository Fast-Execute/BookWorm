-- BookWorm: enforce private PDF storage constraints.
-- Review the current bucket and policies before applying this in production.
-- This is an explicit migration; creating the file does not apply it to Supabase.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'books',
  'books',
  false,
  15728640, -- 15 MiB
  array['application/pdf']::text[]
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Important:
-- * Keep upload authorization enforced by the existing storage.objects RLS policies.
-- * This bucket setting is a second layer; it does not replace admin-only policies.
-- * Do not add anonymous INSERT/UPDATE/DELETE policies.
