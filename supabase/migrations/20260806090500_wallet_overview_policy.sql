-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — surface the office's own limits
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §3.4, §11.
--
-- `office_wallet_overview()` gains a `policy` object. Two reasons, both about the
-- operator rather than the schema:
--
--   1. **Step-up confirmation needs a threshold.** §11 requires re-typing the
--      amount above `require_second_approval_above`. A dialog cannot enforce a
--      limit it has never been told, and hardcoding a number in Dart would be a
--      second definition of a value that already lives in a table.
--
--   2. **A cap the operator cannot see is a cap they discover by being refused.**
--      Showing "الحد الأقصى للعملية 1,000 ج.م" under the amount field turns a
--      server rejection into something that never happens.
--
-- Additive: an extra key on a jsonb document nothing destructures positionally.
-- The caps are still enforced server-side in `wallet_post_entry`; this is display
-- data, never a control.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.office_wallet_overview()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_office uuid := public.current_office_id();
  v_policy public.office_wallet_policies;
begin
  if v_office is null then
    raise exception 'not_an_office_user';
  end if;
  if not public.office_can('wallet_view') then
    raise exception 'not_authorized';
  end if;

  select * into v_policy from public.office_wallet_policies where office_id = v_office;

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
      'policy', jsonb_build_object(
        'max_single_credit',             coalesce(v_policy.max_single_credit, 1000),
        'max_single_debit',              coalesce(v_policy.max_single_debit, 1000),
        'max_operator_daily_promo',      coalesce(v_policy.max_operator_daily_promo, 2000),
        'require_second_approval_above', v_policy.require_second_approval_above,
        'timezone',                      coalesce(v_policy.timezone, 'Africa/Cairo')),
      'generated_at', now())
  );
end;
$$;

revoke all on function public.office_wallet_overview() from public;
revoke all on function public.office_wallet_overview() from anon;
grant execute on function public.office_wallet_overview() to authenticated;
