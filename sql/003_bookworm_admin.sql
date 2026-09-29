-- BookWorm admin authorization
-- Run this migration after 001_bookworm_schema.sql and 002_bookworm_storage.sql.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

drop policy if exists "Admins can read their own admin record" on public.admin_users;
create policy "Admins can read their own admin record"
on public.admin_users
for select
to authenticated
using (user_id = auth.uid());

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "Admins can insert books" on public.books;
create policy "Admins can insert books"
on public.books
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Admins can update books" on public.books;
create policy "Admins can update books"
on public.books
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can delete books" on public.books;
create policy "Admins can delete books"
on public.books
for delete
to authenticated
using (public.is_admin());

drop policy if exists "Admins can upload book PDFs" on storage.objects;
create policy "Admins can upload book PDFs"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'books'
  and public.is_admin()
);

drop policy if exists "Admins can update book PDFs" on storage.objects;
create policy "Admins can update book PDFs"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'books'
  and public.is_admin()
)
with check (
  bucket_id = 'books'
  and public.is_admin()
);

drop policy if exists "Admins can delete book PDFs" on storage.objects;
create policy "Admins can delete book PDFs"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'books'
  and public.is_admin()
);

-- Bootstrap the first administrator after creating the Auth user:
-- insert into public.admin_users (user_id) values ('AUTH-USER-UUID');
