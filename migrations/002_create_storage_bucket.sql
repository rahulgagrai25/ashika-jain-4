-- Migration: Create Storage Bucket and Policies for Blog Images
-- Run this in your Supabase SQL Editor
--
-- IMPORTANT: Bucket creation via SQL may require superuser privileges.
-- If the INSERT statement below fails, create the bucket manually:
-- 1. Go to Supabase Dashboard → Storage → New Bucket
-- 2. Name: blog-images, Public: true, File size: 5MB
-- 3. Then run only the policy creation statements below

-- Step 1: Create the storage bucket for blog images
-- Try to create the bucket (may fail if you don't have superuser access)
DO $$
BEGIN
    -- Check if bucket already exists
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'blog-images') THEN
        -- Insert bucket into storage.buckets table
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'blog-images',
            'blog-images',
            true,  -- Public bucket (allows public access)
            5242880,  -- 5MB file size limit (in bytes)
            ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']  -- Allowed MIME types
        );
        RAISE NOTICE 'Bucket blog-images created successfully';
    ELSE
        RAISE NOTICE 'Bucket blog-images already exists';
    END IF;
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'Insufficient privileges to create bucket. Please create it manually in the dashboard.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating bucket: %. Please create it manually in the dashboard.', SQLERRM;
END $$;

-- Step 2: Create Storage Policies for the blog-images bucket

-- Policy 1: Allow authenticated users to upload (INSERT)
DROP POLICY IF EXISTS "Allow authenticated uploads to blog-images" ON storage.objects;
CREATE POLICY "Allow authenticated uploads to blog-images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'blog-images');

-- Policy 2: Allow authenticated users to update their uploads
DROP POLICY IF EXISTS "Allow authenticated updates to blog-images" ON storage.objects;
CREATE POLICY "Allow authenticated updates to blog-images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'blog-images')
WITH CHECK (bucket_id = 'blog-images');

-- Policy 3: Allow authenticated users to delete their uploads
DROP POLICY IF EXISTS "Allow authenticated deletes from blog-images" ON storage.objects;
CREATE POLICY "Allow authenticated deletes from blog-images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'blog-images');

-- Policy 4: Allow public read access (SELECT)
-- This allows anyone to view the images
DROP POLICY IF EXISTS "Allow public read access to blog-images" ON storage.objects;
CREATE POLICY "Allow public read access to blog-images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'blog-images');

-- Note: If you encounter permission errors, you may need to:
-- 1. Create the bucket manually via Supabase Dashboard
-- 2. Then run only the policy creation statements above
-- See migrations/002_create_storage_bucket_manual.md for detailed manual setup instructions

-- Verify the bucket was created
SELECT * FROM storage.buckets WHERE id = 'blog-images';

-- Verify policies were created
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
