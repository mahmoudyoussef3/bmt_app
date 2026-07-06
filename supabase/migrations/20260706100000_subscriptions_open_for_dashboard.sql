-- The Dashboard runs without an auth session (single-owner, no login screen),
-- so it reads and manages subscriptions as the anon role — exactly like the
-- other operational tables (drivers, vehicles, routes, captain_requests), which
-- all have RLS disabled.
--
-- The subscriptions module was built for an authenticated dashboard admin:
--   * the `subscriptions` table has RLS with `to authenticated`-only policies,
--     so anon SELECT returns nothing; and
--   * fetchSubscriptions() first calls expire_overdue_subscriptions(), which is
--     granted only to `authenticated` and raises unless can_manage_subscriptions().
-- Under the anon Dashboard that RPC throws before any row is read, surfacing as
-- "تعذر تحميل الاشتراكات" (the module can't open at all).
--
-- Align subscriptions with the rest of the operational schema: disable RLS and
-- make the SECURITY DEFINER management RPCs callable by the anon Dashboard.
-- The Client app keeps reading its own rows (its queries are scoped by
-- client_id in app code) and never calls these dashboard-only RPCs.

alter table public.subscriptions disable row level security;

-- ── expire_overdue_subscriptions ─────────────────────────────────────────────
-- Drop the finance-permission guard so the anon Dashboard can run lazy expiry
-- on every list load.
create or replace function public.expire_overdue_subscriptions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.subscriptions
     set status = 'expired',
         updated_at = now()
   where status = 'active'
     and end_date < current_date;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

-- ── confirm_subscription_payment ─────────────────────────────────────────────
-- Drop the guard; the anon Dashboard confirms finance receipt.
create or replace function public.confirm_subscription_payment(
  p_subscription_id uuid
) returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.subscriptions;
begin
  update public.subscriptions
     set status = 'active',
         payment_review_status = 'accepted',
         paid_amount = total_price,
         remaining_amount = 0,
         start_date = greatest(coalesce(start_date, current_date), current_date),
         end_date = greatest(coalesce(start_date, current_date), current_date)
           + greatest(
               coalesce(
                 (select days from public.packages
                   where id = subscriptions.package_id),
                 end_date - start_date,
                 1
               ),
               1
             ) - 1,
         updated_at = now()
   where id = p_subscription_id
     and status = 'pending_payment'
  returning * into result;

  if result.id is null then
    raise exception 'Subscription is not awaiting payment';
  end if;
  return result;
end;
$$;

-- ── request_subscription_renewal ─────────────────────────────────────────────
-- Drop the guard; the anon Dashboard issues renewals.
create or replace function public.request_subscription_renewal(
  p_subscription_id uuid
) returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  source public.subscriptions;
  result public.subscriptions;
  duration_days integer;
  renewal_start date;
begin
  select * into source
    from public.subscriptions
   where id = p_subscription_id;

  if source.id is null then
    raise exception 'Subscription not found';
  end if;

  duration_days := greatest(
    coalesce(
      (select days from public.packages where id = source.package_id),
      source.end_date - source.start_date,
      1
    ),
    1
  );
  renewal_start := greatest(coalesce(source.end_date + 1, current_date), current_date);

  insert into public.subscriptions (
    client_id, customer_name, customer_phone, package_id, package_name,
    route_name, start_date, end_date, status, total_price, paid_amount,
    remaining_amount, renewals_count, trips_count, trips_used,
    payment_review_status
  ) values (
    source.client_id, source.customer_name, source.customer_phone,
    source.package_id, source.package_name, source.route_name,
    renewal_start, renewal_start + duration_days - 1, 'pending_payment',
    source.total_price, 0, source.total_price, source.renewals_count + 1,
    source.trips_count, 0, 'pending'
  )
  returning * into result;

  return result;
end;
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────
-- Open every subscription RPC the anon Dashboard calls. consume_subscription_ride
-- has no permission guard (it validates subscription state only) so it just needs
-- the anon grant.
grant execute on function public.expire_overdue_subscriptions()      to anon, authenticated;
grant execute on function public.confirm_subscription_payment(uuid)  to anon, authenticated;
grant execute on function public.request_subscription_renewal(uuid)  to anon, authenticated;
grant execute on function public.consume_subscription_ride(uuid)     to anon, authenticated;
