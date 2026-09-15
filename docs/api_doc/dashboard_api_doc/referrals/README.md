# Dashboard · Referral Program (برنامج الإحالة)

Admin view of the **platform-wide** referral program: the single reward configuration row,
analytics, a leaderboard, the referral history, and the reward transactions. This module is
**not office-scoped** — the referral tables have no `office_id`, and their RLS is rider-owned
(a user sees only referrals they are part of). What an office operator sees today therefore
depends on grants/policies that were written for the platform era; see the notes.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/referrals/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.referrals` = `/referrals`) |
| Cubit | `presentation/cubit/referrals_cubit.dart` |
| Use cases | `domain/usecases/` (`GetRewardConfigUseCase`, `UpdateRewardConfigUseCase`, `GetReferralAnalyticsUseCase`, `GetReferralLeaderboardUseCase`, `GetReferralHistoryUseCase`, `GetRewardTransactionsUseCase`) |
| Repo | `data/repositories/referral_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_referral_datasource.dart` (`SupabaseReferralDatasource implements ReferralDatasource`) |
| Entities | `domain/entities/referral_reward_config.dart`, `referral_analytics.dart`, `referral_leaderboard_item.dart`, `referral_record.dart` (`ReferralStatus`), `referral_reward_transaction.dart` |
| Permission | `DashboardPermission.referrals` (admin only); feature key `referrals` |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| G1 | Reward config | `GET referral_rewards?id=eq.1` (`.maybeSingle()`) | `GET /api/v1/dashboard/referrals/config` |
| G2 | Update config | `POST referral_rewards` upsert `{id:1, …}` (`Prefer: resolution=merge-duplicates`) | `PUT /api/v1/dashboard/referrals/config` |
| G3 | Analytics | `GET referral_analytics` (view) + `HEAD referral_codes` (count) + `GET referrals?select=status` + `GET referral_reward_transactions?select=role,reward_value` | `GET /api/v1/dashboard/referrals/analytics` |
| G4 | Leaderboard | `GET referral_leaderboard?limit=50` (view) + `GET referrals?select=referrer_id,status,created_at` + `GET clients?select=id,phone&id=in.(…)` + `GET referral_codes?select=user_id,code&user_id=in.(…)` | `GET /api/v1/dashboard/referrals/leaderboard` |
| G5 | History (newest 1 000) | `GET referrals?select=<13 cols>&order=created_at.desc&limit=1000` + `GET clients?select=id,full_name&id=in.(…)` | `GET /api/v1/dashboard/referrals` |
| G6 | Reward transactions (newest 1 000) | `GET referral_reward_transactions?select=<8 cols>&order=created_at.desc&limit=1000` + clients lookup | `GET /api/v1/dashboard/referrals/transactions` |

Every read tolerates a missing relation (`42P01`, `PGRST205`, `42703`) by returning empty/default data
(the module predates the migration being applied everywhere). No other error mapping.

---

## G1 / G2 — Config (lines 26 / 41)

Row `referral_rewards` (singleton `id = 1`): `enabled, reward_type ('wallet'|…), reward_value, referred_value,
currency ('EGP'), coupon_code, updated_at`. Defaults when absent: enabled, wallet, 50 / 25 EGP.
`RLS` (`20260721100000_multi_office_security_hardening.sql` §7): read by anyone; **update/insert only by
`is_platform_admin()`** — an office owner's G2 is refused (0 rows, mapped nowhere; the screen shows the old
value). `NEEDS BACKEND DECISION`: this is a platform setting; move the editor to the platform console.

## G3 — Analytics (line 62)

`referral_analytics` view: `total_referrals, successful_referrals (first_order_completed|reward_granted),
conversion_rate (%, 1 dp), rewards_distributed (reward_status='granted')`, granted to `authenticated` (all
rows, platform-wide, **not RLS-filtered** — a view runs as its owner). The Dart then counts
`referrals.status` buckets and sums `referral_reward_transactions` by `role` (`referred` vs referrer) —
both **RLS-filtered to rows the caller is part of** (`referrals_select_involved`, `rrt_select_own`), so
these figures are near-zero for an operator while the view's totals are global. Inconsistent by construction.

## G4 — Leaderboard (line 118)

`referral_leaderboard` view (top 50: `referrer_id, name, successful_count, total_rewards`) enriched with
per-referrer totals/pending/last from `referrals` (RLS-filtered), phones from `clients`, codes from
`referral_codes` (`referral_codes_select_own` — empty for an operator).

## G5 / G6 — History and transactions (lines 185 / 239)

`referrals` columns: `id, referral_code, referrer_id, referred_id, referred_name, status
(pending_registration|registered|first_order_completed|reward_granted|completed), reward_type,
reward_value, reward_status (pending|granted|…), first_order_id, created_at, first_order_at, rewarded_at`.
`referral_reward_transactions`: `id, referral_id, user_id, role (referrer|referred), reward_type, reward_value,
status, created_at`. Names resolved by a `clients` batch lookup. Both RLS-filtered to the caller's own rows.

`BUSINESS RULE` — rewards are granted by trigger `grant_referral_reward()` on `operation_bookings`
insert/status (`20260620090000_referral_system.sql:395`) when a referred rider completes a first order; the
dashboard never writes referrals.

## Notes for the .NET team

1. The program is platform-level (one config, global leaderboard). Either expose it under `/api/v1/platform/referrals/…`
   for platform admins, or make it per-office (adds `office_id` to referrals + config) — today it is neither.
2. The rider-owned RLS makes most of this module empty for an office operator; only the two views return data.
3. `reward_type = 'wallet'` predates the office wallet subsystem; the trigger does **not** post to the new
   `wallets` ledger. Decide whether a referral reward becomes a `wallet_topup` entry.
