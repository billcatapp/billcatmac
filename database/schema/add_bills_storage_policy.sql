-- Allow authenticated users to upload to the bills bucket
CREATE POLICY IF NOT EXISTS "Authenticated users can upload receipts"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'bills');

-- Allow public (anon) to read receipts — needed for WhatsApp link to work
CREATE POLICY IF NOT EXISTS "Public can read receipts"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'bills');

-- Allow authenticated users to update/overwrite their receipts
CREATE POLICY IF NOT EXISTS "Authenticated users can update receipts"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'bills');
