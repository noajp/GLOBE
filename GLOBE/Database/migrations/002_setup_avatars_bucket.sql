--======================================================================
-- Purpose: Create public 'avatars' bucket and RLS policies so that
--          authenticated users can upload/update their own avatar files
--          under a path prefix of their auth.uid(). Also allow public read.
-- Path: GLOBE/Supabase/migrations/002_setup_avatars_bucket.sql
--======================================================================

-- Create avatars bucket if it doesn't exist (public so profiles can display)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Public read policy for avatars bucket
create policy if not exists "Avatars: public read"
on storage.objects for select
using (bucket_id = 'avatars');

-- Allow authenticated users to upload to their own folder: <uid>/<filename>
create policy if not exists "Avatars: user can upload to own folder"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Allow users to update objects they own (within their folder)
create policy if not exists "Avatars: user can update own objects"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

-- Allow users to delete objects they own (within their folder)
create policy if not exists "Avatars: user can delete own objects"
on storage.objects for delete
using (
  bucket_id = 'avatars'
  and split_part(name, '/', 1) = auth.uid()::text
);

