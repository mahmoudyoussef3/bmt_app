# Client · Loyalty (points)

Points balance, the points ledger, tier catalogue, reward catalogue, and "redeem a reward".
**The redeem write is refused by the database today** (see L2) — the read side works.

## Overview

| Layer | Files (relative to `lib/apps/client/features/loyalty/`) |
|---|---|
| Screen | `presentation/screens/loyalty_screen.dart` (`LoyaltyRoutes.loyalty`) |
| Cubit | `LoyaltyCubit` (`load()`, redeem via `RedeemLoyaltyRewardUseCase` at line 56) |
| Use cases | `GetLoyaltyDataUseCase`, `RedeemLoyaltyRewardUseCase` |
| Repo | `data/repositories/loyalty_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_loyalty_datasource.dart` |
| Models / mappers | `data/models/loyalty_snapshot_model.dart`, `loyalty_account_model.dart`, `points_transaction_model.dart`, `loyalty_tier_model.dart`, `loyalty_reward_model.dart`; `data/mappers/loyalty_mappers.dart` |
| Entity | `domain/entities/loyalty_data.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| Y1 | Snapshot (balance, ledger, tiers, rewards) | 4 reads | session | `GET /api/v1/me/loyalty` |
| Y2 | Redeem a reward | `PATCH loyalty_accounts` (CAS) + `POST loyalty_transactions` | session | `POST /api/v1/me/loyalty/redemptions` |

Both throw `'User is not authenticated'` without a session.

---

## Y1 — `fetchSnapshot()` (`supabase_loyalty_datasource.dart:16-49`)

```
GET /rest/v1/loyalty_accounts?select=*&client_id=eq.<uid>                                  (maybeSingle; null ⇒ 0 points)
GET /rest/v1/loyalty_transactions?select=*&client_id=eq.<uid>&order=created_at.desc         (errors ⇒ [])
GET /rest/v1/loyalty_tiers?select=*&order=points_required_val.asc                            (errors ⇒ [])
GET /rest/v1/loyalty_rewards?select=*&is_active=eq.true&order=points_cost.asc                (errors ⇒ [])
```

| Model | Columns read |
|---|---|
| `LoyaltyAccountModel` | `points` (int, default 0) |
| `PointsTransactionModel` | `title`, `created_at`, `points` (signed; redemptions negative), `is_earned` (bool) |
| `LoyaltyTierModel` | `name`, `points_required` (display string, e.g. `"500 pts"`; sort column is `points_required_val`), `icon_key`, `gradient_colors[]` (ARGB ints as strings; <2 ⇒ fallback slate), `perks[]` |
| `LoyaltyRewardModel` | `id`, `title`, `description`, `points_cost` (int), `value_label`, `category` (default `'Discount'`), `coupon_code` |

`RLS` (`20260721100000_multi_office_security_hardening.sql:480-495`): `loyalty_accounts_self`, `loyalty_transactions_self` — **select only**, `client_id = auth.uid()`; tiers/rewards public read, platform-admin write.

**Proposed .NET:** `GET /api/v1/me/loyalty` → `{ points, transactions[], tiers[], rewards[] }`.

---

## Y2 — `redeemReward({rewardTitle, pointsCost})` (line 52-83) — **broken today**

```
GET   /rest/v1/loyalty_accounts?select=points&client_id=eq.<uid>                    (maybeSingle)
PATCH /rest/v1/loyalty_accounts?client_id=eq.<uid>&points=eq.<balance>               { "points": <balance - cost> }   Prefer: return=representation
POST  /rest/v1/loyalty_transactions                                                   { "client_id","title":"Redeemed: <title>","points": -<cost>,"is_earned": false }
```

Client-side rule: `balance >= pointsCost` else `'Insufficient points balance to redeem this reward'`;
the PATCH is a compare-and-set on the read balance (empty result ⇒ `'Your points balance changed. Please try again.'`).

**But** `20260721100000_multi_office_security_hardening.sql:492` revokes `insert, update, delete` on
both tables from `authenticated` ("never writable from the client tier"), so the PATCH matches no row /
is denied and every redemption fails with the "balance changed" message. There is no RPC for redemption.
`NOT IMPLEMENTED` server-side.

**Proposed .NET:** `POST /api/v1/me/loyalty/redemptions { rewardId }` → `201 { newBalance, couponCode }`,
atomic: check balance, debit, write ledger row, issue the coupon. Also decide what **earns** points —
no backend path writes `loyalty_transactions` today (`NEEDS BACKEND DECISION`).

## Notes for the .NET team

1. Read side works; write side is dead. The screen still shows the redeem button.
2. `loyalty_accounts.wallet_balance` is superseded by `wallets` — do not carry it over.
