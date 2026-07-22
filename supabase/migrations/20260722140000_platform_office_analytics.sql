-- =====================================================================================
-- EWT platform administration — office analytics
-- -------------------------------------------------------------------------------------
-- 20260722090000 gave the platform admin a way to LOOK at an office. What it did not
-- give is a way to tell a healthy office from a dead one, because every number it
-- returns is a LIFETIME count. An office showing "8 trips" might have run all eight
-- yesterday or all eight last spring; an office showing "31 bookings" might be the
-- platform's best tenant or one that was abandoned in March. On the card those two are
-- indistinguishable, which means the platform's most basic questions — who is actually
-- trading, who has gone quiet, who needs a phone call — cannot be asked at all.
--
-- This migration adds the measuring half: windowed activity per office, the platform
-- roll-up of it, and a daily trend. It creates no tables, no new authorisation concept,
-- and no mutation of any kind — `is_platform_admin()` remains the only identity that
-- opens it, and it is `stable`, not `volatile`.
--
-- ── Why money appears here when 090000 excluded it ──────────────────────────────────
--
-- 090000 wrote that "every financial column" was absent, and that boundary is kept
-- exactly where it was: the platform sees MAGNITUDES, never CONTENTS. What that
-- migration excluded was a booking's payment_details, its receipt, its payer — the row.
-- What this one returns is `sum(payment_amount)`, an aggregate over an office's own
-- trade that carries no client, no phone number, no receipt URL and no payment
-- credential out of it. A platform operator who cannot see which tenant generates the
-- volume cannot run the platform; a platform operator who can read a passenger's
-- receipt has overstepped. This function does the first and not the second.
--
-- ── Where revenue is read from, and where it is NOT ─────────────────────────────────
--
-- `operation_trips.revenue` exists and is a trap: it is 0.00 across the entire database
-- despite thousands of pounds of approved bookings, because nothing maintains it — the
-- same unmaintained-denormalisation problem as `operation_trips.booked_seats`, where
-- `trip_seats.state` is the truth. Revenue here is therefore summed from
-- `operation_bookings.payment_amount` filtered to `payment_status = 'approved'`, which
-- is the only value in that column's vocabulary that means money was actually collected
-- and reviewed. 'pending' and 'submitted' are surfaced too, but separately and never as
-- revenue: they are the office's unreviewed queue, which is a workload signal, not
-- income.
--
-- Seat occupancy is read from `trip_seats` for the same reason, joined through the trip
-- to reach an office_id, since `trip_seats` carries none of its own.
-- =====================================================================================

create or replace function public.platform_office_analytics(
  p_window_days int default 30
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  -- Clamped rather than validated: the window is a lens, not an authorisation input,
  -- and a caller asking for 0 or 10000 days wants a sane chart, not an exception.
  v_days       int         := least(greatest(coalesce(p_window_days, 30), 1), 365);
  v_since      timestamptz := now() - make_interval(days => v_days);
  v_since_date date        := (now() - make_interval(days => v_days))::date;
  v_result     jsonb;
begin
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;

  with
  -- Each source table is aggregated ONCE, grouped by office, then joined — rather than
  -- running a correlated subquery per office per metric as `platform_list_offices`
  -- does. At two offices the difference is invisible; the shape is chosen so it stays
  -- invisible at two hundred.
  booking_stats as (
    select b.office_id,
           count(*)                                                          as total,
           count(*) filter (where b.created_at >= v_since)                   as recent,
           count(*) filter (where b.status = 'confirmed')                    as confirmed,
           count(*) filter (where b.status = 'cancelled')                    as cancelled,
           count(*) filter (where b.status = 'cancelled'
                              and b.created_at >= v_since)                   as cancelled_recent,
           coalesce(sum(b.payment_amount)
             filter (where b.payment_status = 'approved'), 0)                as revenue_total,
           coalesce(sum(b.payment_amount)
             filter (where b.payment_status = 'approved'
                       and b.created_at >= v_since), 0)                      as revenue_recent,
           -- The office's unreviewed queue: money a passenger has committed that
           -- nobody has accepted or refused yet. Cancelled bookings are excluded —
           -- a payment attached to a cancelled booking is not waiting on anyone.
           count(*) filter (where b.payment_status in ('pending', 'submitted')
                              and b.status <> 'cancelled')                   as awaiting_review,
           coalesce(sum(b.payment_amount)
             filter (where b.payment_status in ('pending', 'submitted')
                       and b.status <> 'cancelled'), 0)                      as awaiting_amount,
           count(*) filter (where b.payment_status = 'rejected')             as rejected,
           min(b.created_at)                                                 as first_booking_at,
           max(b.created_at)                                                 as last_booking_at
      from public.operation_bookings b
     where b.office_id is not null
     group by b.office_id
  ),
  trip_stats as (
    select t.office_id,
           count(*)                                                          as total,
           count(*) filter (where t.trip_date >= v_since_date)               as recent,
           -- What a passenger can actually buy right now. An office listed on the
           -- marketplace with zero of these is a storefront with empty shelves.
           count(*) filter (where t.trip_date >= current_date
                              and t.status = 'open_for_booking')             as upcoming,
           -- Past-dated and still open. By the owner's explicit choice these are never
           -- auto-closed, so they accumulate until a human sees them — which means
           -- somebody has to be shown them.
           count(*) filter (where t.trip_date < current_date
                              and t.status = 'open_for_booking')             as stale,
           count(*) filter (where t.status = 'completed')                    as completed,
           count(*) filter (where t.status = 'cancelled')                    as cancelled,
           max(t.trip_date)                                                  as last_trip_date
      from public.operation_trips t
     where t.office_id is not null
     group by t.office_id
  ),
  -- Occupancy over the window: how full the office actually runs its buses, which is
  -- the efficiency question a trip count cannot answer. Read from seat states because
  -- `operation_trips.booked_seats` is unmaintained (see header).
  seat_stats as (
    select t.office_id,
           count(*)                                                          as seats_total,
           count(*) filter (where s.state in ('paid', 'reserved'))           as seats_sold
      from public.trip_seats s
      join public.operation_trips t on t.id = s.trip_id
     where t.office_id is not null
       and t.trip_date >= v_since_date
     group by t.office_id
  ),
  ticket_stats as (
    select s.office_id,
           count(*)                                                          as total,
           count(*) filter (where s.status not in ('closed', 'resolved'))    as open_count,
           count(*) filter (where s.created_at >= v_since)                   as recent
      from public.support_tickets s
     where s.office_id is not null
     group by s.office_id
  ),
  captain_stats as (
    select c.office_id,
           count(*) filter (where c.status = 'pending')                      as pending
      from public.captain_requests c
     where c.office_id is not null
     group by c.office_id
  ),
  review_stats as (
    select r.office_id,
           count(*)                                                          as total,
           count(*) filter (where r.created_at >= v_since)                   as recent,
           avg(r.office_rating) filter (where r.office_rating is not null)    as avg_office_rating
      from public.trip_reviews r
     where r.office_id is not null
     group by r.office_id
  ),
  staff_stats as (
    select ou.office_id,
           count(*) filter (where ou.status = 'active')                      as active_operators,
           count(*) filter (where ou.status = 'active'
                              and ou.role = 'dashboard_admin')               as active_admins
      from public.office_users ou
     group by ou.office_id
  ),
  metrics as (
    select o.id                                          as office_id,
           o.name                                        as office_name,
           o.status,
           o.listing_status,
           o.created_at,
           coalesce(t.total, 0)                          as trips_total,
           coalesce(t.recent, 0)                         as trips_recent,
           coalesce(t.upcoming, 0)                       as trips_upcoming,
           coalesce(t.stale, 0)                          as trips_stale,
           coalesce(t.completed, 0)                      as trips_completed,
           coalesce(t.cancelled, 0)                      as trips_cancelled,
           t.last_trip_date,
           coalesce(b.total, 0)                          as bookings_total,
           coalesce(b.recent, 0)                         as bookings_recent,
           coalesce(b.confirmed, 0)                      as bookings_confirmed,
           coalesce(b.cancelled, 0)                      as bookings_cancelled,
           coalesce(b.cancelled_recent, 0)               as bookings_cancelled_recent,
           coalesce(b.revenue_total, 0)                  as revenue_total,
           coalesce(b.revenue_recent, 0)                 as revenue_recent,
           coalesce(b.awaiting_review, 0)                as payments_awaiting_review,
           coalesce(b.awaiting_amount, 0)                as payments_awaiting_amount,
           coalesce(b.rejected, 0)                       as payments_rejected,
           b.first_booking_at,
           b.last_booking_at,
           coalesce(se.seats_total, 0)                   as seats_offered,
           coalesce(se.seats_sold, 0)                    as seats_sold,
           coalesce(ti.total, 0)                         as tickets_total,
           coalesce(ti.open_count, 0)                    as tickets_open,
           coalesce(ti.recent, 0)                        as tickets_recent,
           coalesce(c.pending, 0)                        as captain_requests_pending,
           coalesce(r.total, 0)                          as reviews_total,
           coalesce(r.recent, 0)                         as reviews_recent,
           r.avg_office_rating,
           coalesce(st.active_operators, 0)              as active_operators,
           coalesce(st.active_admins, 0)                 as active_admins
      from public.offices o
      left join booking_stats b  on b.office_id  = o.id
      left join trip_stats t     on t.office_id  = o.id
      left join seat_stats se    on se.office_id = o.id
      left join ticket_stats ti  on ti.office_id = o.id
      left join captain_stats c  on c.office_id  = o.id
      left join review_stats r   on r.office_id  = o.id
      left join staff_stats st   on st.office_id = o.id
  ),
  -- Platform-wide demand per day. Built off a generated calendar so quiet days appear
  -- as zeros rather than as gaps — a line chart that skips empty days draws a business
  -- that never slowed down.
  trend as (
    select d.day::date                                                       as day,
           count(b.id)                                                       as bookings,
           coalesce(sum(b.payment_amount)
             filter (where b.payment_status = 'approved'), 0)                as revenue
      from generate_series(v_since_date, current_date, interval '1 day') d(day)
      left join public.operation_bookings b
             on b.created_at >= d.day
            and b.created_at <  d.day + interval '1 day'
            and b.office_id is not null
     group by d.day
     order by d.day
  )
  select jsonb_build_object(
    'generated_at', now(),
    'window_days',  v_days,

    'totals', (
      select jsonb_build_object(
        'offices',              count(*),
        'active',               count(*) filter (where m.status = 'active'),
        'paused',               count(*) filter (where m.status = 'paused'),
        'suspended',            count(*) filter (where m.status = 'suspended'),
        'archived',             count(*) filter (where m.status = 'archived'),
        'listed',               count(*) filter (where m.status = 'active'
                                                   and m.listing_status = 'listed'),
        'draft',                count(*) filter (where m.listing_status = 'draft'),
        'unlisted',             count(*) filter (where m.listing_status = 'unlisted'),
        -- The three states that actually matter for a platform operator's day:
        -- who is trading, who has stopped, and who never started.
        'trading',              count(*) filter (where m.bookings_recent > 0),
        'idle',                 count(*) filter (where m.bookings_recent = 0
                                                   and m.bookings_total > 0),
        'never_traded',         count(*) filter (where m.bookings_total = 0),
        'onboarded_in_window',  count(*) filter (where m.created_at >= v_since),
        'without_admin',        count(*) filter (where m.active_admins = 0),
        -- A listed office nobody can buy from: visible in the marketplace, with
        -- nothing on sale. Every one of these is a passenger hitting a dead end.
        'listed_without_trips', count(*) filter (where m.status = 'active'
                                                   and m.listing_status = 'listed'
                                                   and m.trips_upcoming = 0),
        'trips_total',          coalesce(sum(m.trips_total), 0),
        'trips_recent',         coalesce(sum(m.trips_recent), 0),
        'trips_upcoming',       coalesce(sum(m.trips_upcoming), 0),
        'trips_stale',          coalesce(sum(m.trips_stale), 0),
        'bookings_total',       coalesce(sum(m.bookings_total), 0),
        'bookings_recent',      coalesce(sum(m.bookings_recent), 0),
        'revenue_total',        coalesce(sum(m.revenue_total), 0),
        'revenue_recent',       coalesce(sum(m.revenue_recent), 0),
        'payments_awaiting_review', coalesce(sum(m.payments_awaiting_review), 0),
        'payments_awaiting_amount', coalesce(sum(m.payments_awaiting_amount), 0),
        'tickets_open',         coalesce(sum(m.tickets_open), 0),
        'captain_requests_pending', coalesce(sum(m.captain_requests_pending), 0),
        'seats_offered',        coalesce(sum(m.seats_offered), 0),
        'seats_sold',           coalesce(sum(m.seats_sold), 0)
      ) from metrics m
    ),

    'trend', coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'day',      tr.day,
                 'bookings', tr.bookings,
                 'revenue',  tr.revenue
               ) order by tr.day
             ) from trend tr
    ), '[]'::jsonb),

    'offices', coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'office_id',                 m.office_id,
                 'trips_total',               m.trips_total,
                 'trips_recent',              m.trips_recent,
                 'trips_upcoming',            m.trips_upcoming,
                 'trips_stale',               m.trips_stale,
                 'trips_completed',           m.trips_completed,
                 'trips_cancelled',           m.trips_cancelled,
                 'last_trip_date',            m.last_trip_date,
                 'bookings_total',            m.bookings_total,
                 'bookings_recent',           m.bookings_recent,
                 'bookings_confirmed',        m.bookings_confirmed,
                 'bookings_cancelled',        m.bookings_cancelled,
                 'bookings_cancelled_recent', m.bookings_cancelled_recent,
                 'revenue_total',             m.revenue_total,
                 'revenue_recent',            m.revenue_recent,
                 'payments_awaiting_review',  m.payments_awaiting_review,
                 'payments_awaiting_amount',  m.payments_awaiting_amount,
                 'payments_rejected',         m.payments_rejected,
                 'first_booking_at',          m.first_booking_at,
                 'last_booking_at',           m.last_booking_at,
                 'seats_offered',             m.seats_offered,
                 'seats_sold',                m.seats_sold,
                 'tickets_total',             m.tickets_total,
                 'tickets_open',              m.tickets_open,
                 'tickets_recent',            m.tickets_recent,
                 'captain_requests_pending',  m.captain_requests_pending,
                 'reviews_total',             m.reviews_total,
                 'reviews_recent',            m.reviews_recent,
                 'avg_office_rating',         m.avg_office_rating,
                 'active_operators',          m.active_operators,
                 'active_admins',             m.active_admins
               ) order by m.revenue_recent desc, m.bookings_recent desc, m.office_name
             ) from metrics m
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.platform_office_analytics(int)
  from public, anon, authenticated;
grant execute on function public.platform_office_analytics(int) to authenticated;

comment on function public.platform_office_analytics(int) is
  'Windowed activity per office plus the platform roll-up and a daily demand trend. '
  'Platform admins only. Aggregates only — sums and counts, never booking rows, '
  'client PII, receipts or payment credentials. Revenue is summed from approved '
  'operation_bookings.payment_amount; operation_trips.revenue is unmaintained and is '
  'deliberately not read.';
