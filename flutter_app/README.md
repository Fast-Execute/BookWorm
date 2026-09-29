# BookWorm Flutter application

BookWorm's primary client uses Flutter and Supabase.

## Supabase configuration

Run:

flutter pub get
flutter run --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY

Never commit service-role keys or passwords.

## Current implementation

- Supabase Flutter client initialization
- Active-book query from public.books
- Seven taps on the b. BookWorm logo open the admin screen
- Basic book metadata write to Supabase

PDF selection/upload and production admin authorization are next.
