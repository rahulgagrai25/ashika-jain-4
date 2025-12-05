-- Migration: Fix Admin Read Policy for Blog Editing
-- Run this in your Supabase SQL Editor if you already ran 001_create_blogs_table.sql
-- This adds the missing policy to allow authenticated users to read all blogs

-- Drop the policy if it already exists (to avoid errors on re-run)
DROP POLICY IF EXISTS "Allow authenticated users to read all blogs" ON blogs;

-- Create policy to allow authenticated users to read all blogs (for admin)
-- This is needed so admins can edit both published and unpublished blogs
CREATE POLICY "Allow authenticated users to read all blogs"
    ON blogs FOR SELECT
    TO authenticated
    USING (true);

-- Verify the policy was created
SELECT * FROM pg_policies 
WHERE tablename = 'blogs' 
AND schemaname = 'public'
AND policyname = 'Allow authenticated users to read all blogs';
