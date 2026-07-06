-- ============================================================================
-- Notification Event Engine
-- ----------------------------------------------------------------------------
-- Turns the notification *foundation* (20260629300000_notification_system.sql)
-- into a fully event-driven system. Every meaningful business action now emits
-- a notification to the correct audience, generated centrally in the database
-- so it fires no matter which app performed the action, delivered live over the
-- Realtime streams the apps already consume.
--
-- Audiences:
--   • Client  -> public.notifications  (target_app in 'client'/'all'), keyed by
--               the client's auth user id.
--   • Captain -> public.notifications  (target_app in 'captain'/'all'), keyed by
--               drivers.user_id (linked via link_current_driver_account()).
--   • Dashboard -> public.operational_alerts (NEW). The Dashboard runs as the
--               anon role (single-owner, no login), so it cannot own or read a
--               per-user notifications row. It reads a dedicated RLS-disabled
--               feed instead, matching the rest of the operational schema
--               (drivers, captain_requests, …).
-- ============================================================================

-- ── 1. operational_alerts — the Dashboard's receive channel ─────────────────
-- RLS is intentionally disabled: the Dashboard reads/updates this table as the
-- anon role exactly like the other operational tables it already consumes.
create table if not exists public.operational_alerts (
  id         uuid primary key default gen_random_uuid(),
  type       text not null,
  title      text not null,
  body       text not null,
  data       jsonb not null default '{}'::jsonb,
  priority   text not null default 'normal'
    check (priority in ('low', 'normal', 'high', 'urgent')),
  action_url text,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_operational_alerts_created
  on public.operational_alerts (created_at desc);
create index if not exists idx_operational_alerts_unread
  on public.operational_alerts (created_at desc) where is_read = false;

alter table public.operational_alerts disable row level security;

-- The Dashboard reaches this feed as the anon role (single-owner, no login),
-- exactly like captain_requests. Grant it explicitly so reads/updates work.
grant select, insert, update, delete on public.operational_alerts
  to anon, authenticated;

do $$ begin
  begin
    alter publication supabase_realtime add table public.operational_alerts;
  exception when duplicate_object then null;
  end;
end $$;

-- ── 2. Central emit helpers (single source of truth) ────────────────────────

-- Insert one per-user notification, honouring notification_preferences when a
-- matching <category>_enabled column exists (defaults to sending otherwise).
-- No-ops when the recipient is null (e.g. an unassigned trip).
create or replace function public.push_notification(
  p_user_id    uuid,
  p_title      text,
  p_body       text,
  p_category   text  default 'general',
  p_target_app text  default 'client',
  p_data       jsonb default '{}'::jsonb,
  p_action_url text  default null,
  p_priority   text  default 'normal'
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_allowed boolean := true;
  v_col     text := p_category || '_enabled';
begin
  if p_user_id is null then
    return;
  end if;

  begin
    execute format(
      'select coalesce((select %I from public.notification_preferences
                        where user_id = $1), true)', v_col)
    into v_allowed using p_user_id;
  exception when undefined_column then
    v_allowed := true;
  end;

  if not v_allowed then
    return;
  end if;

  insert into public.notifications
    (user_id, title, body, type, category, target_app, action_url, data, priority)
  values
    (p_user_id, p_title, p_body, p_category, p_category, p_target_app,
     p_action_url, coalesce(p_data, '{}'::jsonb), p_priority);
end;
$$;

-- Insert one Dashboard operational alert.
create or replace function public.push_operational_alert(
  p_type       text,
  p_title      text,
  p_body       text,
  p_data       jsonb default '{}'::jsonb,
  p_priority   text  default 'normal',
  p_action_url text  default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.operational_alerts
    (type, title, body, data, priority, action_url)
  values
    (p_type, p_title, p_body, coalesce(p_data, '{}'::jsonb), p_priority,
     p_action_url);
end;
$$;

-- Resolve the captain's auth user id for a trip (null when unassigned/unlinked).
create or replace function public.captain_user_for_trip(p_trip_id uuid)
returns uuid
language sql stable security definer set search_path = public as $$
  select d.user_id
  from   public.operation_trips t
  join   public.drivers d on d.id = t.driver_id
  where  t.id = p_trip_id;
$$;

-- Fan a client-facing notification out to every passenger on a trip.
create or replace function public.notify_trip_passengers(
  p_trip_id  uuid,
  p_title    text,
  p_body     text,
  p_category text  default 'trip',
  p_data     jsonb default '{}'::jsonb,
  p_priority text  default 'normal'
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications
    (user_id, title, body, type, category, target_app, data, priority)
  select tp.customer_id, p_title, p_body, p_category, p_category, 'client',
         coalesce(p_data, '{}'::jsonb), p_priority
  from   public.trip_passengers tp
  where  tp.trip_id = p_trip_id
    and  tp.customer_id is not null;
end;
$$;

revoke all on function public.push_notification(
  uuid, text, text, text, text, jsonb, text, text) from public;
revoke all on function public.push_operational_alert(
  text, text, text, jsonb, text, text) from public;
revoke all on function public.notify_trip_passengers(
  uuid, text, text, text, jsonb, text) from public;

-- ── 3. Trip lifecycle + captain assignment ──────────────────────────────────
create or replace function public.on_operation_trip_change()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_captain uuid;
  v_code    text := coalesce(nullif(trim(new.trip_code), ''), 'رحلتك');
begin
  -- Captain (re)assignment
  if new.driver_id is not null
     and new.driver_id is distinct from old.driver_id then
    select user_id into v_captain from public.drivers where id = new.driver_id;
    perform public.push_notification(
      v_captain, 'تم إسنادك لرحلة جديدة',
      'رحلة ' || v_code || ' بتاريخ ' || to_char(new.trip_date, 'YYYY-MM-DD'),
      'assignment', 'captain',
      jsonb_build_object('trip_id', new.id), '/trips', 'high');
  end if;

  -- Status transitions
  if new.status is distinct from old.status then
    v_captain := public.captain_user_for_trip(new.id);

    if new.status = 'boarding' then
      perform public.notify_trip_passengers(
        new.id, 'بدأ صعود الركاب',
        'بدأ صعود الركاب لرحلتك ' || v_code, 'trip',
        jsonb_build_object('trip_id', new.id));
      perform public.push_notification(
        v_captain, 'بدأ صعود الركاب', 'رحلة ' || v_code, 'trip', 'captain',
        jsonb_build_object('trip_id', new.id));

    elsif new.status = 'in_progress' then
      perform public.notify_trip_passengers(
        new.id, 'انطلقت رحلتك',
        'رحلتك ' || v_code || ' في الطريق الآن.', 'trip',
        jsonb_build_object('trip_id', new.id), 'high');
      perform public.push_notification(
        v_captain, 'بدأت الرحلة', 'رحلة ' || v_code || ' قيد التنفيذ.',
        'trip', 'captain', jsonb_build_object('trip_id', new.id));

    elsif new.status = 'completed' then
      perform public.notify_trip_passengers(
        new.id, 'اكتملت رحلتك',
        'نشكرك على السفر معنا في رحلة ' || v_code || '.', 'trip',
        jsonb_build_object('trip_id', new.id));

    elsif new.status = 'cancelled' then
      perform public.notify_trip_passengers(
        new.id, 'تم إلغاء رحلتك',
        'نأسف، تم إلغاء رحلتك ' || v_code || '. سيتم التواصل معك بخصوص الاسترداد.',
        'trip', jsonb_build_object('trip_id', new.id), 'high');
      perform public.push_notification(
        v_captain, 'تم إلغاء الرحلة', 'تم إلغاء رحلة ' || v_code || '.',
        'trip', 'captain', jsonb_build_object('trip_id', new.id), null, 'high');
      perform public.push_operational_alert(
        'trip_cancelled', 'تم إلغاء رحلة', 'تم إلغاء الرحلة ' || v_code || '.',
        jsonb_build_object('trip_id', new.id), 'high', '/live-trips');
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_operation_trip_change on public.operation_trips;
create trigger trg_operation_trip_change
  after update on public.operation_trips
  for each row execute function public.on_operation_trip_change();

-- ── 4. Passenger manifest changes (captain-facing) ──────────────────────────
create or replace function public.on_trip_passenger_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_captain uuid := public.captain_user_for_trip(new.trip_id);
  v_code    text;
begin
  if v_captain is not null then
    select trip_code into v_code from public.operation_trips where id = new.trip_id;
    perform public.push_notification(
      v_captain, 'راكب جديد على رحلتك',
      coalesce(new.passenger_name, 'راكب') || ' انضم إلى رحلة ' ||
        coalesce(v_code, ''),
      'passenger', 'captain',
      jsonb_build_object('trip_id', new.trip_id, 'passenger_id', new.id));
  end if;
  return new;
end;
$$;

drop trigger if exists trg_trip_passenger_insert on public.trip_passengers;
create trigger trg_trip_passenger_insert
  after insert on public.trip_passengers
  for each row execute function public.on_trip_passenger_insert();

create or replace function public.on_trip_passenger_delete()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_captain uuid := public.captain_user_for_trip(old.trip_id);
  v_code    text;
begin
  if v_captain is not null then
    select trip_code into v_code from public.operation_trips where id = old.trip_id;
    perform public.push_notification(
      v_captain, 'ألغى أحد الركاب حجزه',
      coalesce(old.passenger_name, 'راكب') || ' — رحلة ' || coalesce(v_code, ''),
      'passenger', 'captain',
      jsonb_build_object('trip_id', old.trip_id));
  end if;
  return old;
end;
$$;

drop trigger if exists trg_trip_passenger_delete on public.trip_passengers;
create trigger trg_trip_passenger_delete
  after delete on public.trip_passengers
  for each row execute function public.on_trip_passenger_delete();

-- ── 5. Payment review queue (Dashboard) ─────────────────────────────────────
create or replace function public.on_booking_payment_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'submitted' then
    perform public.push_operational_alert(
      'payment_review', 'مراجعة دفع جديدة',
      'طلب مراجعة دفع بقيمة ' || new.amount || ' ' || new.currency,
      jsonb_build_object('booking_id', new.booking_id, 'payment_id', new.id),
      'high', '/payment-verification');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_booking_payment_insert on public.booking_payments;
create trigger trg_booking_payment_insert
  after insert on public.booking_payments
  for each row execute function public.on_booking_payment_insert();

-- ── 6. Captain access requests (Dashboard) ──────────────────────────────────
create or replace function public.on_captain_request_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.push_operational_alert(
    'captain_request', 'طلب انضمام كابتن جديد',
    new.full_name || ' — ' || new.phone,
    jsonb_build_object('request_id', new.id), 'high', '/captain-requests');
  return new;
end;
$$;

drop trigger if exists trg_captain_request_insert on public.captain_requests;
create trigger trg_captain_request_insert
  after insert on public.captain_requests
  for each row execute function public.on_captain_request_insert();

-- ── 7. Support tickets + replies ────────────────────────────────────────────
create or replace function public.on_support_ticket_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.push_operational_alert(
    'support_ticket', 'شكوى/تذكرة جديدة', new.title,
    jsonb_build_object('ticket_id', new.id, 'ticket_number', new.ticket_number),
    case when new.priority in ('high', 'urgent') then 'high' else 'normal' end,
    '/tickets');
  return new;
end;
$$;

drop trigger if exists trg_support_ticket_insert on public.support_tickets;
create trigger trg_support_ticket_insert
  after insert on public.support_tickets
  for each row execute function public.on_support_ticket_insert();

-- Agent/support reply -> notify the ticket owner (client).
create or replace function public.on_support_message_insert()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_client uuid;
begin
  if new.sender_type is distinct from 'client' then
    select client_id into v_client
    from public.support_tickets where id = new.ticket_id;
    perform public.push_notification(
      v_client, 'رد جديد على شكواك', new.message, 'chat', 'client',
      jsonb_build_object('ticket_id', new.ticket_id), '/support');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_support_message_insert on public.support_messages;
create trigger trg_support_message_insert
  after insert on public.support_messages
  for each row execute function public.on_support_message_insert();

-- ── 8. Refund requests ──────────────────────────────────────────────────────
create or replace function public.on_refund_request_change()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.push_operational_alert(
      'refund_request', 'طلب استرداد جديد',
      'بقيمة ' || new.amount || ' ' || new.currency || ' — ' || new.reason,
      jsonb_build_object('refund_id', new.id), 'high', '/payments');

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status
        and new.status in ('approved', 'rejected') then
    perform public.push_notification(
      new.client_id, 'تحديث على طلب الاسترداد',
      case when new.status = 'approved'
        then 'تمت الموافقة على طلب الاسترداد بقيمة ' || new.amount || ' ' ||
             new.currency || '.'
        else 'تم رفض طلب الاسترداد الخاص بك.'
      end,
      'payment', 'client',
      jsonb_build_object('refund_id', new.id, 'status', new.status), '/support');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_refund_request_change on public.refund_requests;
create trigger trg_refund_request_change
  after insert or update on public.refund_requests
  for each row execute function public.on_refund_request_change();

-- ── 9. Subscription lifecycle (client-facing) ───────────────────────────────
create or replace function public.on_subscription_status_change()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'expired' then
      perform public.push_notification(
        new.client_id, 'انتهى اشتراكك',
        'انتهت صلاحية باقتك. جدّد الآن لمواصلة رحلاتك.', 'subscription', 'client',
        jsonb_build_object('subscription_id', new.id), '/subscriptions');
    elsif new.status = 'exhausted' then
      perform public.push_notification(
        new.client_id, 'نفدت رحلات باقتك',
        'لقد استخدمت جميع رحلات باقتك. يمكنك شراء باقة جديدة.', 'subscription',
        'client', jsonb_build_object('subscription_id', new.id), '/subscriptions');
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_subscription_status_change on public.transport_subscriptions;
create trigger trg_subscription_status_change
  after update on public.transport_subscriptions
  for each row execute function public.on_subscription_status_change();
