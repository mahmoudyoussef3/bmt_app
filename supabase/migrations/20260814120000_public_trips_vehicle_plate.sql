-- ═══════════════════════════════════════════════════════════════════════════════════
-- public_trips — expose the vehicle's plate number
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Trip Details tells a passenger which bus is theirs. It could name the vehicle and its
-- type, but not the one string that identifies it at the curb: the plate. The view's
-- sanitised `vehicles` jsonb carried `vehicle_code` — the office's internal fleet label
-- ("bus 1") — and never `plate_number`, so both the Client's booking sheet (which has
-- always read `plate_number`) and Trip Details rendered an empty plate.
--
-- A plate is public by construction: it is displayed on the outside of the vehicle
-- precisely so that it can be read by anyone standing near it. Nothing else about the
-- vehicle record is opened here — this replays the current definition verbatim and adds
-- one key.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace view public.public_trips as
 SELECT t.id,
    t.trip_code,
    t.office_id,
    t.route_id,
    t.trip_date,
    t.departure_time,
    t.arrival_time,
    t.actual_start_time,
    t.actual_end_time,
    t.status,
    t.capacity,
    t.booked_seats,
    GREATEST(t.capacity - t.booked_seats, 0) AS available_seats,
    t.ticket_price,
    t.currency,
        CASE
            WHEN d.id IS NOT NULL THEN jsonb_build_object('full_name', d.full_name, 'profile_image_url', d.profile_image_url, 'rating', d.rating, 'rating_count', d.rating_count)
            ELSE NULL::jsonb
        END AS drivers,
        CASE
            WHEN v.id IS NOT NULL THEN jsonb_build_object('vehicle_code', v.vehicle_code, 'plate_number', v.plate_number, 'vehicle_type', v.vehicle_type, 'brand', v.brand, 'model', v.model, 'manufacture_year', v.manufacture_year, 'color', v.color, 'capacity', v.capacity, 'seat_layout_type', v.seat_layout_type, 'image_url', v.image_url, 'rating', v.rating, 'rating_count', v.rating_count)
            ELSE NULL::jsonb
        END AS vehicles
   FROM operation_trips t
     LEFT JOIN drivers d ON d.id = t.driver_id
     LEFT JOIN vehicles v ON v.id = t.vehicle_id
  WHERE (t.status = ANY (ARRAY['open_for_booking'::text, 'boarding'::text, 'in_progress'::text, 'completed'::text]))
    AND office_is_listed(t.office_id);

comment on view public.public_trips is
  'The only operation_trips surface the Client may read. Excludes scheduled (unpublished) '
  'and cancelled trips; includes boarding/in_progress/completed so a rider can follow and '
  'review a trip they booked. The vehicle jsonb carries the plate number — public by '
  'construction — so a passenger can identify the bus at the curb.';
