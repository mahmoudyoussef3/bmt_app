-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — Step 4/4: the RPC surface
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md Part 4, §5, §9, §10, §12, §13.
--
-- Every function here is SECURITY DEFINER with a pinned search_path, revoked from
-- `public` and `anon`, and granted to `authenticated`. Each one opens with the
-- same two questions — "are you an office user?" and "may you do this?" — asked
-- of the server (`office_can`), never of the Dart permission set.
--
-- Writes funnel into `wallet_post_entry`, which is revoked from every client
-- role so the per-kind guards below cannot be bypassed.
--
-- ── The two serialisation points ────────────────────────────────────────────────
--
--   the WALLET row  — balance arithmetic. Held by wallet_post_entry.
--   the BOOKING row — the cumulative refund cap. Held here, because a refund to
--                     InstaPay never touches a wallet, so the wallet lock alone
--                     would not serialise two concurrent refunds of one booking.
--
-- Batch operations take wallets in ascending client_id order — a fixed total
-- order over a one-wallet-per-customer table — so two batches cannot deadlock.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. Shared refund internals
-- ═══════════════════════════════════════════════════════════════════════════════════

-- How much of this booking is still refundable.
--
-- The cap is the customer's payment minus everything already settled against it,
-- floored at zero. `booking_payments.amount` is the external tender and the
-- primary source; `operation_bookings.payment_amount` (the fare) is the fallback
-- for bookings taken at the desk with no payment instrument on record.
create or replace function public.refund_capacity(
  p_booking_id uuid,
  p_exclude_refund_id uuid default null
)
returns numeric
language sql
stable
security definer
set search_path to 'public'
as $$
  select greatest(
    coalesce(
      (select bp.amount from public.booking_payments bp where bp.booking_id = p_booking_id),
      (select b.payment_amount from public.operation_bookings b where b.id = p_booking_id),
      0)
    - coalesce((select sum(r.approved_amount)
                  from public.refund_requests r
                 where r.booking_id = p_booking_id
                   and r.status = 'settled'
                   and (p_exclude_refund_id is null or r.id <> p_exclude_refund_id)), 0),
    0);
$$;


-- Files a refund row. Private: the capability check belongs to the RPC that
-- calls this, because "raise a request" and "decide one" are different
-- permissions held by different roles.
create or replace function public.refund_file(
  p_booking_id  uuid,
  p_amount      numeric,
  p_category    text,
  p_reason      text,
  p_notes       text,
  p_request_key uuid,
  p_status      text,
  p_batch_id    uuid default null
)
returns public.refund_requests
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office   uuid := public.current_office_id();
  v_booking  public.operation_bookings;
  v_refund   public.refund_requests;
  v_amount   numeric(12,2) := round(coalesce(p_amount, 0), 2);
  v_capacity numeric;
  v_actor    uuid := auth.uid();
  v_name     text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  perform public.assert_office_owns_booking(p_booking_id);

  if nullif(btrim(coalesce(p_reason,'')), '') is null then
    raise exception 'reason_required';
  end if;
  if not public.wallet_category_allowed('refund', p_category) then
    raise exception 'invalid_category';
  end if;

  -- Idempotency before any lock: a retry must not queue behind the original.
  select * into v_refund from public.refund_requests
   where office_id = v_office and request_key = p_request_key;
  if found then
    return v_refund;
  end if;

  -- THE serialisation point for the cumulative cap. Two operators refunding the
  -- same booking at the same moment queue here; the second sees the first's
  -- amount rather than validating against a stale total (§13).
  select * into v_booking from public.operation_bookings
   where id = p_booking_id for update;

  if v_amount <= 0 then
    raise exception 'invalid_amount';
  end if;
  v_capacity := public.refund_capacity(p_booking_id);
  if v_amount > v_capacity then
    raise exception 'refund_exceeds_payment';
  end if;

  select ou.full_name into v_name
    from public.office_users ou
   where ou.user_id = v_actor and ou.office_id = v_office
   limit 1;

  insert into public.refund_requests (
    client_id, booking_id, trip_id, office_id,
    reason, description, notes, category,
    amount, approved_amount, currency, status,
    source, requested_by, requested_by_name,
    reviewed_by, reviewed_by_name, reviewed_at,
    request_key, trip_cancellation_batch_id
  ) values (
    v_booking.client_id, p_booking_id, v_booking.trip_id, v_office,
    btrim(p_reason), btrim(p_reason), nullif(btrim(coalesce(p_notes,'')), ''), p_category,
    v_amount,
    case when p_status = 'approved' then v_amount end,
    'EGP', p_status,
    'dashboard', v_actor, coalesce(v_name, 'مستخدم المكتب'),
    case when p_status = 'approved' then v_actor end,
    case when p_status = 'approved' then coalesce(v_name, 'مستخدم المكتب') end,
    case when p_status = 'approved' then now() end,
    p_request_key, p_batch_id
  )
  returning * into v_refund;

  return v_refund;
end;
$$;


-- Moves an approved refund to settled: posts the wallet leg when the
-- destination is the wallet, stamps the settlement, and closes the booking's
-- payment when the refund is now complete.
create or replace function public.refund_apply_settlement(
  p_refund_id         uuid,
  p_settlement_method text,
  p_request_key       uuid default null
)
returns public.refund_requests
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office   uuid := public.current_office_id();
  v_refund   public.refund_requests;
  v_tx       public.wallet_transactions;
  v_capacity numeric;
  v_settled  numeric;
  v_paid     numeric;
  v_actor    uuid := auth.uid();
  v_name     text;
begin
  select * into v_refund from public.refund_requests where id = p_refund_id for update;
  if not found then
    raise exception 'refund_not_found';
  end if;
  if v_refund.office_id is distinct from v_office then
    raise exception 'cross_office_denied';
  end if;
  if v_refund.status not in ('pending','approved') then
    raise exception 'refund_not_actionable';
  end if;
  if v_refund.approved_amount is null or v_refund.approved_amount <= 0 then
    raise exception 'invalid_amount';
  end if;
  if p_settlement_method not in ('wallet','original_method','cash','bank_transfer') then
    raise exception 'invalid_settlement_method';
  end if;
  -- Guest bookings (F6) have no wallet to refund into. Cash settlement is the
  -- first-class path, not a fallback.
  if p_settlement_method = 'wallet' and v_refund.client_id is null then
    raise exception 'guest_booking_no_wallet';
  end if;

  -- Re-checked at settle time, not only at request time: the amount can be
  -- edited in between, and another refund can settle in between (§14, case 4).
  if v_refund.booking_id is not null then
    perform 1 from public.operation_bookings where id = v_refund.booking_id for update;
    v_capacity := public.refund_capacity(v_refund.booking_id, v_refund.id);
    if v_refund.approved_amount > v_capacity then
      raise exception 'refund_exceeds_payment';
    end if;
  end if;

  if p_settlement_method = 'wallet' then
    -- p_notify => false: the refund record owns the customer message, so a
    -- wallet-settled refund produces exactly one notification, not two.
    v_tx := public.wallet_post_entry(
      p_client_id   => v_refund.client_id,
      p_capability  => 'refund_decide',
      p_kind        => 'refund',
      p_category    => v_refund.category,
      p_amount      => v_refund.approved_amount,
      p_reason      => v_refund.reason,
      p_notes       => v_refund.notes,
      p_request_key => coalesce(p_request_key, v_refund.request_key, gen_random_uuid()),
      p_source      => 'dashboard',
      p_booking_id  => v_refund.booking_id,
      p_refund_id   => v_refund.id,
      p_notify      => false);
  end if;

  select ou.full_name into v_name
    from public.office_users ou
   where ou.user_id = v_actor and ou.office_id = v_office
   limit 1;

  update public.refund_requests
     set status                = 'settled',
         settlement_method     = p_settlement_method,
         settled_at            = now(),
         wallet_transaction_id = v_tx.id,
         reviewed_by           = coalesce(reviewed_by, v_actor),
         reviewed_by_name      = coalesce(reviewed_by_name, v_name, 'مستخدم المكتب'),
         reviewed_at           = coalesce(reviewed_at, now()),
         updated_at            = now()
   where id = v_refund.id
  returning * into v_refund;

  -- `booking_payments.status = 'refunded'` was unreachable before this — nothing
  -- in the schema wrote it (§1.1). It flips only when the refund is complete;
  -- partial refunds leave it `approved`, and REVENUE is correct either way
  -- because §7 subtracts refund *amounts*, not statuses.
  if v_refund.booking_id is not null then
    select coalesce(sum(approved_amount), 0) into v_settled
      from public.refund_requests
     where booking_id = v_refund.booking_id and status = 'settled';

    select coalesce(
             (select bp.amount from public.booking_payments bp where bp.booking_id = v_refund.booking_id),
             (select b.payment_amount from public.operation_bookings b where b.id = v_refund.booking_id),
             0)
      into v_paid;

    if v_paid > 0 and v_settled >= v_paid then
      update public.booking_payments
         set status = 'refunded', updated_at = now()
       where booking_id = v_refund.booking_id and status <> 'refunded';
      update public.operation_bookings
         set payment_status = 'refunded', updated_at = now()
       where id = v_refund.booking_id and payment_status is distinct from 'refunded';
    end if;
  end if;

  return v_refund;
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. Refund RPCs (§9, §10)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- One pipeline, two entry points: the owner's refund is born approved and
-- settles in the same transaction; a support agent's is born pending and lands
-- in the queue (§9). Uniform record, uniform audit, one place Finance reads.
create or replace function public.office_refund_create(
  p_booking_id        uuid,
  p_amount            numeric,
  p_category          text,
  p_reason            text,
  p_notes             text default null,
  p_settlement_method text default 'wallet',
  p_request_key       uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_key      uuid := coalesce(p_request_key, gen_random_uuid());
  v_can_decide boolean;
  v_refund   public.refund_requests;
begin
  if public.current_office_id() is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('refund_request') then
    raise exception 'not_authorized';
  end if;

  v_can_decide := public.office_can('refund_decide');

  v_refund := public.refund_file(
    p_booking_id, p_amount, p_category, p_reason, p_notes, v_key,
    case when v_can_decide then 'approved' else 'pending' end);

  -- Only settle a row this call actually created in the `approved` state; a
  -- replayed key returns whatever it returned the first time.
  if v_can_decide and v_refund.status = 'approved' then
    v_refund := public.refund_apply_settlement(v_refund.id, p_settlement_method, v_key);
  end if;

  return to_jsonb(v_refund);
end;
$$;


create or replace function public.office_refund_decide(
  p_refund_id         uuid,
  p_decision          text,
  p_approved_amount   numeric default null,
  p_settlement_method text default 'wallet',
  p_reason            text default null,
  p_request_key       uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_refund public.refund_requests;
  v_amount numeric(12,2);
  v_actor  uuid := auth.uid();
  v_name   text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('refund_decide') then
    raise exception 'not_authorized';
  end if;
  if p_decision not in ('approve','reject') then
    raise exception 'invalid_decision';
  end if;

  select * into v_refund from public.refund_requests
   where id = p_refund_id and office_id = v_office for update;
  if not found then
    raise exception 'refund_not_found';
  end if;
  if v_refund.status not in ('pending','approved') then
    raise exception 'refund_not_actionable';
  end if;

  select ou.full_name into v_name
    from public.office_users ou
   where ou.user_id = v_actor and ou.office_id = v_office
   limit 1;

  if p_decision = 'reject' then
    if nullif(btrim(coalesce(p_reason,'')), '') is null then
      raise exception 'reason_required';
    end if;
    update public.refund_requests
       set status           = 'rejected',
           reviewed_by      = v_actor,
           reviewed_by_name = coalesce(v_name, 'مستخدم المكتب'),
           reviewed_at      = now(),
           notes            = btrim(p_reason),
           updated_at       = now()
     where id = v_refund.id
    returning * into v_refund;
    return to_jsonb(v_refund);
  end if;

  v_amount := round(coalesce(p_approved_amount, v_refund.amount), 2);
  if v_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  update public.refund_requests
     set status           = 'approved',
         approved_amount  = v_amount,
         reviewed_by      = v_actor,
         reviewed_by_name = coalesce(v_name, 'مستخدم المكتب'),
         reviewed_at      = now(),
         updated_at       = now()
   where id = v_refund.id
  returning * into v_refund;

  v_refund := public.refund_apply_settlement(
    v_refund.id, p_settlement_method, coalesce(p_request_key, gen_random_uuid()));

  return to_jsonb(v_refund);
end;
$$;


-- Cancelling a trip is the single most common refund cause, and a 14-seat bus
-- means 14 refunds. Without this the feature is unusable on the day it matters
-- most (§9.4).
create or replace function public.office_refund_trip_batch(
  p_trip_id           uuid,
  p_category          text default 'trip_cancelled',
  p_reason            text default 'إلغاء الرحلة',
  p_settlement_method text default 'wallet',
  p_request_key       uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office   uuid := public.current_office_id();
  v_batch    uuid := coalesce(p_request_key, gen_random_uuid());
  v_trip     public.operation_trips;
  v_booking  record;
  v_refund   public.refund_requests;
  v_method   text;
  v_created  int := 0;
  v_skipped  int := 0;
  v_total    numeric := 0;
  v_results  jsonb := '[]'::jsonb;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('refund_decide') then
    raise exception 'not_authorized';
  end if;

  select * into v_trip from public.operation_trips
   where id = p_trip_id and office_id = v_office;
  if not found then
    raise exception 'trip_not_found';
  end if;

  -- Ascending client_id is a fixed total order over a one-wallet-per-customer
  -- table, so two concurrent batches acquire their wallets in the same sequence
  -- and cannot deadlock (§13).
  for v_booking in
    select b.id, b.client_id
      from public.operation_bookings b
     where b.trip_id = p_trip_id
       and b.office_id = v_office
       and b.status in ('reserved','confirmed','boarded')
     order by b.client_id nulls last, b.id
  loop
    if public.refund_capacity(v_booking.id) <= 0 then
      v_skipped := v_skipped + 1;
      continue;
    end if;

    -- A guest seat on the same bus settles in cash; it does not fail the batch.
    v_method := case when v_booking.client_id is null and p_settlement_method = 'wallet'
                     then 'cash' else p_settlement_method end;

    -- Deterministic per-booking key derived from the batch key, so re-running an
    -- interrupted batch refunds each seat exactly once.
    v_refund := public.refund_file(
      v_booking.id,
      public.refund_capacity(v_booking.id),
      p_category, p_reason, null,
      extensions.uuid_generate_v5(v_batch, v_booking.id::text),
      'approved', v_batch);

    if v_refund.status = 'approved' then
      v_refund := public.refund_apply_settlement(v_refund.id, v_method, null);
      v_created := v_created + 1;
      v_total := v_total + v_refund.approved_amount;
    else
      v_skipped := v_skipped + 1;
    end if;

    v_results := v_results || jsonb_build_object(
      'refund_id', v_refund.id, 'booking_id', v_booking.id,
      'amount', v_refund.approved_amount, 'status', v_refund.status);
  end loop;

  -- One alert for the batch, not one per seat — the per-row alert is suppressed
  -- by on_refund_request_change() whenever trip_cancellation_batch_id is set.
  perform public.push_operational_alert(
    'refund_batch', 'استرداد جماعي لرحلة ملغاة',
    'تم رد ' || v_created || ' حجز بإجمالي ' ||
      to_char(v_total, 'FM9999999990.00') || ' ج.م.',
    jsonb_build_object('trip_id', p_trip_id, 'batch_id', v_batch),
    'high', '/wallet', v_office);

  return jsonb_build_object(
    'batch_id', v_batch, 'trip_id', p_trip_id,
    'refunded', v_created, 'skipped', v_skipped,
    'total_amount', v_total, 'refunds', v_results);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Adjustment RPCs (§11)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Three thin wrappers rather than one `p_kind` parameter. The kind is what the
-- accounting reads (§7) and what the capability check keys on; making it a
-- caller-supplied string would put the closed axis in the client's hands.

create or replace function public.office_wallet_cashback(
  p_client_id   uuid,
  p_amount      numeric,
  p_category    text default 'promotion',
  p_reason      text default null,
  p_notes       text default null,
  p_request_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  return to_jsonb(public.wallet_post_entry(
    p_client_id => p_client_id, p_capability => 'wallet_adjust',
    p_kind => 'cashback', p_category => p_category, p_amount => p_amount,
    p_reason => p_reason, p_notes => p_notes,
    p_request_key => coalesce(p_request_key, gen_random_uuid())));
end;
$$;

create or replace function public.office_wallet_credit(
  p_client_id   uuid,
  p_amount      numeric,
  p_category    text default 'support_adjustment',
  p_reason      text default null,
  p_notes       text default null,
  p_request_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  return to_jsonb(public.wallet_post_entry(
    p_client_id => p_client_id, p_capability => 'wallet_adjust',
    p_kind => 'manual_credit', p_category => p_category, p_amount => p_amount,
    p_reason => p_reason, p_notes => p_notes,
    p_request_key => coalesce(p_request_key, gen_random_uuid())));
end;
$$;

create or replace function public.office_wallet_debit(
  p_client_id   uuid,
  p_amount      numeric,
  p_category    text default 'correction',
  p_reason      text default null,
  p_notes       text default null,
  p_request_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  return to_jsonb(public.wallet_post_entry(
    p_client_id => p_client_id, p_capability => 'wallet_adjust',
    p_kind => 'manual_debit', p_category => p_category, p_amount => p_amount,
    p_reason => p_reason, p_notes => p_notes,
    p_request_key => coalesce(p_request_key, gen_random_uuid())));
end;
$$;


-- Posts the inverse entry and marks the original `reversed` — the single
-- mutation the immutability trigger permits. Nothing disappears: both rows stay
-- visible and linked (§5.3).
--
-- `p_category` is a trailing parameter with a default, so the three-argument
-- call documented in Part 4 still works while `fraud`, `duplicate` and `dispute`
-- stay reachable.
create or replace function public.office_wallet_reverse(
  p_transaction_id uuid,
  p_reason         text,
  p_request_key    uuid default null,
  p_category       text default 'operator_error'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office   uuid := public.current_office_id();
  v_original public.wallet_transactions;
  v_row      public.wallet_transactions;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_reverse') then
    raise exception 'not_authorized';
  end if;

  select * into v_original from public.wallet_transactions
   where id = p_transaction_id and office_id = v_office;
  if not found then
    raise exception 'transaction_not_found';
  end if;

  v_row := public.wallet_post_entry(
    p_client_id               => v_original.client_id,
    p_capability              => 'wallet_reverse',
    p_kind                    => 'reversal',
    p_category                => p_category,
    p_amount                  => abs(v_original.amount),
    p_reason                  => p_reason,
    p_notes                   => null,
    p_request_key             => coalesce(p_request_key, gen_random_uuid()),
    p_source                  => 'dashboard',
    p_booking_id              => v_original.booking_id,
    p_reverses_transaction_id => v_original.id);

  -- Reversing a settled refund cancels the refund record too, which returns the
  -- booking's refund capacity (§5.3).
  if v_original.refund_id is not null then
    update public.refund_requests
       set status = 'cancelled', updated_at = now()
     where id = v_original.refund_id and status = 'settled';
  end if;

  return to_jsonb(v_row);
end;
$$;


-- Freeze / unfreeze. A frozen wallet still accepts credits — you must always be
-- able to refund someone — but refuses debits and spends (§5.4).
create or replace function public.office_wallet_set_status(
  p_client_id uuid,
  p_status    text,
  p_reason    text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_wallet public.wallets;
  v_name   text;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_freeze') then
    raise exception 'not_authorized';
  end if;
  if p_status not in ('active','frozen') then
    raise exception 'invalid_status';
  end if;
  -- Both directions require a reason, and both raise an alert: unfreezing is as
  -- much a decision as freezing.
  if nullif(btrim(coalesce(p_reason,'')), '') is null then
    raise exception 'reason_required';
  end if;

  select * into v_wallet from public.wallets
   where office_id = v_office and client_id = p_client_id and owner_type = 'client'
   for update;
  if not found then
    raise exception 'wallet_not_found';
  end if;

  update public.wallets
     set status        = p_status,
         frozen_reason = case when p_status = 'frozen' then btrim(p_reason) end,
         frozen_by     = case when p_status = 'frozen' then auth.uid() end,
         frozen_at     = case when p_status = 'frozen' then now() end,
         updated_at    = now()
   where id = v_wallet.id
  returning * into v_wallet;

  select full_name into v_name from public.clients where id = p_client_id;

  perform public.push_operational_alert(
    'wallet_status',
    case when p_status = 'frozen' then 'تجميد محفظة عميل' else 'إلغاء تجميد محفظة عميل' end,
    coalesce(v_name, 'عميل') || ' — ' || btrim(p_reason),
    jsonb_build_object('client_id', p_client_id, 'status', p_status),
    'high', '/wallet', v_office);

  return to_jsonb(v_wallet);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Tamper evidence (§2.5, §14 case 16)
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Recomputes the sequence and the hash chain and reports the FIRST divergence.
--
-- A wallet whose history cannot be trusted must not keep transacting, so a
-- divergence auto-freezes the wallet and raises an urgent alert rather than
-- returning a quiet `false`.
create or replace function public.office_wallet_verify_chain(p_client_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office     uuid := public.current_office_id();
  v_wallet     public.wallets;
  v_entry      record;
  v_prev       bytea := null;
  v_expected   bigint := 0;
  v_divergent  bigint := null;
  v_fault      text := null;
  v_sum        numeric := 0;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_reverse') then
    raise exception 'not_authorized';
  end if;

  select * into v_wallet from public.wallets
   where office_id = v_office and client_id = p_client_id and owner_type = 'client';
  if not found then
    raise exception 'wallet_not_found';
  end if;

  for v_entry in
    select * from public.wallet_transactions
     where wallet_id = v_wallet.id order by seq
  loop
    v_expected := v_expected + 1;
    v_sum := v_sum + v_entry.amount;

    if v_entry.seq <> v_expected then
      v_divergent := v_entry.seq; v_fault := 'sequence_gap'; exit;
    end if;
    if v_entry.prev_hash is distinct from v_prev then
      v_divergent := v_entry.seq; v_fault := 'chain_break'; exit;
    end if;
    if v_entry.entry_hash <> public.wallet_entry_hash(
         v_prev, v_entry.wallet_id, v_entry.seq, v_entry.kind, v_entry.category,
         v_entry.amount, v_entry.balance_after, v_entry.created_at,
         v_entry.performed_by, v_entry.request_key) then
      v_divergent := v_entry.seq; v_fault := 'hash_mismatch'; exit;
    end if;

    v_prev := v_entry.entry_hash;
  end loop;

  if v_fault is null and v_sum <> v_wallet.balance then
    v_fault := 'balance_drift';
  end if;
  if v_fault is null and v_prev is distinct from v_wallet.head_hash then
    v_fault := 'head_mismatch';
  end if;

  if v_fault is not null and v_wallet.status <> 'frozen' then
    update public.wallets
       set status = 'frozen',
           frozen_reason = 'سجل المحفظة غير متطابق: ' || v_fault,
           frozen_at = now(), updated_at = now()
     where id = v_wallet.id;

    perform public.push_operational_alert(
      'wallet_chain_divergence', 'تحذير: سجل محفظة غير متطابق',
      'تم تجميد المحفظة تلقائيًا. نوع الخلل: ' || v_fault,
      jsonb_build_object('client_id', p_client_id, 'wallet_id', v_wallet.id,
                         'seq', v_divergent, 'fault', v_fault),
      'urgent', '/wallet', v_office);
  end if;

  return jsonb_build_object(
    'wallet_id',      v_wallet.id,
    'verified',       v_fault is null,
    'fault',          v_fault,
    'divergent_seq',  v_divergent,
    'entries',        v_expected,
    'ledger_balance', v_sum,
    'cached_balance', v_wallet.balance,
    -- The chain head, for the off-database copy that in-database edits cannot
    -- reach (§2.5 point 3).
    'head_hash',      encode(v_wallet.head_hash, 'hex'));
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Read RPCs
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- These could be table reads — RLS scopes both wallet tables to the office. They
-- are RPCs because each one is a single round trip that returns a screen's worth
-- of already-aggregated data, and because the aggregation then has exactly one
-- definition instead of one per caller.

-- The module header strip (§8.2). Also the source of Finance's LIABILITY figure.
create or replace function public.office_wallet_overview()
returns jsonb
language plpgsql
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

  return (
    select jsonb_build_object(
      'outstanding_balance', coalesce((select sum(balance) from public.wallets
                                        where office_id = v_office), 0),
      'wallet_count',        (select count(*) from public.wallets
                               where office_id = v_office),
      'funded_wallet_count', (select count(*) from public.wallets
                               where office_id = v_office and balance > 0),
      'frozen_count',        (select count(*) from public.wallets
                               where office_id = v_office and status = 'frozen'),
      -- Promotional cost (§7.1): a marketing expense that creates a liability
      -- with no cash received. Reported separately, never netted off revenue.
      'cashback_total',      coalesce((select sum(amount) from public.wallet_transactions
                                        where office_id = v_office and kind = 'cashback'
                                          and status = 'posted'), 0),
      'credit_total',        coalesce((select sum(amount) from public.wallet_transactions
                                        where office_id = v_office and kind = 'manual_credit'
                                          and status = 'posted'), 0),
      'debit_total',         coalesce((select -sum(amount) from public.wallet_transactions
                                        where office_id = v_office and kind = 'manual_debit'
                                          and status = 'posted'), 0),
      -- Refunds come from refund_requests, NOT from the ledger: a refund to
      -- InstaPay never posts a wallet row, and a ledger-derived total would
      -- silently omit exactly the amounts most likely to be disputed (§2.3).
      'refund_total',        coalesce((select sum(approved_amount) from public.refund_requests
                                        where office_id = v_office and status = 'settled'), 0),
      'refund_wallet_total', coalesce((select sum(approved_amount) from public.refund_requests
                                        where office_id = v_office and status = 'settled'
                                          and settlement_method = 'wallet'), 0),
      'pending_refund_count',  (select count(*) from public.refund_requests
                                 where office_id = v_office and status = 'pending'),
      'pending_refund_amount', coalesce((select sum(amount) from public.refund_requests
                                          where office_id = v_office and status = 'pending'), 0),
      'generated_at', now())
  );
end;
$$;


-- Surface 1: the customer directory. There is no customer entity in the
-- dashboard at all (§1.1), so this is the module's foundation, not a nicety.
create or replace function public.office_wallet_directory(
  p_search text default null,
  p_limit  int  default 50,
  p_offset int  default 0
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_limit  int  := least(greatest(coalesce(p_limit, 50), 1), 200);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
  v_search text := nullif(btrim(coalesce(p_search, '')), '');
  v_total  bigint;
  v_rows   jsonb;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_view') then
    raise exception 'not_authorized';
  end if;

  with scoped as (
    select c.id as client_id, c.full_name, c.phone, c.status,
           coalesce(w.balance, 0)        as balance,
           coalesce(w.status, 'active')  as wallet_status,
           coalesce(w.entry_count, 0)    as entry_count,
           (select max(t.created_at) from public.wallet_transactions t
             where t.client_id = c.id and t.office_id = v_office) as last_activity_at,
           (select count(*) from public.refund_requests r
             where r.client_id = c.id and r.office_id = v_office
               and r.status = 'pending') as pending_refunds
      from public.clients c
      left join public.wallets w
        on w.client_id = c.id and w.office_id = v_office and w.owner_type = 'client'
     -- The `clients_office_read` predicate, applied server-side: "my office's
     -- customer" means someone who has bought from this office.
     where exists (select 1 from public.operation_bookings b
                    where b.client_id = c.id and b.office_id = v_office)
        or exists (select 1 from public.subscriptions s
                    where s.client_id = c.id and s.office_id = v_office)
        or w.id is not null
  ), filtered as (
    select * from scoped
     where v_search is null
        or full_name ilike '%' || v_search || '%'
        or phone     ilike '%' || v_search || '%'
  )
  select (select count(*) from filtered),
         coalesce((select jsonb_agg(to_jsonb(p)) from (
                     select * from filtered
                      order by balance desc, last_activity_at desc nulls last, full_name
                      limit v_limit offset v_offset) p), '[]'::jsonb)
    into v_total, v_rows;

  return jsonb_build_object('total', v_total, 'rows', v_rows);
end;
$$;


-- Surface 2: everything the wallet detail screen needs, in one round trip.
create or replace function public.office_wallet_summary(p_client_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_wallet public.wallets;
  v_client public.clients;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_view') then
    raise exception 'not_authorized';
  end if;
  if not public.office_owns_client(p_client_id, v_office) then
    raise exception 'client_not_in_office';
  end if;

  select * into v_client from public.clients where id = p_client_id;
  select * into v_wallet from public.wallets
   where office_id = v_office and client_id = p_client_id and owner_type = 'client';

  return jsonb_build_object(
    'client', jsonb_build_object(
      'id', p_client_id, 'full_name', v_client.full_name,
      'phone', v_client.phone, 'status', v_client.status,
      'created_at', v_client.created_at),

    -- A customer with no wallet yet is not an error: the wallet is created on
    -- first posting, so "no row" and "zero balance" are the same thing.
    'wallet', case when v_wallet.id is null then
        jsonb_build_object('exists', false, 'balance', 0, 'available_balance', 0,
                           'status', 'active', 'entry_count', 0,
                           'lifetime_credited', 0, 'lifetime_debited', 0)
      else
        jsonb_build_object('exists', true, 'id', v_wallet.id,
                           'balance', v_wallet.balance,
                           'available_balance', v_wallet.available_balance,
                           'status', v_wallet.status,
                           'frozen_reason', v_wallet.frozen_reason,
                           'frozen_at', v_wallet.frozen_at,
                           'entry_count', v_wallet.entry_count,
                           'lifetime_credited', v_wallet.lifetime_credited,
                           'lifetime_debited', v_wallet.lifetime_debited,
                           'last_seq', v_wallet.last_seq,
                           'head_hash', encode(v_wallet.head_hash, 'hex'),
                           'updated_at', v_wallet.updated_at)
      end,

    'totals_by_kind', coalesce((
      select jsonb_object_agg(k, total) from (
        select kind as k, sum(abs(amount)) as total
          from public.wallet_transactions
         where office_id = v_office and client_id = p_client_id and status = 'posted'
         group by kind) g), '{}'::jsonb),

    -- Surfaced inline as a banner, not in a separate tab: an operator must not
    -- be able to issue a second refund while unaware one is already waiting.
    -- This is a control, not a convenience (§8.2).
    'pending_refunds', coalesce((
      select jsonb_agg(to_jsonb(r) order by r.created_at desc)
        from public.refund_requests r
       where r.office_id = v_office and r.client_id = p_client_id
         and r.status in ('pending','approved')), '[]'::jsonb),

    'entries', coalesce((
      select jsonb_agg(to_jsonb(e) order by e.seq desc) from (
        select t.id, t.seq, t.kind, t.category, t.source, t.amount,
               t.balance_before, t.balance_after, t.status, t.reason, t.notes,
               t.booking_id, t.refund_id, t.reverses_transaction_id,
               t.performed_by, t.performed_by_name, t.performed_by_role,
               t.created_at,
               b.booking_number,
               -- The reversing entry, so a struck-through row can link to what
               -- corrected it rather than just looking cancelled (§8.2).
               (select x.id from public.wallet_transactions x
                 where x.reverses_transaction_id = t.id limit 1) as reversed_by
          from public.wallet_transactions t
          left join public.operation_bookings b on b.id = t.booking_id
         where t.office_id = v_office and t.client_id = p_client_id
         order by t.seq desc
         limit 200) e), '[]'::jsonb));
end;
$$;


-- Surface 3: office-wide financial activity (§8.3). Answers "what did my staff
-- do this week".
create or replace function public.office_wallet_ledger(
  p_filters jsonb default '{}'::jsonb,
  p_limit   int   default 100,
  p_offset  int   default 0
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_limit  int  := least(greatest(coalesce(p_limit, 100), 1), 500);
  v_offset int  := greatest(coalesce(p_offset, 0), 0);
  v_f      jsonb := coalesce(p_filters, '{}'::jsonb);
  v_total  bigint;
  v_credit numeric;
  v_debit  numeric;
  v_rows   jsonb;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_ledger_view') then
    raise exception 'not_authorized';
  end if;

  with filtered as (
    select t.id, t.seq, t.kind, t.category, t.source, t.amount,
           t.balance_before, t.balance_after, t.status, t.reason, t.notes,
           t.client_id, c.full_name as client_name, c.phone as client_phone,
           t.booking_id, b.booking_number, t.refund_id,
           t.reverses_transaction_id,
           (select x.id from public.wallet_transactions x
             where x.reverses_transaction_id = t.id limit 1) as reversed_by,
           t.performed_by, t.performed_by_name, t.performed_by_role, t.created_at
      from public.wallet_transactions t
      left join public.clients c            on c.id = t.client_id
      left join public.operation_bookings b on b.id = t.booking_id
     where t.office_id = v_office
       and (v_f->>'client_id'    is null or t.client_id    = (v_f->>'client_id')::uuid)
       and (v_f->>'booking_id'   is null or t.booking_id   = (v_f->>'booking_id')::uuid)
       and (v_f->>'performed_by' is null or t.performed_by = (v_f->>'performed_by')::uuid)
       and (v_f->>'date_from'    is null or t.created_at  >= (v_f->>'date_from')::timestamptz)
       and (v_f->>'date_to'      is null or t.created_at  <  (v_f->>'date_to')::timestamptz)
       and (v_f->>'min_amount'   is null or abs(t.amount) >= (v_f->>'min_amount')::numeric)
       and (v_f->>'max_amount'   is null or abs(t.amount) <= (v_f->>'max_amount')::numeric)
       -- jsonb_typeof, not `is null`: an explicit JSON null is a present key
       -- with no value, and must read as "no filter" rather than "match nothing".
       and (jsonb_typeof(v_f->'kinds') is distinct from 'array'
            or t.kind = any(array(select jsonb_array_elements_text(v_f->'kinds'))))
       and (jsonb_typeof(v_f->'categories') is distinct from 'array'
            or t.category = any(array(select jsonb_array_elements_text(v_f->'categories'))))
       and (jsonb_typeof(v_f->'statuses') is distinct from 'array'
            or t.status = any(array(select jsonb_array_elements_text(v_f->'statuses'))))
       and (jsonb_typeof(v_f->'sources') is distinct from 'array'
            or t.source = any(array(select jsonb_array_elements_text(v_f->'sources'))))
       and (v_f->>'direction' is null
            or (v_f->>'direction' = 'credit' and t.amount > 0)
            or (v_f->>'direction' = 'debit'  and t.amount < 0))
       -- Isolates corrected entries — the first thing anyone investigating a
       -- discrepancy wants (§8.3).
       and (v_f->>'has_reversal' is null
            or (v_f->>'has_reversal')::boolean = (t.status = 'reversed' or t.kind = 'reversal'))
       and (nullif(btrim(coalesce(v_f->>'search','')),'') is null
            or c.full_name ilike '%' || btrim(v_f->>'search') || '%'
            or c.phone     ilike '%' || btrim(v_f->>'search') || '%'
            or t.reason    ilike '%' || btrim(v_f->>'search') || '%'
            or b.booking_number ilike '%' || btrim(v_f->>'search') || '%')
  )
  select count(*),
         coalesce(sum(amount) filter (where amount > 0), 0),
         coalesce(-sum(amount) filter (where amount < 0), 0),
         coalesce((select jsonb_agg(to_jsonb(x)) from (
                     select * from filtered
                      order by created_at desc, seq desc
                      limit v_limit offset v_offset) x), '[]'::jsonb)
    into v_total, v_credit, v_debit, v_rows
    from filtered;

  return jsonb_build_object(
    'total', v_total, 'sum_credit', v_credit, 'sum_debit', v_debit, 'rows', v_rows);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Grants
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Private internals: reachable only from the SECURITY DEFINER functions above.
revoke all on function public.refund_file(uuid, numeric, text, text, text, uuid, text, uuid) from public;
revoke all on function public.refund_file(uuid, numeric, text, text, text, uuid, text, uuid) from anon;
revoke all on function public.refund_file(uuid, numeric, text, text, text, uuid, text, uuid) from authenticated;
revoke all on function public.refund_apply_settlement(uuid, text, uuid) from public;
revoke all on function public.refund_apply_settlement(uuid, text, uuid) from anon;
revoke all on function public.refund_apply_settlement(uuid, text, uuid) from authenticated;

do $$
declare
  v_sig text;
begin
  foreach v_sig in array array[
    'public.refund_capacity(uuid, uuid)',
    'public.office_refund_create(uuid, numeric, text, text, text, text, uuid)',
    'public.office_refund_decide(uuid, text, numeric, text, text, uuid)',
    'public.office_refund_trip_batch(uuid, text, text, text, uuid)',
    'public.office_wallet_cashback(uuid, numeric, text, text, text, uuid)',
    'public.office_wallet_credit(uuid, numeric, text, text, text, uuid)',
    'public.office_wallet_debit(uuid, numeric, text, text, text, uuid)',
    'public.office_wallet_reverse(uuid, text, uuid, text)',
    'public.office_wallet_set_status(uuid, text, text)',
    'public.office_wallet_verify_chain(uuid)',
    'public.office_wallet_overview()',
    'public.office_wallet_directory(text, int, int)',
    'public.office_wallet_summary(uuid)',
    'public.office_wallet_ledger(jsonb, int, int)'
  ] loop
    execute format('revoke all on function %s from public', v_sig);
    execute format('revoke all on function %s from anon', v_sig);
    execute format('grant execute on function %s to authenticated', v_sig);
  end loop;
end $$;
