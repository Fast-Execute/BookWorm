# Supabase setup

BookWorm uses Supabase for the production data layer.

## 1. Create a Supabase project

Create a project in the Supabase dashboard and keep the project URL and publishable/anonymous client key private to your application configuration.

## 2. Run the database migration

Open the Supabase SQL Editor and run:

sql/001_bookworm_schema.sql

This creates:

- books
- reading_progress
- Row Level Security policies

## 3. Storage

Create a private Storage bucket named:

books

PDF files should be stored as object paths such as:

books/<book-id>/<filename>.pdf

Do not make the PDF bucket public. The application should request short-lived signed URLs for authorized readers.

## 4. Admin security

Do not rely on the seven-tap b. gesture for authorization. The gesture is only the hidden navigation entrance.

Production administrator access should use Supabase Auth plus a server-enforced admin role/policy before allowing book uploads, edits, or deletion.

## 5. Client configuration

Never commit Supabase secrets or service-role keys.

For Flutter, supply the project URL and publishable/anonymous key through environment configuration or a secure build/deployment mechanism.
