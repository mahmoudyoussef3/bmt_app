-- Subscription payment integrity.
-- A subscription is usable only after finance approval and through end_date.

alter table public.subscriptions
  drop constraint if exists subscriptions_status_check;

alter table public.subscriptions
  add constraint subscriptions_status_check
  check (status in ('active', 'expired', 'cancelled', 'paused', 'pending_payment'));

alter table public.subscriptions
  add column if not exists payment_method text,
  add column if not exists payment_reference text,
  add column if not exists payment_receipt_url text,
  add column if not exists payment_review_status text not null default 'pending',
  add column if not exists payment_notes jsonb not null default '[]'::jsonb;

alter table public.subscriptions
  drop constraint if exists subscriptions_payment_review_status_check;

alter table public.subscriptions
  add constraint subscriptions_payment_review_status_check
  check (payment_review_status in ('pending', 'needs_review', 'accepted', 'rejected'));

update public.subscriptions
   set payment_review_status = case
     when status in ('active', 'expired') and paid_amount >= total_price
       then 'accepted'
     when status = 'cancelled' then 'rejected'
     else 'pending'
   end;

create or replace function public.can_manage_subscriptions()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists(select 1 from public.admins where user_id = auth.uid())
    or exists(
      select 1 from public.user_roles
       where user_id = auth.uid()
         and role in ('dashboard_admin', 'operations_manager', 'finance_agent')
    );
$$;

alter table public.subscriptions enable row level security;

drop policy if exists subscriptions_client_read_own on public.subscriptions;
create policy subscriptions_client_read_own
  on public.subscriptions for select to authenticated
  using (client_id = auth.uid() or public.can_manage_subscriptions());

drop policy if exists subscriptions_client_create_pending on public.subscriptions;
create policy subscriptions_client_create_pending
  on public.subscriptions for insert to authenticated
  with check (
    (client_id = auth.uid()
      and status = 'pending_payment'
      and paid_amount = 0
      and payment_review_status = 'pending')
    or public.can_manage_subscriptions()
  );

drop policy if exists subscriptions_dashboard_manage on public.subscriptions;
create policy subscriptions_dashboard_manage
  on public.subscriptions for all to authenticated
  using (public.can_manage_subscriptions())
  with check (public.can_manage_subscriptions());

create or replace function public.expire_overdue_subscriptions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  if not public.can_manage_subscriptions() then
    raise exception 'Dashboard finance permission required';
  end if;

  update public.subscriptions
     set status = 'expired',
         updated_at = now()
   where status = 'active'
     and end_date < current_date;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

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
  if not public.can_manage_subscriptions() then
    raise exception 'Operations permission required';
  end if;

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

create or replace function public.consume_subscription_ride(
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
     set trips_used = trips_used + 1,
         status = case
           when trips_count > 0 and trips_used + 1 >= trips_count
             then 'expired'
           else status
         end,
         updated_at = now()
   where id = p_subscription_id
     and status = 'active'
     and start_date <= current_date
     and end_date >= current_date
     and (trips_count = 0 or trips_used < trips_count)
  returning * into result;

  if result.id is null then
    raise exception 'Subscription is inactive, expired, or has no rides left';
  end if;
  return result;
end;
$$;

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
  if not public.can_manage_subscriptions() then
    raise exception 'Dashboard permission required';
  end if;

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

grant execute on function public.confirm_subscription_payment(uuid)
  to authenticated;
grant execute on function public.consume_subscription_ride(uuid)
  to authenticated;
grant execute on function public.request_subscription_renewal(uuid)
  to authenticated;
grant execute on function public.can_manage_subscriptions() to authenticated;

create index if not exists idx_subscriptions_payment_review
  on public.subscriptions(payment_review_status, created_at desc);
