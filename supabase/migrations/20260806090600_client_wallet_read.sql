-- ═══════════════════════════════════════════════════════════════════════════════════
-- Wallet & Financial Adjustments — the customer's own read
--
-- Design: docs/dashboard/DASHBOARD_CUSTOMER_WALLET.md §2.1, §14 case 15, Part 16 phase 6.
--
-- A customer who uses three offices holds three wallets and sees three labelled
-- balances. That is the honest model — these are three separate credit
-- relationships with three separate businesses, and there is no inter-office
-- clearing mechanism in this platform to net them against each other.
--
-- ── Why an RPC and not the table ────────────────────────────────────────────────
--
-- `wallets_self_read` and `wallet_transactions_self_read` already let a customer
-- read their own rows, and that stays true. But the *label* does not come from
-- those tables: it comes from `offices`, whose client-facing policy is
-- `status = 'active' AND listing_status = 'listed'`. An office that has taken
-- itself off the marketplace would therefore show a customer their real balance
-- next to a blank name — the one screen where "who owes me this?" is the entire
-- question.
--
-- This resolves the name server-side for offices the customer demonstrably has a
-- relationship with (they hold a wallet there), and nothing else. It reads only
-- `auth.uid()`'s own rows; there is no parameter to point somewhere else.
--
-- ── Why the balance is never computed on the device (§14 case 15) ───────────────
--
-- The client screen is read-only and the balance always comes from here. A
-- device that added up its own ledger would disagree with the server the moment
-- an operator posted an entry, and the customer would be told a number the
-- office does not recognise.
-- ═══════════════════════════════════════════════════════════════════════════════════

create or replace function public.client_wallet_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  v_client uuid := auth.uid();
begin
  if v_client is null then
    raise exception 'not_authenticated';
  end if;

  return jsonb_build_object(
    'total_balance', coalesce((select sum(balance) from public.wallets
                                where client_id = v_client), 0),
    'wallets', coalesce((
      select jsonb_agg(to_jsonb(x) order by x.balance desc, x.office_name)
        from (
          select w.id            as wallet_id,
                 w.office_id,
                 o.name          as office_name,
                 o.logo_url      as office_logo_url,
                 w.balance,
                 w.available_balance,
                 w.status,
                 w.entry_count,
                 w.updated_at,
                 -- Recent history per wallet, newest first. Capped: this is a
                 -- phone screen answering "why is my balance this", not an
                 -- archive.
                 coalesce((
                   select jsonb_agg(to_jsonb(e) order by e.seq desc)
                     from (
                       select t.id, t.seq, t.kind, t.category, t.amount,
                              t.balance_after, t.status, t.reason, t.created_at
                         from public.wallet_transactions t
                        where t.wallet_id = w.id
                        order by t.seq desc
                        limit 30) e), '[]'::jsonb) as entries
            from public.wallets w
            join public.offices o on o.id = w.office_id
           where w.client_id = v_client
        ) x), '[]'::jsonb),
    'generated_at', now());
end;
$$;

revoke all on function public.client_wallet_summary() from public;
revoke all on function public.client_wallet_summary() from anon;
grant execute on function public.client_wallet_summary() to authenticated;


-- ───────────────────────────────────────────────────────────────────────────────────
-- Retire the dead path (§15 step 5)
-- ───────────────────────────────────────────────────────────────────────────────────
--
-- `loyalty_accounts.wallet_balance` was a wallet in name only: 0 rows, no office
-- column, a self-SELECT policy and no writer anywhere. The client app's
-- `redeemWalletBalance()` zeroed it and reported a payout that never happened —
-- RLS denied the write without throwing, so the app celebrated a redemption the
-- database refused. That Dart is deleted in the same change as this comment.
--
-- The column is NOT dropped. Dropping it belongs with the wider loyalty cleanup,
-- not with a money feature, and a comment is enough to stop the next person
-- reaching for it.
comment on column public.loyalty_accounts.wallet_balance is
  'SUPERSEDED (2026-08-06) by public.wallets. Never written by any backend path; '
  'kept only so the loyalty cleanup can drop it deliberately. Do not read or write it.';
