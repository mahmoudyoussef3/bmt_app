-- Migration 08: Captain Messages
-- Enables driver ↔ operations messaging per trip

CREATE TABLE IF NOT EXISTS public.captain_messages (
  id            uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id       uuid         NOT NULL REFERENCES public.operation_trips(id) ON DELETE CASCADE,
  sender_type   text         NOT NULL CHECK (sender_type IN ('driver', 'operations')),
  sender_id     uuid         REFERENCES auth.users(id),
  passenger_id  uuid         REFERENCES public.trip_passengers(id),
  body          text         NOT NULL,
  message_type  text         NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'broadcast', 'image', 'voice')),
  sent_at       timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_captain_messages_trip_id
  ON public.captain_messages (trip_id, sent_at DESC);

ALTER TABLE public.captain_messages ENABLE ROW LEVEL SECURITY;

-- Drivers can read/write messages for their assigned trips
CREATE POLICY "captain_messages_driver_access"
  ON public.captain_messages
  USING (
    trip_id IN (
      SELECT id FROM public.operation_trips
      WHERE driver_id = (
        SELECT id FROM public.drivers WHERE user_id = auth.uid()
      )
    )
  );

-- Operations can read/write all messages
CREATE POLICY "captain_messages_operations_access"
  ON public.captain_messages
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid()
        AND role IN ('dashboard_admin', 'operations_manager', 'support_agent')
    )
  );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.captain_messages;
