-- Trip execution spans several related tables. Publish all of them so the
-- dashboard, client, and captain applications can invalidate and refetch their
-- authoritative joined views as soon as operational data changes.
do $$
declare
  table_name text;
begin
  if not exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    return;
  end if;

  foreach table_name in array array[
    'operation_trips',
    'operation_bookings',
    'trip_passengers',
    'trip_events',
    'trip_route_points',
    'trip_seats',
    'trip_live_locations'
  ]
  loop
    if to_regclass(format('public.%I', table_name)) is not null
       and not exists (
         select 1
         from pg_publication_tables
         where pubname = 'supabase_realtime'
           and schemaname = 'public'
           and tablename = table_name
       ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end
$$;
