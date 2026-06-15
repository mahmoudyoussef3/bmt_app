-- Phase 4 - FIX: Auto-Create Clients on Sign Up
-- Resolves foreign key constraint errors when creating tickets or bookings.

-- 1. Create a function to automatically insert a new client
CREATE OR REPLACE FUNCTION public.handle_new_client_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.clients (id, full_name, phone, email)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Unknown User'),
    COALESCE(new.raw_user_meta_data->>'phone', new.phone, ''),
    new.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created_client ON auth.users;
CREATE TRIGGER on_auth_user_created_client
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_client_user();

-- 3. IMMEDIATELY FIX EXISTING USERS
-- This will insert your current auth user into the clients table.
-- It correctly deduplicates multiple auth.users with the same phone number to prevent unique constraint errors.
WITH RankedUsers AS (
  SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'Existing User') as full_name,
    email,
    COALESCE(raw_user_meta_data->>'phone', phone, '') as phone,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(raw_user_meta_data->>'phone', phone, '') ORDER BY created_at DESC) as rn
  FROM auth.users
  WHERE NOT EXISTS (
    SELECT 1 FROM public.clients WHERE public.clients.id = auth.users.id
  )
)
INSERT INTO public.clients (id, full_name, email, phone)
SELECT 
  id, 
  full_name,
  email,
  CASE 
    WHEN phone = '' THEN ''
    WHEN rn > 1 THEN phone || '_' || substr(id::text, 1, 8)
    WHEN EXISTS (SELECT 1 FROM public.clients c WHERE c.phone = RankedUsers.phone) THEN phone || '_' || substr(id::text, 1, 8)
    ELSE phone
  END
FROM RankedUsers;
