-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet authority regression suite
-- ═══════════════════════════════════════════════════════════════════════════════════
-- Exercises every control the wallet subsystem claims to have, against the linked
-- database, in one pass:
--
--   isolation      — a different office sees nothing, reads nothing, cannot post
--   immutability   — the ledger refuses UPDATE and DELETE, even from the owner
--   authority      — a support agent may look and may request, but may not move money
--   arithmetic     — balance = Σ amount, no entry can violate it, no debit below zero
--   idempotency    — a replayed key returns the original; a reused key with a new
--                    intention is refused
--   fraud controls — self-dealing, over-refund, frozen wallets, policy caps
--   tamper evidence— sequence + hash chain verify, reconciliation is clean
--
-- Runs entirely inside BEGIN … ROLLBACK. It posts real ledger entries and throws
-- them away; nothing survives the run, so it is safe against the production-bound
-- development database.
--
--   supabase db query --linked -f supabase/tests/wallet_authority_regression.sql
--
-- Every row of the output should read OK. Any row reading "BROKEN", "LEAK" or
-- "STILL EXPLOITABLE" is a regression.
--
-- Covers: 20260806090000 (policies), 20260806090100 (core), 20260806090200
--         (refund record), 20260806090300 (RPCs).
--
-- ── Fixtures ────────────────────────────────────────────────────────────────────
-- Identities are read out of the linked database rather than hardcoded, so the
-- suite keeps working as data changes. It needs one office with an active
-- dashboard_admin, and one booking in that office with a payment, a client, and a
-- refundable balance under the default 1000 single-credit cap. If there is none it
-- aborts loudly rather than passing vacuously.
-- ═══════════════════════════════════════════════════════════════════════════════════

begin;

create temp table probe(step text, result text) on commit drop;
create temp table fixture(k text primary key, v text) on commit drop;
grant all on probe to authenticated, anon;
grant all on fixture to authenticated, anon;

-- ───────────────────────────────────────────────────────────────────────────────────
-- Resolve the cast as superuser, before any impersonation starts.
-- ───────────────────────────────────────────────────────────────────────────────────
do $$
declare
  v_office  uuid;
  v_admin   uuid;
  v_booking uuid;
  v_client  uuid;
  v_cap     numeric;
begin
  -- The office with the most refundable bookings — the one where the test has
  -- something to act on.
  select b.office_id, b.id, b.client_id, public.refund_capacity(b.id)
    into v_office, v_booking, v_client, v_cap
    from public.operation_bookings b
    join public.booking_payments bp on bp.booking_id = b.id
   where b.client_id is not null
     and b.office_id is not null
     and bp.status = 'approved'
     and bp.amount between 50 and 900
     and exists (select 1 from public.office_users u
                  where u.office_id = b.office_id
                    and u.status = 'active' and u.role = 'dashboard_admin'
                    and u.user_id <> b.client_id)
   order by bp.amount desc
   limit 1;

  if v_booking is null then
    insert into probe values ('00. fixture',
      'ABORTED — no office has an approved booking payment between 50 and 900 EGP');
    return;
  end if;

  select u.user_id into v_admin from public.office_users u
   where u.office_id = v_office and u.status = 'active'
     and u.role = 'dashboard_admin' and u.user_id <> v_client
   limit 1;

  insert into fixture values
    ('office', v_office::text), ('admin', v_admin::text),
    ('booking', v_booking::text), ('client', v_client::text),
    ('capacity', v_cap::text);

  -- An operator in some other office, to prove isolation.
  insert into fixture
  select 'other_admin', u.user_id::text from public.office_users u
   where u.office_id <> v_office and u.status = 'active' limit 1;

  insert into probe values ('00. fixture',
    'OK — office ' || left(v_office::text, 8) || ', booking capacity ' || v_cap);
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. The owner posts. Balance arithmetic, idempotency, and the fingerprint guard.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_key    uuid := gen_random_uuid();
  v_first  jsonb;
  v_second jsonb;
  v_bal    numeric;
begin
  if not exists (select 1 from fixture where k = 'admin') then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'admin'),
                      'role', 'authenticated')::text, true);

  v_first := public.office_wallet_cashback(v_client, 100, 'compensation',
                                           'اختبار: تعويض', null, v_key);
  select balance into v_bal from public.wallets
   where client_id = v_client and office_id = (select v::uuid from fixture where k = 'office');

  insert into probe values ('01. owner posts cashback',
    case when (v_first->>'amount')::numeric = 100 and v_bal >= 100
         then 'OK — posted, balance ' || v_bal
         else 'BROKEN — amount ' || (v_first->>'amount') || ', balance ' || v_bal end);

  -- Retry with the same key and the same intention: returns the original, posts
  -- nothing, and sends no second notification.
  v_second := public.office_wallet_cashback(v_client, 100, 'compensation',
                                            'اختبار: تعويض', null, v_key);
  insert into probe values ('02. replayed request key',
    case when v_second->>'id' = v_first->>'id'
         then 'OK — returned the original, no second entry'
         else 'BROKEN — a retry created a second transaction' end);

  -- Same key, different intention: refused rather than silently returning an
  -- unrelated transaction and reporting success.
  begin
    perform public.office_wallet_cashback(v_client, 250, 'compensation',
                                          'اختبار: تعويض', null, v_key);
    insert into probe values ('03. reused key, new amount', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('03. reused key, new amount',
      case when sqlerrm like '%request_key_conflict%' then 'OK — request_key_conflict'
           else 'BROKEN — ' || sqlerrm end);
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. The non-negative invariant, the policy cap, and self-dealing.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_admin  uuid := (select v::uuid from fixture where k = 'admin');
  v_bal    numeric;
begin
  if v_admin is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select balance into v_bal from public.wallets
   where client_id = v_client and office_id = (select v::uuid from fixture where k = 'office');

  begin
    perform public.office_wallet_debit(v_client, v_bal + 500, 'correction',
                                       'اختبار: خصم أكبر من الرصيد');
    insert into probe values ('04. debit below zero', 'BROKEN — balance went negative');
  exception when others then
    insert into probe values ('04. debit below zero',
      case when sqlerrm like '%insufficient_wallet_balance%' then 'OK — refused'
           else 'BROKEN — ' || sqlerrm end);
  end;

  begin
    perform public.office_wallet_cashback(v_client, 999999, 'promotion', 'اختبار: فوق الحد');
    insert into probe values ('05. amount over policy cap', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('05. amount over policy cap',
      case when sqlerrm like '%amount_exceeds_policy%' then 'OK — amount_exceeds_policy'
           else 'BROKEN — ' || sqlerrm end);
  end;

  -- The operator crediting their own customer account. clients.id IS the auth
  -- user id, so this is the whole check.
  begin
    perform public.office_wallet_cashback(v_admin, 50, 'promotion', 'اختبار: تمويل ذاتي');
    insert into probe values ('06. self-dealing', 'STILL EXPLOITABLE — operator credited themselves');
  exception when others then
    insert into probe values ('06. self-dealing',
      case when sqlerrm like '%self_adjustment_denied%' then 'OK — self_adjustment_denied'
           when sqlerrm like '%client_not_in_office%'   then 'OK — not a customer of this office'
           else 'BROKEN — ' || sqlerrm end);
  end;

  -- A category outside the per-kind allowlist (§5.2, law L3).
  begin
    perform public.office_wallet_cashback(v_client, 10, 'not_a_real_category', 'اختبار');
    insert into probe values ('07. invalid category', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('07. invalid category',
      case when sqlerrm like '%invalid_category%' then 'OK — invalid_category'
           else 'BROKEN — ' || sqlerrm end);
  end;

  -- A blank reason. Every money movement carries an operator's own words.
  begin
    perform public.office_wallet_cashback(v_client, 10, 'promotion', '   ');
    insert into probe values ('08. blank reason', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('08. blank reason',
      case when sqlerrm like '%reason_required%' then 'OK — reason_required'
           else 'BROKEN — ' || sqlerrm end);
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Refunds: the cumulative cap, the wallet leg, and the payment flip.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_admin   uuid    := (select v::uuid from fixture where k = 'admin');
  v_booking uuid    := (select v::uuid from fixture where k = 'booking');
  v_cap     numeric := (select v::numeric from fixture where k = 'capacity');
  v_first   jsonb;
  v_second  jsonb;
  v_status  text;
begin
  if v_admin is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  -- The owner's refund is born approved and settles in the same call (§9).
  v_first := public.office_refund_create(
    v_booking, round(v_cap * 0.4, 2), 'trip_cancelled', 'اختبار: إلغاء رحلة',
    null, 'wallet');

  insert into probe values ('09. owner refund settles in one step',
    case when v_first->>'status' = 'settled'
          and v_first->>'wallet_transaction_id' is not null
         then 'OK — settled with a linked ledger entry'
         else 'BROKEN — status ' || (v_first->>'status') end);

  -- More than what is left. The cap is cumulative and read under the booking lock.
  begin
    perform public.office_refund_create(v_booking, v_cap, 'other', 'اختبار: تجاوز');
    insert into probe values ('10. refund beyond the payment', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('10. refund beyond the payment',
      case when sqlerrm like '%refund_exceeds_payment%' then 'OK — refund_exceeds_payment'
           else 'BROKEN — ' || sqlerrm end);
  end;

  -- The remainder. Settling it completes the refund, which is the only thing
  -- that may flip booking_payments.status to 'refunded' — a value nothing in the
  -- schema could reach before this module existed.
  v_second := public.office_refund_create(
    v_booking, round(v_cap * 0.6, 2), 'trip_cancelled', 'اختبار: باقي المبلغ',
    null, 'wallet');

  perform set_config('role', 'postgres', true);
  select status into v_status from public.booking_payments where booking_id = v_booking;
  insert into probe values ('11. fully refunded booking payment',
    case when v_status = 'refunded' then 'OK — booking_payments.status = refunded'
         else 'BROKEN — still ' || coalesce(v_status, 'null') end);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Immutability. The ledger refuses UPDATE and DELETE — from anyone.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_id uuid;
begin
  select id into v_id from public.wallet_transactions
   where office_id = (select v::uuid from fixture where k = 'office') limit 1;
  if v_id is null then
    insert into probe values ('12. immutability', 'SKIPPED — no ledger rows'); return;
  end if;

  -- As the table owner: the trigger binds the owner too, so a future SECURITY
  -- DEFINER function that gets this wrong still fails.
  begin
    update public.wallet_transactions set amount = amount + 1 where id = v_id;
    insert into probe values ('12. owner edits a ledger amount', 'STILL EXPLOITABLE — history is writable');
  exception when others then
    insert into probe values ('12. owner edits a ledger amount',
      case when sqlerrm like '%wallet_ledger_immutable%' then 'OK — wallet_ledger_immutable'
           else 'OK — blocked (' || left(sqlerrm, 40) || ')' end);
  end;

  begin
    delete from public.wallet_transactions where id = v_id;
    insert into probe values ('13. owner deletes a ledger row', 'STILL EXPLOITABLE — history is deletable');
  exception when others then
    insert into probe values ('13. owner deletes a ledger row',
      case when sqlerrm like '%wallet_ledger_immutable%' then 'OK — wallet_ledger_immutable'
           else 'OK — blocked (' || left(sqlerrm, 40) || ')' end);
  end;

  -- Money moved without a ledger row (law L4).
  begin
    update public.wallets set balance = balance + 1000
     where office_id = (select v::uuid from fixture where k = 'office');
    insert into probe values ('14. balance moved without a ledger entry',
      'STILL EXPLOITABLE — Σ ledger no longer equals balance');
  exception when others then
    insert into probe values ('14. balance moved without a ledger entry',
      case when sqlerrm like '%wallet_balance_requires_ledger_entry%'
           then 'OK — wallet_balance_requires_ledger_entry'
           else 'BROKEN — ' || sqlerrm end);
  end;
end $$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. Client-role write paths. RLS alone must deny every mutation.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare v_n int;
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select v from fixture where k = 'admin'),
                      'role', 'authenticated')::text, true);

  begin
    insert into public.wallet_transactions
      (wallet_id, office_id, seq, kind, category, amount, balance_before, balance_after,
       reason, performed_by_name, request_key, request_fingerprint, entry_hash)
    select w.id, w.office_id, 9999, 'cashback', 'promotion', 1000, 0, 1000,
           'forged', 'forger', gen_random_uuid(), 'x', '\x00'::bytea
      from public.wallets w limit 1;
    insert into probe values ('15. forged ledger entry', 'STILL EXPLOITABLE — insert accepted');
  exception when others then
    insert into probe values ('15. forged ledger entry', 'OK — blocked');
  end;

  begin
    truncate public.wallet_transactions;
    insert into probe values ('16. TRUNCATE the ledger', 'STILL EXPLOITABLE — ledger erased');
  exception when others then
    insert into probe values ('16. TRUNCATE the ledger', 'OK — blocked');
  end;

  begin
    perform public.wallet_post_entry(
      (select v::uuid from fixture where k = 'client'), 'wallet_adjust',
      'cashback', 'promotion', 500, 'bypass');
    insert into probe values ('17. calling the shared writer directly',
      'STILL EXPLOITABLE — per-kind guards bypassed');
  exception when others then
    insert into probe values ('17. calling the shared writer directly', 'OK — blocked');
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. Cross-office isolation.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_other uuid := (select v::uuid from fixture where k = 'other_admin');
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_n int;
begin
  if v_other is null then
    insert into probe values ('18. cross-office', 'SKIPPED — only one office has users'); return;
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_other, 'role', 'authenticated')::text, true);

  select count(*) into v_n from public.wallets
   where office_id = (select v::uuid from fixture where k = 'office');
  insert into probe values ('18. another office reads these balances',
    case when v_n = 0 then 'OK — 0 rows' else 'LEAK — ' || v_n || ' wallets visible' end);

  select count(*) into v_n from public.wallet_transactions
   where office_id = (select v::uuid from fixture where k = 'office');
  insert into probe values ('19. another office reads this ledger',
    case when v_n = 0 then 'OK — 0 rows' else 'LEAK — ' || v_n || ' entries visible' end);

  begin
    perform public.office_wallet_cashback(v_client, 50, 'promotion', 'اختبار: مكتب آخر');
    insert into probe values ('20. another office credits this customer',
      'STILL EXPLOITABLE — cross-office posting accepted');
  exception when others then
    insert into probe values ('20. another office credits this customer',
      case when sqlerrm like '%client_not_in_office%' then 'OK — client_not_in_office'
           else 'OK — blocked (' || left(sqlerrm, 40) || ')' end);
  end;

  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 7. Reversal, and the frozen wallet.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_admin  uuid := (select v::uuid from fixture where k = 'admin');
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_office uuid := (select v::uuid from fixture where k = 'office');
  v_tx     uuid;
  v_rev    jsonb;
  v_status text;
begin
  if v_admin is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select id into v_tx from public.wallet_transactions
   where office_id = v_office and client_id = v_client
     and kind = 'cashback' and status = 'posted'
   order by seq limit 1;

  if v_tx is not null then
    v_rev := public.office_wallet_reverse(v_tx, 'اختبار: عكس العملية');
    select status into v_status from public.wallet_transactions where id = v_tx;
    insert into probe values ('21. reversal',
      case when v_rev->>'kind' = 'reversal' and v_status = 'reversed'
           then 'OK — inverse posted, original marked reversed'
           else 'BROKEN — original is ' || coalesce(v_status,'null') end);

    begin
      perform public.office_wallet_reverse(v_tx, 'اختبار: عكس مكرر');
      insert into probe values ('22. double reversal', 'BROKEN — accepted');
    exception when others then
      insert into probe values ('22. double reversal',
        case when sqlerrm like '%already_reversed%' then 'OK — already_reversed'
             else 'BROKEN — ' || sqlerrm end);
    end;
  else
    insert into probe values ('21. reversal', 'SKIPPED — no posted cashback');
  end if;

  -- Freezing is a fraud hold, not a punishment: credits still land, debits do not.
  perform public.office_wallet_set_status(v_client, 'frozen', 'اختبار: تجميد');
  begin
    perform public.office_wallet_debit(v_client, 1, 'correction', 'اختبار: خصم من محفظة مجمدة');
    insert into probe values ('23. debit on a frozen wallet', 'BROKEN — accepted');
  exception when others then
    insert into probe values ('23. debit on a frozen wallet',
      case when sqlerrm like '%wallet_frozen%' then 'OK — wallet_frozen'
           else 'BROKEN — ' || sqlerrm end);
  end;

  begin
    perform public.office_wallet_credit(v_client, 1, 'goodwill', 'اختبار: إضافة لمحفظة مجمدة');
    insert into probe values ('24. credit on a frozen wallet',
      'OK — credits still land (you must always be able to refund someone)');
  exception when others then
    insert into probe values ('24. credit on a frozen wallet', 'BROKEN — ' || sqlerrm);
  end;

  perform public.office_wallet_set_status(v_client, 'active', 'اختبار: إلغاء التجميد');
  perform set_config('role', 'postgres', true);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 8. The support agent: sees everything, moves nothing (§6).
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_admin   uuid := (select v::uuid from fixture where k = 'admin');
  v_client  uuid := (select v::uuid from fixture where k = 'client');
  v_office  uuid := (select v::uuid from fixture where k = 'office');
  v_booking uuid := (select v::uuid from fixture where k = 'booking');
  v_n int;
  v_refund jsonb;
begin
  if v_admin is null then return; end if;

  -- Demoted for the duration of the transaction; the ROLLBACK puts it back.
  update public.office_users set role = 'support_agent'
   where user_id = v_admin and office_id = v_office;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select count(*) into v_n from public.wallets where office_id = v_office;
  insert into probe values ('25. agent sees balances',
    case when v_n > 0 then 'OK — ' || v_n || ' wallets visible'
         else 'BROKEN — agents cannot see the balances they are asked about' end);

  begin
    perform public.office_wallet_cashback(v_client, 25, 'promotion', 'اختبار: وكيل');
    insert into probe values ('26. agent grants cashback', 'STILL EXPLOITABLE — accepted');
  exception when others then
    insert into probe values ('26. agent grants cashback',
      case when sqlerrm like '%not_authorized%' then 'OK — not_authorized'
           else 'BROKEN — ' || sqlerrm end);
  end;

  begin
    perform public.office_wallet_debit(v_client, 25, 'correction', 'اختبار: وكيل');
    insert into probe values ('27. agent debits', 'STILL EXPLOITABLE — accepted');
  exception when others then
    insert into probe values ('27. agent debits',
      case when sqlerrm like '%not_authorized%' then 'OK — not_authorized'
           else 'BROKEN — ' || sqlerrm end);
  end;

  -- Their escalation path: a request, born pending, that lands in the owner's queue.
  begin
    v_refund := public.office_refund_create(v_booking, 1, 'other', 'اختبار: طلب من الوكيل');
    insert into probe values ('28. agent files a refund request',
      case when v_refund->>'status' = 'pending' then 'OK — born pending'
           else 'BROKEN — born ' || (v_refund->>'status') end);
  exception when others then
    -- The fixture booking may already be fully refunded by section 3.
    insert into probe values ('28. agent files a refund request',
      case when sqlerrm like '%refund_exceeds_payment%'
           then 'OK — capacity exhausted by section 3, authority not the blocker'
           else 'BROKEN — ' || sqlerrm end);
  end;

  begin
    perform public.office_refund_decide(
      (select id from public.refund_requests where office_id = v_office
        and status = 'pending' limit 1), 'approve');
    insert into probe values ('29. agent approves a refund', 'STILL EXPLOITABLE — accepted');
  exception when others then
    insert into probe values ('29. agent approves a refund',
      case when sqlerrm like '%not_authorized%' then 'OK — not_authorized'
           else 'OK — blocked (' || left(sqlerrm, 40) || ')' end);
  end;

  perform set_config('role', 'postgres', true);
  update public.office_users set role = 'dashboard_admin'
   where user_id = v_admin and office_id = v_office;
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 9. Tamper evidence and reconciliation.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_admin  uuid := (select v::uuid from fixture where k = 'admin');
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_office uuid := (select v::uuid from fixture where k = 'office');
  v_chain  jsonb;
  v_n      int;
begin
  if v_admin is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  v_chain := public.office_wallet_verify_chain(v_client);
  insert into probe values ('30. hash chain verifies',
    case when (v_chain->>'verified')::boolean
         then 'OK — ' || (v_chain->>'entries') || ' entries, head ' ||
              left(coalesce(v_chain->>'head_hash','-'), 12)
         else 'BROKEN — ' || (v_chain->>'fault') || ' at seq ' || (v_chain->>'divergent_seq') end);

  insert into probe values ('31. Σ ledger = balance',
    case when (v_chain->>'ledger_balance')::numeric = (v_chain->>'cached_balance')::numeric
         then 'OK — ' || (v_chain->>'cached_balance')
         else 'BROKEN — ledger ' || (v_chain->>'ledger_balance') ||
              ' vs cached ' || (v_chain->>'cached_balance') end);

  perform set_config('role', 'postgres', true);

  select count(*) into v_n from public.wallet_reconcile(v_office);
  insert into probe values ('32. office-wide reconciliation',
    case when v_n = 0 then 'OK — every wallet reconciles'
         else 'BROKEN — ' || v_n || ' wallet(s) do not' end);
end $$;

reset role;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 10. Read surfaces return, and stay scoped.
-- ═══════════════════════════════════════════════════════════════════════════════════
do $$
declare
  v_admin  uuid := (select v::uuid from fixture where k = 'admin');
  v_client uuid := (select v::uuid from fixture where k = 'client');
  v_out    jsonb;
begin
  if v_admin is null then return; end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  v_out := public.office_wallet_overview();
  insert into probe values ('33. overview',
    'OK — liability ' || (v_out->>'outstanding_balance') ||
    ', refunds ' || (v_out->>'refund_total') ||
    ', pending ' || (v_out->>'pending_refund_count'));

  v_out := public.office_wallet_directory(null, 10, 0);
  insert into probe values ('34. directory',
    case when jsonb_array_length(v_out->'rows') > 0
         then 'OK — ' || (v_out->>'total') || ' customers'
         else 'BROKEN — no customers listed for an office with bookings' end);

  v_out := public.office_wallet_summary(v_client);
  insert into probe values ('35. summary',
    case when jsonb_array_length(v_out->'entries') > 0
         then 'OK — ' || jsonb_array_length(v_out->'entries') || ' entries, balance ' ||
              (v_out->'wallet'->>'balance')
         else 'BROKEN — no entries after posting several' end);

  v_out := public.office_wallet_ledger(jsonb_build_object('kinds', jsonb_build_array('cashback')), 50, 0);
  insert into probe values ('36. ledger, filtered by kind',
    case when (v_out->>'total')::int > 0 then 'OK — ' || (v_out->>'total') || ' cashback rows'
         else 'BROKEN — filter returned nothing' end);

  perform set_config('role', 'postgres', true);
end $$;

reset role;


select step, result from probe order by step;

rollback;
