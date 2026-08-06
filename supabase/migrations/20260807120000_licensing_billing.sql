-- ═══════════════════════════════════════════════════════════════════════════════════
-- EWT Entitlement Platform — Phase 5/6 (a): billing records
--
-- Design: docs/architecture/PLATFORM_LICENSING.md Part 12, §17.1–17.5.
--
-- ── Scope: STRUCTURE ONLY ──────────────────────────────────────────────────────────
--
-- No payment gateway, no card capture, no automatic collection. What ships is the
-- record-keeping a gateway later plugs into, and the deliberate non-goals are:
--
--   * No proration. Mid-cycle changes bill from the next period; `line_items` already
--     has the shape to support proration when a real billing engine exists.
--   * No multi-currency conversion. Currency is stored per plan and per license; no FX.
--   * No usage-based pricing. Meters exist and are enforced; nothing charges overage.
--   * `office_payment_configs` is NOT touched (§2.6). That table is how an OFFICE
--     collects from RIDERS, and its entire security model is "the office's own
--     secrets". EWT collecting from offices is the mirror image and gets its own
--     table, so the platform's merchant credentials never share a home with a
--     tenant's.
--
-- ── Two shapes that are load-bearing ───────────────────────────────────────────────
--
--   line_items jsonb  — add-ons, overage, proration, coupons and per-seat charges are
--                       all line items. None of them ever needs a column.
--   plan_snapshot     — freezes the commercial terms at issue time. A plan renamed or
--                       repriced next month must not retroactively change what an
--                       already-issued invoice says. Same discipline the booking
--                       system already applies to fares.
-- ═══════════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 1. office_invoices
-- ═══════════════════════════════════════════════════════════════════════════════════

create table if not exists public.office_invoices (
  id             uuid primary key default gen_random_uuid(),

  -- restrict, everywhere an actor or an office is referenced (F8): an invoice must
  -- not be deletable by removing a user.
  office_id      uuid not null references public.offices(id) on delete restrict,

  invoice_number text not null unique,        -- INV-2026-0001, gapless per year

  plan_snapshot  jsonb not null,

  period_start   timestamptz not null,
  period_end     timestamptz not null,

  -- [{type, label, qty, unit, amount}]
  line_items     jsonb not null default '[]'::jsonb,

  subtotal       numeric(12,2) not null default 0,
  discount       numeric(12,2) not null default 0,
  tax            numeric(12,2) not null default 0,
  total          numeric(12,2) not null default 0,
  currency       text not null default 'EGP',

  status         text not null default 'draft'
                   check (status in ('draft','issued','paid','overdue','void','refunded')),

  issued_at      timestamptz,
  due_at         timestamptz,
  paid_at        timestamptz,

  -- Manual collection in V1: how the office actually paid.
  payment_method text,
  payment_ref    text,
  recorded_by    uuid references auth.users(id) on delete restrict,

  -- Gateway hook, inert in V1.
  external_ref   text,

  notes          text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),

  constraint invoice_paid_coherent check ((status = 'paid') = (paid_at is not null)),
  constraint invoice_period_order  check (period_end > period_start)
);

create index if not exists idx_office_invoices_office
  on public.office_invoices (office_id, created_at desc);
create index if not exists idx_office_invoices_status
  on public.office_invoices (status, due_at);

-- Idempotency for the renewal job: one invoice per (office, period) that is not void.
create unique index if not exists uniq_invoice_office_period
  on public.office_invoices (office_id, period_start, period_end)
  where status <> 'void';

comment on table public.office_invoices is
  'The platform billing an OFFICE. Distinct in every way from office_payment_configs, '
  'which is an office collecting from riders (§2.6). Records only — collection is '
  'manual in V1 and external_ref is the inert hook a gateway later fills.';

drop trigger if exists update_office_invoices_updated_at on public.office_invoices;
create trigger update_office_invoices_updated_at
  before update on public.office_invoices
  for each row execute function public.update_updated_at_column();

drop trigger if exists trg_audit_invoices on public.office_invoices;
create trigger trg_audit_invoices
  after insert or update or delete on public.office_invoices
  for each row execute function public.platform_audit_trigger('invoice', 'invoice_number');


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 2. Gapless invoice numbers
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- A sequence would be simpler but leaks gaps on rollback, and an invoice series with
-- holes in it is a question every auditor asks. A counter row taken under FOR UPDATE
-- serialises issuance instead — invoices are issued in the tens per month, so the
-- contention this costs is nil.

create table if not exists public.platform_invoice_sequence (
  year        int primary key,
  last_number int not null default 0 check (last_number >= 0)
);

alter table public.platform_invoice_sequence enable row level security;
revoke all on public.platform_invoice_sequence from anon, authenticated;

create or replace function public.platform_next_invoice_number()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_year int := extract(year from now())::int;
  v_next int;
begin
  insert into public.platform_invoice_sequence (year, last_number)
  values (v_year, 1)
  on conflict (year) do update
    set last_number = public.platform_invoice_sequence.last_number + 1
  returning last_number into v_next;

  return 'INV-' || v_year::text || '-' || lpad(v_next::text, 4, '0');
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 3. Issue / pay / void
-- ═══════════════════════════════════════════════════════════════════════════════════

-- The renewal job runs with no JWT at all (pg_cron, or an Edge Function on the
-- service role), so it has no platform-admin identity to present. This is the same
-- construction wallet_post_entry uses for its 'system' source: the JWT-less path is
-- allowed, and the function stays revoked from `anon` so nothing can reach it over
-- PostgREST without authenticating first.
create or replace function public.assert_platform_admin_or_system()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;
  if not public.is_platform_admin() then
    raise exception 'platform_admin_required';
  end if;
end;
$$;

revoke all on function public.assert_platform_admin_or_system() from public, anon;
grant execute on function public.assert_platform_admin_or_system() to authenticated;


create or replace function public.platform_issue_invoice(
  p_office_id    uuid,
  p_period_start timestamptz default null,
  p_period_end   timestamptz default null,
  p_options      jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_license public.office_licenses;
  v_plan    public.platform_plans;
  v_start   timestamptz;
  v_end     timestamptz;
  v_amount  numeric(12,2);
  v_items   jsonb;
  v_row     public.office_invoices;
  v_status  text := coalesce(p_options ->> 'status', 'issued');
  v_due     int  := coalesce((p_options ->> 'due_days')::int, 14);
begin
  perform public.assert_platform_admin_or_system();
  perform set_config('bmt.licensing_reason', coalesce(p_options ->> 'reason', ''), true);

  select * into v_license from public.office_licenses where office_id = p_office_id;
  if not found then raise exception 'license_not_found'; end if;

  select * into v_plan from public.platform_plans where id = v_license.plan_id;

  v_start := coalesce(p_period_start, v_license.period_start);
  v_end   := coalesce(p_period_end, v_license.period_end,
                      v_start + case v_license.billing_cycle
                                  when 'yearly' then interval '1 year'
                                  else interval '1 month'
                                end);

  -- The negotiated price wins over the list price; a 'free' or 'custom' cycle with
  -- no negotiated price bills zero rather than guessing.
  v_amount := coalesce(
    nullif(p_options ->> 'amount', '')::numeric,
    v_license.price_override,
    case v_license.billing_cycle
      when 'yearly'  then v_plan.price_yearly
      when 'monthly' then v_plan.price_monthly
      else null
    end,
    0);

  v_items := coalesce(p_options -> 'line_items', jsonb_build_array(jsonb_build_object(
    'type',   'plan',
    'label',  'اشتراك المنصة — ' || v_plan.name_ar,
    'qty',    1,
    'unit',   v_amount,
    'amount', v_amount)));

  insert into public.office_invoices (
    office_id, invoice_number, plan_snapshot, period_start, period_end,
    line_items, subtotal, discount, tax, total, currency,
    status, issued_at, due_at, notes)
  values (
    p_office_id,
    public.platform_next_invoice_number(),
    public.platform_plan_snapshot(v_plan.id),
    v_start, v_end,
    v_items,
    v_amount,
    coalesce((p_options ->> 'discount')::numeric, 0),
    coalesce((p_options ->> 'tax')::numeric, 0),
    v_amount - coalesce((p_options ->> 'discount')::numeric, 0)
             + coalesce((p_options ->> 'tax')::numeric, 0),
    coalesce(v_license.currency, 'EGP'),
    v_status,
    case when v_status <> 'draft' then now() end,
    case when v_status <> 'draft' then now() + make_interval(days => v_due) end,
    coalesce(p_options ->> 'notes', ''))
  -- Idempotent per (office, period): the renewal job may run twice without
  -- double-billing anyone.
  on conflict (office_id, period_start, period_end) where status <> 'void'
    do nothing
  returning * into v_row;

  if v_row.id is null then
    select * into v_row from public.office_invoices
     where office_id = p_office_id and period_start = v_start and period_end = v_end
       and status <> 'void'
     limit 1;
    return to_jsonb(v_row);
  end if;

  perform public.push_operational_alert(
    'invoice_issued',
    'صدرت فاتورة اشتراك المنصة',
    'فاتورة ' || v_row.invoice_number || ' بمبلغ ' ||
      to_char(v_row.total, 'FM9999999990.00') || ' ' || v_row.currency,
    jsonb_build_object('invoice_id', v_row.id),
    'normal', '/settings/billing', p_office_id);

  return to_jsonb(v_row);
end;
$$;


create or replace function public.platform_record_payment(
  p_invoice_id uuid,
  p_method     text,
  p_reference  text default null,
  p_paid_at    timestamptz default null
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.office_invoices;
begin
  perform public.assert_platform_admin();
  perform set_config('bmt.licensing_reason', 'تسجيل سداد يدوي', true);

  update public.office_invoices
     set status         = 'paid',
         paid_at        = coalesce(p_paid_at, now()),
         payment_method = p_method,
         payment_ref    = p_reference,
         recorded_by    = auth.uid()
   where id = p_invoice_id
     and status in ('issued','overdue','draft')
  returning * into v_row;

  if not found then raise exception 'invoice_not_payable'; end if;

  -- Payment clears a dunning state. It never, by itself, changes the plan.
  update public.office_licenses
     set status           = 'active',
         grace_ends_at    = null,
         suspended_at     = null,
         suspended_reason = null
   where office_id = v_row.office_id
     and status in ('past_due','grace','suspended');

  perform public.platform_audit_write(
    v_row.office_id, 'invoice', v_row.invoice_number, 'renewed',
    null, jsonb_build_object('total', v_row.total, 'method', p_method), 'سداد');

  return to_jsonb(v_row);
end;
$$;


create or replace function public.platform_void_invoice(p_invoice_id uuid, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.office_invoices;
begin
  perform public.assert_platform_admin();
  if length(btrim(coalesce(p_reason,''))) < 8 then raise exception 'reason_required'; end if;
  perform set_config('bmt.licensing_reason', p_reason, true);

  update public.office_invoices
     set status = 'void',
         notes  = case when notes = '' then btrim(p_reason)
                       else notes || E'\n' || btrim(p_reason) end
   where id = p_invoice_id and status <> 'paid'
  returning * into v_row;

  -- A paid invoice is not voidable. Reversing money that was received is a refund,
  -- and a refund is a new record rather than an edit to the old one.
  if not found then raise exception 'invoice_not_voidable'; end if;

  return to_jsonb(v_row);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 4. Reads
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_billing_overview(p_filters jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return jsonb_build_object(
    'totals', (
      select jsonb_build_object(
        'issued',  coalesce(sum(total) filter (where status in ('issued','overdue')), 0),
        'paid',    coalesce(sum(total) filter (where status = 'paid'), 0),
        'overdue', coalesce(sum(total) filter (where status = 'overdue'), 0),
        'count',   count(*))
        from public.office_invoices
       where status <> 'void'),

    'mrr', (
      -- Monthly recurring revenue at list, from ACTIVE licenses only. Trials and
      -- suspended offices are excluded because neither is billing anybody today.
      select coalesce(sum(
        case l.billing_cycle
          when 'yearly'  then coalesce(l.price_override, p.price_yearly, 0) / 12
          when 'monthly' then coalesce(l.price_override, p.price_monthly, 0)
          else 0
        end), 0)
        from public.office_licenses l
        join public.platform_plans p on p.id = l.plan_id
       where l.status = 'active'),

    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'invoice_number', i.invoice_number,
               'office_id', i.office_id, 'office_name', o.name,
               'period_start', i.period_start, 'period_end', i.period_end,
               'total', i.total, 'currency', i.currency, 'status', i.status,
               'issued_at', i.issued_at, 'due_at', i.due_at, 'paid_at', i.paid_at,
               'payment_method', i.payment_method, 'line_items', i.line_items)
             order by i.created_at desc)
        from (select * from public.office_invoices
               where (not (p_filters ? 'office_id')
                      or office_id = (p_filters ->> 'office_id')::uuid)
                 and (not (p_filters ? 'status') or status = (p_filters ->> 'status'))
               order by created_at desc limit 200) i
        join public.offices o on o.id = i.office_id), '[]'::jsonb),

    'renewals', coalesce((
      select jsonb_agg(jsonb_build_object(
               'office_id', o.id, 'office_name', o.name,
               'plan_key', p.key, 'period_end', l.period_end,
               'auto_renew', l.auto_renew,
               'amount', coalesce(l.price_override,
                           case l.billing_cycle when 'yearly' then p.price_yearly
                                                else p.price_monthly end))
             order by l.period_end)
        from public.office_licenses l
        join public.offices o on o.id = l.office_id
        join public.platform_plans p on p.id = l.plan_id
       where l.period_end is not null
         and l.period_end <= now() + interval '30 days'), '[]'::jsonb));
end;
$$;


-- The office's own billing history. Scoped by current_office_id(), so there is no
-- parameter an operator could pass to read another office's invoices.
create or replace function public.office_invoices(p_limit int default 50, p_offset int default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_office uuid := public.current_office_id();
begin
  if v_office is null then raise exception 'not_an_office_user'; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'id', i.id, 'invoice_number', i.invoice_number,
             'period_start', i.period_start, 'period_end', i.period_end,
             'line_items', i.line_items, 'total', i.total, 'currency', i.currency,
             'status', i.status, 'issued_at', i.issued_at,
             'due_at', i.due_at, 'paid_at', i.paid_at)
           order by i.created_at desc)
      from (select * from public.office_invoices
             where office_id = v_office and status <> 'draft'
             order by created_at desc
             limit greatest(least(p_limit, 200), 1) offset greatest(p_offset, 0)) i), '[]'::jsonb);
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 5. The office license detail gains its billing section (§9.4 item 6)
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.platform_office_license(p_office_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.assert_platform_admin();

  return jsonb_build_object(
    'office', (select jsonb_build_object(
                 'id', o.id, 'name', o.name, 'slug', o.slug,
                 'status', o.status, 'listing_status', o.listing_status,
                 'licensing_hold', coalesce(o.licensing_hold, 'none'))
                 from public.offices o where o.id = p_office_id),
    'entitlements', public.platform_license_document(p_office_id),
    'overrides', coalesce((
      select jsonb_agg(jsonb_build_object(
               'feature_key', ov.feature_key,
               'name_ar', f.name_ar,
               'category_key', f.category_key,
               'value_type', f.value_type,
               'value', ov.value,
               'plan_value', public.platform_resolve_feature(null,
                               (select l.plan_id from public.office_licenses l
                                 where l.office_id = p_office_id), ov.feature_key) -> 'value',
               'reason', ov.reason,
               'expires_at', ov.expires_at,
               'expired', ov.expires_at is not null and ov.expires_at <= now(),
               'created_at', ov.created_at)
             order by f.category_key, f.sort_order)
        from public.office_feature_overrides ov
        join public.platform_features f on f.key = ov.feature_key
       where ov.office_id = p_office_id), '[]'::jsonb),
    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'invoice_number', i.invoice_number,
               'period_start', i.period_start, 'period_end', i.period_end,
               'total', i.total, 'currency', i.currency, 'status', i.status,
               'issued_at', i.issued_at, 'due_at', i.due_at, 'paid_at', i.paid_at,
               'payment_method', i.payment_method)
             order by i.created_at desc)
        from (select * from public.office_invoices
               where office_id = p_office_id order by created_at desc limit 50) i), '[]'::jsonb),
    'activity', coalesce((
      select jsonb_agg(to_jsonb(a) order by a.created_at desc)
        from (select * from public.platform_license_audit
               where office_id = p_office_id
               order by created_at desc limit 50) a), '[]'::jsonb));
end;
$$;


-- ═══════════════════════════════════════════════════════════════════════════════════
-- 6. RLS and grants
-- ═══════════════════════════════════════════════════════════════════════════════════

alter table public.office_invoices enable row level security;

-- An office reads its own invoices; the platform reads everyone's. No write policy
-- for anybody: issuance goes through the audited definer RPC or it does not happen.
drop policy if exists office_invoices_read on public.office_invoices;
create policy office_invoices_read on public.office_invoices
  for select to authenticated
  using (office_id = public.current_office_id() or public.is_platform_admin());

revoke all on public.office_invoices from anon, authenticated;
grant select on public.office_invoices to authenticated;

revoke all on function public.platform_next_invoice_number()                        from public, anon, authenticated;
revoke all on function public.platform_issue_invoice(uuid, timestamptz, timestamptz, jsonb) from public, anon;
revoke all on function public.platform_record_payment(uuid, text, text, timestamptz) from public, anon;
revoke all on function public.platform_void_invoice(uuid, text)                     from public, anon;
revoke all on function public.platform_billing_overview(jsonb)                      from public, anon;
revoke all on function public.office_invoices(int, int)                             from public, anon;

grant execute on function public.platform_issue_invoice(uuid, timestamptz, timestamptz, jsonb) to authenticated;
grant execute on function public.platform_record_payment(uuid, text, text, timestamptz) to authenticated;
grant execute on function public.platform_void_invoice(uuid, text)                  to authenticated;
grant execute on function public.platform_billing_overview(jsonb)                   to authenticated;
grant execute on function public.office_invoices(int, int)                          to authenticated;
