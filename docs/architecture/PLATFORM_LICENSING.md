# EWT Entitlement Platform — Licensing, Plans & Feature Management

Status: **implemented**, all six phases, 2026-08-06. `enforcement_mode = 'off'` — the subsystem
is live, resolves correctly, and enforces nothing until the owner moves the switch (Part 15).
Audited against the linked database and `main`..`cashback` on 2026-08-06.

> **Post-implementation verification, 2026-08-06.** Every Dart parser was re-checked against the
> *live* RPC payloads rather than fixtures, which found two integration defects that no test on
> either side could have caught alone. Both are fixed and both now have regression checks
> (sections L and M, suite now **62 checks**):
>
> - **`office_licenses` was not in the `supabase_realtime` publication.**
>   `EntitlementService` subscribes to it so a suspension or plan change reaches an open
>   console; the subscription connected, never errored and never fired.
>   `20260807150000_licensing_realtime.sql`.
> - **The two enforcement paths spelled the dependency refusal differently.**
>   `assert_feature()` raised `feature_dependency_blocked` (§7.2) while
>   `office_can_consume_for()` reported `dependency_blocked`, and the quota trigger re-raises
>   `reason` verbatim — so a trigger-path dependency block matched none of the six codes
>   `LicensingFailure.tryParse` knows and degraded to a generic error.
>   `20260807150100_licensing_refusal_code_parity.sql`.
>
> Also completed: §10.2's **locked-vs-hidden** sidebar rule, which `EntitlementContext.isLocked`
> was written for but nothing called — a purchasable, unowned module is now shown dimmed with a
> lock and opens the upgrade card instead of being hidden outright.

> **What shipped, and where the design was adapted.** Ten migrations
> (`20260807090000` … `20260807150100`), `supabase/tests/licensing_authority_regression.sql`
> (62 checks), `lib/apps/dashboard/core/entitlements/`, `features/platform_licensing/`,
> `features/office_billing/`, and the captain licensing gate. Four deviations, each for a
> reason recorded in the migration that makes it:
>
> 1. **Feature enforcement is triggers too, not only RPC guards.** §7.3 puts `assert_feature()`
>    inside gated RPCs. It ships and is the documented helper, but the *boundary* for `wallet`,
>    `cashback`, `refunds` and `passenger_packages` is a `BEFORE INSERT` trigger on the
>    underlying table — the same argument decision 3 makes for quotas, applied one step
>    further. It closes every path at once and needed no edit to functions that already work.
> 2. **Gate rows are seeded by the phase that creates the gate**, not by the catalog seed.
>    Seeding them up front would have made `enforcement_status` claim, on day one, that 34
>    features were enforced by code that did not exist yet — the exact drift decision 7 exists
>    to prevent. 17 features are `enforced` today; the rest are honestly `declared`.
> 3. **`licensing_hold` is maintained from four writers, not one.** §3.9 derives it from
>    licence status. `client_app` can also be withdrawn by a plan edit or an override with no
>    billing event at all, so the projection also fires on `office_feature_overrides` and
>    `platform_plan_features`. The read path stays the single cheap boolean the design wanted.
> 4. **`platform_license_audit(…)` is named `platform_audit_log(…)`**, so the RPC and the
>    table it reads do not share a name.
>
> **Not built, by design:** `promotions` and `loyalty` have no gate — `promo_codes` does not
> exist in this database and `loyalty_accounts` carries no `office_id`, so both stay
> `declared` rather than pretending. Plan *creation* from scratch, bulk override editing and
> plan comparison have RPCs (`platform_save_plan`, `platform_bulk_set_overrides`,
> `platform_compare_plans`) but no dedicated UI yet; the console builds on the ones it has.
>
> **The six questions in Part 18 are still open.** The seed answers them provisionally —
> 14-day trial on `professional` downgrading to `starter`, 7-day grace, `founder` grandfathered
> indefinitely, captains kept signing in — and every one of those is a console edit, not a
> migration.

> **What this is.** The architecture that turns EWT from "every office can do everything" into a multi-tenant
> SaaS platform where the platform owner decides, per office, what is available — by plan, by contract, by
> override, and by usage limit. It is deliberately *not* a package system: packages are one of four
> independent concepts, and the least important of them.

### Deliverable index

| # | Requested deliverable | Where |
|---|---|---|
| 1 | Architecture review | Part 0, Part 2 |
| 2 | Database design | Part 3 |
| 3 | Feature catalog schema | §3.1, §3.2, Part 6 |
| 4 | Package schema | §3.3, §3.4 |
| 5 | Subscription schema | §3.5 |
| 6 | Override schema | §3.6 |
| 7 | Usage tracking model | §3.7, Part 5 |
| 8 | Entitlement resolution architecture | Part 4 |
| 9 | Permission integration strategy | Part 7 |
| 10 | Dashboard UX (platform owner) | Part 9 |
| 11 | Office UX | Part 10 |
| 12 | Billing architecture | Part 12 |
| 13 | Security model | Part 13 |
| 14 | Migration strategy | Part 15 |
| 15 | Phased implementation plan | Part 16 |

---

## Part 0 — Verdict

**The platform is unusually well prepared for this.** Multi-office isolation, a platform-admin identity, an
office-scoped RLS model, a platform console, and a two-ring permission doctrine (server boundary + client UX)
all already exist and are sound. This design adds a **third orthogonal axis** on top of them rather than
replacing anything.

Eleven decisions in this document are load-bearing. Six of them contradict the obvious implementation:

| # | Decision | Why it matters |
|---|---|---|
| 1 | **Do not merge entitlements into the existing permission systems.** `may = role ∧ entitlement ∧ quota`, three independent predicates, ANDed. | 🔴 The prompt says "avoid duplicated permission systems". The correct reading is *compose*, not *merge*. Merged, the system can never answer "why can't I do this?" — the one question a licensing UI must always answer. (Part 7) |
| 2 | **Never use the words `package` or `subscription` in the licensing domain.** Both are already taken — twice each — by the passenger ride-bundle domain. Licensing uses `plan` and `license`. | 🔴 `packages`, `transport_packages`, `subscriptions`, `transport_subscriptions` all exist and mean *passenger fare bundles*. A third meaning of "subscription" would be an unrecoverable naming failure. (§1.2 F2) |
| 3 | **Quota enforcement must be database triggers, not RPC guards.** | 🔴 Drivers, vehicles and routes are written by **direct table INSERT** from the dashboard's Supabase client under RLS — there is no RPC to guard. Trips go through `office_create_trip`. A guard-only design leaves the three largest quota surfaces unenforced. (§1.2 F4) |
| 4 | **Suspension degrades to read-only; it never blacks out.** A suspended office keeps serving passengers who already hold tickets and keeps its captains driving. | 🔴 A licensing action that strands a bus mid-route is a safety incident, not a billing event. (§14.3) |
| 5 | **Limits gate creation, never existence.** Downgrading from 50 to 10 drivers deletes nothing; it blocks driver 11 onward until the office is under. | 🟠 The single most common unstated rule in limit systems, and the one that destroys customer trust when it is discovered by accident. (§5.4) |
| 6 | **Stock limits and flow limits are different things and must not share a mechanism.** "Current drivers" is a `COUNT` at check time; "trips this month" is an accumulating counter that a deletion does not refund. | 🟠 Conflating them either lets an office cycle rows to farm free quota, or makes deleting a driver permanently cost them a seat. (§5.2) |
| 7 | **Every catalog feature declares whether it is actually enforced.** `enforcement_status ∈ {enforced, declared}` plus a `platform_feature_gates` registry of exactly where. | 🟠 Half the features in the brief have no code to gate yet. Shipping flags that silently do nothing is how a licensing system loses credibility internally. It also answers the brief's "view where they are used" with real data. (§3.2) |
| 8 | **Enforcement ships disabled, behind a kill switch, after a shadow-mode period.** `platform_settings.enforcement_mode ∈ {off, shadow, enforcing}`. | 🟠 Three live offices, all currently unlimited. A rollout that changes behaviour on deploy day risks the entire customer base at once. (Part 15) |
| 9 | **The resolved entitlement document is a client-side *hint*, exactly like `isPlatformAdmin` already is.** | 🟢 The codebase has already written this doctrine down in [office_context.dart:44](lib/apps/dashboard/core/session/office_context.dart#L44). Reuse the sentence, reuse the discipline. |
| 10 | **One resolver, two verbs.** `office_feature(key)` returns a *value*; `office_can_consume(key, n)` returns a *write verdict*. Never one function doing both. | 🟢 Reading "is wallet on" and asking "may I add driver 11" have different costs, different callers and different failure modes. (Part 4) |
| 11 | **No resolution cache in V1**, with a named trigger for adding one. | 🟢 12 drivers, 9 routes, 34 bookings platform-wide. A cache now is invalidation risk bought with no performance won. (§4.6) |

**Nothing in the current system needs to be rewritten.** `office_can()`, `DashboardPermissions`,
`is_platform_admin()`, `current_office_id()` and the RLS model all survive unchanged and are *composed with*,
not replaced.

---

## Part 1 — Audit

### 1.1 What already exists and is reusable

| Capability | Where | Verdict |
|---|---|---|
| Office root entity + status axis | `offices` (`status`, `listing_status`) | **Reuse.** Licensing drives `listing_status`, does not duplicate it. |
| Platform-owner identity | `platform_admins` + `is_platform_admin()` ([20260721100000](supabase/migrations/20260721100000_multi_office_security_hardening.sql)) | **Reuse as-is.** The Super Admin already exists. No new identity concept. |
| Platform console UI | `features/platform_admin/`, nav item `مكاتب المنصة`, `platformOnly` gating in [dashboard_shell.dart:400](lib/apps/dashboard/core/routes/dashboard_shell.dart#L400) | **Extend.** The licensing console is new modules in the same nav group, not a new app. |
| Office identity resolution | `current_office_id()`, `office_role()`, `current_office_context()` | **Reuse.** The resolver reads `current_office_id()` and takes no office parameter. |
| Server-side capability boundary | `office_can(text)` ([20260806090100_wallet_core.sql:45](supabase/migrations/20260806090100_wallet_core.sql#L45)) | **Reuse pattern, do not extend this function.** It answers *who you are*. Entitlement is a sibling, not a branch. |
| Client-side permission set | `DashboardPermissions` / `DashboardPermission` | **Reuse.** Gains a parallel entitlement check at the same call sites. |
| Per-office limits as data | `office_wallet_policies` (typed columns, one row per office) | **Precedent acknowledged, shape rejected** — see §2.3. |
| Definer-helper RLS pattern | Established in [20260729090000_tracking_authority.sql](supabase/migrations/20260729090000_tracking_authority.sql) | **Reuse verbatim.** Entitlement helpers are `security definer`, `stable`, `set search_path`, granted to `authenticated`. |
| Machine-code → Arabic error mapping | `_messages` map in [supabase_wallet_datasource.dart:351](lib/apps/dashboard/features/wallet/data/datasources/supabase_wallet_datasource.dart#L351) | **Reuse verbatim.** Entitlement refusals are codes, translated at the datasource. |
| Platform ↔ office messaging | `operational_alerts`, `platform_broadcast_notification` | **Reuse.** Trial-expiry and suspension warnings are alerts, not a new channel. |
| DB regression suite | `supabase/tests/*_regression.sql` (12 files) | **Extend.** `licensing_authority_regression.sql` is a phase deliverable, not optional. |

### 1.2 Findings

**F1 — There is no entitlement system of any kind.** A full-repo search for `feature_flag`, `entitlement`,
`license` and equivalents returns nothing outside vehicle licence plates. Every office has every capability.
This is a greenfield subsystem, not a refactor — which is good news, because it means no legacy semantics
have to be preserved.

**F2 — The words `package` and `subscription` are already spoken for, twice each (critical).**

```
packages              ─┐  passenger fare bundles the Client app sells
transport_packages    ─┘  (documented in memory: "Subscription two worlds")
subscriptions         ─┐  a passenger's active ride bundle
transport_subscriptions┘  + subscription_ride_usage ledger
```

The dashboard nav already has **`الاشتراكات`** meaning *passenger subscriptions*, and the codebase already
carries a documented scar from having two subscription worlds. Introducing a third — an office's subscription
to EWT — under the same nouns would make `subscriptions` unreadable in SQL, in Dart, in the UI and in every
future conversation.

> **Naming law.** The licensing domain uses `plan` and `license`, prefixed `platform_` for catalog-side tables
> and `office_` for tenant-side tables. The strings `package` and `subscription` are **forbidden** in it, in
> both SQL and Dart. Arabic UI: passenger subs stay `الاشتراكات`; the office's own plan is `الباقة والفوترة`,
> and the platform-side console is `خطط المنصة`.

**F3 — Two permission systems exist, and they are correctly layered already.** `office_can()` is the
boundary; `DashboardPermissions` is UX. The wallet migration says so in a comment. This is exactly the
doctrine the entitlement system needs, so it inherits it rather than inventing one.

**F4 — Write paths are inconsistent, and this decides the enforcement design (critical).**

| Resource | Write path | Guardable by RPC? |
|---|---|---|
| Trips | `office_create_trip()` RPC | ✅ |
| Wallet / refunds | `office_wallet_*`, `office_refund_*` RPCs | ✅ |
| Bookings (approve) | `office_approve_booking()` RPC | ✅ |
| **Drivers** | `.from('drivers').insert()` — [supabase_fleet_datasource.dart:271](lib/apps/dashboard/features/fleet/data/datasources/supabase_fleet_datasource.dart#L271) | ❌ **RLS only** |
| **Vehicles** | `.from('vehicles').insert()` — [supabase_fleet_datasource.dart:383](lib/apps/dashboard/features/fleet/data/datasources/supabase_fleet_datasource.dart#L383) | ❌ **RLS only** |
| **Routes** | direct insert | ❌ **RLS only** |
| **Operators** | direct insert into `office_users` | ❌ **RLS only** |

The three biggest quota surfaces in the brief — max drivers, max vehicles, max routes — have **no RPC to put a
guard in**. The dashboard is a Supabase client holding the operator's JWT; it can issue any REST call RLS
permits. Therefore quota enforcement is `BEFORE INSERT` triggers, and RPC guards are a convenience layer on
top for better error messages.

**F5 — Offices can create themselves.** [`office_self_signup`](supabase/migrations/20260721160000_office_self_signup.sql)
lets an operator register with no platform admin in the loop, landing `status=active` + `listing_status=draft`.
So an office can exist with **no license row at all**. The resolver must therefore have a defined answer for
"no license" — it is not an error state, it is the **default plan**, and it is where the trial attaches.

**F6 — `office_is_listed()` is already the single marketplace predicate.** Every anon-facing surface was swept
onto it in [20260721140000 §3](supabase/migrations/20260721140000_platform_office_onboarding.sql). Gating the
Client app by entitlement therefore costs *one predicate change*, not a sweep. The precedent that this sweep
works is in the repo.

**F7 — No general audit log exists.** `wallet_transactions.performed_by` is the only actor-attributed record
on the platform. The licensing audit log will be the first. It should be shaped so it *could* become the
platform-wide audit log, but must not try to be one now.

**F8 — Financial rows are reachable by cascade.** Carried forward from the wallet audit (F1 there):
`auth.users → clients` is `ON DELETE CASCADE`. Every billing table added here uses `ON DELETE RESTRICT` on
office and actor references. An invoice must not be deletable by removing a user.

**F9 — `request.headers` is unavailable off the PostgREST path.** Verified: `current_setting('request.headers', true)`
returns NULL on a direct connection. It *is* set for PostgREST calls. So audit `ip` is nullable by design,
populated best-effort, and **never** a security control — it is spoofable by anything that can set
`X-Forwarded-For` upstream of the edge.

**F10 — The platform is pre-scale.** 3 offices, 3 operators, 12 drivers, 6 vehicles, 9 routes, 12 trips,
34 bookings, 21 clients. Migration cost is effectively zero and there is no performance problem to solve.
This design optimises for being *correct and extensible*, and says so instead of pretending otherwise.

---

## Part 2 — Architecture review: the decisions

### 2.1 Four concepts, and why the brief is right to separate them

```
       ┌─────────────────────┐
       │  Feature Catalog    │   what the platform CAN sell        (platform-owned, versionless)
       └──────────┬──────────┘
                  │ referenced by key
       ┌──────────▼──────────┐
       │  Plans              │   named bundles of default values    (platform-owned, editable live)
       └──────────┬──────────┘
                  │ chosen by
       ┌──────────▼──────────┐
       │  Office License     │   this office's commercial state     (platform-owned, per office)
       └──────────┬──────────┘
                  │ selectively contradicted by
       ┌──────────▼──────────┐
       │  Overrides          │   per-office, per-feature exceptions (platform-owned, highest priority)
       └─────────────────────┘
```

The separation earns its keep the first time a salesperson promises one office 50 drivers on a Starter plan.
Coupled, that is a new plan (`starter-with-50-drivers`) and a plan table that grows one row per negotiation
until nobody can say what "Starter" means. Decoupled, it is one override row with a reason and an expiry.

**A plan is a template with no behaviour.** It cannot contain logic, conditions, or code. Anything a plan
"does" is a value the resolver reads. This is what makes plans safe to edit live.

### 2.2 Why a fifth concept is *not* added

Rejected: an `office_addons` table in V1. Add-ons are a real future need, but they are structurally identical
to overrides with a price attached. Adding them now means two write paths into the same resolution rung
before there is any billing to attach them to. §14.1 shows the exact additive migration when they arrive.

### 2.3 Why not typed columns, given `office_wallet_policies` sets that precedent

`office_wallet_policies` has one row per office with `max_single_credit`, `max_single_debit`, … as real
numeric columns. It is the right shape *there*: the wallet has a fixed, small, known set of policies that
change only when the wallet's own design changes.

It is the wrong shape here, for one reason: the brief's central requirement is **"support adding future
features without schema redesign."** A typed-column table means every new feature is a migration, a Dart model
change, a mapper change and a UI change. Thirty features today, sixty in two years, and each one costs a
deploy.

So: **key → jsonb value**, with the type safety moved *into the catalog* rather than given up:

- `platform_features.value_type` declares the shape (`boolean` | `limit` | `enum` | `config`).
- `platform_features.value_schema` (jsonb) constrains it further (`allowed_values`, `min`, `max`).
- `platform_validate_feature_value(key, value)` is called by a `BEFORE INSERT OR UPDATE` trigger on **every**
  table that stores a feature value — plan values and overrides alike.

It has to be a trigger, not a `CHECK` constraint, because validation requires a lookup in `platform_features`
and `CHECK` cannot subquery. Stated plainly so nobody "fixes" it into a constraint later.

**The cost, stated honestly:** jsonb values are not type-checked by Postgres, and a Dart model reading them
does `switch` on `value_type`. That is real ceremony. It buys the ability to add a feature with one `INSERT`
and zero deploys, which is the requirement.

### 2.4 The "unlimited" representation

A limit value is **an integer, or the JSON string `"unlimited"`**. Not `-1`, not SQL `NULL`, not JSON `null`.

- `-1` is a magic number that arithmetic silently accepts (`used < -1` is false — a "fix" that becomes a
  denial of service).
- SQL `NULL` is indistinguishable from "no row", which is a different rung of the ladder.
- JSON `null` is distinguishable from SQL NULL in Postgres, but not in Dart's `Map<String, dynamic>`, where
  both arrive as `null`.

`"unlimited"` survives every layer unambiguously and reads correctly in a UI that dumps the raw value.

### 2.5 What "immediately affects all subscribed offices" means, and its escape hatch

The brief requires plan edits to propagate live. The resolver reads plan values at resolution time, so this is
automatic — there is no per-office copy to keep in sync.

But every SaaS that raises prices needs grandfathering within its first year. So:

- Every plan edit **snapshots the previous state** into `platform_plan_revisions` (append-only). This gives
  compare, audit and rollback.
- `office_licenses.pinned_revision_id` (nullable, **NULL for every office in V1**) freezes one office to a
  historical revision.

Revisions are *history plus an escape hatch*, not parallel live variants. There is deliberately no UI for
pinning in V1 — the column exists so grandfathering is later a UI task, not a migration.

### 2.6 Where the entitlement system must not reach

Three explicit non-goals, because each is a plausible mistake:

1. **It does not decide passenger pricing.** Ticket fares and package tiers belong to the office
   ([memory: trip pricing model](docs/architecture/) — one fare, expanded). The platform licenses *capability*,
   never the office's own commercial terms.
2. **It does not become the office's internal role system.** An office admin configuring who on *their* team
   may issue refunds is `office_can()`'s job. Entitlement answers only "did this office buy refunds at all".
3. **It does not collect money from passengers.** `office_payment_configs` is how an *office* collects from
   *riders*. The platform collecting from offices is the mirror image and gets its own table (§12). Reusing
   `office_payment_configs` would put EWT's merchant credentials in a table whose entire security model is
   "the office's own secrets".

---

## Part 3 — Database design

Nine tables. All `platform_`-prefixed (catalog side) or `office_`-prefixed (tenant side). All new; none
modify an existing table except one nullable column on `offices` (§3.9).

> Presented in reading order, not creation order: `platform_features` below references
> `platform_feature_categories`, which appears in §3.2. The migration creates categories first.

### 3.1 `platform_features` — the catalog

```sql
create table public.platform_features (
  key                text primary key
                       check (key ~ '^[a-z][a-z0-9_]{2,63}$'),

  name_ar            text not null,
  name_en            text not null,
  description_ar     text not null default '',

  -- Grouping for the console. Open text against a lookup table rather than a CHECK,
  -- so a new category is data. (§3.2 holds the categories.)
  category_key       text not null references public.platform_feature_categories(key),

  value_type         text not null
                       check (value_type in ('boolean', 'limit', 'enum', 'config')),

  -- Shape constraint beyond value_type. enum: {"allowed": ["basic","pro"]}.
  -- limit: {"min": 0, "max": 100000}. config: {"kind": "url"} etc.
  value_schema       jsonb not null default '{}'::jsonb,

  -- The bottom rung of the resolution ladder. Applies when no override, no plan
  -- value and no platform rule produced one. MUST be the safe/restrictive answer.
  default_value      jsonb not null,

  -- Lifecycle of the FEATURE ITSELF, distinct from whether an office has it.
  --   active     — sellable, resolvable
  --   hidden     — resolvable, not shown in the plan builder (internal/beta)
  --   deprecated — resolvable, warns in the console, cannot be added to new plans
  --   disabled   — platform kill switch: resolves to default_value for EVERYONE
  status             text not null default 'active'
                       check (status in ('active','hidden','deprecated','disabled')),

  -- Is the flag real, or a promise? (§0 decision 7.)
  --   enforced — at least one row in platform_feature_gates
  --   declared — catalogued, sellable in principle, NOT yet gated by any code
  enforcement_status text not null default 'declared'
                       check (enforcement_status in ('enforced','declared')),

  -- Metering discriminator. NULL for non-limit features. (§5.2 — this is the
  -- stock/flow distinction, and getting it wrong is the classic quota bug.)
  --   stock — a COUNT of live rows; deleting a row returns quota
  --   flow  — an accumulating counter per period; deletion does NOT refund
  meter_kind         text check (meter_kind in ('stock','flow')),
  meter_period       text check (meter_period in ('lifetime','month')),
  unit_ar            text not null default '',

  sort_order         int  not null default 100,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  -- A limit feature must declare how it is metered; a non-limit must not.
  constraint platform_features_meter_coherent check (
    (value_type = 'limit' and meter_kind is not null and meter_period is not null)
    or (value_type <> 'limit' and meter_kind is null and meter_period is null)
  )
);
```

`key` is the primary key, not a surrogate uuid. Feature keys appear in trigger bodies, RPC guards, Dart
constants and audit rows; a uuid there would be unreadable in every one of those places, and the key is
already immutable and unique.

### 3.2 Supporting catalog tables

```sql
-- Categories are data so the console can grow sections without a deploy.
create table public.platform_feature_categories (
  key         text primary key,
  name_ar     text not null,
  icon_key    text not null default '',
  sort_order  int  not null default 100
);

-- Dependencies: a separate table, not an array column, so it is joinable,
-- FK-enforced, and can carry a minimum value rather than just "requires".
create table public.platform_feature_dependencies (
  feature_key   text not null references public.platform_features(key) on delete cascade,
  requires_key  text not null references public.platform_features(key) on delete restrict,

  -- For non-boolean prerequisites: analytics_ai requires analytics_level >= 'advanced'.
  -- NULL means "requires truthy".
  min_value     jsonb,

  primary key (feature_key, requires_key),
  constraint no_self_dependency check (feature_key <> requires_key)
);

-- "View where they are used" (brief) as real data rather than a doc comment.
-- Populated by the migration that adds each gate; read by the console.
create table public.platform_feature_gates (
  id           bigserial primary key,
  feature_key  text not null references public.platform_features(key) on delete cascade,
  gate_kind    text not null check (gate_kind in ('trigger','rpc','rls','view','ui')),
  gate_ref     text not null,          -- 'trg_quota_drivers', 'office_wallet_cashback', …
  note         text not null default '',
  unique (feature_key, gate_kind, gate_ref)
);
```

A trigger on `platform_feature_gates` maintains `platform_features.enforcement_status`, so the console's
"enforced / declared" badge can never drift from reality.

Cycle prevention for dependencies is a `BEFORE INSERT` trigger doing a recursive walk. Cheap (the graph is
tens of edges) and prevents a resolver infinite loop, which would be a platform-wide outage.

### 3.3 `platform_plans`

```sql
create table public.platform_plans (
  id             uuid primary key default gen_random_uuid(),

  -- Stable family identifier. Survives renames; referenced by seeds and tests.
  key            text not null unique
                   check (key ~ '^[a-z][a-z0-9_-]{2,47}$'),

  name_ar        text not null,
  name_en        text not null,
  tagline_ar     text not null default '',

  status         text not null default 'draft'
                   check (status in ('draft','active','archived')),

  -- Can an office self-select this at signup, or is it assignment-only?
  -- Enterprise and the incumbent Founder plan are is_public = false.
  is_public      boolean not null default false,

  -- Commercial terms. Nullable because 'custom' and 'free' cycles have no list price.
  price_monthly  numeric(12,2) check (price_monthly >= 0),
  price_yearly   numeric(12,2) check (price_yearly  >= 0),
  currency       text not null default 'EGP',

  -- Trial length offered when an office lands on this plan. 0 = no trial.
  trial_days     int not null default 0 check (trial_days between 0 and 365),

  -- Where an office falls when its license lapses. Self-reference, nullable to
  -- terminate the chain. Every plan except the fallback should set this.
  downgrade_to_plan_id uuid references public.platform_plans(id) on delete restrict,

  sort_order     int not null default 100,
  notes          text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- The plan's default configuration. Absence of a row = fall through to catalog default.
create table public.platform_plan_features (
  plan_id      uuid not null references public.platform_plans(id) on delete cascade,
  feature_key  text not null references public.platform_features(key) on delete restrict,
  value        jsonb not null,
  primary key (plan_id, feature_key)
);

-- Append-only snapshot of a plan's full state before each edit. Compare / audit /
-- rollback / grandfathering, all from one place.
create table public.platform_plan_revisions (
  id          uuid primary key default gen_random_uuid(),
  plan_id     uuid not null references public.platform_plans(id) on delete restrict,
  revision    int  not null,
  snapshot    jsonb not null,          -- {plan: {...}, features: {key: value, …}}
  changed_by  uuid references auth.users(id) on delete set null,
  reason      text not null default '',
  created_at  timestamptz not null default now(),
  unique (plan_id, revision)
);
```

`on delete restrict` on `platform_plan_features.feature_key`: deleting a catalogued feature that plans
reference must fail loudly. Deprecate features; never delete them.

### 3.4 Plan operations, as data

| Brief requirement | Mechanism |
|---|---|
| Create Package | `INSERT` into `platform_plans` + rows in `platform_plan_features`. |
| Duplicate Package | `platform_clone_plan(p_plan_id, p_new_key, p_new_name)` — copies both tables in one transaction. |
| Archive Package | `status = 'archived'`. Existing licenses keep resolving; no new office can select it. |
| Version Package | `platform_plan_revisions`, written automatically by the plan-write RPC. |
| Compare Packages | `platform_compare_plans(uuid[])` → jsonb matrix, one row per feature, one column per plan. |
| Preview Effective Permissions | `platform_preview_plan(p_plan_id)` → the resolver run against a hypothetical office on that plan with no overrides. **The same resolver**, not a reimplementation — otherwise the preview lies. |

### 3.5 `office_licenses` — the office's commercial state

```sql
create table public.office_licenses (
  -- PK, not just FK+unique. "Every office has ONE active subscription" becomes a
  -- database fact rather than a convention nobody can enforce later.
  office_id       uuid primary key references public.offices(id) on delete restrict,

  plan_id         uuid not null references public.platform_plans(id) on delete restrict,

  -- Freeze to a historical plan revision. NULL = follow the live plan (§2.5).
  -- Inert in V1: no UI writes it.
  pinned_revision_id uuid references public.platform_plan_revisions(id) on delete restrict,

  -- The lifecycle axis. See §14.3 for the state machine and what each state
  -- actually does to the office.
  status          text not null default 'trialing'
                    check (status in ('trialing','active','past_due','grace',
                                      'suspended','cancelled','expired')),

  billing_cycle   text not null default 'monthly'
                    check (billing_cycle in ('monthly','yearly','custom','free')),

  -- Negotiated price. NULL = use the plan's list price for the cycle.
  price_override  numeric(12,2) check (price_override >= 0),
  currency        text not null default 'EGP',

  trial_ends_at   timestamptz,
  period_start    timestamptz not null default now(),
  period_end      timestamptz,          -- NULL for 'custom' / perpetual contracts
  grace_ends_at   timestamptz,
  auto_renew      boolean not null default true,

  -- Enterprise contract metadata. Free text on purpose: a contract reference and a
  -- salesperson's note are not a schema.
  contract_ref    text,
  notes           text not null default '',

  suspended_at    timestamptz,
  suspended_reason text,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  -- A trial must say when it ends; a non-trial must not pretend to be one.
  constraint license_trial_coherent check (
    (status = 'trialing') = (trial_ends_at is not null)
  )
);
```

`on delete restrict` on `office_id` (F8): an office with billing history is not deletable by cascade.

**There is deliberately no `office_licenses` history table.** Every change is an audit row (§3.8) plus, where
money is involved, an invoice (§12). A third history table would be a third version of the truth.

### 3.6 `office_feature_overrides`

```sql
create table public.office_feature_overrides (
  office_id    uuid not null references public.offices(id) on delete restrict,
  feature_key  text not null references public.platform_features(key) on delete restrict,

  value        jsonb not null,

  -- Mandatory. An override with no stated reason is an unexplained exception that
  -- nobody will dare remove in two years. This is the cheapest possible control
  -- against override sprawl, and it is why the column is NOT NULL with a length check.
  reason       text not null check (length(trim(reason)) >= 8),

  -- Temporary grants: a three-month sales concession, a trial extension, a goodwill
  -- gesture. NULL = permanent. Expired overrides stop applying but are NOT deleted —
  -- the row is the record that the concession happened.
  expires_at   timestamptz,

  created_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  primary key (office_id, feature_key)
);
```

One row per (office, feature): an office cannot have two contradictory overrides for the same feature, which
removes an entire class of "which one wins" bug before it exists.

**Overrides can both grant and revoke.** The brief's examples include *disabling* API access on Enterprise.
The resolver treats an override as the authoritative value regardless of direction — that is what "highest
priority" means, and the console shows the direction as ▲ upgrade / ▼ restriction.

### 3.7 `office_usage_counters` — flow meters only

```sql
create table public.office_usage_counters (
  office_id   uuid not null references public.offices(id) on delete restrict,
  metric_key  text not null references public.platform_features(key) on delete restrict,

  -- 'lifetime', or 'YYYY-MM' in the office's billing timezone.
  period_key  text not null,

  used_value  bigint not null default 0 check (used_value >= 0),
  updated_at  timestamptz not null default now(),

  primary key (office_id, metric_key, period_key)
);
```

**Stock meters are not in this table.** "Current drivers" is `select count(*) from drivers where office_id = …`,
computed at check time. Storing it would create a cache that drifts the first time a row is deleted outside
the app, and self-healing beats reconciliation. §5.2 is the full argument.

Flow meters (`trips_per_month`, `api_calls`, `exports`) are incremented by the same trigger that enforces
them, in the same transaction as the row they count.

### 3.8 `platform_license_audit`

```sql
create table public.platform_license_audit (
  id           bigserial primary key,

  -- The office affected. NULL for catalog/plan changes, which are platform-wide.
  office_id    uuid references public.offices(id) on delete restrict,

  entity_type  text not null
                 check (entity_type in ('feature','category','plan','plan_feature',
                                        'license','override','invoice','usage','settings')),
  entity_ref   text not null,       -- plan key, feature key, invoice id …

  action       text not null
                 check (action in ('created','updated','deleted','enabled','disabled',
                                   'plan_changed','limit_changed','override_created',
                                   'override_removed','trial_started','trial_extended',
                                   'renewed','suspended','restored','cancelled')),

  old_value    jsonb,
  new_value    jsonb,

  actor_id     uuid references auth.users(id) on delete set null,
  actor_label  text not null default '',   -- denormalised: survives actor deletion
  reason       text not null default '',

  -- Best-effort, PostgREST path only (F9). Never a security control.
  ip           inet,
  user_agent   text,

  created_at   timestamptz not null default now()
);

create index on public.platform_license_audit (office_id, created_at desc);
create index on public.platform_license_audit (entity_type, entity_ref, created_at desc);
```

Written by triggers on every licensing table, not by application code. An audit log a caller can forget to
write is not an audit log.

Immutability: `revoke update, delete` from all API roles, plus a `BEFORE UPDATE OR DELETE` trigger raising
`audit_is_append_only` — the same belt-and-braces the wallet ledger uses.

### 3.9 The one change to an existing table

```sql
alter table public.offices
  add column if not exists licensing_hold text
    check (licensing_hold in ('none','read_only','delisted'));
```

**Why not derive it from `office_licenses.status`?** Because `office_is_listed()` is called from RLS policies
on anon-facing surfaces, on the hottest read path in the Client app. Joining through `office_licenses` →
`platform_plans` → `platform_plan_features` inside every marketplace policy is a real cost for an answer that
changes maybe twice a year per office.

So the licensing state machine **projects** its consequence onto one denormalised column, maintained by a
trigger on `office_licenses`. `office_is_listed()` gains one cheap term:

```sql
where status = 'active'
  and listing_status = 'listed'
  and coalesce(licensing_hold, 'none') <> 'delisted'
```

One column, one trigger, one predicate — versus a three-table join in every anon policy. Stated here because
it is the one place this design deliberately denormalises, and the reason must survive.

---

## Part 4 — Entitlement resolution architecture

### 4.1 The ladder

`office_feature(p_office_id, p_key)` walks rungs top to bottom. **First match wins for the value.**

| # | Rung | Wins when | Yields |
|---|---|---|---|
| 0 | **Kill switch** | `platform_features.status = 'disabled'` | `default_value` (platform-wide off switch) |
| 1 | **License hold** | license status ∈ {`suspended`,`cancelled`,`expired`} | the **restricted value** — see §4.3 |
| 2 | **Override** | a non-expired row in `office_feature_overrides` | its `value` |
| 3 | **Plan** | a row in `platform_plan_features` for the effective plan | its `value` |
| 4 | **Catalog default** | always | `platform_features.default_value` |

Then, **independently and only ever reducing**:

| | Gate | Effect |
|---|---|---|
| 5 | **Dependencies** | if any prerequisite resolves falsey, a boolean collapses to `false`; a limit collapses to `0`; an enum collapses to its lowest allowed value. Never raises. |
| 6 | **Usage** | does **not** change the value. Produces a separate verdict, consumed only by write paths (§4.4). |

> **Dependencies can only subtract.** If cashback requires wallet and wallet is off, cashback is off — even if
> an explicit override says `true`. The override is honoured at rung 2 and then defeated at gate 5, and the
> resolver reports both facts (`source: 'override'`, `blocked_by: 'wallet'`) so the console can say *exactly*
> that instead of appearing to ignore the operator's override.

### 4.2 Return shape

```jsonc
{
  "key":        "cashback",
  "value":      false,
  "value_type": "boolean",
  "source":     "override",        // kill_switch | license_hold | override | plan | default
  "blocked_by": "wallet",          // null unless a dependency defeated it
  "plan_key":   "professional",
  "license_status": "active",
  "expires_at": null               // override expiry, when source = override
}
```

The `source` field is not decoration. It is what makes the console able to answer "why does this office have
this?" in one click, and what makes a support conversation two minutes instead of twenty.

### 4.3 Rung 1: what suspension actually does

**The restricted value is not "everything off".** A suspended office must still be able to:

- sign in and see *why* it is suspended and what to pay,
- honour tickets passengers already bought,
- let its captains complete trips already in progress,
- read its own historical data.

It must **not** be able to create new sellable inventory. So the restricted value is computed from a
designated **fallback plan** (`platform_settings.restricted_plan_id`), not hardcoded:

| Capability class | Suspended |
|---|---|
| Read own data, reports, finance | ✅ allowed |
| Live tracking of in-flight trips | ✅ allowed |
| Captain app sign-in and trip completion | ✅ allowed |
| Client marketplace listing | ❌ `licensing_hold = 'delisted'` |
| Create trips / routes / drivers / vehicles | ❌ blocked |
| Wallet credits, cashback, refund approval | ❌ blocked (money out, while money in is disputed) |
| Refund *requests* | ✅ allowed — a passenger's claim must not be blocked by the office's billing dispute |

This is decision 4 in Part 0, and it is the decision most likely to be argued down for being "soft". It should
not be: the alternative is a licensing action that strands a passenger, and no billing outcome justifies that.

### 4.4 The two verbs

```sql
-- VERB 1 — the value. Cheap, STABLE, safe in RLS, safe in a tight loop.
public.office_feature(p_key text) returns jsonb            -- caller's office
public.office_feature_value(p_key text) returns jsonb      -- just the value, for guards
public.office_has(p_key text) returns boolean              -- boolean sugar, the 90% case

-- VERB 2 — the write verdict. Counts usage. Only ever called at the moment of creation.
public.office_can_consume(p_key text, p_amount bigint default 1) returns jsonb
```

`office_can_consume` returns:

```jsonc
{
  "allowed":   false,
  "limit":     10,
  "used":      10,
  "remaining": 0,
  "unlimited": false,
  "reason":    "quota_exceeded",   // or feature_disabled | dependency_blocked | license_suspended
  "feature":   "max_drivers",
  "plan_key":  "starter"
}
```

Two functions rather than one overloaded call, because reading "is wallet on" for a nav item and asking "may I
create driver 11" have different costs (one does a `COUNT`), different callers (UI vs trigger) and different
failure modes.

### 4.5 The document RPC

```sql
public.office_entitlements() returns jsonb
```

One round-trip returning every feature resolved for the caller's office, plus current usage, plus the license
summary. Called once at sign-in, exactly like `current_office_context()`:

```jsonc
{
  "license": { "plan_key": "professional", "plan_name_ar": "الاحترافية",
               "status": "active", "trial_ends_at": null, "period_end": "2026-09-06T…",
               "grace_ends_at": null, "auto_renew": true },
  "features": {
    "wallet":       { "value": true,  "source": "plan" },
    "cashback":     { "value": false, "source": "override", "blocked_by": null, "expires_at": null },
    "max_drivers":  { "value": 25,    "source": "plan", "used": 12, "remaining": 13 },
    "report_level": { "value": "professional", "source": "plan" }
  },
  "resolved_at": "2026-08-06T…"
}
```

Usage is embedded for `limit` features so the office UX can show "12 / 25 drivers" without a second call.

### 4.6 Performance, and the named trigger for revisiting it

**No cache in V1.** Justification, with numbers (F10): 12 drivers, 9 routes, 12 trips platform-wide. Quota
triggers fire on creation events measured in *tens per day*. `office_entitlements()` runs once per sign-in.
A `STABLE` function is re-planned once per statement and Postgres caches within it.

**The named trigger for adding a cache:** the first time a `limit` feature guards the **booking** path.
Bookings are passenger-driven and the only high-rate write in the system. If `max_bookings_per_month` is ever
sold, add `office_entitlements_resolved` (a materialised row per office, invalidated by triggers on the five
licensing tables) *at that point* — and note the second problem it brings: a flow counter is a single hot row
per office, so a booking-rate meter serialises concurrent bookings for that office. Mitigation is to meter
only what is billed, not everything that can be counted.

---

## Part 5 — Usage & limits

### 5.1 The catalogue of meters

| Feature key | Meter | Source of truth | Enforcement point |
|---|---|---|---|
| `max_drivers` | stock / lifetime | `count(drivers where office_id, status='active')` | `BEFORE INSERT` on `drivers` |
| `max_vehicles` | stock | `count(vehicles)` | `BEFORE INSERT` on `vehicles` |
| `max_routes` | stock | `count(operation_routes)` | `BEFORE INSERT` on `operation_routes` |
| `max_admin_users` | stock | `count(office_users where status='active')` | `BEFORE INSERT` on `office_users` |
| `max_captains` | stock | `count(drivers where user_id is not null)` | captain-request approval RPC |
| `max_live_trips` | stock | `count(operation_trips where status in ('in_progress',…))` | `office_update_trip_status` |
| `max_trips_per_month` | **flow** / month | `office_usage_counters` | `office_create_trip` + `BEFORE INSERT` on `operation_trips` |
| `max_exports_per_month` | **flow** | counter | export RPC |
| `max_api_calls_per_month` | **flow** | counter | (declared — no API surface yet) |
| `max_storage_mb` | stock | Storage bucket sum for the office prefix | logo/document upload |
| `max_branches` | stock | (declared — no branch entity yet) | — |

### 5.2 Why stock and flow cannot share a mechanism

**Stock** = "how many exist right now". Delete a driver, get the seat back. Recomputable from the base table,
therefore self-healing: a row deleted by a migration, a cascade or a manual `psql` session cannot corrupt it.

**Flow** = "how many happened this period". Delete a trip, the quota is *not* refunded — otherwise an office
on a 100-trips plan runs 1,000 trips by deleting each one after it completes. Not recomputable, because the
evidence is intentionally destructible.

Conflating them produces one of two failures, both silent:
- Counting stock with a counter → deleting a driver permanently costs a seat, and the office is throttled with
  no visible cause.
- Counting flow with a `COUNT` → free unlimited usage via delete-and-recreate.

Hence `platform_features.meter_kind`, `NOT NULL` for every limit, enforced by the coherence CHECK in §3.1.

**Honest cost:** stock meters need a `CASE` in `office_usage_stock(p_key)` mapping key → count query. Adding a
metered stock feature therefore touches one function. That is a real limit on "no schema redesign" and it is
named rather than hidden. It is accepted because the alternative — storing count SQL as data and `EXECUTE`ing
it — is a SQL-injection surface owned by the console's own UI.

### 5.3 The enforcement trigger

One generic function, attached per table with a parameter:

```sql
create function public.enforce_office_quota() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_key     text := tg_argv[0];
  v_mode    text := public.platform_enforcement_mode();
  v_verdict jsonb;
begin
  if v_mode = 'off' then return new; end if;

  v_verdict := public.office_can_consume_for(new.office_id, v_key, 1);

  if not (v_verdict->>'allowed')::boolean then
    if v_mode = 'shadow' then
      insert into public.platform_quota_violations(office_id, feature_key, verdict, table_name)
        values (new.office_id, v_key, v_verdict, tg_table_name);
      return new;                      -- observed, not blocked
    end if;
    raise exception 'quota_exceeded'
      using detail = v_verdict::text, errcode = 'check_violation';
  end if;

  return new;
end $$;

create trigger trg_quota_drivers before insert on public.drivers
  for each row execute function public.enforce_office_quota('max_drivers');
```

`office_can_consume_for(office_id, …)` takes an explicit office because a trigger runs in the row's context,
not the caller's. `office_can_consume()` (no office arg) is the thin wrapper for RPC callers, and it is the
only one granted to `authenticated` — the explicit-office variant is `revoke`d from all API roles so it cannot
be used to probe another office's limits.

**`raise exception … using detail =` carries the full verdict jsonb to the client**, so the Flutter layer can
render "12 of 12 drivers used on الأساسية" rather than "quota_exceeded". This is the mechanism behind the
upgrade UX in §10.3.

### 5.4 Limits gate creation, never existence

Downgrading an office from 50 drivers to 10 **deletes nothing and disables nothing**. It blocks the next
`INSERT` until the office is at or under 10. Existing drivers keep driving, keep appearing in reports, keep
being assignable.

The console shows this honestly as an **over-limit** state (`used > limit`) with an explicit "over by 40"
badge, rather than pretending the office is compliant. That is a real state, it should be visible, and it must
never be resolved by the platform deleting a tenant's operational data.

The same rule for `office_users`: reducing `max_admin_users` never disables an existing operator. Locking a
customer out of their own dashboard as a *billing* action is not a downgrade, it is a lockout.

### 5.5 Flow counter reset

`period_key = to_char(now() at time zone <office tz>, 'YYYY-MM')`. Rows are never reset or deleted — a new
month is a new row. That makes usage history free (the brief's "Usage" console section) and removes the entire
class of "the reset job didn't run" bug. Timezone comes from `office_wallet_policies.timezone`, which already
exists and already means exactly this.

---

## Part 6 — Feature catalog (seed)

Every feature from the brief, mapped to its real gate in *this* repo. `E` = enforced at ship, `D` = declared
(catalogued and sellable in principle, no code to gate yet).

### Operations — `operations`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `trips` | boolean | `true` | trips module + `office_create_trip` | E |
| `routes` | boolean | `true` | routes module | E |
| `max_routes` | limit/stock | `"unlimited"` | trigger on `operation_routes` | E |
| `max_trips_per_month` | limit/flow | `"unlimited"` | `office_create_trip` + trigger | E |
| `max_live_trips` | limit/stock | `"unlimited"` | `office_update_trip_status` | E |
| `live_tracking` | boolean | `true` | `trip_live_locations` policies, live-ops module | E |
| `live_ops_center` | boolean | `true` | `/live-ops` nav + module | E |

### Fleet — `fleet`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `drivers` | boolean | `true` | fleet module | E |
| `max_drivers` | limit/stock | `"unlimited"` | trigger on `drivers` | E |
| `max_vehicles` | limit/stock | `"unlimited"` | trigger on `vehicles` | E |
| `max_captains` | limit/stock | `"unlimited"` | captain-request approval | E |
| `driver_app` | boolean | `true` | `captain_session_context`, `resolve_captain_login` | E |
| `bulk_import` | boolean | `false` | fleet import surface | D |

### Sales & customers — `sales`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `bookings` | boolean | `true` | bookings module | E |
| `client_app` | boolean | `true` | `office_is_listed()` (§3.9) | E |
| `passenger_packages` | boolean | `true` | `packages` / `transport_packages` surfaces | E |
| `qr_tickets` | boolean | `false` | — | D |

### Money — `finance`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `finance` | boolean | `true` | finance module + report views | E |
| `wallet` | boolean | `false` | every `office_wallet_*` RPC + nav | E |
| `refunds` | boolean | `false` | `office_refund_create` / `office_refund_decide` | E |
| `cashback` | boolean | `false` | `office_wallet_cashback` — **requires `wallet`** | E |
| `promotions` | boolean | `false` | `promo_codes` | E |
| `loyalty` | boolean | `false` | `loyalty_*` | E |
| `referrals` | boolean | `true` | referrals module | E |

### Insight — `insight`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `reports` | boolean | `true` | reports module | E |
| `report_level` | enum `basic\|professional\|enterprise` | `basic` | report surface breadth | E |
| `analytics_level` | enum `basic\|advanced\|ai` | `basic` | owner-overview breadth — `ai` **requires** `advanced` | E |
| `export_pdf` | boolean | `false` | export action (`pdf`/`printing` deps present) | E |
| `export_excel` | boolean | `false` | export action (`excel`/`csv` deps present) | E |
| `max_exports_per_month` | limit/flow | `"unlimited"` | export RPC | E |

### Engagement — `engagement`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `notifications` | boolean | `true` | `operational_alerts` | E |
| `push_notifications` | boolean | `false` | notification dispatch RPC | E |
| `support_tickets` | boolean | `true` | tickets module | E |
| `support_sla` | enum `standard\|priority\|dedicated` | `standard` | ticket routing, informational in V1 | D |
| `marketing` | boolean | `false` | — | D |

### Platform & scale — `platform`
| Key | Type | Default | Gate | |
|---|---|---|---|---|
| `max_admin_users` | limit/stock | `"unlimited"` | trigger on `office_users` | E |
| `custom_roles` | boolean | `false` | users & permissions module | D |
| `multi_branch` | boolean | `false` | — | D |
| `max_branches` | limit/stock | `1` | — | D |
| `api_access` | boolean | `false` | — | D |
| `max_api_calls_per_month` | limit/flow | `0` | — | D |
| `webhook_url` | config | `""` | — | D |
| `white_label` | boolean | `false` | office-profile branding — **requires `custom_domain`** | D |
| `custom_domain` | config | `""` | — | D |
| `max_storage_mb` | limit/stock | `500` | logo/document upload | E |
| `logo_max_kb` | config | `512` | office-profile upload | E |
| `booking_retention_days` | config | `"unlimited"` | — | D |

**47 features: 34 enforced, 13 declared at ship.** The console shows the split. A declared feature can be sold, but the
plan builder marks it "غير مفعّل بعد" so nobody promises a customer something the code does not do.

---

## Part 7 — Permission integration strategy

### 7.1 The composition law

```
may(operator, office, action) =
      role_permits(operator, action)        // WHO you are        — office_can() / DashboardPermissions
   ∧  office_entitled(office, feature)      // WHAT you bought    — office_has()
   ∧  quota_allows(office, metric)          // HOW MUCH is left   — office_can_consume()
```

Three predicates, ANDed, never merged. They change for different reasons (a role changes when staff change; an
entitlement when a contract changes; a quota when usage changes), are owned by different people (the office
owner; the platform owner; nobody — it is measured), and move on different timescales (weekly; yearly;
continuously).

The practical payoff: when an action is refused, the system knows **which predicate said no** and can say so.
"You don't have permission" when the truth is "your plan doesn't include this" is the difference between a
support ticket and a sale.

### 7.2 Refusal codes, and the UI they drive

| Code | Failed predicate | UI response |
|---|---|---|
| `not_authorized` | role | "ليس لديك صلاحية" — contact your office owner |
| `feature_not_licensed` | entitlement | **Upgrade card** naming the feature and the cheapest plan that has it |
| `feature_dependency_blocked` | dependency | "يتطلب تفعيل: المحفظة" |
| `quota_exceeded` | usage | **Limit card**: used / limit / the plan that raises it |
| `license_suspended` | license status | Billing banner + what to pay |
| `license_expired` | license status | Renewal card |

Six codes, added to the existing `_messages` map pattern at each datasource. No new error infrastructure.

### 7.3 Server-side guard

One helper, one line per gated RPC:

```sql
create function public.assert_feature(p_key text) returns void
language plpgsql stable security definer set search_path = public as $$
begin
  if public.platform_enforcement_mode() = 'off' then return; end if;
  if not public.office_has(p_key) then
    raise exception 'feature_not_licensed' using detail = p_key;
  end if;
end $$;
```

Applied at the top of gated RPCs, immediately after the existing `office_can()` check — never instead of it:

```sql
if not public.office_can('wallet_adjust') then raise exception 'not_authorized'; end if;
perform public.assert_feature('cashback');
```

The order is deliberate: **role first, entitlement second.** A support agent who may not adjust wallets should
be told that, not shown an upgrade prompt for a feature they would still not be allowed to use.

### 7.4 Client-side integration

`EntitlementContext` sits beside `OfficeContext` in `DashboardSession`, loaded from `office_entitlements()`
during the same sign-in sequence, refreshed on app resume, on a realtime subscription to the office's
`office_licenses` row, and after any `feature_not_licensed` / `quota_exceeded` error.

`DashboardPermission` gains an optional `feature` field, and `_isItemAllowed` in
[dashboard_shell.dart:399](lib/apps/dashboard/core/routes/dashboard_shell.dart#L399) gains one clause:

```dart
bool _isItemAllowed(_DashboardNavItem item) {
  if (item.platformOnly && !widget.office.isPlatformAdmin) return false;
  final permission = item.permission;
  if (permission == null) return true;
  if (!DashboardPermissions.canAccess(_role, permission)) return false;
  return _entitlements.allows(item.feature);      // ← the only new line
}
```

**Hidden vs locked.** A nav item whose feature is off is *hidden* when the office could never have it
(`declared` features, platform-internal), and *shown locked with an upgrade affordance* when it is purchasable
on a higher plan. Hiding a purchasable feature makes it unsellable; showing an unpurchasable one is noise.
`platform_features.is_public` decides which.

Doctrine, inherited verbatim from [office_context.dart:44](lib/apps/dashboard/core/session/office_context.dart#L44):

> A hint for the shell, nothing more. […] a forged `true` reaches a screen whose every action is refused.

---

## Part 8 — RPC surface

**Platform-admin only** (each begins `if not is_platform_admin() then raise exception 'platform_admin_required'`,
matching `platform_list_offices`):

| RPC | Purpose |
|---|---|
| `platform_feature_catalog()` | Full catalog + categories + dependencies + gates |
| `platform_upsert_feature(jsonb)` | Create / edit a catalog entry |
| `platform_set_feature_status(key, status)` | Kill switch / deprecate |
| `platform_list_plans()` | Plans with office counts and effective feature summaries |
| `platform_plan_detail(plan_id)` | One plan, all values, revision history |
| `platform_save_plan(jsonb)` | Upsert plan + feature values, snapshots a revision |
| `platform_clone_plan(plan_id, key, name)` | Duplicate |
| `platform_compare_plans(uuid[])` | Feature × plan matrix |
| `platform_preview_plan(plan_id)` | Runs the real resolver against a hypothetical office |
| `platform_office_license(office_id)` | License + effective entitlements + usage + overrides + invoices |
| `platform_assign_plan(office_id, plan_id, cycle, jsonb)` | Change plan; writes audit + invoice |
| `platform_set_license_status(office_id, status, reason)` | Suspend / restore / cancel |
| `platform_start_trial(office_id, plan_id, days)` | Begin a trial |
| `platform_extend_trial(office_id, days, reason)` | Extend |
| `platform_set_override(office_id, key, value, reason, expires_at)` | Create / update an override |
| `platform_clear_override(office_id, key, reason)` | Remove |
| `platform_bulk_set_overrides(office_id, jsonb, reason)` | Bulk edit (brief requirement) |
| `platform_license_audit(filters, limit, offset)` | The audit trail |
| `platform_usage_report(period, filters)` | Cross-office usage |
| `platform_licensing_health()` | Trials expiring, past-due, over-limit, unenforced features |

**Office-scoped** (any authenticated office user, answering only for their own office):

| RPC | Purpose |
|---|---|
| `office_entitlements()` | The resolved document (§4.5) |
| `office_feature(key)` / `office_has(key)` | Single lookup |
| `office_can_consume(key, amount)` | Write verdict |
| `office_license_summary()` | Plan, status, dates, usage — for the الباقة والفوترة screen |
| `office_invoices(limit, offset)` | Own billing history |

Every platform RPC returns `jsonb`, following the precedent set by `platform_office_details` and the wallet
RPCs. Every one writes its own audit row inside its own transaction.

---

## Part 9 — Platform owner console UX

### 9.1 Navigation

A new sidebar group **`المنصة`**, visible only when `isPlatformAdmin`, appearing after `النظام`:

| Item | Route | Content |
|---|---|---|
| مكاتب المنصة | `/platform-offices` | **exists** — gains a license column, plan badge, over-limit flag |
| الخطط والباقات | `/platform-plans` | Plan builder |
| كتالوج الميزات | `/platform-features` | Feature catalog |
| التراخيص | `/platform-licenses` | Every office's license, filterable by status |
| الفوترة | `/platform-billing` | Invoices, revenue, renewals |
| الاستخدام | `/platform-usage` | Usage across offices, over-limit list |
| سجل التغييرات | `/platform-audit` | The audit log |

Existing conventions apply without exception: `DashboardModuleHeader`, `DashboardPanel`, `OpsDataTable`,
`DashboardEmptyState`, `MasterDetailLayout`, `DashboardKpiCard`, `DashboardIcons`, `dashboard_colors.dart`.
No new design system — the memory note on the dashboard design system governs.

### 9.2 Plans screen — master/detail

Left: plan list (name, status, price, office count, `is_public`). Right, tabbed:

- **الميزات** — the catalog grouped by category, each row a control typed by `value_type` (switch / number
  field with an "غير محدود" toggle / dropdown / text). Live diff badge against the last revision.
- **المكاتب** — offices on this plan; click through to the license.
- **السجل** — revisions with a side-by-side diff and a restore action.

Actions: حفظ · نسخ · أرشفة · مقارنة (select 2–4 plans → matrix) · معاينة (runs `platform_preview_plan`).

### 9.3 Feature catalog screen

A searchable table — search is the primary interaction, because at 47 features and growing, browsing is not
the access pattern. Columns: key · name · category · type · default · status · **enforcement** · plans
containing it · offices overridden.

Row expansion shows:
- **أين تُستخدم** — from `platform_feature_gates`: the triggers, RPCs and policies that gate it.
- **التبعيات** — prerequisites and dependents, both directions, with a warning if disabling this feature would
  collapse others.
- **الأثر** — how many offices currently resolve to each value.

Bulk edit: select features → apply value → to a plan or to an office, with a mandatory reason, previewed as a
diff before commit.

### 9.4 Office license detail

Reachable from `مكاتب المنصة` (the existing `platform_office_details_panel.dart` gains a tab) and from
`التراخيص`. Sections, in the brief's order:

1. **بيانات المكتب** — name, slug, owner, contact, listing status *(exists)*
2. **الترخيص** — plan, status pill, cycle, price, trial/period/grace dates, auto-renew
3. **الميزات الفعّالة** — the resolved entitlement table, each row showing its **source** (§4.2) with override
   rows marked ▲/▼ and expiry
4. **الحدود والاستخدام** — a bar per limit feature: used / limit, over-limit in `dashboardDanger`
5. **التجاوزات** — overrides with reason, author, expiry; add / edit / clear inline
6. **الفوترة** — invoices, amounts, statuses
7. **النشاط** — this office's slice of the audit log
8. **المحفظة والشكاوى** — links to existing modules *(read-only summary)*

Every mutating action here requires a reason and shows the resulting diff before commit. That is not
friction for its own sake: an override created without a stated reason becomes permanent because nobody dares
remove it.

### 9.5 Health screen (`platform_licensing_health`)

Not in the brief, added because it is what actually gets used daily: trials ending in 7 days · past-due
licenses · offices over any limit · features that are `declared` but sold on an active plan (a promise the
code does not keep) · overrides expiring soon · offices with no license row.

---

## Part 10 — Office-facing UX

### 10.1 One new screen: `الباقة والفوترة`

Under the `النظام` group, `DashboardPermission.officeBilling`, **owner only** — a support agent has no
business seeing the office's commercial terms.

- Current plan, status, renewal date, price.
- **الاستخدام** — a bar per limit feature, sourced from the same `office_entitlements()` document already in
  memory. No extra call.
- **ما تشمله باقتك** — features grouped by category, on/off, with locked-but-purchasable ones shown as
  upgrade prompts.
- **الفواتير** — history with status.
- Trial countdown banner when `status = 'trialing'`.

The office **cannot change its own plan** in V1 (§13.2). The screen's call to action is contact, not checkout.

### 10.2 Degradation, not disappearance

When a feature is off, its nav item is hidden (unpurchasable) or locked (purchasable). Data already created
under a previously-enabled feature stays **readable**. Turning off `wallet` freezes wallet movement; it does
not hide the ledger, and it certainly does not delete balances customers are owed. A licensing state change
must never destroy or conceal a tenant's financial record.

### 10.3 The upgrade moment

Because `raise exception … using detail` carries the full verdict jsonb (§5.3), the block is specific:

```
┌────────────────────────────────────────────┐
│  وصلت إلى حد الباقة                         │
│                                             │
│  السائقون          12 / 12                  │
│  باقتك الحالية      الأساسية                 │
│                                             │
│  باقة "الاحترافية" تتيح 50 سائقًا            │
│                                             │
│  [ تواصل مع المنصة ]      [ إغلاق ]         │
└────────────────────────────────────────────┘
```

Named limit, real numbers, the specific plan that lifts it. Never a toast, never "quota_exceeded".

---

## Part 11 — Client & Captain app integration

Neither passenger-facing app gets an entitlement API. Their behaviour is **derived** from the office's
entitlements, server-side.

| Feature off | Client app effect | Mechanism |
|---|---|---|
| `client_app` | Office vanishes from the marketplace; existing bookings still visible and trackable | `office_is_listed()` + `licensing_hold` (§3.9) — **one predicate**, F6 |
| `wallet` | Wallet surfaces hidden for that office's context; `wallet_post_entry` refuses | existing RPC guards + `assert_feature` |
| `live_tracking` | Tracking degrades to schedule + status, no live map | `trip_live_locations` policy term |
| `passenger_packages` | Office's packages hidden from the packages marketplace | `public_trips` / packages surfaces |
| `promotions` / `loyalty` | Codes and rewards inert for that office | promo/loyalty RPCs |

| Feature off | Captain app effect |
|---|---|
| `driver_app` | `captain_session_context` returns a licensing block; sign-in shows an explicit message, **not** a crash or an empty home. Captains on a trip **in progress** are never cut off mid-trip. |
| `live_tracking` | Location publisher stops; trip flow continues |

**The mid-trip rule is absolute.** No licensing state — expiry, suspension, non-payment — may interrupt a trip
that has started or a ticket already sold. The gates are on *creating new commitments*, never on *honouring
existing ones*. This is decision 4 restated where it matters most, because the captain app is where it would
do physical harm.

---

## Part 12 — Billing architecture

**Scope: structure only.** No payment gateway, no card capture, no automatic collection. What ships is the
record-keeping that a gateway later plugs into.

```sql
create table public.office_invoices (
  id             uuid primary key default gen_random_uuid(),
  office_id      uuid not null references public.offices(id) on delete restrict,

  invoice_number text not null unique,        -- INV-2026-0001, gapless per year

  -- What was billed, frozen. A plan renamed or repriced next month must not
  -- retroactively change what this invoice says — the same discipline the booking
  -- pricing model already applies to fares.
  plan_snapshot  jsonb not null,

  period_start   timestamptz not null,
  period_end     timestamptz not null,

  -- Open-ended so add-ons, overages, proration and coupons land as line items
  -- rather than columns. [{type, label, qty, unit, amount}]
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
  recorded_by    uuid references auth.users(id) on delete set null,

  -- Gateway hook, inert in V1.
  external_ref   text,

  notes          text not null default '',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
```

- **`line_items` as jsonb** is the future-proofing that matters: add-ons, usage overage, proration, coupons and
  per-seat charges are all line items. None of them needs a column.
- **`plan_snapshot`** freezes the commercial terms at issue time, matching the authoritative-pricing discipline
  the booking system already uses.
- **Renewal** is a scheduled job (`platform_run_billing_cycle()`) that issues invoices for licenses whose
  `period_end` has passed with `auto_renew = true`, advances the period, and emits an operational alert. It is
  idempotent per (office, period) via a unique index. Whether it runs on `pg_cron` or an Edge Function is an
  implementation choice for Phase 5, not an architectural one.
- **Dunning** is entirely state transitions in §14.3 plus alerts through the existing `operational_alerts`
  channel. No new notification infrastructure.
- **Payment collection is explicitly out of scope**, and `office_payment_configs` must not be touched (§2.6).

---

## Part 13 — Security model

### 13.1 Identity

`is_platform_admin()` is the only identity that may write anything in this subsystem. It already exists, is
already append-only from the backend, and is already `revoke`d from `anon`/`authenticated` for writes
([20260721140000 §6](supabase/migrations/20260721140000_platform_office_onboarding.sql)). No new identity concept.

### 13.2 Authorisation matrix

| Action | Platform admin | Office owner | Support agent | Captain | Client | anon |
|---|---|---|---|---|---|---|
| Read feature catalog | ✅ | ✅ *(names only, via `office_entitlements`)* | — | — | — | — |
| Create/edit/delete features | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create/edit/archive plans | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Read plan catalogue (public plans) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Assign / change an office's plan | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Suspend / restore a license | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create / remove overrides | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Extend a trial | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Read own license + usage | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Read own invoices | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Read audit log | ✅ | ❌ *(V1)* | ❌ | ❌ | ❌ | ❌ |

### 13.3 RLS

- All nine licensing tables: RLS enabled.
- `platform_features`, `platform_feature_categories`, `platform_feature_dependencies`, `platform_plans`,
  `platform_plan_features` — `select` to `authenticated` **only where `status <> 'draft'`** (an office may
  legitimately learn what plans exist); all writes `is_platform_admin()`.
- `office_licenses`, `office_feature_overrides`, `office_usage_counters`, `office_invoices` — `select` where
  `office_id = current_office_id() or is_platform_admin()`; **no** insert/update/delete policy at all, for
  anyone. Writes happen exclusively through `security definer` RPCs. Zero write policies means the only path
  is the audited one, which is the same construction `office_payment_configs` already uses.
- `platform_license_audit` — `select` to `is_platform_admin()`; no write policy; append-only trigger.
- `platform_plan_revisions` — `select` to `is_platform_admin()`; append-only.

### 13.4 Resolver hardening

- Every resolver function is `security definer`, `stable`, `set search_path = public`.
- `office_feature()` / `office_has()` / `office_can_consume()` take **no office parameter** — they read
  `current_office_id()`. There is no value a caller can pass to read another office's entitlements. This is the
  same construction `SupabaseWalletDatasource`'s doc comment describes and it should be described the same way.
- The `_for(office_id, …)` variants exist for triggers only and are `revoke`d from `anon` and `authenticated`.
- Every function referenced from an RLS policy is granted to `authenticated` — the trap documented in
  [20260721140000 §2](supabase/migrations/20260721140000_platform_office_onboarding.sql): a revoked function in
  a policy turns every guarded query into a permission error rather than an empty result.
- `revoke all … from public` before every explicit grant, per house convention.

### 13.5 What is achievable, stated plainly

Following the wallet doc's discipline: RLS, revocations and definer functions stop application-level tampering.
Nothing inside Postgres stops a database owner, and a platform admin *is* effectively that. The control is
therefore **detectability**: an append-only audit log with denormalised actor labels, written by triggers
rather than callers, so that removing evidence requires disabling a trigger — which is itself a schema change.

No hash chain here. The wallet ledger has one because it records *money that must reconcile*. The licensing
audit log records *decisions*, and the reconciliation target for a decision is the invoice it produced. Adding
a chain would be cargo-culting a control whose purpose does not transfer.

---

## Part 14 — Lifecycle: trials, contracts, and states

### 14.1 Trials

A trial is `office_licenses.status = 'trialing'` with `trial_ends_at` set — **not** a separate table and not a
separate plan. It is the same license row on a real plan, with an end date.

| Brief requirement | Mechanism |
|---|---|
| Free trial | `platform_plans.trial_days > 0` |
| Time-limited trial | `trial_ends_at` |
| **Feature-limited trial** | Overrides with `expires_at = trial_ends_at` — full plan, selected features capped |
| Automatic expiration | `platform_run_licensing_lifecycle()`: `trialing` + past `trial_ends_at` → `expired` |
| Automatic downgrade | `expired` → assign `plan.downgrade_to_plan_id`, status `active`, cycle `free` |
| Manual extension | `platform_extend_trial(office, days, reason)` — audited |

That feature-limited trials fall out of the override table with **no new schema** is the clearest evidence the
four-concept separation is the right one.

### 14.2 Enterprise contracts

An enterprise contract is: an existing plan + a set of overrides + `billing_cycle = 'custom'` +
`price_override` + `contract_ref`. The brief's example — Enterprise plus extra drivers, unlimited storage, API
enabled, dedicated support — is four override rows. **No new plan is created**, which is exactly the outcome
the decoupling exists to produce.

### 14.3 License state machine

```
                    ┌──────────┐
      onboard ─────▶│ trialing │──── trial_ends_at ────┐
                    └────┬─────┘                       │
                  pay/assign                           ▼
                    ┌────▼─────┐   period_end     ┌─────────┐
                    │  active  │─── unpaid ──────▶│past_due │
                    └────┬─────┘                  └────┬────┘
                         │ ◀──── payment ─────────────┘│
                         │                       grace_days
                    cancel│                            ▼
                         │                        ┌─────────┐
                         │                        │  grace  │
                         │                        └────┬────┘
                    ┌────▼──────┐                grace_ends_at
                    │ cancelled │                     ▼
                    └───────────┘                ┌───────────┐
                                                 │ suspended │
                                                 └─────┬─────┘
                                            restore /  │
                                            downgrade  ▼
                                                 ┌──────────┐
                                                 │ expired  │
                                                 └──────────┘
```

| Status | `licensing_hold` | Can operate? | Marketplace | Captains |
|---|---|---|---|---|
| `trialing` | `none` | full | listed | yes |
| `active` | `none` | full | listed | yes |
| `past_due` | `none` | full + banner | listed | yes |
| `grace` | `none` | full + urgent banner | listed | yes |
| `suspended` | `delisted` | **read-only** (§4.3) | **hidden** | yes, in-flight only |
| `cancelled` | `delisted` | read-only | hidden | yes, in-flight only |
| `expired` | `read_only` | restricted plan | hidden | yes, in-flight only |

Transitions are made only by `platform_set_license_status`, `platform_assign_plan` and the lifecycle job. Each
writes audit + an operational alert. The state machine mirrors the discipline already applied to trips
([20260727160000_trip_lifecycle_authority.sql](supabase/migrations/20260727160000_trip_lifecycle_authority.sql)):
transitions belong to one authority, not to whoever happens to be updating a row.

---

## Part 15 — Extensibility contract & migration strategy

### 15.1 Forward cost of each future capability

The brief asks that these need "little or no schema change". Honest accounting:

| Capability | Cost | Detail |
|---|---|---|
| **Add-ons** | 🟢 1 table, 1 resolver rung | `office_addons(office_id, feature_key, value, invoice_line)` inserted at rung 2.5. Ladder gains one branch. |
| **Feature store / marketplace** | 🟢 0 schema | The catalog *is* the store. Add `is_purchasable` + `price` to `platform_features`. |
| **Pay-as-you-go** | 🟢 1 column | Flow meters exist. Add `overage_price` to `platform_plan_features`; billing reads counters into line items. |
| **Per-seat licensing** | 🟢 0 schema | `max_admin_users` is already a stock meter; billing multiplies usage by a line-item rate. |
| **AI credits** | 🟢 0 schema | A flow meter with `meter_period = 'month'` and an overage price. |
| **Usage billing** | 🟢 0 schema | `office_usage_counters` → `line_items`. |
| **Regional packages** | 🟡 1 column | `platform_plans.region` + a filter in plan selection. Currency already per-license. |
| **Seasonal promotions** | 🟡 1 table | `platform_promotions` producing invoice discount line items. |
| **Coupon codes** | 🟡 1 table | `platform_coupons` + a line item. Must not reuse the passenger `promo_codes` table (F2 discipline). |
| **Reseller accounts** | 🟠 1 column + policy work | `platform_admins.scope_office_ids uuid[]`, and every `is_platform_admin()` call site becomes `is_platform_admin_for(office)`. ~20 call sites. The most expensive item, and it is named rather than hidden. |
| **Partner portals** | 🟠 follows resellers | Same scoping work, plus a portal surface. |
| **White-label editions** | 🟡 config features | `white_label` / `custom_domain` are catalogued; cost is in the apps, not the schema. |

**One structural limit, named:** adding a *metered stock* feature requires editing `office_usage_stock()`
(§5.2). Everything else is data.

### 15.2 Migration into the live platform

Three offices, all `active`/`listed`, all currently unlimited. The rollout must be a no-op on deploy day.

**Step 1 — schema.** Nine tables, functions, triggers created but **`platform_settings.enforcement_mode = 'off'`**.
Zero behaviour change.

**Step 2 — seed.** Catalog (47 features), categories, dependencies, gates. Five plans:

| Plan | `is_public` | Purpose |
|---|---|---|
| `founder` | ❌ | **Everything unlimited.** The incumbent plan. |
| `starter` | ✅ | 5 drivers, 3 vehicles, 5 routes, 100 trips/mo, no wallet |
| `professional` | ✅ | 25 / 15 / 20, 1000 trips/mo, wallet + refunds + cashback, exports |
| `enterprise` | ❌ | unlimited, API, white-label, dedicated SLA |
| `restricted` | ❌ | the suspension fallback (§4.3) — read-only |

**Step 3 — backfill.** All three existing offices → `founder`, `status = 'active'`,
`billing_cycle = 'custom'`, `period_end = null`, `auto_renew = false`, note recording the grandfather. **They
never lose anything.** Same guarantee the multi-office migration gave the incumbent office.

**Step 4 — shadow mode.** `enforcement_mode = 'shadow'`. Triggers evaluate and log to
`platform_quota_violations`, block nothing. Run for at least one full billing period. A non-empty violations
table in shadow means a limit is wrong, not that a customer is cheating — this is how the seeded numbers get
corrected before they can hurt anyone.

**Step 5 — enforce, per ring.** RPC guards first (best error messages, narrowest blast radius), then triggers,
then the marketplace predicate. Kill switch stays available throughout: `enforcement_mode = 'off'` is a
one-row `UPDATE` that disables the entire subsystem without a deploy.

**Step 6 — new offices.** `office_self_signup` and `platform_create_office` assign the default plan
(`platform_settings.default_signup_plan_id` → `starter`) with its trial. Grandfathered offices are unaffected.

### 15.3 Rollback

Each phase reverses independently. `enforcement_mode = 'off'` restores current behaviour instantly at any
point. Dropping the tables is safe up to Phase 5 because nothing outside the subsystem depends on them —
except `offices.licensing_hold`, which is nullable and `coalesce`d at its single read site.

---

## Part 16 — Phased implementation plan

Migration timestamps follow the repo convention (`YYYYMMDDHHMMSS_*.sql`).

| Phase | Deliverable | Migrations | Flutter | Exit criteria |
|---|---|---|---|---|
| **1 — Foundation** | Catalog, plans, dependencies, validation, audit, `platform_settings` | `20260807090000_licensing_foundation.sql`<br>`20260807090100_licensing_catalog_seed.sql` | — | Catalog + 5 plans seeded; validation trigger rejects malformed values; audit rows written; `enforcement_mode='off'` |
| **2 — Resolution** | Licenses, overrides, usage counters, the resolver, `office_entitlements()` | `20260807100000_licensing_resolution.sql` | `EntitlementContext` + `DashboardSession` wiring | Resolver returns correct `source` for all 5 rungs; 3 offices on `founder`; regression suite green |
| **3 — Platform console** | Plans / features / licenses / overrides / audit UI | — | `features/platform_licensing/` (full Clean Architecture, per playbook) | Owner can create a plan, assign it, create an override with reason, and see it in the audit log |
| **4 — Enforcement** | Quota triggers, `assert_feature`, shadow mode, violations log | `20260807110000_licensing_enforcement.sql` | Refusal-code mapping, upgrade/limit dialogs, nav gating | Shadow mode logs violations; `enforcing` blocks correctly; **existing suite still green** |
| **5 — Lifecycle & billing** | Invoices, renewal job, trials, dunning, suspension → `licensing_hold` | `20260807120000_licensing_billing.sql`<br>`20260807130000_licensing_lifecycle.sql` | Billing console + office `الباقة والفوترة` screen | Trial expires → downgrades; suspension delists; invoice issued on renewal |
| **6 — Passenger surfaces** | `office_is_listed()` term, captain gate, client degradation | `20260807140000_licensing_marketplace.sql` | Client/captain messaging | Suspended office vanishes from marketplace; **in-flight trips unaffected** |

Per-phase, non-negotiable, matching this repo's established practice:

- `supabase/tests/licensing_authority_regression.sql` extended each phase — the 12 existing regression files
  are the precedent, and a licensing bug is a revenue bug.
- Cross-office isolation test: office A's admin cannot read or write office B's license, overrides or usage.
- Every new RPC: `revoke all from public, anon` then explicit `grant`.
- `flutter analyze` clean; `dart format` only on touched files.
- Phase 4 must prove the **existing** dashboard test suite still passes unchanged — enforcement that breaks
  the current app is not enforcement, it is an outage.

---

## Part 17 — What this design deliberately does not do

Named so they are decisions rather than omissions:

1. **No payment gateway.** Invoices are records; collection is manual. §12.
2. **No self-service plan changes.** Offices cannot upgrade themselves in V1. Checkout without a gateway is a
   lie, and plan changes have proration implications that need a real billing engine.
3. **No proration.** Mid-cycle changes bill from the next period. The `line_items` shape supports it later.
4. **No multi-currency conversion.** `currency` is stored per plan and per license; no FX.
5. **No usage-based pricing.** Meters exist and are enforced; nothing charges for overage.
6. **No reseller scoping.** `is_platform_admin()` stays binary. §15.1 prices the change.
7. **No office-facing audit log.** Offices see their license and invoices, not the platform's decision trail.
8. **No entitlement caching.** §4.6 names the trigger for revisiting.
9. **`declared` features are not enforced.** 13 of 47 are catalogued only, visibly marked, and cannot be sold
   as working. That is the honest state, and the health screen surfaces any plan that violates it.

---

## Part 18 — Open questions for the owner

Six decisions that are commercial, not technical. The design works under either answer to each; these change
the seed data and the UX, not the architecture.

1. **Do the three existing offices stay on `founder` permanently, or migrate to paid plans on a date?**
   The design grandfathers them indefinitely. A migration date is a business decision with a customer
   conversation attached.
2. **Trial length and default signup plan** for self-registered offices. Proposed: 14 days on `professional`,
   downgrading to `starter`.
3. **Grace period length** between `past_due` and `suspended`. Proposed: 7 days.
4. **Should a suspended office's captains keep signing in?** The design says yes for in-flight trips only.
   Confirm — this is the decision with real-world safety consequences.
5. **Plan prices and limits.** The seed numbers in §15.2 are placeholders and should not be treated as a
   recommendation.
6. **Does `client_app: false` hide the office from the marketplace, or is that only ever a suspension
   consequence?** The design allows both; selling "no marketplace listing" as a plan tier may not be
   commercially sensible.

---

## Part 19 — Final recommendation

**Approve, and implement in the six phases above.**

The design is deliberately conservative in three places and ambitious in one. Conservative: it adds no new
identity concept, no new permission system, and no new design system — every one of those already exists here
and works. Ambitious: it makes the *database* the enforcement boundary rather than the UI, which is the only
choice that survives the fact that the dashboard is a Supabase client holding a user JWT and can call anything
RLS permits.

The two things most likely to be argued down are the two that should not be:

- **Shadow mode before enforcement.** It looks like delay. It is the only way to discover that a seeded limit
  is wrong before it blocks a paying customer.
- **Read-only suspension instead of blackout.** It looks soft. The alternative is a billing action that
  strands passengers and captains, and there is no version of that which is worth the leverage it buys.

The naming law (§1.2) is the one rule with no flexibility. `packages` and `subscriptions` already mean
passenger fare bundles in four tables, one nav item and every conversation about this system. The licensing
domain says `plan` and `license`, and it says them everywhere.
