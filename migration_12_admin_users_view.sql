-- Migration 12: Admin users view joining user_roles with auth.users for email display
-- Use a security-definer function to safely expose auth.users email to authenticated dashboard users

CREATE OR REPLACE FUNCTION public.get_dashboard_users()
RETURNS TABLE(
  id          uuid,
  user_id     uuid,
  email       text,
  role        text,
  created_at  timestamptz
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT
    ur.id,
    ur.user_id,
    au.email,
    ur.role,
    ur.created_at
  FROM public.user_roles ur
  JOIN auth.users au ON au.id = ur.user_id
  WHERE ur.role != 'client'
  ORDER BY ur.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_dashboard_users TO authenticated;
