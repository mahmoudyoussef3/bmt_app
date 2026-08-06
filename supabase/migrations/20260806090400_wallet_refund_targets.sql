-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — refund target lookups
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §8.2, §9.4.
--
-- Two reads the module's write surfaces cannot work without:
--
--   office_wallet_refundable_bookings — "which of this customer's bookings can
--     still be refunded, and by how much". Money movement must always start from
--     a named customer AND a named booking (§8.1 rejects a context-free
--     adjustments page for exactly this reason), so the refund dialog needs this
--     list before it can offer anything.
--
--   office_cancelled_trips_with_refunds — the batch surface's queue: cancelled
--     trips that still owe money.
--
-- Both are RPCs rather than client-side joins so that `refund_capacity` stays the
-- single definition of "how much is left". A Dart reimplementation of that rule
-- would be a second definition, and the two would drift.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.office_wallet_refundable_bookings(p_client_id uuid)
returns jsonb
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
  if not public.office_can('wallet_view') then
    raise exception 'not_authorized';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.trip_date desc nulls last, x.created_at desc)
      from (
        select b.id            as booking_id,
               b.booking_number,
               b.trip_id,
               b.trip_date,
               b.route,
               b.seat,
               b.status,
               b.payment_status,
               b.payment_amount,
               b.created_at,
               coalesce(bp.amount, b.payment_amount, 0) as paid_amount,
               bp.method  as payment_method,
               bp.status  as payment_state,
               public.refund_capacity(b.id) as refundable_amount
          from public.operation_bookings b
          left join public.booking_payments bp on bp.booking_id = b.id
         where b.office_id = v_office
           and b.client_id = p_client_id
           -- A draft was never sold, so there is nothing to give back.
           and b.status <> 'draft'
           and public.refund_capacity(b.id) > 0
      ) x), '[]'::jsonb);
end;
$$;


create or replace function public.office_cancelled_trips_with_refunds()
returns jsonb
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
  if not public.office_can('refund_decide') then
    raise exception 'not_authorized';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(x) order by x.trip_date desc)
      from (
        select t.id as trip_id, t.trip_date, t.departure_time, t.status,
               r.name as route_name,
               count(b.id)                          as pending_bookings,
               coalesce(sum(public.refund_capacity(b.id)), 0) as refundable_amount
          from public.operation_trips t
          left join public.operation_routes r on r.id = t.route_id
          join public.operation_bookings b
            on b.trip_id = t.id
           and b.status in ('reserved','confirmed','boarded')
           and public.refund_capacity(b.id) > 0
         where t.office_id = v_office
           and t.status = 'cancelled'
         group by t.id, t.trip_date, t.departure_time, t.status, r.name
      ) x), '[]'::jsonb);
end;
$$;


revoke all on function public.office_wallet_refundable_bookings(uuid) from public;
revoke all on function public.office_wallet_refundable_bookings(uuid) from anon;
grant execute on function public.office_wallet_refundable_bookings(uuid) to authenticated;

revoke all on function public.office_cancelled_trips_with_refunds() from public;
revoke all on function public.office_cancelled_trips_with_refunds() from anon;
grant execute on function public.office_cancelled_trips_with_refunds() to authenticated;
