-- Lock submit_trip_review to signed-in passengers at the privilege level, not
-- just inside the function body.
--
-- `revoke ... from public` in the previous migration did NOT exclude anon:
-- Supabase's default privileges grant EXECUTE on new public-schema functions to
-- anon / authenticated / service_role explicitly, and revoking from PUBLIC does
-- not touch an explicit grant. The function still refused anon callers (it
-- raises not_authenticated when auth.uid() is null), so nothing was exposed —
-- but the grant said something the design did not mean, and the next person to
-- edit the body would have been one line away from making that matter.
--
-- Reviewing is an act by an authenticated passenger about their own booking.
-- The anon role — which is what the Dashboard reads as — must never write one.

revoke all on function public.submit_trip_review(uuid, int, int, int, text)
  from anon;

-- The Dashboard reads reviews (RLS policy "dashboard reads all reviews"); it
-- has no business creating them.
revoke insert, update, delete on public.trip_reviews from anon;
