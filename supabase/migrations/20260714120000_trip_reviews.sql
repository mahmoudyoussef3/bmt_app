-- Trip reviews — the passenger's verdict on a completed trip.
--
-- Visibility model (deliberate, and enforced here rather than in the apps):
--
--   * An individual review — the stars AND the free-text feedback — is
--     OPERATIONAL data. Only the Dashboard reads the queue. A passenger never
--     sees another passenger's review, and a captain never learns who said what
--     about them.
--   * The DRIVER and VEHICLE averages are PUBLIC. They are denormalised onto
--     drivers.rating / vehicles.rating by trigger, so every screen that already
--     selects `drivers (*)` or `vehicles (*)` picks them up with no new query.
--   * The ROUTE rating stays internal. Passengers do not shop for a route on
--     quality — operations tunes it — so publishing it would only confuse.
--
-- Nothing writes to this table directly: submit_trip_review() is the only door,
-- and it enforces ownership, trip completion, and one review per booking.

create table if not exists public.trip_reviews (
  id uuid primary key default gen_random_uuid(),

  -- One review per booking. This unique constraint is what makes a double-tap
  -- (or a retried request) idempotent instead of a duplicate.
  booking_id uuid not null unique
    references public.operation_bookings(id) on delete cascade,

  client_id  uuid references public.clients(id) on delete set null,
  trip_id    uuid references public.operation_trips(id) on delete set null,
  driver_id  uuid references public.drivers(id) on delete set null,
  vehicle_id uuid references public.vehicles(id) on delete set null,
  route_id   uuid references public.operation_routes(id) on delete set null,

  driver_rating  int not null check (driver_rating  between 1 and 5),
  vehicle_rating int not null check (vehicle_rating between 1 and 5),
  route_rating   int not null check (route_rating   between 1 and 5),
  comment        text not null default '',

  -- Snapshots taken at submit time, so the Dashboard queue stays readable (and
  -- one query wide) even after a driver is archived or a vehicle is sold.
  booking_number text not null default '',
  client_name    text not null default '',
  driver_name    text not null default '',
  vehicle_name   text not null default '',
  route_label    text not null default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_trip_reviews_created
  on public.trip_reviews (created_at desc);

create index if not exists idx_trip_reviews_driver
  on public.trip_reviews (driver_id, created_at desc);

create index if not exists idx_trip_reviews_vehicle
  on public.trip_reviews (vehicle_id, created_at desc);

-- Operations triages unhappy passengers first, so make that scan cheap. Spelled
-- out as an OR rather than least(...) so the predicate is unambiguously
-- immutable and the index is always accepted.
create index if not exists idx_trip_reviews_low
  on public.trip_reviews (created_at desc)
  where driver_rating <= 2 or vehicle_rating <= 2 or route_rating <= 2;

-- ── Public aggregates ───────────────────────────────────────────────────────
-- The client app already reads `drivers.rating` (it has always returned 0.0,
-- because the column never existed). Adding it here makes that live everywhere
-- at once instead of threading a new join through every screen.

alter table public.drivers
  add column if not exists rating numeric(3, 2) not null default 0,
  add column if not exists rating_count int not null default 0;

alter table public.vehicles
  add column if not exists rating numeric(3, 2) not null default 0,
  add column if not exists rating_count int not null default 0;

create or replace function public.refresh_driver_rating(p_driver uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_driver is null then return; end if;

  update public.drivers d
     set rating       = coalesce(agg.avg_rating, 0),
         rating_count = coalesce(agg.n, 0),
         updated_at   = now()
    from (
      select round(avg(driver_rating)::numeric, 2) as avg_rating,
             count(*) as n
        from public.trip_reviews
       where driver_id = p_driver
    ) agg
   where d.id = p_driver;
end;
$$;

create or replace function public.refresh_vehicle_rating(p_vehicle uuid)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if p_vehicle is null then return; end if;

  update public.vehicles v
     set rating       = coalesce(agg.avg_rating, 0),
         rating_count = coalesce(agg.n, 0),
         updated_at   = now()
    from (
      select round(avg(vehicle_rating)::numeric, 2) as avg_rating,
             count(*) as n
        from public.trip_reviews
       where vehicle_id = p_vehicle
    ) agg
   where v.id = p_vehicle;
end;
$$;

-- Branches on TG_OP rather than coalesce(new.…, old.…): in a DELETE trigger NEW
-- is unassigned, and touching it would raise instead of recomputing. Both sides
-- are refreshed on UPDATE so that re-pointing a review at another driver fixes
-- the averages on both of them.
create or replace function public.refresh_rating_aggregates()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op <> 'INSERT' then
    perform public.refresh_driver_rating(old.driver_id);
    perform public.refresh_vehicle_rating(old.vehicle_id);
  end if;

  if tg_op <> 'DELETE' then
    perform public.refresh_driver_rating(new.driver_id);
    perform public.refresh_vehicle_rating(new.vehicle_id);
  end if;

  return null;
end;
$$;

drop trigger if exists trg_trip_reviews_aggregates on public.trip_reviews;
create trigger trg_trip_reviews_aggregates
after insert or update or delete on public.trip_reviews
for each row execute function public.refresh_rating_aggregates();

-- ── Row level security ──────────────────────────────────────────────────────

alter table public.trip_reviews enable row level security;

-- The Dashboard is a single-owner workspace with no login gate, so it reads as
-- the anon role — the same way it reads the rest of the operational schema. It
-- is the only reader of the full queue.
drop policy if exists "dashboard reads all reviews" on public.trip_reviews;
create policy "dashboard reads all reviews"
  on public.trip_reviews for select
  to anon using (true);

-- A signed-in passenger may re-read their OWN review (the sheet shows it back
-- to them) and nothing else. There is deliberately no insert/update/delete
-- policy: every write goes through submit_trip_review().
drop policy if exists "clients read own reviews" on public.trip_reviews;
create policy "clients read own reviews"
  on public.trip_reviews for select
  to authenticated using (client_id = auth.uid());

-- ── Write path ──────────────────────────────────────────────────────────────

-- Records (or amends) the passenger's review of one completed booking.
-- Raises: not_authenticated | booking_not_found | not_authorized |
--         booking_cancelled | trip_not_completed | invalid_rating
create or replace function public.submit_trip_review(
  p_booking_id     uuid,
  p_driver_rating  int,
  p_vehicle_rating int,
  p_route_rating   int,
  p_comment        text default ''
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_b   record;
  v_id  uuid;
  v_low int;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if p_driver_rating  not between 1 and 5
  or p_vehicle_rating not between 1 and 5
  or p_route_rating   not between 1 and 5 then
    raise exception 'invalid_rating';
  end if;

  select b.id,
         b.client_id,
         b.trip_id,
         b.status                          as booking_status,
         coalesce(b.booking_number, '')    as booking_number,
         t.status                          as trip_status,
         t.driver_id,
         t.vehicle_id,
         t.route_id,
         coalesce(c.full_name, '')         as client_name,
         coalesce(d.full_name, '')         as driver_name,
         trim(coalesce(v.brand, '') || ' ' || coalesce(v.model, ''))
                                           as vehicle_name,
         coalesce(
           nullif(r.name, ''),
           nullif(trim(coalesce(r.start_city, '') || ' → ' ||
                       coalesce(r.end_city, '')), '→'),
           coalesce(b.route, '')
         )                                 as route_label
    into v_b
    from public.operation_bookings b
    left join public.operation_trips   t on t.id = b.trip_id
    left join public.clients           c on c.id = b.client_id
    left join public.drivers           d on d.id = t.driver_id
    left join public.vehicles          v on v.id = t.vehicle_id
    left join public.operation_routes  r on r.id = t.route_id
   where b.id = p_booking_id;

  if v_b.id is null then
    raise exception 'booking_not_found';
  end if;

  -- A passenger reviews their own trip. Nobody reviews on their behalf.
  if v_b.client_id is distinct from v_uid then
    raise exception 'not_authorized';
  end if;

  if v_b.booking_status = 'cancelled' then
    raise exception 'booking_cancelled';
  end if;

  -- Rating a trip that has not happened yet would be noise, not signal.
  if coalesce(v_b.trip_status, '') <> 'completed' then
    raise exception 'trip_not_completed';
  end if;

  insert into public.trip_reviews (
    booking_id, client_id, trip_id, driver_id, vehicle_id, route_id,
    driver_rating, vehicle_rating, route_rating, comment,
    booking_number, client_name, driver_name, vehicle_name, route_label
  ) values (
    p_booking_id, v_uid, v_b.trip_id, v_b.driver_id, v_b.vehicle_id, v_b.route_id,
    p_driver_rating, p_vehicle_rating, p_route_rating,
    left(coalesce(p_comment, ''), 1000),
    v_b.booking_number, v_b.client_name, v_b.driver_name,
    v_b.vehicle_name, coalesce(v_b.route_label, '')
  )
  on conflict (booking_id) do update
     set driver_rating  = excluded.driver_rating,
         vehicle_rating = excluded.vehicle_rating,
         route_rating   = excluded.route_rating,
         comment        = excluded.comment,
         updated_at     = now()
  returning id into v_id;

  -- An unhappy passenger is an operational problem, not a statistic. Put it in
  -- the Dashboard inbox the moment it lands instead of waiting to be noticed.
  v_low := least(p_driver_rating, p_vehicle_rating, p_route_rating);
  if v_low <= 2 then
    perform public.push_operational_alert(
      'low_trip_rating',
      'تقييم منخفض لرحلة',
      format(
        '%s قيّم الرحلة %s بأقل من 3 نجوم (السائق: %s نجوم).',
        nullif(v_b.client_name, ''),
        nullif(v_b.booking_number, ''),
        p_driver_rating
      ),
      jsonb_build_object(
        'review_id',      v_id,
        'booking_id',     p_booking_id,
        'booking_number', v_b.booking_number,
        'driver_id',      v_b.driver_id,
        'driver_rating',  p_driver_rating,
        'vehicle_rating', p_vehicle_rating,
        'route_rating',   p_route_rating
      ),
      'high',
      '/reviews'
    );
  end if;

  return v_id;
end;
$$;

revoke all on function public.submit_trip_review(uuid, int, int, int, text)
  from public;
grant execute on function public.submit_trip_review(uuid, int, int, int, text)
  to authenticated;

-- ── Live feed ───────────────────────────────────────────────────────────────
-- A review landing while operations is on the board should appear without a
-- refresh. Without this the Dashboard's stream() subscribes to silence.

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'trip_reviews'
    ) then
      alter publication supabase_realtime add table public.trip_reviews;
    end if;
  end if;
end $$;
