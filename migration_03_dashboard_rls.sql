-- Phase 3 - MIGRATION: Dashboard RLS and Admin Roles
-- Resolves the HTTP 401 (42501) RLS Violation when creating routes.

-- ============================================================================
-- 1. CREATE ADMINS TABLE
-- ============================================================================
-- This table securely designates which auth.users have Dashboard access.
CREATE TABLE IF NOT EXISTS public.admins (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade unique,
    role text not null default 'super_admin',
    created_at timestamptz not null default now()
);
CREATE INDEX IF NOT EXISTS idx_admins_user_id ON public.admins(user_id);
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- Admins can view the admins list
DROP POLICY IF EXISTS "Admins can view admins" ON public.admins;
CREATE POLICY "Admins can view admins" ON public.admins FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid()));

-- ============================================================================
-- 2. HELPER FUNCTION: is_admin()
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (SELECT 1 FROM public.admins WHERE user_id = auth.uid());
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================================
-- 3. RLS POLICIES FOR ROUTES & STATIONS
-- ============================================================================

-- OPERATION ROUTES
ALTER TABLE public.operation_routes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to operation_routes" ON public.operation_routes;
CREATE POLICY "Admins have full access to operation_routes" ON public.operation_routes 
FOR ALL TO authenticated 
USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Anyone can view operation_routes" ON public.operation_routes;
CREATE POLICY "Anyone can view operation_routes" ON public.operation_routes 
FOR SELECT TO anon, authenticated 
USING (true); -- Clients only need to see routes. Filtering by 'active' can be done in the app or enforced here if needed.

-- ROUTE STATIONS
ALTER TABLE public.route_stations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins have full access to route_stations" ON public.route_stations;
CREATE POLICY "Admins have full access to route_stations" ON public.route_stations 
FOR ALL TO authenticated 
USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Anyone can view route_stations" ON public.route_stations;
CREATE POLICY "Anyone can view route_stations" ON public.route_stations 
FOR SELECT TO anon, authenticated 
USING (true);

-- ============================================================================
-- 4. INSERT YOUR FIRST ADMIN
-- ============================================================================
-- IMPORTANT: You must run this snippet with YOUR actual Dashboard user's email 
-- to grant yourself access to create routes!

DO $$
DECLARE
    v_admin_user_id uuid;
BEGIN
    -- Replace 'your_dashboard_email@example.com' with the email you use to log into the Dashboard.
    SELECT id INTO v_admin_user_id FROM auth.users ORDER BY created_at ASC LIMIT 1; 
    
    -- We are falling back to granting admin to the FIRST user created in auth.users just to unblock you safely.
    -- In production, you would specify the email exactly.
    IF v_admin_user_id IS NOT NULL THEN
        INSERT INTO public.admins (user_id, role) 
        VALUES (v_admin_user_id, 'super_admin') 
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
END $$;
