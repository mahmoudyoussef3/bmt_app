# Referral & Rewards System

> Brand: **EasyWay / BMT** · Backend: **Supabase** · Reward engine: configurable
> Status: client experience + backend engine implemented; **admin dashboard UI** is
> the remaining surface (the data/config/analytics it needs already exist).

---

## 1. Business overview

Every user automatically receives a unique referral code. They share it; when a referred
customer registers and completes their **first paid order**, the system grants a
configurable reward to the referrer (and a welcome reward to the referred customer),
notifies both, and records an immutable reward transaction.

## 2. Referral code

- Auto-issued on account creation by the `on_auth_user_created_referral` trigger →
  `generate_unique_referral_code(name)` (e.g. `MAHMOUD-AB45`, `BMT-78291`).
- Stored in `referral_codes (user_id unique, code unique)`; existing users are backfilled
  by the migration.
- The client reads it from the user's row; until the table is provisioned it falls back to
  a deterministic `BMT-<uid8>` code so the screen always works.

## 3. Referral usage flow

A code can be supplied at **registration** or **first checkout**:

- **Registration** — the Sign Up screen has an optional “Referral code” field. The code is
  sent in the Supabase sign-up metadata (`referral_code`); the new-user trigger validates
  it and creates a `registered` referral row linking referrer → new user.
- **Checkout** — call the `redeem_referral_code(p_code)` RPC. It validates: code exists,
  not self-referral, the customer hasn’t already been referred, and creates the referral.

Validation rules enforced server-side: code exists · not your own code · customer not
already referred · (reward only on) first successful order.

## 4. Reward engine (configurable)

Single config row `referral_rewards (id=1)`, admin-editable:

| column | meaning |
| --- | --- |
| `enabled` | master on/off switch for the whole system |
| `reward_type` | `points` · `wallet` · `coupon` · `loyalty` |
| `reward_value` | reward to the **referrer** |
| `referred_value` | welcome reward to the **referred** customer |
| `currency` | e.g. `EGP` (for wallet/coupon) |
| `coupon_code` | coupon to issue when `reward_type = coupon` |

Reward granting (`grant_referral_reward` trigger on `operation_bookings`):
1. Fires when a booking enters `confirmed`/`approved` and it is the customer’s **first**
   such order.
2. Marks the referral `first_order_completed`, then (if enabled) writes two
   `referral_reward_transactions` rows, credits `loyalty_accounts`
   (`wallet_balance` for wallet/coupon, `points_balance` for points/loyalty), sets the
   referral `reward_granted`, and inserts the two notifications.

## 5. Notifications

On reward grant, two rows are inserted into `notifications (user_id, title, body, type)`:
- Referrer: “Congratulations! {name} completed their first order using your referral code.
  You earned {value} {currency/points}.”
- Referred: “You received a welcome reward for using a referral code.”

They appear in the existing in-app Notifications tab.

## 6. Referral history & statuses

The referral screen lists each invite with: friend name, date joined, status, reward
earned. Status lifecycle (stored in `referrals.status`):

`pending_registration → registered → first_order_completed → reward_granted`

## 7. Database design

| table | purpose |
| --- | --- |
| `referral_codes` | one unique code per user |
| `referrals` | lifecycle: referrer/referred, code, status, reward fields, first_order_id, timestamps |
| `referral_rewards` | reward engine configuration (admin) |
| `referral_reward_transactions` | immutable reward ledger (referrer + referred rows) |

Views: `referral_leaderboard` (top referrers) and `referral_analytics` (totals,
conversion rate, rewards distributed). RLS restricts rows to the involved users; the
config is world-readable, writable by admins only (add an admin write policy in the
dashboard role).

Full DDL: [supabase/migrations/20260620090000_referral_system.sql](../supabase/migrations/20260620090000_referral_system.sql).

## 8. Client app (implemented)

- **Referral screen** ([referral_rewards_screen.dart](../lib/apps/client/features/referrals/presentation/screens/referral_rewards_screen.dart)):
  code card, copy, **share**, stats grid (Total invites · Successful · **Pending** ·
  Total earned), milestone progress ring, **leaderboard** (top referrers, current user
  highlighted), referral history with statuses, scratch vouchers, success animations.
- **Multi-channel sharing**
  ([referral_share_sheet.dart](../lib/apps/client/features/referrals/presentation/widgets/referral_share_sheet.dart)):
  WhatsApp, Facebook, Messenger, Instagram (copy + open), Copy link, and the **native
  share sheet** (`share_plus`). Channel deep links via `url_launcher`; unavailable apps
  fall back to the native sheet.
- **Sign-up capture**: optional referral code field → sign-up metadata.
- Data layer degrades gracefully (empty states) until the migration is applied.

## 9. Dashboard Admin module (implemented)

A full **Referral Management** module lives in the Dashboard app, built on the existing
dashboard architecture (Arabic/RTL, `DashboardModuleHeader`, `DashboardKpiGrid`,
`DashboardPanel` charts, `OpsDataTable`, `StatusChip`, clean-architecture layers, GetIt DI).

- **Route / nav:** `DashboardRoutes.referrals` (`/referrals`), sidebar item
  **«برنامج الإحالات»** in the Finance group. Screen:
  [referral_management_screen.dart](../lib/apps/dashboard/features/referrals/presentation/screens/referral_management_screen.dart).
- **Permission:** `DashboardPermission.referrals` — admin-only (the support-agent role
  set excludes it; admin receives all permissions). The sidebar hides the item and the
  router blocks the route for unauthorized roles via the existing RBAC.
- **Architecture:** `domain/` (entities `ReferralRewardConfig`, `ReferralAnalytics`,
  `ReferralLeaderboardItem`, `ReferralRecord`, `ReferralRewardTransaction` +
  `ReferralRepository` + 6 use cases) → `data/` (`ReferralDatasource` /
  `SupabaseReferralDatasource` / `ReferralRepositoryImpl`) → `presentation/`
  (`ReferralCubit` / `ReferralState` + screen + tab widgets). Registered in
  `dashboard_di.dart`.

### Tabs & flows
1. **Overview** — 9 KPI cards (codes, total/pending referrals, first-order completions,
   rewards granted, conversion rate, referrer/referred/total rewards) + a status-breakdown
   donut and a reward-distribution ranked-bar chart.
2. **Reward Settings** — edit the `referral_rewards` config row: enable/disable (with a
   **confirmation dialog before disabling**), reward type (points/wallet/coupon/loyalty),
   referrer reward value, referred reward value, currency, coupon code (shown for coupon
   type). Form validation, saving state, success/error snackbars, helper text per field.
3. **Leaderboard** — `referral_leaderboard` view enriched with phone + code + per-referrer
   total/pending/last-date; search, sort (completed/total/rewards), medals for top 3,
   responsive table (desktop) / cards (mobile), pagination.
4. **Referral History** — `referrals` table with referrer/referred names resolved from
   `clients`; status chips, search, status + reward-status filters, date-range filter,
   details dialog, paginated table.
5. **Reward Transactions** — read-only `referral_reward_transactions` ledger with an
   "immutable" banner, role/search filters, paginated table.

### Supabase queries used (read-only except the config update)
- `referral_rewards` — `select … eq('id',1)` (read) / `update … eq('id',1)` (Reward Settings).
- `referral_analytics` (view) + `referral_codes.count()` + `referrals.select('status')`
  + `referral_reward_transactions.select('role, reward_value')` → Overview analytics.
- `referral_leaderboard` (view) + `referrals.select('referrer_id,status,created_at')`
  + batch `clients`/`referral_codes` lookups → Leaderboard.
- `referrals.select(…)` + batch `clients` name lookup → History.
- `referral_reward_transactions.select(…)` + batch `clients` name lookup → Transactions.

All reads degrade to empty/zero when a relation is missing (pre-migration), so the screen
never hard-crashes.

### Revenue-from-referrals (optional, not yet surfaced)
Join `referrals.first_order_id → operation_bookings` and sum order amounts where
`reward_status = 'granted'`. Add as an extra Overview KPI when needed.

## 10. Assumptions / required backend

- `loyalty_accounts.points_balance` is assumed for points-type rewards (wallet uses the
  confirmed `wallet_balance`). Adjust the column name in the trigger if different.
- “First paid order” = first `operation_bookings` row reaching `confirmed`/`approved`.
  Tune the status set in `grant_referral_reward` to match the real paid state.
- Universal/app links: `https://easyway.app/r/<code>` is a placeholder; configure the
  real deep link + store fallback for installs.
- Add an admin-only RLS write policy on `referral_rewards` for the dashboard role.

### Dashboard admin — RLS & schema notes
- **RLS for admin reads:** the migration's RLS restricts `referrals` /
  `referral_reward_transactions` rows to the *involved* users. The dashboard admin needs
  to read **all** rows, so add an admin policy (recommended), e.g.:
  ```sql
  create policy referrals_admin_read on public.referrals for select
    using (exists (select 1 from public.user_roles ur
                   where ur.user_id = auth.uid() and ur.role = 'dashboard_admin'));
  -- (repeat for referral_reward_transactions; and an UPDATE policy on referral_rewards)
  ```
  Otherwise run the dashboard with a service-role context. Until a policy exists, admin
  tables will read empty (handled gracefully).
- **Schema gaps (documented, not faked):** the spec's optional *minimum qualifying order
  amount* and *notes/description* fields are **not** columns on `referral_rewards`, so the
  Reward Settings form omits them. Add `min_order_amount numeric` / `notes text` to the
  table to surface them.
- **Reward unit:** values are shown with the config currency for wallet/coupon and as
  "points" otherwise; the per-role split in Overview comes from the transactions ledger.
