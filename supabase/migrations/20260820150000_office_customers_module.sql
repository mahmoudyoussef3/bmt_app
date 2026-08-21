-- ═══════════════════════════════════════════════════════════════════════════════════
-- العملاء — the Customer 360 module's read surface.
--
-- Design: docs/dashboard/customers/CLIENTS_DATA_MODEL.md
--
-- ── Why this is RPCs and not table reads ────────────────────────────────────────
--
-- A customer is not a row. `clients` carries an identity and nothing else — no
-- office_id, no counters, no last-seen. Everything the office knows about a
-- passenger lives in six office-scoped tables keyed on `client_id`. Assembling
-- that in Dart would mean pulling every booking, payment and subscription the
-- office has ever taken in order to display twelve rows, which is the exact
-- failure `DashboardQueryCaps` was written to stop.
--
-- So the aggregation, the filtering, the sort and the paging all happen here,
-- and the client sends a page request rather than a table scan.
--
-- ── The ownership predicate ─────────────────────────────────────────────────────
--
-- "My office's customer" is defined once, by `office_owns_client`, and it is the
-- same sentence `clients_office_read` enforces on the table: someone who has
-- bought from this office. Every function below re-asks it server-side, so a
-- client id guessed by the caller resolves to `not_authorized` rather than to
-- another office's passenger.
--
-- No function accepts an office id. It comes from `current_office_id()`.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Indexes for the access paths this module introduces
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Boarding history is read per customer; the only indexes on trip_passengers are
-- by trip, because until now nobody asked "where has this person been".
create index if not exists idx_trip_passengers_customer
  on public.trip_passengers (customer_id) where customer_id is not null;

-- Both of these are read per customer, newest first, by the profile tabs.
create index if not exists idx_trip_reviews_client
  on public.trip_reviews (client_id, created_at desc) where client_id is not null;

create index if not exists idx_booking_payments_client
  on public.booking_payments (client_id, submitted_at desc);


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The capability
--
-- `office_can` closes with `else false`, so an unknown capability name is a
-- denial rather than a default-allow. `customers_view` therefore has to be added
-- here or every function below refuses everyone.
--
-- Both roles get it, and that is not a widening: the directory aggregates
-- bookings, wallets and tickets, three surfaces the support agent already reads
-- in full. Withholding the *summary* of data they can already page through would
-- protect nothing and would leave the person who answers "where is my money"
-- assembling it by hand, which is the problem this module exists to remove.
--
-- It is a read-only capability. Nothing in this migration writes.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.office_can(p_capability text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select case public.office_role()
    when 'dashboard_admin' then p_capability in (
      'wallet_view',        -- see customers, balances, ledger
      'wallet_ledger_view', -- office-wide financial activity
      'wallet_export',      -- the one read that leaves the audited system
      'refund_request',     -- file a refund request
      'refund_decide',      -- approve / reject / settle
      'wallet_adjust',      -- cashback, manual credit, manual debit
      'wallet_reverse',
      'wallet_freeze',
      'wallet_policy_edit',
      'customers_view')     -- the Customer 360 read surface
    -- Support agents see everything and move nothing (§6). They are the ones who
    -- hear "where is my money", so denying visibility just makes them guess.
    when 'support_agent' then p_capability in (
      'wallet_view',
      'wallet_ledger_view',
      'refund_request',
      'customers_view')
    else false
  end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Shared guards
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Resolves the caller's office and refuses anyone who is not an office user or
-- lacks the capability. Every function opens with this, so the two questions are
-- asked identically everywhere rather than remembered eight times.
create or replace function public.customers_office_guard()
returns uuid
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('customers_view') then
    raise exception 'not_authorized';
  end if;
  return v_office;
end;
$$;

-- The same guard, plus the ownership check for a single customer.
create or replace function public.customers_client_guard(p_client_id uuid)
returns uuid
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_office_guard();
begin
  if not public.office_owns_client(p_client_id, v_office) then
    raise exception 'not_authorized';
  end if;
  return v_office;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. The directory
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The office's customer base, filtered, sorted and paged server-side.
--
-- `owned` is built from the office-scoped tables first — each of them indexed on
-- office_id — and only then joined back to `clients`. The reverse (scan clients,
-- test each one) would seq-scan every passenger on the platform to find the
-- office's own.
--
-- A subscription counts as current when it is `active` **and** has not run past
-- its end date. `office_expire_overdue_subscriptions()` exists and the
-- subscriptions module calls it before reading, but a read surface that mutates
-- is a read surface that cannot be cached or run by a support agent, so the
-- staleness is corrected in the predicate instead of in the table.
create or replace function public.office_customer_directory(
  p_search       text default null,
  p_subscription text default null,  -- 'active' | 'none'
  p_upcoming     text default null,  -- 'has'    | 'none'
  p_activity     text default null,  -- 'active' | 'dormant'
  p_status       text default null,  -- clients.status
  p_sort         text default 'recent',
  p_limit        int  default 25,
  p_offset       int  default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_office_guard();
  v_limit  int  := least(greatest(coalesce(p_limit, 25), 1), 100);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_sort   text := coalesce(nullif(btrim(coalesce(p_sort, '')), ''), 'recent');
  v_total  bigint;
  v_rows   jsonb;
begin
  return (
    with owned as (
      select b.client_id from public.operation_bookings b
        where b.office_id = v_office and b.client_id is not null
      union
      select s.client_id from public.subscriptions s
        where s.office_id = v_office and s.client_id is not null
      union
      select w.client_id from public.wallets w
        where w.office_id = v_office and w.owner_type = 'client' and w.client_id is not null
    ),
    bk as (
      select b.client_id,
             count(*)                                             as bookings_total,
             count(*) filter (where b.status = 'cancelled')        as bookings_cancelled,
             count(*) filter (where b.status = 'completed')        as bookings_completed,
             min(b.created_at)                                     as first_booking_at,
             max(b.created_at)                                     as last_booking_at,
             min(b.trip_date) filter (
               where b.trip_date >= current_date and b.status <> 'cancelled') as next_trip_date
        from public.operation_bookings b
       where b.office_id = v_office and b.client_id is not null
       group by b.client_id
    ),
    active_sub as (
      select distinct on (s.client_id)
             s.client_id, s.package_name, s.end_date, s.trips_count, s.trips_used
        from public.subscriptions s
       where s.office_id = v_office and s.client_id is not null
         and s.status = 'active'
         and (s.end_date is null or s.end_date >= current_date)
       order by s.client_id, s.end_date desc nulls last, s.created_at desc
    ),
    pay as (
      select p.client_id,
             coalesce(sum(p.amount) filter (where p.status = 'approved'), 0) as total_paid,
             max(p.submitted_at)                                             as last_payment_at
        from public.booking_payments p
       where p.office_id = v_office
       group by p.client_id
    ),
    wal as (
      select w.client_id, w.balance, w.status as wallet_status
        from public.wallets w
       where w.office_id = v_office and w.owner_type = 'client'
    ),
    wtx as (
      select t.client_id, max(t.created_at) as last_wallet_at
        from public.wallet_transactions t
       where t.office_id = v_office and t.client_id is not null
       group by t.client_id
    ),
    scoped as (
      select c.id                            as client_id,
             c.full_name,
             c.phone,
             c.email,
             c.status,
             c.created_at                    as joined_at,
             coalesce(bk.bookings_total, 0)     as bookings_total,
             coalesce(bk.bookings_cancelled, 0) as bookings_cancelled,
             coalesce(bk.bookings_completed, 0) as bookings_completed,
             bk.first_booking_at,
             bk.next_trip_date,
             a.package_name                  as active_package_name,
             a.end_date                      as active_package_end_date,
             a.trips_count                   as active_package_trips_count,
             a.trips_used                    as active_package_trips_used,
             coalesce(pay.total_paid, 0)     as total_paid,
             wal.balance                     as wallet_balance,
             wal.wallet_status,
             greatest(
               coalesce(bk.last_booking_at,  'epoch'::timestamptz),
               coalesce(pay.last_payment_at, 'epoch'::timestamptz),
               coalesce(wtx.last_wallet_at,  'epoch'::timestamptz)
             )                               as last_activity_raw
        from owned o
        join public.clients c on c.id = o.client_id
        left join bk         on bk.client_id  = c.id
        left join active_sub a on a.client_id = c.id
        left join pay        on pay.client_id = c.id
        left join wal        on wal.client_id = c.id
        left join wtx        on wtx.client_id = c.id
    ),
    shaped as (
      -- `last_activity_raw` exists only so the greatest() above can fold three
      -- nullable timestamps; it is dropped here rather than shipped, and the
      -- epoch sentinel becomes the null it stands for.
      select s.client_id, s.full_name, s.phone, s.email, s.status, s.joined_at,
             s.bookings_total, s.bookings_cancelled, s.bookings_completed,
             s.first_booking_at, s.next_trip_date,
             s.active_package_name, s.active_package_end_date,
             s.active_package_trips_count, s.active_package_trips_used,
             s.total_paid, s.wallet_balance, s.wallet_status,
             nullif(s.last_activity_raw, 'epoch'::timestamptz) as last_activity_at
        from scoped s
    ),
    filtered as (
      select * from shaped
       where (v_search is null
              or full_name ilike '%' || v_search || '%'
              or phone     ilike '%' || v_search || '%'
              or coalesce(email, '') ilike '%' || v_search || '%'
              or client_id::text ilike v_search || '%')
         and (p_subscription is null
              or (p_subscription = 'active' and active_package_name is not null)
              or (p_subscription = 'none'   and active_package_name is null))
         and (p_upcoming is null
              or (p_upcoming = 'has'  and next_trip_date is not null)
              or (p_upcoming = 'none' and next_trip_date is null))
         and (p_activity is null
              or (p_activity = 'active'
                  and last_activity_at is not null
                  and last_activity_at >= now() - interval '30 days')
              or (p_activity = 'dormant'
                  and (last_activity_at is null
                       or last_activity_at < now() - interval '90 days')))
         and (p_status is null or status = p_status)
    )
    select jsonb_build_object(
      'total', (select count(*) from filtered),
      'rows',  coalesce((select jsonb_agg(to_jsonb(p)) from (
                 select * from filtered
                  order by
                    case when v_sort = 'recent'   then last_activity_at end desc nulls last,
                    case when v_sort = 'bookings' then bookings_total    end desc nulls last,
                    case when v_sort = 'paid'     then total_paid        end desc nulls last,
                    case when v_sort = 'upcoming' then next_trip_date    end asc  nulls last,
                    case when v_sort = 'name'     then full_name         end asc  nulls last,
                    full_name
                  limit v_limit offset v_offset) p), '[]'::jsonb)
    )
  );
end;
$$;


-- The five headline counts, over the same base the directory pages.
--
-- Each one is a separate targeted query rather than a slice of the directory
-- CTE: the KPIs describe the whole customer base and must not move when the
-- operator filters or pages the list under them.
create or replace function public.office_customers_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_office_guard();
begin
  return jsonb_build_object(
    'total_customers', (
      select count(*) from (
        select b.client_id from public.operation_bookings b
          where b.office_id = v_office and b.client_id is not null
        union
        select s.client_id from public.subscriptions s
          where s.office_id = v_office and s.client_id is not null
        union
        select w.client_id from public.wallets w
          where w.office_id = v_office and w.owner_type = 'client' and w.client_id is not null
      ) o),
    'active_customers', (
      select count(distinct b.client_id) from public.operation_bookings b
       where b.office_id = v_office and b.client_id is not null
         and b.created_at >= now() - interval '30 days'),
    'with_active_subscription', (
      select count(distinct s.client_id) from public.subscriptions s
       where s.office_id = v_office and s.client_id is not null
         and s.status = 'active'
         and (s.end_date is null or s.end_date >= current_date)),
    'with_upcoming_trip', (
      select count(distinct b.client_id) from public.operation_bookings b
       where b.office_id = v_office and b.client_id is not null
         and b.trip_date >= current_date and b.status <> 'cancelled'),
    -- "New" is measured from the first booking with THIS office, not from
    -- clients.created_at: a passenger who signed up two years ago and bought
    -- here for the first time yesterday is new to this office.
    'new_customers', (
      select count(*) from (
        select b.client_id, min(b.created_at) as first_at
          from public.operation_bookings b
         where b.office_id = v_office and b.client_id is not null
         group by b.client_id) f
       where f.first_at >= now() - interval '30 days')
  );
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. The profile — the Customer 360 header and overview
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Boarding counts join through `operation_trips`, not through the booking:
-- `trip_passengers.booking_id` is nullable (a passenger can be put on a manifest
-- at the desk), while `trip_id` is not, so the trip is the only reliable way to
-- prove the row belongs to this office.
create or replace function public.office_customer_profile(p_client_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_client_guard(p_client_id);
  v_client public.clients;
begin
  select * into v_client from public.clients where id = p_client_id;
  if not found then
    raise exception 'client_not_found';
  end if;

  return jsonb_build_object(
    'client', jsonb_build_object(
      'client_id',  v_client.id,
      'full_name',  v_client.full_name,
      'phone',      v_client.phone,
      'email',      v_client.email,
      'status',     v_client.status,
      'joined_at',  v_client.created_at
    ),
    'metrics', (
      select jsonb_build_object(
        'bookings_total',     coalesce(b.total, 0),
        'bookings_upcoming',  coalesce(b.upcoming, 0),
        'bookings_completed', coalesce(b.completed, 0),
        'bookings_cancelled', coalesce(b.cancelled, 0),
        'first_booking_at',   b.first_at,
        'last_booking_at',    b.last_at,
        'next_trip_date',     b.next_trip_date,
        'boarded_count',      coalesce(tp.boarded, 0),
        'no_show_count',      coalesce(tp.no_show, 0),
        'total_paid',         coalesce(p.total_paid, 0),
        'payments_count',     coalesce(p.cnt, 0),
        'last_payment_at',    p.last_at,
        'subscriptions_total', coalesce(s.total, 0),
        'active_subscriptions', coalesce(s.active, 0),
        'wallet_balance',     w.balance,
        'wallet_status',      w.status,
        'wallet_currency',    w.currency,
        'last_wallet_at',     wt.last_at,
        'reviews_count',      coalesce(r.cnt, 0),
        'avg_office_rating',  r.avg_rating,
        'tickets_total',      coalesce(t.total, 0),
        'tickets_open',       coalesce(t.open, 0),
        'refunds_settled_amount', coalesce(rf.amount, 0)
      )
      from (select 1) _
      left join lateral (
        select count(*)                                        as total,
               count(*) filter (where b.trip_date >= current_date
                                  and b.status <> 'cancelled')  as upcoming,
               count(*) filter (where b.status = 'completed')   as completed,
               count(*) filter (where b.status = 'cancelled')   as cancelled,
               min(b.created_at)                                as first_at,
               max(b.created_at)                                as last_at,
               min(b.trip_date) filter (where b.trip_date >= current_date
                                          and b.status <> 'cancelled') as next_trip_date
          from public.operation_bookings b
         where b.client_id = p_client_id and b.office_id = v_office) b on true
      left join lateral (
        select count(*) filter (where tp.boarded_at is not null) as boarded,
               count(*) filter (where tp.status = 'no_show')     as no_show
          from public.trip_passengers tp
          join public.operation_trips ot on ot.id = tp.trip_id
         where tp.customer_id = p_client_id and ot.office_id = v_office) tp on true
      left join lateral (
        select coalesce(sum(bp.amount) filter (where bp.status = 'approved'), 0) as total_paid,
               count(*)            as cnt,
               max(bp.submitted_at) as last_at
          from public.booking_payments bp
         where bp.client_id = p_client_id and bp.office_id = v_office) p on true
      left join lateral (
        select count(*) as total,
               count(*) filter (where sb.status = 'active'
                                  and (sb.end_date is null or sb.end_date >= current_date)) as active
          from public.subscriptions sb
         where sb.client_id = p_client_id and sb.office_id = v_office) s on true
      left join lateral (
        select wl.balance, wl.status, wl.currency
          from public.wallets wl
         where wl.client_id = p_client_id and wl.office_id = v_office
           and wl.owner_type = 'client' limit 1) w on true
      left join lateral (
        select max(wx.created_at) as last_at
          from public.wallet_transactions wx
         where wx.client_id = p_client_id and wx.office_id = v_office) wt on true
      left join lateral (
        select count(*) as cnt, round(avg(tr.office_rating)::numeric, 2) as avg_rating
          from public.trip_reviews tr
         where tr.client_id = p_client_id and tr.office_id = v_office) r on true
      left join lateral (
        select count(*) as total,
               count(*) filter (where st.status in ('open', 'submitted')) as open
          from public.support_tickets st
         where st.client_id = p_client_id and st.office_id = v_office) t on true
      left join lateral (
        select coalesce(sum(rr.approved_amount), 0) as amount
          from public.refund_requests rr
         where rr.client_id = p_client_id and rr.office_id = v_office
           and rr.status = 'settled') rf on true
    ),
    'active_subscription', (
      select to_jsonb(x) from (
        select s.id, s.package_name, s.route_name, s.status,
               s.start_date, s.end_date, s.trips_count, s.trips_used,
               s.total_price, s.paid_amount, s.remaining_amount
          from public.subscriptions s
         where s.client_id = p_client_id and s.office_id = v_office
           and s.status = 'active'
           and (s.end_date is null or s.end_date >= current_date)
         order by s.end_date desc nulls last, s.created_at desc
         limit 1) x),
    -- Preferred routes, derived from what the customer actually booked. Three
    -- rows, because a "top route" over one or two trips is noise.
    'top_routes', coalesce((
      select jsonb_agg(to_jsonb(x)) from (
        select b.route, count(*) as trips
          from public.operation_bookings b
         where b.client_id = p_client_id and b.office_id = v_office
           and b.status <> 'cancelled'
         group by b.route
         order by count(*) desc, b.route
         limit 3) x), '[]'::jsonb)
  );
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. The tabs
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Trips, split into قادمة / سابقة. A cancelled booking is always past, whatever
-- its trip date says — it is not something the passenger is still going to do.
create or replace function public.office_customer_trips(
  p_client_id uuid,
  p_scope     text default 'upcoming',
  p_limit     int  default 20,
  p_offset    int  default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_client_guard(p_client_id);
  v_limit  int  := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
  v_up     bool := coalesce(p_scope, 'upcoming') = 'upcoming';
begin
  return (
    with rows as (
      select b.id                     as booking_id,
             b.booking_number,
             b.route,
             b.trip_date,
             b.trip_time,
             b.seat,
             b.pickup_point_name,
             b.dropoff_point_name,
             b.status,
             b.payment_status,
             b.payment_amount,
             b.payment_method,
             b.cancelled_at,
             b.cancellation_reason,
             b.created_at,
             b.subscription_id is not null as via_subscription,
             b.package_id is not null      as via_package,
             tpk.name_ar                  as subscription_name,
             ot.status                    as trip_status,
             ot.trip_code,
             tp.status                    as boarding_status,
             tp.boarded_at,
             tp.no_show_reason
        from public.operation_bookings b
        left join public.operation_trips ot on ot.id = b.trip_id
        -- `operation_bookings.subscription_id` is a foreign key into
        -- `transport_subscriptions`, NOT into `subscriptions`. The two are
        -- different tables for different jobs — the booking funnel consumes
        -- rides from the first, the الاشتراكات module sells and reports the
        -- second — and joining the wrong one silently yields null on every row.
        left join public.transport_subscriptions ts
               on ts.id = b.subscription_id and ts.office_id = v_office
        left join public.transport_packages tpk on tpk.id = ts.package_id
        left join public.trip_passengers tp on tp.booking_id = b.id
       where b.client_id = p_client_id and b.office_id = v_office
         and (case when v_up
                   then b.trip_date >= current_date and b.status <> 'cancelled'
                   else b.trip_date <  current_date or  b.status  = 'cancelled'
              end)
    )
    select jsonb_build_object(
      'total', (select count(*) from rows),
      'rows',  coalesce((select jsonb_agg(to_jsonb(p)) from (
                 select * from rows
                  order by case when v_up then trip_date end asc,
                           case when not v_up then trip_date end desc,
                           trip_time
                  limit v_limit offset v_offset) p), '[]'::jsonb)
    )
  );
end;
$$;


-- Every subscription this customer holds with this office.
--
-- Usage is `trips_used` over `trips_count`, and `trips_count = 0` is a real
-- value in the data (three seeded rows carry it), so the share is left null
-- rather than divided by zero — the screen shows the counts and omits the bar.
create or replace function public.office_customer_subscriptions(p_client_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_client_guard(p_client_id);
begin
  return coalesce((
    select jsonb_agg(to_jsonb(x)) from (
      select s.id,
             s.package_name,
             s.route_name,
             s.status,
             s.start_date,
             s.end_date,
             s.trips_count,
             s.trips_used,
             greatest(s.trips_count - s.trips_used, 0) as trips_remaining,
             case when s.trips_count > 0
                  then round((s.trips_used::numeric / s.trips_count) * 100, 1)
             end                                        as usage_percent,
             s.total_price,
             s.paid_amount,
             s.remaining_amount,
             s.renewals_count,
             s.payment_method,
             s.payment_review_status,
             s.created_at,
             (s.status = 'active'
              and (s.end_date is null or s.end_date >= current_date)) as is_current
        from public.subscriptions s
       where s.client_id = p_client_id and s.office_id = v_office
       order by is_current desc, s.created_at desc
       limit 100) x), '[]'::jsonb);
end;
$$;


-- Payment history and the wallet position.
--
-- The `gateway_*` columns are deliberately not selected. `gateway_response` is
-- the processor's raw payload and can carry tokens and instrument details; none
-- of it answers a question an operator asks, and a read surface that never
-- selects it cannot leak it.
create or replace function public.office_customer_payments(
  p_client_id uuid,
  p_limit     int default 20,
  p_offset    int default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_client_guard(p_client_id);
  v_limit  int  := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
begin
  return (
    with pays as (
      select bp.id,
             bp.booking_id,
             b.booking_number,
             b.route,
             b.trip_date,
             bp.method,
             bp.amount,
             bp.currency,
             bp.status,
             bp.payment_reference,
             bp.submitted_at,
             bp.paid_at,
             bp.reviewed_at,
             bp.rejection_reason
        from public.booking_payments bp
        left join public.operation_bookings b on b.id = bp.booking_id
       where bp.client_id = p_client_id and bp.office_id = v_office
    )
    select jsonb_build_object(
      'total', (select count(*) from pays),
      'rows',  coalesce((select jsonb_agg(to_jsonb(p)) from (
                 select * from pays order by submitted_at desc
                  limit v_limit offset v_offset) p), '[]'::jsonb),
      'total_approved', (select coalesce(sum(amount), 0) from pays where status = 'approved'),
      'wallet', (
        select to_jsonb(x) from (
          select w.balance, w.available_balance, w.reserved_balance,
                 w.currency, w.status, w.lifetime_credited, w.lifetime_debited
            from public.wallets w
           where w.client_id = p_client_id and w.office_id = v_office
             and w.owner_type = 'client' limit 1) x),
      'wallet_transactions', coalesce((
        select jsonb_agg(to_jsonb(x)) from (
          select t.id, t.kind, t.category, t.amount, t.currency,
                 t.balance_after, t.reason, t.created_at, t.performed_by_name
            from public.wallet_transactions t
           where t.client_id = p_client_id and t.office_id = v_office
           order by t.created_at desc
           limit 50) x), '[]'::jsonb)
    )
  );
end;
$$;


-- The activity timeline.
--
-- Every entry is a real timestamp on a real row — a booking's `created_at`, a
-- receipt's `submitted_at`, the moment a passenger was marked aboard. Nothing
-- here is synthesised from an absence, and nothing is inferred: if the database
-- did not record when something happened, it does not appear.
create or replace function public.office_customer_activity(
  p_client_id uuid,
  p_limit     int default 40
)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.customers_client_guard(p_client_id);
  v_limit  int  := least(greatest(coalesce(p_limit, 40), 1), 200);
begin
  return coalesce((
    select jsonb_agg(to_jsonb(x)) from (
      select * from (
        select 'booking_created' as kind, b.created_at as at,
               b.route as subject, b.booking_number as reference, null::numeric as amount
          from public.operation_bookings b
         where b.client_id = p_client_id and b.office_id = v_office
        union all
        select 'booking_cancelled', b.cancelled_at, b.route, b.booking_number, null
          from public.operation_bookings b
         where b.client_id = p_client_id and b.office_id = v_office
           and b.cancelled_at is not null
        union all
        select 'payment_submitted', bp.submitted_at, bp.method, bp.payment_reference, bp.amount
          from public.booking_payments bp
         where bp.client_id = p_client_id and bp.office_id = v_office
        union all
        select 'payment_approved', bp.reviewed_at, bp.method, bp.payment_reference, bp.amount
          from public.booking_payments bp
         where bp.client_id = p_client_id and bp.office_id = v_office
           and bp.status = 'approved' and bp.reviewed_at is not null
        union all
        select 'boarded', tp.boarded_at, ot.trip_code, tp.seat_label, null
          from public.trip_passengers tp
          join public.operation_trips ot on ot.id = tp.trip_id
         where tp.customer_id = p_client_id and ot.office_id = v_office
           and tp.boarded_at is not null
        union all
        select 'no_show', tp.resolved_at, ot.trip_code, tp.no_show_reason, null
          from public.trip_passengers tp
          join public.operation_trips ot on ot.id = tp.trip_id
         where tp.customer_id = p_client_id and ot.office_id = v_office
           and tp.status = 'no_show' and tp.resolved_at is not null
        union all
        select 'subscription_created', s.created_at, s.package_name, s.route_name, s.total_price
          from public.subscriptions s
         where s.client_id = p_client_id and s.office_id = v_office
        union all
        select 'wallet_' || t.kind, t.created_at, t.reason, t.category, t.amount
          from public.wallet_transactions t
         where t.client_id = p_client_id and t.office_id = v_office
        union all
        select 'review_submitted', tr.created_at, tr.route_label,
               tr.office_rating::text, null
          from public.trip_reviews tr
         where tr.client_id = p_client_id and tr.office_id = v_office
        union all
        select 'ticket_opened', st.created_at, st.title, st.ticket_number, null
          from public.support_tickets st
         where st.client_id = p_client_id and st.office_id = v_office
        union all
        select 'refund_settled', rr.settled_at, rr.reason, rr.category, rr.approved_amount
          from public.refund_requests rr
         where rr.client_id = p_client_id and rr.office_id = v_office
           and rr.status = 'settled' and rr.settled_at is not null
      ) e
      where e.at is not null
      order by e.at desc
      limit v_limit) x), '[]'::jsonb);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. Grants
--
-- Definer functions are revoked from `public` and `anon` and granted only to
-- `authenticated`; the guard inside each one is what narrows that to office
-- users holding `customers_view`.
-- ═══════════════════════════════════════════════════════════════════════════════════

do $$
declare
  v_fn text;
begin
  foreach v_fn in array array[
    'public.customers_office_guard()',
    'public.customers_client_guard(uuid)',
    'public.office_customers_overview()',
    'public.office_customer_directory(text,text,text,text,text,text,int,int)',
    'public.office_customer_profile(uuid)',
    'public.office_customer_trips(uuid,text,int,int)',
    'public.office_customer_subscriptions(uuid)',
    'public.office_customer_payments(uuid,int,int)',
    'public.office_customer_activity(uuid,int)'
  ] loop
    execute format('revoke all on function %s from public, anon', v_fn);
    execute format('grant execute on function %s to authenticated', v_fn);
  end loop;
end $$;
