-- BookWorm private PDF storage
-- Run after the database schema.

insert into storage.buckets (id, name, public)
values ('books', 'books', false)
on conflict (id) do update set public = false;

-- Authenticated readers may download objects only when application policy permits.
drop policy if exists "Authenticated users can read book PDFs" on storage.objects;
create policy "Authenticated users can read book PDFs"
on storage.objects
for select
to authenticated
using (bucket_id = 'books');

-- Upload/update/delete policies are intentionally not public.
-- Admin write access will be added after Supabase Auth admin roles are configured.
