-- Complete Database Setup for Midday
-- Run this in Supabase SQL Editor after creating a new project

-- Step 1: Apply main schema (includes functions)
-- The schema.sql file contains:
-- - All table definitions
-- - Database functions (generate_inbox, extract_product_names, etc.)
-- - Basic RLS policies for documents and users tables
-- 
-- To apply: Copy contents of schema.sql and run in SQL Editor

-- Step 2: Storage Policies (REQUIRED - not in schema.sql)
-- These policies enable file upload/download functionality

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated reads" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
DROP POLICY IF EXISTS "Allow anonymous uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow anonymous reads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access" ON storage.objects;

-- Create comprehensive storage policies

-- 1. Allow authenticated users to upload to any bucket
CREATE POLICY "Allow authenticated uploads" ON storage.objects
FOR INSERT 
TO authenticated
WITH CHECK (true);

-- 2. Allow authenticated users to read any file
CREATE POLICY "Allow authenticated reads" ON storage.objects
FOR SELECT 
TO authenticated
USING (true);

-- 3. Allow authenticated users to update any file
CREATE POLICY "Allow authenticated updates" ON storage.objects
FOR UPDATE 
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Allow authenticated users to delete any file
CREATE POLICY "Allow authenticated deletes" ON storage.objects
FOR DELETE 
TO authenticated
USING (true);

-- 5. Allow anonymous users to upload (for development)
CREATE POLICY "Allow anonymous uploads" ON storage.objects
FOR INSERT 
TO anon
WITH CHECK (true);

-- 6. Allow anonymous users to read (for development)
CREATE POLICY "Allow anonymous reads" ON storage.objects
FOR SELECT 
TO anon
USING (true);

-- 7. Allow public access to public-uploads bucket
CREATE POLICY "Allow public access" ON storage.objects
FOR SELECT 
TO public
USING (bucket_id = 'public-uploads');

-- Enable RLS on storage.objects (should already be enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Also ensure buckets table has proper policies
DROP POLICY IF EXISTS "Allow bucket access" ON storage.buckets;
CREATE POLICY "Allow bucket access" ON storage.buckets
FOR SELECT TO public USING (true);

-- Step 3: Create required storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('public-uploads', 'public-uploads', true),
  ('documents', 'documents', false),
  ('invoices', 'invoices', false)
ON CONFLICT (id) DO NOTHING;

-- Step 4: Verify setup
-- Run these queries to confirm everything is working:

-- Check functions exist
SELECT 'generate_inbox function' as check, 
       EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'generate_inbox') as status;
       
SELECT 'extract_product_names function' as check,
       EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'extract_product_names') as status;

-- Check storage policies exist
SELECT 'Storage policies' as check,
       COUNT(*) as policy_count 
FROM pg_policies 
WHERE tablename = 'objects' AND schemaname = 'storage';

-- Expected: 7 policies

-- Check buckets exist
SELECT 'Storage buckets' as check,
       COUNT(*) as bucket_count
FROM storage.buckets;

-- Expected: At least 3 buckets