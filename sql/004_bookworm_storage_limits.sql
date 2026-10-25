-- Enforce BookWorm's server-side PDF upload constraints.
-- This is intentionally an UPDATE: the private 'books' bucket already exists.
-- 15 MiB = 15 * 1024 * 1024 bytes.
update storage.buckets
set
  public = false,
  file_size_limit = 15728640,
  allowed_mime_types = array['application/pdf']::text[]
where id = 'books';

-- Fail loudly if the expected bucket is missing rather than silently succeeding.
do $$
begin
  if not exists (
    select 1
    from storage.buckets
    where id = 'books'
      and public = false
      and file_size_limit = 15728640
      and allowed_mime_types = array['application/pdf']::text[]
  ) then
    raise exception 'BookWorm books bucket was not configured with the expected private PDF limits';
  end if;
end
$$;
