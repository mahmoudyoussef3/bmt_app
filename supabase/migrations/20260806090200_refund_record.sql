-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — Step 3/4: refund_requests becomes THE refund record
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §2.3, §3.3, §10, §15.
--
-- ── Why this table and not the wallet ledger ────────────────────────────────────
--
-- Offices refund to InstaPay, to a card via Paymob, and in cash. Those refunds
-- never touch the wallet, so any refund total derived from the wallet ledger
-- under-reports — by exactly the amounts most likely to be disputed. One row per
-- refund decision, whatever its destination; only settlement_method = 'wallet'
-- also posts a wallet_transactions row, linked both ways.
--
-- ── Why all of this is free ─────────────────────────────────────────────────────
--
-- `refund_requests` has 0 rows. Every structural fix below is free today and
-- expensive in six months. Verified immediately before apply.
--
-- ── The four defects being fixed (F2), plus one cascade (F1) ────────────────────
--
--   booking_id  was `text`               → uuid + FK to operation_bookings
--   reviewed_by was `text`               → uuid + FK to auth.users
--   status      had no CHECK             → six-value CHECK + shape constraints
--   office_id   was ON DELETE SET NULL   → RESTRICT (its own RLS policy requires
--                                          office_id is not null, so nulling it
--                                          made a refund invisible to everyone,
--                                          forever)
--   client_id   was ON DELETE CASCADE    → RESTRICT. Deleting one Supabase auth
--                                          user silently destroyed that
--                                          customer's refund history.
-- ═══════════════════════════════════════════════════════════════════════════════════

-- Refuse to run against a populated table. The column retypes below assume there
-- is nothing to convert; if that ever stops being true this must become a real
-- backfill rather than an ALTER.
do $$
begin
  if (select count(*) from public.refund_requests) > 0 then
    raise exception 'refund_requests is not empty — this migration assumes 0 rows (see §15 step 2)';
  end if;
end $$;


-- ───────────────────────────────────────────────────────────────────────────────────
-- 1. Retype and re-key
-- ───────────────────────────────────────────────────────────────────────────────────

-- `trg_refund_requests_office` lists booking_id in its UPDATE OF clause, and
-- Postgres refuses to retype a column a trigger definition names. Dropped here
-- and recreated in section 4 alongside the function it calls.
drop trigger if exists trg_refund_requests_office on public.refund_requests;

alter table public.refund_requests
  alter column booking_id type uuid using nullif(btrim(booking_id), '')::uuid;

alter table public.refund_requests
  drop constraint if exists refund_booking_fk,
  add  constraint refund_booking_fk foreign key (booking_id)
       references public.operation_bookings(id) on delete restrict;

alter table public.refund_requests
  drop constraint if exists refund_requests_client_id_fkey,
  drop constraint if exists refund_requests_client_fk,
  add  constraint refund_requests_client_fk foreign key (client_id)
       references public.clients(id) on delete restrict;

alter table public.refund_requests
  drop constraint if exists refund_requests_office_fk,
  add  constraint refund_requests_office_fk foreign key (office_id)
       references public.offices(id) on delete restrict;

alter table public.refund_requests
  alter column office_id set not null;

-- ── Deliberate deviation from §3.3: client_id stays NULLABLE ────────────────────
--
-- §3.3 sets `client_id NOT NULL`; §14 case 10 requires that a GUEST booking
-- (operation_bookings.client_id is nullable — F6) can still be refunded in cash.
-- Those two cannot both hold. NOT NULL would mean a guest refund cannot be
-- recorded at all, which pushes real money off the ledger — precisely what this
-- module exists to prevent, and a worse outcome than a nullable column.
--
-- Nothing the NOT NULL was protecting is lost: the client self-read policy is
-- `client_id = auth.uid()`, which already excludes NULL, and
-- `refund_wallet_needs_client` (section 3) keeps the one path that genuinely
-- requires a customer — wallet settlement — closed to guests.


-- ───────────────────────────────────────────────────────────────────────────────────
-- 2. Decision, settlement and audit columns
-- ───────────────────────────────────────────────────────────────────────────────────

-- reviewed_by was text. Nothing has written it, so it is dropped and re-added as
-- a real user reference rather than converted.
alter table public.refund_requests drop column if exists reviewed_by;

alter table public.refund_requests
  add column if not exists reviewed_by       uuid references auth.users(id) on delete restrict,
  add column if not exists reviewed_by_name  text,
  add column if not exists requested_by      uuid references auth.users(id) on delete restrict,
  add column if not exists requested_by_name text,

  -- Which side filed it. The client-initiated request and the office-initiated
  -- refund are the same record at different stages — one pipeline, one audit
  -- trail, one queue (§9).
  add column if not exists source text not null default 'client',

  -- The "why" axis (§2.4). `reason` stays free text for the operator's own
  -- words; this is the closed-allowlist value the ledger entry and every report
  -- group on, so refund reporting never has to clean free text. It shares the
  -- wallet's refund allowlist deliberately — one vocabulary, two tables.
  add column if not exists category text not null default 'other',

  -- The requested amount lives in `amount`; this is what was actually decided.
  add column if not exists approved_amount numeric(12,2),

  add column if not exists settlement_method text,
  add column if not exists settled_at        timestamptz,

  -- Set only when settlement_method = 'wallet'. The other direction of the link
  -- is wallet_transactions.refund_id.
  add column if not exists wallet_transaction_id uuid
      references public.wallet_transactions(id) on delete restrict,

  -- Law L5: provider identifiers live on the instrument, never in the ledger.
  add column if not exists external_transaction_id text,

  add column if not exists request_key uuid,

  -- Stamps every refund produced by one cancelled-trip batch, so the operator can
  -- see, verify and if necessary reverse the batch as a unit (§9.4).
  add column if not exists trip_cancellation_batch_id uuid,

  add column if not exists notes text;

alter table public.refund_requests
  drop constraint if exists refund_source_check,
  add  constraint refund_source_check check (source in ('client','dashboard'));

alter table public.refund_requests
  drop constraint if exists refund_category_check,
  add  constraint refund_category_check
       check (public.wallet_category_allowed('refund', category));

alter table public.refund_requests
  drop constraint if exists refund_approved_amount_check,
  add  constraint refund_approved_amount_check
       check (approved_amount is null or approved_amount > 0);

alter table public.refund_requests
  drop constraint if exists refund_settlement_method_check,
  add  constraint refund_settlement_method_check
       check (settlement_method is null
              or settlement_method in ('wallet','original_method','cash','bank_transfer'));


-- ───────────────────────────────────────────────────────────────────────────────────
-- 3. Status: a closed set, plus the shape each terminal state must have
-- ───────────────────────────────────────────────────────────────────────────────────

alter table public.refund_requests
  drop constraint if exists refund_status_check,
  add  constraint refund_status_check
       check (status in ('pending','approved','rejected','settled','failed','cancelled'));

-- A settled refund without an amount, a destination or a time is not a settled
-- refund. This is what makes §7's REVENUE query trustworthy: it sums
-- approved_amount where status = 'settled', and every such row is complete.
alter table public.refund_requests
  drop constraint if exists refund_settled_shape,
  add  constraint refund_settled_shape check (
        status <> 'settled'
        or (approved_amount is not null
            and settlement_method is not null
            and settled_at is not null));

alter table public.refund_requests
  drop constraint if exists refund_wallet_link,
  add  constraint refund_wallet_link check (
        settlement_method is distinct from 'wallet'
        or status <> 'settled'
        or wallet_transaction_id is not null);

-- The guest-booking guard promised in section 1: no customer, no wallet leg.
alter table public.refund_requests
  drop constraint if exists refund_wallet_needs_client,
  add  constraint refund_wallet_needs_client check (
        settlement_method is distinct from 'wallet' or client_id is not null);

-- Idempotency for the refund pipeline, mirroring the ledger's
-- unique (office_id, request_key). Partial, because client-filed requests
-- predate the key and may not carry one.
create unique index if not exists uniq_refund_request_key
  on public.refund_requests (office_id, request_key) where request_key is not null;

create index if not exists idx_refund_office_status
  on public.refund_requests (office_id, status, created_at desc);
create index if not exists idx_refund_booking
  on public.refund_requests (booking_id) where booking_id is not null;
create index if not exists idx_refund_client
  on public.refund_requests (client_id, created_at desc);
create index if not exists idx_refund_batch
  on public.refund_requests (trip_cancellation_batch_id)
  where trip_cancellation_batch_id is not null;


-- ───────────────────────────────────────────────────────────────────────────────────
-- 4. The office-attribution trigger, adjusted for the uuid retype
-- ───────────────────────────────────────────────────────────────────────────────────
--
-- Behaviour is unchanged. The only edit is the removal of the
-- `pg_input_is_valid(booking_id, 'uuid')` guard and the `::uuid` cast, both of
-- which existed solely because the column used to be text — and both of which
-- would now raise, because pg_input_is_valid takes text.
create or replace function public.sync_refund_request_office()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid;
begin
  if new.booking_id is not null then
    select office_id into v_office
      from public.operation_bookings where id = new.booking_id;
  end if;

  if v_office is null and new.trip_id is not null then
    select office_id into v_office
      from public.operation_trips where id = new.trip_id;
  end if;

  if v_office is null and new.ticket_id is not null then
    select office_id into v_office
      from public.support_tickets where id = new.ticket_id;
  end if;

  new.office_id := coalesce(v_office, new.office_id, public.current_office_id());
  return new;
end $$;

create trigger trg_refund_requests_office
  before insert or update of booking_id, trip_id, ticket_id
  on public.refund_requests
  for each row execute function public.sync_refund_request_office();


-- ───────────────────────────────────────────────────────────────────────────────────
-- 5. The notification trigger, extended to the new terminal states
-- ───────────────────────────────────────────────────────────────────────────────────
--
-- The original notified on approved/rejected only. `settled` did not exist when
-- it was written, and the owner's one-step refund is born settled (§9) — so
-- without this the customer whose money actually moved is the one who hears
-- nothing.
--
-- Wallet-settled refunds post their ledger entry with notifications suppressed,
-- so a refund produces exactly one customer message: this one.
create or replace function public.on_refund_request_change()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_amount numeric := coalesce(new.approved_amount, new.amount);
begin
  if tg_op = 'INSERT' then
    -- Batch refunds raise one alert for the batch, not fourteen (§9.4).
    if new.trip_cancellation_batch_id is null then
      perform public.push_operational_alert(
        'refund_request',
        case when new.status = 'settled' then 'استرداد منفّذ' else 'طلب استرداد جديد' end,
        'بقيمة ' || to_char(v_amount, 'FM9999999990.00') || ' ' || new.currency ||
          ' — ' || new.reason,
        jsonb_build_object('refund_id', new.id, 'booking_id', new.booking_id),
        'high', '/wallet', new.office_id);
    end if;

    if new.status = 'settled' then
      perform public.push_notification(
        new.client_id, 'تم تنفيذ الاسترداد',
        'تم رد مبلغ ' || to_char(v_amount, 'FM9999999990.00') || ' ' || new.currency ||
          case new.settlement_method
            when 'wallet'          then ' إلى محفظتك.'
            when 'cash'            then ' نقدًا.'
            when 'bank_transfer'   then ' عبر تحويل بنكي.'
            else ' بنفس وسيلة الدفع الأصلية.'
          end,
        'payment', 'client',
        jsonb_build_object('refund_id', new.id, 'status', new.status), '/wallet');
    end if;

  elsif tg_op = 'UPDATE' and new.status is distinct from old.status
        and new.status in ('approved', 'rejected', 'settled', 'cancelled') then
    perform public.push_notification(
      new.client_id, 'تحديث على طلب الاسترداد',
      case new.status
        when 'settled'  then 'تم رد مبلغ ' || to_char(v_amount, 'FM9999999990.00') ||
                             ' ' || new.currency ||
                             case new.settlement_method
                               when 'wallet'        then ' إلى محفظتك.'
                               when 'cash'          then ' نقدًا.'
                               when 'bank_transfer' then ' عبر تحويل بنكي.'
                               else ' بنفس وسيلة الدفع الأصلية.'
                             end
        when 'approved' then 'تمت الموافقة على طلب الاسترداد بقيمة ' ||
                             to_char(v_amount, 'FM9999999990.00') || ' ' || new.currency || '.'
        when 'rejected' then 'تم رفض طلب الاسترداد الخاص بك.'
        else 'تم إلغاء طلب الاسترداد الخاص بك.'
      end,
      'payment', 'client',
      jsonb_build_object('refund_id', new.id, 'status', new.status), '/wallet');
  end if;

  return new;
end;
$$;


-- ───────────────────────────────────────────────────────────────────────────────────
-- 6. RLS: the office reads; it does not decide by UPDATE
-- ───────────────────────────────────────────────────────────────────────────────────
--
-- The office policy was `FOR ALL`, which made "approve a refund" a client-side
-- UPDATE — no amount cap, no cumulative check, no ledger entry, no audit trail.
-- Decisions now go through office_refund_decide (step 4). The office keeps full
-- read access, which is what the dashboard's queue and Finance's pending-liability
-- KPI actually use.
drop policy if exists refund_requests_office on public.refund_requests;
create policy refund_requests_office_read
  on public.refund_requests for select to authenticated
  using (office_id = public.current_office_id());

-- The client-side pair is unchanged: a customer may file a request and read
-- their own. Filing is the one write a customer performs on this table.
revoke insert, update, delete, truncate on public.refund_requests from anon;
revoke update, delete, truncate on public.refund_requests from authenticated;
grant select, insert on public.refund_requests to authenticated;
