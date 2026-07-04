-- Create an RPC to check if a phone number already exists
-- This allows the client app to validate uniqueness before calling signUp,
-- preventing opaque 500 internal server errors from the AFTER INSERT trigger.

CREATE OR REPLACE FUNCTION public.check_phone_exists(p_phone text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.clients WHERE phone = p_phone);
END;
$$;

-- Allow anonymous and authenticated users to call this function
GRANT EXECUTE ON FUNCTION public.check_phone_exists(text) TO public;
