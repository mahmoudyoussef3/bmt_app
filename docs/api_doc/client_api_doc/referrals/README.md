# Client · Referrals

The "Refer & earn" hub: the rider's referral code, invite stats, referral history, scratch-voucher
style rewards and a leaderboard. Read-only; the only write is at sign-up (the referral code in the
sign-up metadata — see `auth/A1`).

## Overview

| Layer | Files (relative to `lib/apps/client/features/referrals/`) |
|---|---|
| Screen | `presentation/screens/referral_rewards_screen.dart` (`ReferralRoutes.rewards`; shares the code via `share_plus`) |
| Cubit | `ReferralRewardsCubit` (`load()`) |
| Use case | `domain/usecases/get_referral_rewards_data_usecase.dart` |
| Repo | `data/repositories/referral_rewards_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_referral_rewards_datasource.dart` (`getReferralRewardsData()`, line 9) |
| Entity | `domain/entities/referral_rewards.dart` (`ReferralRewardsData`, `ReferralHistoryItem`, `ScratchVoucher`, `ReferralLeaderboardEntry`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| E1 | Load the hub (4 reads) | `GET loyalty_accounts`, `GET loyalty_rewards`, `GET referrals`, `GET referral_leaderboard` | session | `GET /api/v1/me/referrals` |

Throws `'User not authenticated'` without a session.

---

## E1 — `getReferralRewardsData()` (`supabase_referral_rewards_datasource.dart:9-120`)

```
GET /rest/v1/loyalty_accounts?select=*&client_id=eq.<uid>                                   (maybeSingle)
GET /rest/v1/loyalty_rewards?select=*&is_active=eq.true&order=points_cost.asc&limit=5        (errors ⇒ [])
GET /rest/v1/referrals?select=*&referrer_id=eq.<uid>&order=created_at.desc                   (errors ⇒ [])
GET /rest/v1/referral_leaderboard?select=*&order=successful_count.desc&limit=10              (errors ⇒ [])
```

| Result field | Derivation |
|---|---|
| `referralCode` | **computed on the device**: `'BMT-' + first 8 hex of uid (upper)` — **not** the server-issued `referral_codes.code` (the trigger `handle_new_user_referral` generates one from the name; the app never reads it). The shared code therefore does not match what sign-up validates. **Bug to fix in the port.** |
| `walletBalance` | `loyalty_accounts.wallet_balance` — column marked SUPERSEDED by `wallets` (`20260806090600_client_wallet_read.sql:100`); always 0 |
| `totalInvites` | `count(referrals)` |
| `successfulReferrals` / `earnedRewardsTotal` | rows with `status IN ('completed','first_order_completed','reward_granted')`; sum of `reward_value` (fallback `reward_amount`) |
| `pendingReferrals` | the rest |
| `history[]` | `{ name = referred_name ?? 'Guest', date = created_at (yyyy-MM-dd), status label: registered → 'Registered', first_order_completed → 'First Order Completed', reward_granted|completed → 'Reward Granted', else 'Pending Registration', rewardAmount }` |
| `vouchers[]` | from `loyalty_rewards`: `{ id, title, description, promoCode = coupon_code, amount = value_label }` |
| `leaderboard[]` | from the view: `{ rank (1-based), name, successfulCount = successful_count, totalRewards = total_rewards, isCurrentUser = referrer_id == uid }` |
| `contacts` | constant `[]` |

`RLS` (`20260620090000_referral_system.sql:410-447`): `referrals_select_involved` (referrer or referred = me);
`referral_rewards_read` public; `referral_leaderboard` view granted to `authenticated`;
`loyalty_accounts_self` / `loyalty_rewards` public read.

**`referral_leaderboard` view** (`20260620090000_referral_system.sql:399`):
`referrer_id, name (clients.full_name or 'Member'), successful_count (status in first_order_completed|reward_granted), total_rewards (sum reward_value where reward_status='granted')`.

**Server-side lifecycle** the backend must own: `handle_new_user_referral` (issue code, record
`registered` referral from sign-up metadata), `redeem_referral_code(p_code)` RPC (exists, **not called by the app**),
and trigger `grant_referral_reward()` on `operation_bookings` status transitions (first paid order ⇒ `first_order_completed` / `reward_granted`).

**Proposed .NET:** `GET /api/v1/me/referrals` → `{ referralCode (server-issued), totalInvites, successfulReferrals, pendingReferrals, earnedRewardsTotal, history[], vouchers[], leaderboard[] }`;
`POST /api/v1/me/referrals/redeem { code }` to expose the existing "enter later" path.

## Notes for the .NET team

1. Return the **real** referral code; drop the device-side `BMT-<uid>` derivation.
2. `wallet_balance` on `loyalty_accounts` is dead — money lives in `wallets` (see `wallet/`).
