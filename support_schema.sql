-- Supabase Support Schema & RLS Policies

-- 1. support_tickets
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id uuid primary key default gen_random_uuid(),
    client_id uuid references auth.users(id) on delete cascade,
    ticket_number text unique not null,
    category text not null,
    title text not null,
    description text not null,
    priority text not null,
    status text not null,
    assigned_agent_name text,
    related_booking_id text,
    related_trip_id uuid,
    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    resolved_at timestamptz,
    closed_at timestamptz
);

-- 2. support_messages
CREATE TABLE IF NOT EXISTS public.support_messages (
    id uuid primary key default gen_random_uuid(),
    ticket_id uuid references public.support_tickets(id) on delete cascade,
    sender_type text not null, -- 'client', 'agent', 'system'
    sender_id uuid,
    sender_name text not null,
    message text not null,
    created_at timestamptz default now()
);

-- 3. support_attachments
CREATE TABLE IF NOT EXISTS public.support_attachments (
    id uuid primary key default gen_random_uuid(),
    ticket_id uuid references public.support_tickets(id) on delete cascade,
    message_id uuid references public.support_messages(id) on delete cascade,
    file_url text not null,
    file_name text not null,
    file_type text not null,
    file_size int,
    created_at timestamptz default now()
);

-- 4. support_timeline_events
CREATE TABLE IF NOT EXISTS public.support_timeline_events (
    id uuid primary key default gen_random_uuid(),
    ticket_id uuid references public.support_tickets(id) on delete cascade,
    title text not null,
    description text not null,
    event_type text not null,
    done boolean default true,
    created_at timestamptz default now()
);

-- 5. refund_requests
CREATE TABLE IF NOT EXISTS public.refund_requests (
    id uuid primary key default gen_random_uuid(),
    client_id uuid references auth.users(id) on delete cascade,
    ticket_id uuid references public.support_tickets(id) on delete set null,
    booking_id text,
    trip_id uuid,
    reason text not null,
    description text,
    amount numeric(12,2) not null default 0,
    currency text not null default 'EGP',
    status text not null default 'pending',
    evidence_url text,
    reviewed_by text,
    reviewed_at timestamptz,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;

-- Create Indexes
CREATE INDEX IF NOT EXISTS support_tickets_client_id_idx ON public.support_tickets(client_id);
CREATE INDEX IF NOT EXISTS support_tickets_status_idx ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS support_tickets_created_at_idx ON public.support_tickets(created_at);
CREATE INDEX IF NOT EXISTS support_messages_ticket_id_idx ON public.support_messages(ticket_id);
CREATE INDEX IF NOT EXISTS support_attachments_ticket_id_idx ON public.support_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS refund_requests_client_id_idx ON public.refund_requests(client_id);
CREATE INDEX IF NOT EXISTS refund_requests_status_idx ON public.refund_requests(status);

-- Updated_at triggers function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_support_tickets_updated_at
BEFORE UPDATE ON public.support_tickets
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_refund_requests_updated_at
BEFORE UPDATE ON public.refund_requests
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies (Client view/manage only their own data)

-- Tickets
CREATE POLICY "Clients can view their own tickets"
ON public.support_tickets FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Clients can insert their own tickets"
ON public.support_tickets FOR INSERT
WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Clients can update their own tickets"
ON public.support_tickets FOR UPDATE
USING (auth.uid() = client_id);

-- Messages
CREATE POLICY "Clients can view messages for their tickets"
ON public.support_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.support_tickets 
        WHERE support_tickets.id = support_messages.ticket_id 
        AND support_tickets.client_id = auth.uid()
    )
);

CREATE POLICY "Clients can insert messages to their tickets"
ON public.support_messages FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.support_tickets 
        WHERE support_tickets.id = support_messages.ticket_id 
        AND support_tickets.client_id = auth.uid()
    )
    AND sender_id = auth.uid()
    AND sender_type = 'client'
);

-- Attachments
CREATE POLICY "Clients can view their ticket attachments"
ON public.support_attachments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.support_tickets 
        WHERE support_tickets.id = support_attachments.ticket_id 
        AND support_tickets.client_id = auth.uid()
    )
);

CREATE POLICY "Clients can insert their ticket attachments"
ON public.support_attachments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.support_tickets 
        WHERE support_tickets.id = support_attachments.ticket_id 
        AND support_tickets.client_id = auth.uid()
    )
);

-- Timeline Events
CREATE POLICY "Clients can view timeline events for their tickets"
ON public.support_timeline_events FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.support_tickets 
        WHERE support_tickets.id = support_timeline_events.ticket_id 
        AND support_tickets.client_id = auth.uid()
    )
);

-- Refund Requests
CREATE POLICY "Clients can view their own refund requests"
ON public.refund_requests FOR SELECT
USING (auth.uid() = client_id);

CREATE POLICY "Clients can insert their own refund requests"
ON public.refund_requests FOR INSERT
WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Clients can update their own refund requests"
ON public.refund_requests FOR UPDATE
USING (auth.uid() = client_id);

-- STORAGE SETUP
-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('support-attachments', 'support-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
-- Allow anyone to read public attachments (since bucket is public, this is generally default but we can enforce SELECT)
CREATE POLICY "Public Read Access for Support Attachments"
ON storage.objects FOR SELECT
USING (bucket_id = 'support-attachments');

-- Allow authenticated users to upload to support-attachments
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'support-attachments');

-- Allow clients to delete their own uploaded files
CREATE POLICY "Users can delete own attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'support-attachments' AND auth.uid() = owner);

-- Allow Realtime on support_messages and support_tickets and support_timeline_events
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_timeline_events;
