# Supabase Admin Setup

BookWorm uses Supabase Auth for administrator sign-in and a database-backed admin allowlist.

## 1. Run the admin migration

Run:

`sql/003_bookworm_admin.sql`

in the Supabase SQL Editor.

## 2. Create the administrator Auth user

In Supabase:

1. Open **Authentication → Users**.
2. Create the administrator with an email and password.
3. Copy that user's UUID.

Do not place the password in the repository.

## 3. Add the user to the admin allowlist

Run this SQL, replacing the placeholder with the Auth user's UUID:

```sql
insert into public.admin_users (user_id)
values ('AUTH-USER-UUID');
```

## 4. Test the hidden admin entrance

Run the Flutter app with the project URL and publishable key supplied through `--dart-define`.

From the library:

1. Tap **b. BookWorm** seven times within two seconds.
2. Sign in with the administrator account.
3. Select a PDF.
4. Enter title, author, and total pages.
5. Upload the book.
6. Confirm the book appears in the library.

The seven-tap gesture is only a navigation shortcut. Authorization is enforced by Supabase Auth, the `is_admin()` function, database RLS, and Storage RLS.

## Security notes

- Never commit a Supabase service-role key.
- Keep the `books` Storage bucket private.
- Admin writes are restricted to users present in `public.admin_users`.
- The publishable/anonymous client key is intended for the Flutter client; sensitive server credentials must remain outside the app.
