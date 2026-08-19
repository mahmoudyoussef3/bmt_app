-- ═══════════════════════════════════════════════════════════════════════════════════
-- The departure gate is the passengers, and only the passengers
-- ═══════════════════════════════════════════════════════════════════════════════════
-- 20260811090000 made leaving a station a transition the database decides, on two
-- conditions ANDed together:
--
--     canProceed = boarding requirement resolved AND earliest departure reached
--
-- The second condition is wrong for how this platform actually sells seats. A rider
-- reaches a station's manifest exactly one way — by booking, and booking is refused for
-- any trip past `open_for_booking` (`create_booking`, and every path into it since).
-- So the moment every rider expected at a station is accounted for — aboard, a recorded
-- no-show, or cancelled — there is nobody else who *can* turn up there. Holding the
-- vehicle to its published minute at that point waits for a passenger who cannot exist,
-- and spends the wait on every station after it: the trip arrives late everywhere
-- downstream because it sat still at a stop it had already finished with.
--
-- From here the rule is one condition:
--
--     canProceed = boarding requirement resolved
--
-- The schedule does not stop protecting riders by being dropped here, because it was
-- never the thing protecting them — condition A is. A vehicle that runs ahead simply
-- reaches the next station early and stands there, where riders *are* still pending and
-- the same gate is shut. Nobody is left behind by leaving a stop that is done.
--
-- `expected_departure_at` and `min_dwell_seconds` keep their meaning and keep being
-- served: both apps still show the published time, and the Captain App now names an
-- early departure as one (`StationGate.aheadOfSchedule`) and asks the captain to
-- confirm it, rather than refusing it.
--
-- Mirrored in Dart by `StationBoard.gateAt` in
-- lib/core/tracking/progress/station_board.dart — the Dart side disables a button, this
-- side refuses the transition, and the two must always answer alike.
--
-- Nothing else changes: the captain check, the trip lock, the same-instant recount, the
-- idempotent refusal on a retry, and `boarding -> in_progress` on leaving the first
-- station all stay exactly as they were.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.captain_depart_station(p_trip_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_trip      public.operation_trips;
  v_station   public.trip_station_progress;
  v_next      int;
begin
  v_trip := public.assert_captain_running_trip(p_trip_id);
  perform public.ensure_trip_station_progress(p_trip_id);

  select * into v_station
    from public.trip_station_progress
   where trip_id = p_trip_id
     and actual_arrival_at is not null
     and actual_departure_at is null
   order by sequence
   limit 1
   for update;

  if not found then
    -- Either the vehicle has not reported arriving anywhere yet, or this station was
    -- already departed by a request that beat this one. Both are refusals, not
    -- advances: the alternative is a retry silently departing the *next* station.
    raise exception 'no_current_station';
  end if;

  -- The gate: every rider due here is accounted for.
  -- Recounted first: the tally is maintained by trigger, but a rider confirming
  -- boarding in the same instant as this call must not be able to lose the race and be
  -- left behind, and re-reading under the trip lock closes that window.
  perform public.recount_trip_stations(p_trip_id);
  select * into v_station from public.trip_station_progress where id = v_station.id;

  if v_station.pending_count > 0 then
    raise exception 'passengers_not_boarded:%', v_station.pending_count;
  end if;

  update public.trip_station_progress
     set actual_departure_at = now(),
         status              = 'departed',
         departed_by         = auth.uid(),
         updated_at          = now()
   where id = v_station.id;

  v_next := v_station.sequence + 1;

  update public.trip_station_progress
     set status = 'arriving', updated_at = now()
   where trip_id = p_trip_id
     and sequence = v_next
     and status = 'upcoming';

  -- Leaving the first station *is* the trip departing. Routed through the captain
  -- wrapper so the status allowlist (20260723090000) stays the single authority on
  -- which transitions a captain may cause.
  if v_trip.status = 'boarding' then
    perform public.captain_update_trip_status(p_trip_id, 'in_progress', null);
  end if;

  return jsonb_build_object(
    'success',       true,
    'station_id',    v_station.id,
    'sequence',      v_station.sequence,
    'point_name',    v_station.point_name,
    'departed_at',   now(),
    'next_sequence', case when exists (
                            select 1 from public.trip_station_progress
                             where trip_id = p_trip_id and sequence = v_next)
                          then v_next else null end);
end;
$$;

comment on function public.captain_depart_station(uuid) is
  'The one way a trip advances between stations. Refuses unless the caller is the '
  'trip''s captain, the station is the one the vehicle is standing at, and every '
  'expected passenger is resolved (boarded, no-show or cancelled). The published '
  'departure time is NOT a gate: no rider can join a station''s manifest once the trip '
  'leaves open_for_booking, so a stop whose riders are all accounted for has nobody '
  'left to wait for. Row-locked, so concurrent requests can never advance two stations.';

-- Kept, and still granted, because both apps read the published departure moment it
-- describes — but it no longer gates anything.
comment on function public.station_earliest_departure(timestamptz, timestamptz, int) is
  'The later of (actual arrival + configured dwell) and the published departure time — '
  'the minute the riders due at a stop were given. Informational since '
  '20260819120000: departure is gated on the boarding requirement alone, and this is '
  'what the Captain App calls an early departure against.';

revoke all on function public.captain_depart_station(uuid) from public, anon;
grant execute on function public.captain_depart_station(uuid) to authenticated;
