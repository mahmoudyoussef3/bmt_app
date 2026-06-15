-- Phase 5 - MIGRATION: Simplify Support Flow
-- Simplifies the customer support tables to a robust ticket management system.

-- ============================================================================
-- 1. ALTER SUPPORT_TICKETS TABLE
-- ============================================================================

-- Add new columns for internal operations
ALTER TABLE public.support_tickets 
ADD COLUMN IF NOT EXISTS internal_note text,
ADD COLUMN IF NOT EXISTS customer_contacted_at timestamptz;

-- Update the default status to 'submitted'
ALTER TABLE public.support_tickets 
ALTER COLUMN status SET DEFAULT 'submitted';

-- Update existing open tickets to 'submitted'
UPDATE public.support_tickets 
SET status = 'submitted' 
WHERE status = 'open';

-- Drop redundant constraints if needed
-- (Not strictly required, but we ensure status has standard values)
ALTER TABLE public.support_tickets 
DROP CONSTRAINT IF EXISTS support_tickets_status_check;

ALTER TABLE public.support_tickets 
ADD CONSTRAINT support_tickets_status_check 
CHECK (status IN ('submitted', 'under review', 'contacted', 'resolved', 'closed', 'rejected'));

-- Ensure client_id points to public.clients safely
-- (Already pointing to auth.users in current schema, we leave it or change to public.clients.
-- The user requested `references public.clients(id)`. Since clients.id is a FK to auth.users, they are 1:1.)
ALTER TABLE public.support_tickets 
DROP CONSTRAINT IF EXISTS support_tickets_client_id_fkey;

ALTER TABLE public.support_tickets 
ADD CONSTRAINT support_tickets_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;

-- ============================================================================
-- 2. RLS POLICIES FOR SUPPORT_TICKETS
-- ============================================================================
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- CLIENTS: Can view their own tickets
DROP POLICY IF EXISTS "Clients can view their own tickets" ON public.support_tickets;
CREATE POLICY "Clients can view their own tickets" 
ON public.support_tickets FOR SELECT 
TO authenticated 
USING (client_id = auth.uid());

-- CLIENTS: Can insert their own tickets
DROP POLICY IF EXISTS "Clients can insert their own tickets" ON public.support_tickets;
CREATE POLICY "Clients can insert their own tickets" 
ON public.support_tickets FOR INSERT 
TO authenticated 
WITH CHECK (client_id = auth.uid());

-- DASHBOARD (ADMINS): Can manage all tickets
DROP POLICY IF EXISTS "Admins can manage all tickets" ON public.support_tickets;
CREATE POLICY "Admins can manage all tickets" 
ON public.support_tickets FOR ALL 
TO authenticated 
USING (public.is_admin()) WITH CHECK (public.is_admin());


-- ============================================================================
-- 3. RLS POLICIES FOR SUPPORT_ATTACHMENTS
-- ============================================================================
ALTER TABLE public.support_attachments ENABLE ROW LEVEL SECURITY;

-- Make message_id nullable since we don't use messages anymore
ALTER TABLE public.support_attachments 
ALTER COLUMN message_id DROP NOT NULL;

-- CLIENTS: Can view attachments linked to their tickets
DROP POLICY IF EXISTS "Clients can view their own attachments" ON public.support_attachments;
CREATE POLICY "Clients can view their own attachments" 
ON public.support_attachments FOR SELECT 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM public.support_tickets st 
    WHERE st.id = support_attachments.ticket_id AND st.client_id = auth.uid()
  )
);

-- CLIENTS: Can insert attachments for their tickets
DROP POLICY IF EXISTS "Clients can insert attachments for their tickets" ON public.support_attachments;
CREATE POLICY "Clients can insert attachments for their tickets" 
ON public.support_attachments FOR INSERT 
TO authenticated 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.support_tickets st 
    WHERE st.id = support_attachments.ticket_id AND st.client_id = auth.uid()
  )
);

-- DASHBOARD (ADMINS): Can view all attachments
DROP POLICY IF EXISTS "Admins can view all attachments" ON public.support_attachments;
CREATE POLICY "Admins can view all attachments" 
ON public.support_attachments FOR SELECT 
TO authenticated 
USING (public.is_admin());

-- ============================================================================
-- 4. DEPRECATE UNUSED TABLES (DO NOT DROP)
-- ============================================================================
COMMENT ON TABLE public.support_messages IS 'DEPRECATED: Feature simplified. No longer used.';
COMMENT ON TABLE public.support_timeline_events IS 'DEPRECATED: Feature simplified. No longer used.';
COMMENT ON TABLE public.operation_complaints IS 'DEPRECATED: Migrated to public.support_tickets.';
