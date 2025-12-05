-- Migration: Create blogs table and admin users table
-- Run this in your Supabase SQL Editor
-- 
-- IMPORTANT: After running this migration, also run:
-- migrations/002_create_storage_bucket.sql to set up image storage

-- Create blogs table
CREATE TABLE IF NOT EXISTS blogs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    excerpt TEXT,
    description TEXT,
    image_url TEXT,
    image TEXT,
    category TEXT DEFAULT 'GENERAL',
    slug TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published BOOLEAN DEFAULT true,
    author_id UUID REFERENCES auth.users(id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_blogs_created_at ON blogs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blogs_published ON blogs(published);
CREATE INDEX IF NOT EXISTS idx_blogs_category ON blogs(category);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_blogs_updated_at BEFORE UPDATE ON blogs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE blogs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access to published blogs
CREATE POLICY "Allow public read access to published blogs"
    ON blogs FOR SELECT
    USING (published = true);

-- Create policy to allow authenticated users to insert blogs (for admin)
CREATE POLICY "Allow authenticated users to insert blogs"
    ON blogs FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Create policy to allow authenticated users to update blogs (for admin)
CREATE POLICY "Allow authenticated users to update blogs"
    ON blogs FOR UPDATE
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Create policy to allow authenticated users to delete blogs (for admin)
CREATE POLICY "Allow authenticated users to delete blogs"
    ON blogs FOR DELETE
    TO authenticated
    USING (true);

-- Create admin_users table to track admin users (optional - for additional admin management)
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
    role TEXT DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on admin_users
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Policy for admin_users (only admins can read)
CREATE POLICY "Admins can read admin_users"
    ON admin_users FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
        )
    );

-- Insert sample blog data (optional)
INSERT INTO blogs (title, excerpt, content, category, image_url, created_at) VALUES
('Finding Peace in Nature', 
 'Discover how connecting with the natural world can deepen your yoga practice and bring tranquility to your mind.',
 'Full article content here...',
 'MINDFULNESS',
 'nature.png',
 NOW() - INTERVAL '10 days'),
('Yoga for Beginners',
 'Starting your journey? Here are the essential poses and breathing techniques to build a strong foundation.',
 'Full article content here...',
 'PRACTICE',
 'seated.png',
 NOW() - INTERVAL '6 days'),
('The Art of Breathing',
 'Pranayama is more than just breathing. Learn how to control your life force through conscious breath control.',
 'Full article content here...',
 'BREATHWORK',
 'hero.png',
 NOW() - INTERVAL '15 days')
ON CONFLICT DO NOTHING;
