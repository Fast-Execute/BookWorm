-- BookWorm / Supabase schema
-- Run this migration in the Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null,
  description text,
  cover_path text,
  pdf_path text not null,
  total_pages integer not null check (total_pages > 0),
  published_year integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists books_active_idx on public.books (is_active);
create index if not exists books_created_at_idx on public.books (created_at desc);

alter table public.books enable row level security;

-- Public readers can see active book metadata.
drop policy if exists "Public can read active books" on public.books;
create policy "Public can read active books"
on public.books
for select
using (is_active = true);

-- Writes are intentionally not opened to public clients.
-- Admin write policies should be added only after Supabase Auth roles are configured.

create table if not exists public.reading_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  current_page integer not null default 1 check (current_page > 0),
  progress_percent numeric(5,2) not null default 0 check (progress_percent >= 0 and progress_percent <= 100),
  updated_at timestamptz not null default now(),
  unique (user_id, book_id)
);

alter table public.reading_progress enable row level security;

drop policy if exists "Users can read their own progress" on public.reading_progress;
create policy "Users can read their own progress"
on public.reading_progress
for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert their own progress" on public.reading_progress;
create policy "Users can insert their own progress"
on public.reading_progress
for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update their own progress" on public.reading_progress;
create policy "Users can update their own progress"
on public.reading_progress
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
