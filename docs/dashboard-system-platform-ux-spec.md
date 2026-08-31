# EWT Dashboard — System & Platform UX Specification

> **Status:** evidence-based audit, written 2026-08-30 against the working tree on branch `client-reui`.
> **Scope:** the two sidebar sections **النظام** (5 modules) and **المنصة** (5 modules).
> **Purpose:** the single source of truth a Claude Design session can read *instead of* the Flutter code.
> **Nothing in this document was invented.** Every claim is anchored to a file, a class, an RPC or a
> migration. Where behaviour is absent, partial or contradictory it is tagged:
> `[NOT IMPLEMENTED]` `[PARTIALLY IMPLEMENTED]` `[UI GAP]` `[BACKEND GAP]` `[UNCLEAR]` `[BUSINESS RULE UNCLEAR]`.

---

## Contents

1. [Executive Summary](#1-executive-summary)
2. [Dashboard Context](#2-dashboard-context)
3. [Architecture Overview](#3-architecture-overview)
4. **Section 1 — النظام**
   · [4.1 الإشعارات](#41-الإشعارات-notifications-center)
   · [4.2 ملف المكتب](#42-ملف-المكتب-office-profile)
   · [4.3 الباقة والفوترة](#43-الباقة-والفوترة-office-plan--billing--financial)
   · [4.4 المستخدمون والصلاحيات](#44-المستخدمون-والصلاحيات-office-users--permissions)
   · [4.5 الإعدادات](#45-الإعدادات-settings)
5. **Section 2 — المنصة**
   · [5.1 مكاتب المنصة](#51-مكاتب-المنصة-platform-offices)
   · [5.2 الباقات والميزات](#52-الباقات-والميزات-plans--features-catalog--financial)
   · [5.3 التراخيص](#53-التراخيص-office-licences--financial)
   · [5.4 الفوترة والسجل](#54-الفوترة-والسجل-platform-billing--audit-trail--financial)
   · [5.5 برنامج الإحالة](#55-برنامج-الإحالة-referral-programme--financial)
6. [Cross-Feature Relationships](#6-cross-feature-relationships)
7. [Global UX Requirements](#7-global-ux-requirements)
8. [Screen Inventory](#8-screen-inventory)
9. [UI Priority Matrix](#9-ui-priority-matrix)
10. [Implementation Gaps & Risks](#10-implementation-gaps--risks)
11. [**CLAUDE DESIGN HANDOFF**](#11-claude-design-handoff)

Each feature in §4 and §5 follows the same 13-part structure: Purpose · Users/Roles · Entry Points ·
Main Screen · Data Model · User Actions · Workflows · States · Validation & Business Rules ·
Backend Dependencies · UI Requirements · UX Problems · Recommended Information Architecture.

---

## 1. Executive Summary

### What these two sections are

The EWT dashboard is a **multi-tenant SaaS console with two audiences sharing one shell**:

| Section | Audience | Question it answers |
|---|---|---|
| **النظام** | The **office** (tenant) — its owner, and sometimes its support agents | "How is *my office* configured, who works here, what did I buy, and what needs my attention?" |
| **المنصة** | **EWT itself** — the platform operator | "Which offices exist, what may they use, what do they owe us, and where did that referral money go?" |

They sit adjacent in the sidebar (`_navSystem` then `_navPlatform`, [dashboard_shell.dart:83-97](lib/apps/dashboard/core/routes/dashboard_shell.dart#L83-L97)) and the المنصة group is drawn **only** when `OfficeContext.isPlatformAdmin` is true — so an office owner's sidebar never changes shape.

### The three-predicate access law

Everything in both sections obeys one composition rule, stated verbatim in [entitlement_context.dart](lib/apps/dashboard/core/entitlements/entitlement_context.dart):

```
may = role_permits  ∧  office_entitled  ∧  quota_allows
```

Three predicates, **ANDed, never merged**, because a merged system cannot answer *"why can't I do this?"* — which is the one question a licensing UI must always be able to answer. The design must preserve that distinction visually: a role refusal, a plan refusal and a quota refusal look different and lead somewhere different.

### Headline findings

1. **These 10 modules are the only ones in the dashboard that do not use the console's own list/form design system.** Six modules (`bookings`, `customers`, `reviews`, `subscriptions`, `tickets`, `wallet`) use `DashboardFilterBar` + `DashboardResultsHeader` + `DashboardPagerBar`; three (`fleet`, `routes`, `trips`) use the shared form kit in `core/widgets/forms/`. **None of the ten modules audited here uses either.** That single fact explains most of the perceived inconsistency.
2. **The licensing lifecycle engine never runs.** `platform_run_licensing_lifecycle()` (trial expiry → dunning → grace → suspension → automatic downgrade) has **no pg_cron schedule** (migration `20260729090000` states plainly "No pg_cron on this project") **and no UI trigger** — `runLifecycle()` exists on the cubit and is called from nowhere. Every licence state after `active`/`trialing` is currently reachable only by a manual platform action.
3. **The platform kill switch has no confirmation.** `_EnforcementModeBar` ([platform_licenses_screen.dart:409](lib/apps/dashboard/features/platform_licensing/presentation/screens/platform_licenses_screen.dart#L409)) is a bare `SegmentedButton` that flips the whole platform between `off` / `shadow` / `enforcing` on one tap. It is the most consequential control in the console and the least guarded.
4. **برنامج الإحالة is structurally blind.** `referrals`, `referral_codes` and `referral_reward_transactions` carry RLS policies scoped to `auth.uid() = referrer_id / referred_id / user_id` and **no platform-admin read policy exists**. The dashboard reads those tables directly, so 3 of the 5 tabs render empty for the very admin the screen is built for.
5. **Notification deep links are broken.** DB triggers write `action_url` values `/settings/billing`, `/live-trips` and `/support`; none of the three is a registered `DashboardRoutes` constant, so tapping those alerts shows "غير مصرح" instead of navigating.
6. **The notification composer's default action is the one an office owner cannot perform.** "إرسال جماعي" defaults ON and calls `platform_broadcast_notification`, which raises `platform_admin_required`.
7. **الإعدادات is a stub** — a light/dark toggle, a paragraph saying settings live elsewhere, and a duplicate of the sign-out already in the top bar.

---

## 2. Dashboard Context

### 2.1 The shell

One `StatefulWidget`, [`DashboardShell`](lib/apps/dashboard/core/routes/dashboard_shell.dart), owns navigation. There is no `Navigator` route table for modules — `_route` is a `String` field and `_buildContent()` is a `switch` that returns the module wrapped in its `BlocProvider`. Consequences the design must respect:

- **No browser URL, no back button, no deep link from outside the app.** "Navigation" is `_openRoute(String)`.
- **Modules are torn down and rebuilt on every switch** (except the licensing cubit, see §2.4). Any unsaved state must be owned above the module or guarded by a discard dialog.
- Layout: sidebar 256px with labels, 76px icon rail below 1180px, `Drawer` below 920px.

### 2.2 The sidebar groups

`_navGroupOrder` = التشغيل → المبيعات → الأسطول → المالية → الدعم → **النظام** → **المنصة**.

**النظام** (`_navSystem`) — 5 sidebar rows + 1 hidden row:

| # | Label | Route | Permission | Licensing feature |
|---|---|---|---|---|
| 1 | الإشعارات | `/notifications` | `notifications` | `FeatureKeys.notifications` (`'notifications'`) |
| 2 | ملف المكتب | `/office-profile` | `officeProfile` | — |
| 3 | الباقة والفوترة | `/office-billing` | `officeBilling` | — |
| 4 | المستخدمون والصلاحيات | `/permissions` | `permissions` | — |
| 5 | الإعدادات | `/settings` | `settings` | — |
| — | *(hidden)* المستخدمون والصلاحيات | `/users` | `permissions` | — |

> `/permissions` and `/users` both render `const UsersScreen()`. `/users` is registered `inSidebar: false` purely so the route passes the gate. **This is a duplicate registration with no behavioural difference** — `[UI GAP]`, and a naming inconsistency the design should collapse.

**المنصة** (`_navPlatform`) — 5 rows, every one `platformOnly: true`:

| # | Label | Route | Permission |
|---|---|---|---|
| 1 | مكاتب المنصة | `/platform-offices` | `platformOffices` |
| 2 | الباقات والميزات | `/platform-catalog` | `platformLicensing` |
| 3 | التراخيص | `/platform-licenses` | `platformLicensing` |
| 4 | الفوترة والسجل | `/platform-billing` | `platformLicensing` |
| 5 | برنامج الإحالة | `/referrals` | `referrals` |

> برنامج الإحالة is `platformOnly` with an explicit code comment: the referral tables carry **no `office_id`**, so an office owner opening it would be reading the whole platform's numbers.

### 2.3 Roles — there are exactly two

[`DashboardRole`](lib/apps/dashboard/core/permissions/dashboard_role.dart):

| Enum | Arabic label | DB value |
|---|---|---|
| `admin` | **المالك** | `dashboard_admin` |
| `supportAgent` | **خدمة العملاء** | `support_agent` |

`DashboardPermissions.permissionsFor` grants `admin` **every** permission; `supportAgent` gets exactly eight: `liveOps`, `bookings`, `tickets`, `reports`, `paymentVerification`, `notifications`, `customerWallets`, `customers`.

**Therefore, inside these two sections:**

| Module | المالك | خدمة العملاء |
|---|---|---|
| الإشعارات | full | **full** (only module in النظام they can open) |
| ملف المكتب | read + write | **no access** |
| الباقة والفوترة | read | **no access** |
| المستخدمون والصلاحيات | full | **no access** |
| الإعدادات | full | **no access** |
| all of المنصة | only if `isPlatformAdmin` | never |

> **`[UI GAP]` — a support agent cannot reach الإعدادات, which is where the theme toggle lives.** Sign-out survives because the shell's top bar has its own; the theme control does not.

> **`[UNCLEAR]` / server-vs-client divergence:** two RPCs behind owner-only screens are granted to *any* office user server-side. `get_dashboard_users()` and `office_invoices(int,int)` both check only `current_office_id() is not null`. The owner-only restriction on المستخدمون and الباقة والفوترة is therefore **client-side only**. Writes are correctly gated (`assert_office_staff_admin()` requires `dashboard_admin`), so this is a read-exposure question, not a write hole.

### 2.4 Session, entitlements, and what a screen may assume

Three long-lived holders, all registered as lazy singletons in [`dashboard_di.dart`](lib/apps/dashboard/core/di/dashboard_di.dart):

- **[`DashboardSession`](lib/apps/dashboard/core/session/dashboard_session.dart)** — holds `OfficeContext`. `officeId` **throws** if read while signed out, deliberately: a query that silently dropped its filter would return every tenant's rows.
- **[`OfficeContext`](lib/apps/dashboard/core/session/office_context.dart)** — `officeId`, `officeName`, `officeSlug`, `role`, `username`, `fullName`, `logoUrl`, `listingStatus`, `isPlatformAdmin`. Built once at sign-in from the `current_office_context` RPC. Refreshed mid-session **only** by `DashboardAuthCubit.refreshContext()`, which ملف المكتب calls after a successful save so the shell's office name/logo stop being stale.
- **[`EntitlementService`](lib/apps/dashboard/core/entitlements/entitlement_service.dart)** — holds the resolved `EntitlementContext`. Refreshed on six events: sign-in, a licensing refusal, explicit reload, and **realtime** changes to `office_licenses`, `office_feature_overrides`, `platform_plan_features`, `platform_features`.

**`EntitlementContext.unknown` fails OPEN** (allows everything) — the opposite of the usual security default, on purpose: this object is a UX hint, the server is the boundary, and a network blip that silently hid half the console would be indistinguishable from a downgrade nobody agreed to.

The licensing console keeps **one `PlatformLicensingCubit` across all three المنصة licensing routes**, held by the shell (`_licensingCubit`), because the sections read each other constantly and a per-route provider would refetch the whole catalog on every tab change.

### 2.5 The refusal channel

`LicensingGuard` → `licensingRefusals` (a `ValueNotifier`) → the shell's `_onLicensingRefusal` → `showLicensingRefusal(...)`. One wiring point, so a new module cannot forget to have an upgrade path. Six refusal codes, each with fixed Arabic text ([licensing_failure.dart](lib/apps/dashboard/core/entitlements/licensing_failure.dart)):

`not_authorized` · `feature_not_licensed` · `feature_dependency_blocked` · `quota_exceeded` · `license_suspended` · `license_expired`

The server carries the **full verdict** (`feature`, `limit`, `used`, `plan_key`, `blocked_by`) in the exception's `DETAIL` payload, so the dialog names real numbers rather than printing `quota_exceeded`. **`StorageException` drops `DETAIL`** — the logo-upload path reports the refusal correctly but without figures. `[PARTIALLY IMPLEMENTED]`

---

## 3. Architecture Overview

### 3.1 Layering

Every module follows feature-first Clean Architecture:

```
presentation/  screens · widgets · cubit (+ sealed state)
domain/        entities · repositories (interfaces) · usecases
data/          models · datasources (Supabase) · repositories (impl)
```

Exceptions worth knowing:
- `settings/` has **only** `presentation/screens/settings_screen.dart`. No cubit, no data layer.
- `users/` has **no `data/repositories/`** — `SupabaseUsersDatasource` *implements* `UsersRepository` directly.
- `platform_licensing/` maps nothing: the RPCs already return the domain shape and the entities parse it; the repository interface exists purely to keep presentation out of `data/`.

### 3.2 State-management shapes in use

Three distinct patterns appear across the ten modules — the design must accommodate all three:

| Shape | Modules | Behaviour |
|---|---|---|
| **Sealed union** (`Initial/Loading/Loaded/Error` + `ActionSuccess`/`ActionFailure` carrying the last good data) | office_profile, users, platform_admin, referrals, notifications | A failed **action** emits a state that still carries the list/form, so the screen never blanks. `ActionSuccess` is a **one-frame** state immediately followed by `Loaded`. |
| **Multi-concern `Loaded`** (per-section slices + per-section flags) | platform_licensing | One `Loaded` with `catalog`/`plans`/`licenses`/`usage`/`audit`/`billing`/`health`/`settings`, plus `isBusy`, `actionError`, `actionMessage`. A failed audit fetch cannot take the plan list down. |
| **Bare/streaming** | notifications (alerts), office_billing | `OperationalAlertsCubit` is a stream subscription; `OperationalAlertsBadgeCubit extends Cubit<int>` is a raw int. |

**The console-wide law, stated in three separate files:** *an action error never replaces the screen.* A failed load shows the error view; a failed action shows a notice **over** whatever the operator was editing.

> **`[UI GAP]` — referrals breaks this law.** `ReferralCubit.saveConfig` emits `ReferralError` on failure ([referral_cubit.dart:66](lib/apps/dashboard/features/referrals/presentation/cubit/referral_cubit.dart#L66)), which the screen renders as a full-page `DashboardErrorState` — destroying the settings form the operator just typed into. Every other module in this audit gets this right.

### 3.3 Shared UI inventory — and what these modules actually use

`core/widgets/` provides: `DashboardModuleHeader`, `DashboardKpiCard`/`DashboardKpiGrid`, `DashboardPanel`, `DashboardCollapsibleSection`, `DashboardFilterBar`, `DashboardResultsHeader`, `DashboardPager`/`DashboardPagerBar`, `DashboardQueueTabs`, `DashboardStatusChip`, `DashboardEmptyState`, `DashboardLoading`/`DashboardErrorState`, `OpsDataTable`, `MasterDetailLayout`, `DashboardCapNotice`, `DashboardDialogHeader`, charts (`line`, `bar`, `donut`, `ranked bars`, `sparkline`), and a **form kit** (`DashboardFormController`, `DashboardFormField`, `DashboardFormSection`, `DashboardFormFeedback`).

Measured usage across the ten audited modules:

| Widget | Used by (of the 10) |
|---|---|
| `DashboardModuleHeader` | 8 |
| `DashboardStatusChip` | platform_licensing (20×), platform_admin (8×), users, referrals, office_billing |
| `DashboardEmptyState` | platform_licensing (13×), users (2×), platform_admin (2×), office_billing |
| `DashboardPanel` | platform_licensing (13×), office_billing (3×), referrals (2×) |
| `DashboardKpiCard` | referrals (9×), platform_admin (6×), office_billing (4×), office_profile (3×) |
| `OpsDataTable` | referrals (3×), platform_licensing (1×) |
| `MasterDetailLayout` | platform_admin, platform_licensing |
| **`DashboardFilterBar`** | **0** |
| **`DashboardResultsHeader`** | **0** |
| **`DashboardPagerBar`** | **0** |
| **form kit (`core/widgets/forms/`)** | **0** |

Every form in these two sections is a hand-rolled `TextFormField` + `OutlineInputBorder` + local `GlobalKey<FormState>`: `office_identity_form.dart`, `staff_account_form.dart`, `office_onboarding_form.dart`, `plan_editor_dialog.dart`, `notification_composer.dart`, `referral_settings_tab.dart`. **This is the single largest source of visual inconsistency between these sections and the rest of the console.**

### 3.4 Backend access patterns

| Pattern | Where |
|---|---|
| **RPC only, no table reads** | platform_licensing (every licensing table has SELECT policies but **no INSERT/UPDATE/DELETE policy for anyone** — the only write path is a `security definer` RPC that audits itself) |
| **RPC + Edge Function** | users (`office-manage-user`), platform_admin (`platform-create-office`) — both because creating an `auth.users` row needs the service-role key, which must never be in a Flutter binary |
| **Direct table read/write under RLS** | office_profile (`offices`), notifications (`operational_alerts` stream), referrals (`referrals`, `referral_codes`, `referral_reward_transactions`, `referral_rewards`) |
| **Realtime** | `operational_alerts` (feed + badge), `office_licenses` / `office_feature_overrides` / `platform_plan_features` / `platform_features` (entitlement refresh) |
| **Storage** | `office-logos` bucket (public read; writable only by the office's own owner inside a folder named for the office id) |

**Error-message convention:** the server raises **machine codes** (`username_taken`, `reason_required`, `plan_archived`, …); the Arabic text lives once in the Dart datasource's `_messageForCode` / `_messages` map. Design must assume every server error already arrives as a finished Arabic sentence.
---

# 4. Section 1 — النظام

---

## 4.1 الإشعارات (Notifications Center)

### 1. Purpose

Two unrelated jobs sharing one destination:

1. **الوارد (inbox)** — the office's *inbound* operational alert feed. Populated **exclusively by database triggers** whenever something needs an operator's attention (a payment to review, a captain request, a ticket, a refund, a licence event). It is the console's "what happened while I wasn't looking" surface, and it is the source of the bell badge in the top bar.
2. **إرسال إشعار (composer)** — an *outbound* push: send a notification to one user, or broadcast to every user of a target app.

The two are opposite directions of travel and have completely different permission models. They are currently tabs of one screen.

### 2. Users / Roles

- Sidebar gate: `DashboardPermission.notifications` — granted to **both** `admin` and `supportAgent`. This is the **only** النظام module a support agent can open.
- Licensing gate: `FeatureKeys.notifications` (`'notifications'`).
- **Inbox** — RLS scopes `operational_alerts` to `office_id = current_office_id()` for SELECT and UPDATE. Any active office user reads and marks read.
- **Composer, single recipient** — `office_dispatch_notification` requires `current_office_id()` (any office user), asserts the **`push_notifications`** entitlement (a *different* key from the module's own gate), and refuses any recipient who is not a client who booked with this office, one of its drivers, or one of its `office_users`.
- **Composer, broadcast** — `platform_broadcast_notification` raises `platform_admin_required` unless `is_platform_admin()`.

> **`[UI GAP] — the most important one in this module.** `_broadcast` defaults to `true` ([notification_composer.dart:32](lib/apps/dashboard/features/notifications/presentation/widgets/notification_composer.dart#L32)). An office owner who opens the composer and presses send hits `platform_admin_required` on the default path. Nothing in the UI says broadcast is a platform-only action.

> **`[UI GAP]`** — on the `starter` plan the seed sets `notifications = true` but `push_notifications = false`. The module opens; the single-recipient send is refused server-side. The composer shows no locked state and no upgrade affordance.

> **`[BUSINESS RULE UNCLEAR]`** — broadcast is **platform-wide**, not office-scoped (`broadcast_notification` fans out to every user of a target app). A platform admin who is *also* an office owner sees this control inside what reads as their office console. The blast radius is not stated anywhere on screen.

### 3. Entry Points

- Sidebar: النظام → الإشعارات → `/notifications`.
- **Top-bar bell** (`_openRoute(DashboardRoutes.notifications)`, two call sites in the shell) carrying a live unread badge, capped at `99+`.
- **Home screen** mounts its own `OperationalAlertsCubit..startWatching()` and shows alerts inline.
- **Alert tap → `onOpenRoute(alert.actionUrl)`** — the only cross-module deep-link mechanism in the console.

### 4. Main Screen — information architecture

`NotificationsCenterScreen` = `DashboardModuleHeader` + a 2-tab `TabBar` + `TabBarView`.

**Tab 1 — الوارد** (`OperationalAlertsView`)
- Right-aligned `TextButton.icon` **«تعليم الكل كمقروء (N)»**, shown only when `unread > 0`.
- Flat `ListView` of `AlertTile`, newest first, **capped at 100 rows** by the stream. No pagination, no "load more", no date grouping, no search, **no filter**.
- Each tile: type icon in a tinted circle · unread dot · title (bold) · body · `'${type.label} · منذ N د'` · a check `IconButton` (unread only).

**Tab 2 — إرسال إشعار** (`NotificationComposer`, `maxWidth: 560`, centred)
- التطبيق المستهدف (dropdown) · **إرسال جماعي** (Switch) · معرّف المستخدم (only when broadcast is off) · التصنيف (dropdown) · العنوان · نص الرسالة (3 lines) · full-width send button.

### 5. Data Model

**`OperationalAlert`** (table `public.operational_alerts`)

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `type` | text | Mapped to `OperationalAlertType`; unknown → `general` |
| `title`, `body` | text | Arabic, written by the trigger |
| `data` | jsonb | e.g. `{trip_id}`, `{ticket_id}`, `{invoice_id}`, `{plan_key}` — **parsed into the entity, never rendered** |
| `priority` | text | `low` / `normal` / `high` / `urgent` (CHECK) — **parsed, never rendered** |
| `action_url` | text | Deep link |
| `is_read` | boolean | |
| `created_at` | timestamptz | |
| `office_id` | uuid | Added by `20260721090000`; the RLS axis |

`OperationalAlertType` handles **6** values: `payment_review`, `captain_request`, `support_ticket`, `refund_request`, `trip_cancelled`, `general`.

**The database emits at least 17:** `payment_review`, `captain_request`, `support_ticket`, `refund_request`, `trip_cancelled`, `booking_cancelled_by_client`, `low_trip_rating`, `refund_batch`, `wallet_status`, `wallet_chain_divergence`, `trial_ending`, `license_past_due`, `license_grace`, `license_suspended`, `license_downgraded`, `license_plan_changed`, `invoice_issued`.

> **`[UI GAP]` — 11 of 17 alert types collapse to «عام» with a generic bell icon**, including every licensing alert. The single most consequential message an office can receive ("تم تحويل الحساب إلى وضع القراءة فقط") is visually indistinguishable from a routine notice.

**`NotificationDraft`** (outbound) — `recipientUserId?` (null ⇒ broadcast), `title`, `body`, `category` (9 values), `targetApp` (`client` / `captain` / `all`), `actionUrl?`, `data`. `actionUrl` and `data` are on the entity and **never exposed in the composer** `[UI GAP]`.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Mark one read** | Check button **or** tapping the tile | — | none | Optimistic state update, then `update operational_alerts set is_read` | no | no |
| **Mark all read** | «تعليم الكل كمقروء (N)» | — | none | Optimistic `withAllRead()`, then a **bulk UPDATE on every unread row in the office** | **no** `[UI GAP]` | irreversible (no unread toggle exists) |
| **Open alert** | Tap tile | — | none | Marks read **then** `onOpenRoute(actionUrl)` | no | no |
| **Send / broadcast** | «إرسال إشعار» | target app, broadcast on/off, user id, category, title, body | title/body/user-id non-empty only | Snackbar `تم الإرسال إلى N مستلم`; title+body cleared, target/category/broadcast retained | **no** `[UI GAP]` | **yes — a broadcast is unrecallable** |
| **Retry (inbox)** | error view | — | — | Re-subscribes the stream | no | no |
| **Filter by type** | — | — | — | **`[NOT IMPLEMENTED]` in the UI** | | |

> **`[PARTIALLY IMPLEMENTED]` — the type filter exists in state and cubit and is not wired.** `OperationalAlertsLoaded` carries `activeType` and a computed `filtered`; `OperationalAlertsCubit.filterByType()` exists. `OperationalAlertsView._buildLoaded` renders **`alerts`, not `filtered`**, and no control calls `filterByType`. The mechanism is built and unreachable.

### 7. Workflows

**Inbound (the common path)**
```
DB trigger fires → push_operational_alert(...) inserts a row (SECURITY DEFINER)
  → Realtime pushes it into the office's stream
  → badge cubit re-counts server-side (exact, unbounded, indexed)
  → operator opens الإشعارات or the bell
  → taps an alert → marked read → routed to the module named by action_url
```

**Outbound, single recipient**
```
composer → dispatch(draft) → office_dispatch_notification RPC
  → current_office_id() resolved server-side
  → assert_feature('push_notifications')
  → recipient must be this office's client / driver / operator, else recipient_not_in_office
  → row inserted into public.notifications → the Client or Captain app receives it
```

**Outbound, broadcast**
```
composer (broadcast ON, the default) → platform_broadcast_notification
  → is_platform_admin() or raise platform_admin_required
  → broadcast_notification fans out to every user of target_app, platform-wide
  → returns a recipient count
```

### 8. States

| State | Current behaviour |
|---|---|
| **Loading** | `Center(CircularProgressIndicator)` — **not** the shared `DashboardLoading` `[UI GAP]` |
| **Empty** | Bespoke centred illustration: "لا توجد تنبيهات" + "ستظهر هنا مراجعات الدفع وطلبات الكباتن والشكاوى فور وصولها." — **not** the shared `DashboardEmptyState` `[UI GAP]` |
| **Error** | Bespoke centred error + «إعادة المحاولة» — **not** `DashboardErrorState` `[UI GAP]` |
| **Success** | List of tiles; unread tiles carry a tinted background, a primary-coloured border and a dot |
| **Partial** | Every field defaults defensively (`title ?? ''`, `type ?? general`) |
| **Sending** | Send button disabled, spinner in the icon slot, label → «جارٍ الإرسال…» |
| **Permission denied** | Server code surfaced raw via `e.toString()` in a red snackbar — an operator sees `PostgrestException(message: platform_admin_required, …)` `[UI GAP]` |
| **Offline** | Not handled distinctly. The Realtime stream's `onError` becomes a full-screen error view. `OperationalAlertsBadgeCubit` swallows stream errors silently (`onError: (_) {}`) — the badge simply stops updating |

### 9. Validation & Business Rules

**Implemented**
- `priority ∈ {low, normal, high, urgent}` (DB CHECK).
- Alert rows are written **only** by `push_operational_alert()` (SECURITY DEFINER). There is no INSERT policy.
- RLS: SELECT and UPDATE scoped to `office_id = current_office_id()`. `anon` revoked.
- Feed capped at 100 rows, `created_at desc`.
- Unread count is a **server-side exact count**, not a count of the loaded page.
- `trg_quota_operational_alerts` meters alert inserts against the `notifications` entitlement — and is documented as **"تُحجب بلا إفشال العملية"**: over quota, the alert is silently dropped rather than failing the business operation that raised it. `[BUSINESS RULE — worth surfacing]`
- Composer: title, body, and (non-broadcast) user id must be non-empty after trim. That is the entire client-side validation.
- `office_dispatch_notification` requires a non-blank title and a recipient inside the office.

**Unclear / absent**
- `[BUSINESS RULE UNCLEAR]` No retention or archival rule for `operational_alerts`. Rows accumulate; only the 100-row read cap bounds the UI.
- `[UNCLEAR]` The recipient-id field expects a raw auth UUID with no picker, no search, no validation of format, and no name resolution. There is no surface in the console that displays a user's auth id, so this control is effectively unusable without direct DB access.
- `[UNCLEAR]` `NotificationDraft.category` (9 values) is sent to the RPC but nothing in the dashboard documents what each category *does* on the receiving app (`notification_preferences` has per-category `<category>_enabled` columns; the composer never mentions that a recipient can have opted out).

### 10. Backend Dependencies

| Dependency | Kind | What the UI needs |
|---|---|---|
| `public.operational_alerts` | table + Realtime publication | The feed and the badge |
| `idx_operational_alerts_office_unread (office_id, created_at desc) where is_read = false` | index | Makes the exact unread count cheap |
| `push_operational_alert(...)` | SECURITY DEFINER fn | The only writer |
| `office_dispatch_notification(uuid,text,text,text,text,text,jsonb)` | RPC | Single-recipient send |
| `platform_broadcast_notification(text,text,text,text,text,jsonb)` | RPC | Broadcast (platform admin) |
| `public.notifications` | table | Destination for outbound; read by the Client/Captain apps |
| `trg_quota_operational_alerts` | trigger | Meters against `notifications` |
| `assert_feature('push_notifications')` | guard | Gates the send |

### 11. UI Requirements

**Primary hierarchy** — *what changed, how urgent, and what to do about it.* Right now urgency (`priority`) is fetched and thrown away; it should be the strongest signal on a tile after the title.

- The **type** must be legible at a glance for all 17 emitted types, not 6. Group them into families the operator recognises: مالية (payment_review, refund_request, refund_batch, invoice_issued), تشغيل (trip_cancelled, booking_cancelled_by_client), أسطول (captain_request), دعم (support_ticket, low_trip_rating), محفظة (wallet_*), اشتراك (trial_ending, license_*).
- **Unread must survive scanning** — a dot alone on a 44px avatar is weak at list scale.
- **Group by day.** A flat 100-row list with only relative timestamps loses the operator's sense of "today vs last week".
- **Filters belong on screen**: type (or family), read/unread, priority. The state already supports type.
- **`data` is evidence** — a `trip_id` or `invoice_id` should be visible on the tile or in a detail, not silently discarded.
- **Bulk mark-all-read must confirm** and should state the count it will affect.
- **The composer is a different job and deserves a different affordance.** It is a *write* surface with a platform-wide blast radius living behind a tab on a *read* surface. Consider: composer as a primary action (dialog / drawer) opened from the inbox header, not a peer tab.
- **The composer must state its own reach** before the send: "سيصل هذا الإشعار إلى ‹N› من عملاء تطبيق العملاء" vs "كل مستخدمي المنصة". A broadcast needs a typed confirmation, not a switch that is on by default.
- **The recipient control must be a person picker**, not a UUID field.
- **Locked state**: when `push_notifications` is off, the composer should render locked with the upgrade path, not fail on submit.

### 12. UX Problems in the current implementation

1. **Two opposite jobs behind peer tabs**, one read-only and safe, one write and irreversible.
2. **Broadcast defaults ON** and is refused for the module's primary audience.
3. **Raw UUID entry** for the recipient with no picker anywhere in the console to source it from.
4. **11 of 17 alert types render identically** as «عام».
5. **Priority is loaded and never shown.**
6. **A built type filter is unreachable.**
7. **Bespoke loading/empty/error views** instead of the three shared ones — three inconsistencies in one screen.
8. **Raw exception strings** shown to operators on send failure.
9. **No confirmation on mark-all-read**, which is irreversible.
10. **Broken deep links**: `/settings/billing`, `/live-trips`, `/support` are not registered routes, so those alerts navigate nowhere and show «غير مصرح».
11. **No search, no pagination, no date grouping** on a feed hard-capped at 100.

### 13. Recommended Information Architecture

```
الإشعارات
├── الوارد  (default; the module's identity)
│   ├── Header: title + unread count + [تعليم الكل كمقروء] (confirmed)
│   ├── Filter bar: search · family · read state · priority
│   ├── Day-grouped feed  (priority-marked, type-iconed, evidence-carrying)
│   └── Alert detail (inline expand or drawer): body · data payload · [افتح الوحدة]
└── إرسال إشعار  → promote to a primary action opening a composer dialog
    ├── Step: من تستهدف؟  (person picker | audience)  ← states reach
    ├── Step: الرسالة      (category · title · body · action link)
    └── Confirm: "سيُرسل إلى N — لا يمكن التراجع"
```
---

## 4.2 ملف المكتب (Office Profile)

### 1. Purpose

The office's own record, split along one axis that the whole screen is organised around:

- **What the office owns and may edit** — its shopfront: name, logo, description, phone, email, service areas. This is literally the card passengers browse in the Client app's office directory.
- **What the platform owns** — `slug` (stable public identifier other rows key off), `status`, `listing_status`, `rating`/`ratings_count` (maintained by a trigger from `trip_reviews`), and `join_code`.

Plus one operational credential that lives nowhere else: the **captain join code**. `submit_captain_request` requires it, and before this card existed the office held a credential it could not read.

### 2. Users / Roles

- Sidebar gate: `DashboardPermission.officeProfile` → **owner only**.
- The screen receives `canEdit: office.role == DashboardRole.admin`. A support agent reaching it would see it **read-only with an explicit notice** rather than being bounced — but the nav gate means they cannot reach it at all today. `[UNCLEAR]` — dead defensive code, or intent to widen the role later.
- Server: `offices_operator_read` (SELECT `id = current_office_id()`), `offices_operator_update` (UPDATE, same office **and** `office_role() = 'dashboard_admin'`).
- **Column privileges are the real boundary.** `revoke all on public.offices from anon, authenticated` then:
  - `grant select (id, name, slug, logo_url, description, phone, email, service_areas, status, rating, ratings_count, created_at, updated_at)`
  - `grant select (listing_status, listed_at)` (added later)
  - `grant update (name, slug, logo_url, description, phone, email, service_areas)` — **and nothing else**
  - `join_code` / `join_code_rotated_at`: **no privilege at all**. Naming them in a `select` makes the whole statement fail with "permission denied for table offices". The code is read only through `office_join_code()`.

> **Note for design:** `slug` **is** DB-updatable by the office. The UI presents it as an immutable chip with the tooltip "المعرّف العام للمكتب — ثابت ولا يمكن تغييره." That is a **product decision enforced only in the UI**, and it is the right one (the slug is unique platform-wide and anything holding the old value breaks). Do not surface it as editable.

### 3. Entry Points

Sidebar only: النظام → ملف المكتب → `/office-profile`. No deep link into it, and nothing else in the console navigates to it.

### 4. Main Screen — information architecture

A single scrolling `ListView` of three stacked blocks:

**(a) `DashboardModuleHeader`** — icon, title «ملف المكتب», subtitle, one action **«تحديث»** (a `FilledButton.icon`), and a collapsible `summary` = `OfficeMarketplaceSummary`.

**(b) `OfficeMarketplaceSummary`** (platform-owned facts, all read-only) — a `DashboardKpiGrid(maxColumns: 3)`:
| KPI | Value | Detail |
|---|---|---|
| حالة الظهور في السوق | `listingLabel` | "يظهر المكتب في دليل العملاء" / "لا يظهر المكتب للعملاء حالياً" |
| تقييم المكتب | `rating` to 1dp, or `—` | "N تقييم" / "لا توجد تقييمات بعد" |
| اكتمال الملف | `((4 - missing)/4 * 100)%` | "كل البيانات مكتملة" / "ينقص: …" |

…followed by a coloured `_Notice` carrying `listingExplanation` — a **long, genuinely useful paragraph** per listing state, plus (when not listed) "النشر والسحب من السوق قرار إداري على مستوى منصة EWT ولا يتم من هنا."

**(c) `OfficeJoinCodeCard`** — title «كود انضمام الكباتن», an explanatory paragraph, the code rendered large/monospace with `letterSpacing: 4` in a tinted box, and **«نسخ الكود»**. If blank: "لم يُصدر كود لهذا المكتب بعد."

**(d) `OfficeIdentityForm`** — `AppCard` titled «بيانات المكتب» with the slug chip in the header, then: اسم المكتب · وصف المكتب (4 lines, `maxLength: 500`) · logo block (72px preview + upload + remove + URL field) · رقم التواصل · البريد الإلكتروني · مناطق الخدمة (chip editor) · **«حفظ بيانات المكتب»** (start-aligned, only when `canEdit`).

> The form is keyed `ValueKey(profile.updatedAt)`, so a successful save **rebuilds the whole form from the server's row** and discards local edits. Correct after a save; it also means any concurrent refresh discards typing. `[UNCLEAR]` risk.

### 5. Data Model

**`OfficeProfile`** — `id`, `name`, `slug`, `description`, `serviceAreas: List<String>`, `status`, `listingStatus`, `rating`, `ratingsCount`, `joinCode`, `logoUrl?`, `phone?`, `email?`, `joinCodeRotatedAt?`, `createdAt?`, `updatedAt?`.

**Two independent status axes — the single most important concept on this screen:**

| Axis | Values | Meaning |
|---|---|---|
| `status` (operational) | `active` · `paused` · `suspended` · `archived` | Whether the office can **work** — whether its staff can sign in, whether it can recruit captains |
| `listing_status` (marketplace) | `draft` · `listed` · `unlisted` | Whether **passengers can see it** |

`isListed = status == 'active' && listingStatus == 'listed'` — the same conjunction `office_is_listed()` applies in the database, so the badge cannot claim a visibility the backend does not grant.

Arabic labels: status → نشط / متوقف مؤقتًا / موقوف / مؤرشف. Listing → قيد التجهيز / معروض في السوق / مسحوب من السوق (wording deliberately identical to the platform admin's office list, so both sides of the platform name the same state alike).

**`missingMarketplaceFields`** — exactly four: وصف المكتب, شعار المكتب, رقم التواصل, مناطق الخدمة. Drives the completeness KPI. Note the platform side counts **five** (it adds البريد الإلكتروني) — the two completeness figures **do not agree**. `[UI GAP]`

**`joinCodeRotatedAt` is always null** — the column sits behind the same privilege revoke and `office_join_code()` returns only the code. Kept on the entity so a future RPC can surface it without a signature change. `[NOT IMPLEMENTED]`

**`OfficeProfileEdit`** — the *only* write surface: `name`, `description`, `serviceAreas`, `logoUrl?`, `phone?`, `email?`. A dedicated type rather than the whole entity, so the write surface is impossible to widen by accident.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? | Permission |
|---|---|---|---|---|---|---|---|
| **Refresh** | «تحديث» | — | — | Full reload | no | no | any who can open |
| **Save profile** | «حفظ بيانات المكتب» | 6 fields | name ≥3 chars & required; email format if non-empty; logo URL must be `http(s)` with a host if non-empty; description `maxLength 500`; blank areas dropped, all values trimmed | `UPDATE offices … .select().maybeSingle()`; `ActionSuccess` → snackbar + `DashboardAuthCubit.refreshContext()` so the shell's name/logo update | no | no | `admin` (UI) + `dashboard_admin` (RLS) |
| **Upload logo** | «رفع صورة الشعار» / «تغيير الصورة» | png/jpg/jpeg/webp, ≤ 2 MB | extension allowlist; size checked client-side *before* upload with a message naming the limit; explicit `contentType` because the bucket restricts `allowed_mime_types` | Uploads to `office-logos/<officeId>/<ts>-<slug>.<ext>`, returns the public URL **into the form field**. **The profile is unchanged until Save** | no | no | owner |
| **Remove logo** | «إزالة» | — | — | Clears the URL field only (the stored object is **not** deleted) | no | no | owner |
| **Add / remove service area** | «إضافة» / chip × | free text | non-empty; **case-insensitive duplicate check** | Local list mutation only | no | no | owner |
| **Copy join code** | «نسخ الكود» | — | — | Clipboard + snackbar «تم نسخ كود الانضمام» | no | no | any who can open |
| **Rotate join code** | — | — | — | **`[NOT IMPLEMENTED]` in the UI** | | | |

> **`[UI GAP]` — `office_rotate_join_code()` exists, is `security definer`, checks `dashboard_admin`, loops until the new code is unique platform-wide, stamps `join_code_rotated_at`, and is `grant execute … to authenticated`. It is called from nowhere in the Flutter codebase.** An office that leaks its join code to the wrong driver has no way to invalidate it. The backend is finished; only the button is missing.

> Storage note: removing a logo or replacing one **orphans the previous object** in the bucket. No cleanup path exists. `[BACKEND GAP]`

### 7. Workflows

**Editing the shopfront**
```
open → GetOfficeProfileUseCase → select(_columns) on offices (RLS-scoped)
                               → office_join_code() RPC  (failure ⇒ empty code, screen survives)
  → operator edits → Save → UPDATE (column privileges + RLS) → returns the stored row
  → ActionSuccess (one frame) → snackbar → Loaded(updated)
  → DashboardAuthCubit.refreshContext() → shell header re-reads name/logo
```

**Uploading a logo (deliberately two-phase)**
```
pick file → size/extension check → uploadBinary to office-logos/<officeId>/…
  → public URL returned → written into the URL field → preview renders it
  → operator still has to press Save; an abandoned upload never becomes the live logo
```

**Recruiting a captain (cross-app, why the card exists)**
```
owner copies the join code → hands it to a driver out of band
  → captain app: submit_captain_request(code) → the code, not a caller-supplied office id,
    decides which queue the request lands in
  → طلبات الكباتن (الأسطول) → owner approves
```

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` (shared) ✔ |
| **Empty** | Not applicable — the office row always exists. If `maybeSingle()` returns null the screen raises "تعذر قراءة بيانات المكتب. سجّل الخروج ثم الدخول مرة أخرى." |
| **Error** | `DashboardErrorState` + retry (shared) ✔ |
| **Saving** | `isSaving` → the whole form disabled, save button shows a spinner and «جارٍ الحفظ...», «تحديث» disabled |
| **Uploading** | `isUploadingLogo` — **tracked separately from `isSaving` on purpose**: an upload is not a save. Only the logo control disables; the preview shows a spinner |
| **Action success** | One-frame `OfficeProfileActionSuccess` → snackbar, then `Loaded` |
| **Action failure** | `OfficeProfileActionFailure` **carries the last good profile** → red snackbar over an intact form |
| **Partial data** | Every field defaults; `listing_status` defaults to `'draft'` when absent (deliberately the pessimistic default) |
| **Read-only** | `_ReadOnlyNotice`: lock icon + "العرض فقط — تعديل بيانات المكتب متاح لحساب المالك." Save button removed entirely |
| **Join code unavailable** | `_fetchJoinCode` swallows failures to `''` on purpose — losing one card beats losing the screen. Renders "لم يُصدر كود لهذا المكتب بعد." — **which is a different statement from "we could not read it"** `[UI GAP]` |
| **Broken logo URL** | `Image.network` `errorBuilder` → a red broken-image icon, visible **before** saving |
| **Offline** | Not handled distinctly |

### 9. Validation & Business Rules

**Implemented (client)**
- Name required, ≥ 3 chars after trim.
- Description ≤ 500 chars (`maxLength`, hard-stops typing).
- Email optional; when present must pass `ContactValidation.isValidEmail`.
- Logo URL optional; when present must parse with scheme `http`/`https` and a non-empty host.
- Logo file: extension ∈ {png, jpg, jpeg, webp}, ≤ 2 MB (mirrors the bucket's `file_size_limit`).
- Service areas: trimmed, blanks dropped, case-insensitive dedupe.
- **Phone has no validation at all** `[UI GAP]` — while the platform-admin onboarding form *does* validate it (7–20 chars). Two forms writing the same column disagree.

**Implemented (server)**
- `offices_listing_status_check`: `listing_status ∈ {draft, listed, unlisted}`.
- Column-level UPDATE grant is the write allowlist (7 columns).
- `offices_operator_update` additionally requires `dashboard_admin`.
- `office-logos` bucket: public read, write only by the office's owner, inside `<officeId>/`, MIME-restricted.
- `rating` / `ratings_count` maintained by a trigger from `trip_reviews`.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` Nothing states who moves an office from `draft` → `listed`, or on what criteria, beyond "قرار إداري على مستوى منصة EWT". The platform side has a hard rule (`office_profile_incomplete` — description + service areas + active status) that **the office is never shown**. The office sees a 4-item completeness checklist that is *not* the publishing criterion.
- `[UNCLEAR]` No maximum on the number of service areas here; the platform onboarding form caps it at 30.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `public.offices` | table, column-privileged | The row |
| `offices_operator_read` / `offices_operator_update` | RLS | Tenant + role boundary |
| `office_join_code()` | RPC | The code (no parameter — resolves from `current_office_id()`) |
| `office_rotate_join_code()` | RPC | **Unused** |
| `office-logos` | Storage bucket | Logo |
| `current_office_context` | RPC (via auth) | Re-read after save |
| `public_offices` | view | What passengers actually see (rendered on the *platform* side, not here) |

### 11. UI Requirements

- **The two status axes must be visually distinct and both explained.** They are the concept operators most often misread ("I'm active, why can't customers see me?"). The `listingExplanation` strings are excellent copy — they deserve a real home, not a tinted paragraph box.
- **Completeness is a call to action, not a statistic.** "٧٥٪" with "ينقص: الشعار" should be a checklist that scrolls to the offending field.
- **Reconcile the two completeness definitions** (office counts 4, platform counts 5) or state plainly that they measure different things.
- **The join code is a credential.** It deserves credential treatment: masked by default with a reveal, copy, "last rotated", and a **rotate** action with confirmation — the backend is ready.
- **The form belongs in the shared form kit** (`DashboardFormSection` + `DashboardFormField` + completion counting + jump-to-error + discard guard). It is currently the only long form in النظام and it is hand-rolled.
- **Save needs a dirty-state guard.** Right now leaving the module (a sidebar click) discards edits with no warning — while the licensing console's plan and feature editors both guard exactly this.
- **Logo, name and description are the shopfront** — they should be previewed *as the passenger sees them* (the platform side already renders `public_offices` as a card; the office cannot see its own).
- Secondary: slug, created/updated timestamps, rating — reference facts, not primary.

### 12. UX Problems

1. **No unsaved-changes guard.** Every peer editor in the console has one.
2. **Hand-rolled form** — inconsistent field chrome, no section grouping, no completion counter, no jump-to-error.
3. **Phone unvalidated here, validated in the platform's form for the same column.**
4. **"لم يُصدر كود" is shown for a failed read**, conflating "no code" with "could not fetch".
5. **No way to rotate the join code**, though the RPC exists and is granted.
6. **Two different completeness counts** for one office.
7. **The publishing criterion is invisible to the office** — it is told it is not listed but not what would make it listable.
8. **Logo removal orphans storage objects.**
9. The form is `ValueKey`'d on `updatedAt`, so any refresh that changes the row wipes in-progress typing.

### 13. Recommended Information Architecture

```
ملف المكتب
├── نظرة عامة        ← identity + the two status axes + rating + completeness checklist
│   └── معاينة بطاقة السوق  (what the passenger sees — read-only preview)
├── بيانات المكتب     ← the editable shopfront (shared form kit, dirty guard, save bar)
│   ├── الهوية      name · description · logo
│   ├── التواصل     phone · email
│   └── التغطية     service areas
└── كود الانضمام     ← credential card: masked · copy · rotated-at · [تدوير الكود] (confirmed)
```
---

## 4.3 الباقة والفوترة (Office Plan & Billing) — **financial**

### 1. Purpose

The office's own commercial screen: **what it bought, what that includes, how much of it it has used, and what it has been invoiced.** It is explicitly *not* a checkout. From the file's own header:

> "The office **cannot change its own plan here** (§17.2): a checkout without a payment gateway would be a lie, and a plan change has proration implications that need a real billing engine. So the call to action is contact, not purchase — and saying that plainly is better than a disabled 'upgrade' button that teaches the owner the console is broken."

### 2. Users / Roles

- `DashboardPermission.officeBilling` → **owner only** in the UI.
- Server: `office_invoices(p_limit, p_offset)` is SECURITY DEFINER, resolves the office from `current_office_id()`, **filters `status <> 'draft'`**, and refuses a caller with no office membership by name (`not_an_office_user` → "حسابك غير مرتبط بمكتب."). It is granted to **all** `authenticated` — see §2.3.
- `office_entitlements` RPC resolves the entitlement document for the caller's office.
- **Read-only end to end.** There is no write path from this screen at all.

### 3. Entry Points

- Sidebar: النظام → الباقة والفوترة → `/office-billing`.
- `LicenseBanner` carries an optional `onOpenBilling` callback labelled «الباقة والفوترة» — **but the banner is rendered in exactly one place: this screen itself**, without that callback. `[UI GAP]` The banner was clearly designed to live on Home/shell and route here.
- **DB triggers point here with `action_url = '/settings/billing'` — which is not a registered route.** Seven emit sites across `licensing_console.sql`, `licensing_billing.sql` and `licensing_lifecycle.sql`. Every licence alert's deep link is dead. `[UI GAP]`

### 4. Main Screen — information architecture

A single `SingleChildScrollView`, top to bottom:

**(a) `LicenseBanner`** — renders only when `license.needsAttention` (`past_due`, `grace`, `suspended`, `cancelled`, `expired`) **or** a trial with ≤ 7 days left. Urgent tone for `grace`/held. Title + body per status, e.g.
- `past_due` → "فاتورة اشتراك متأخرة" / "الحساب يعمل بالكامل. سدّد الفاتورة لتجنّب التقييد."
- `grace` → "مهلة أخيرة قبل تقييد الحساب"
- `suspended`/`cancelled` → "الحساب في وضع القراءة فقط" / "لا يمكن إنشاء رحلات أو سائقين أو خطوط جديدة. التذاكر المُباعة والرحلات الجارية ودخول الكباتن تعمل كالمعتاد."

**(b) `DashboardModuleHeader`** «الباقة والفوترة» / "باقتك الحالية، وما تشمله، وفواتيرك." with a `DashboardKpiGrid`:

| KPI | Value | Detail |
|---|---|---|
| الباقة | `planNameAr` or `—` | `statusLabelAr` |
| التجديد | `licensingDate(periodEnd)` | «تجديد تلقائي» / «بدون تجديد تلقائي» |
| القيمة | `licensingMoney(price, currency)` | شهريًا / سنويًا / عقد مخصص / مجانية |
| باقٍ من التجربة *(trialing only)* | `N يوم` | — |

**(c) الاستخدام** (`DashboardPanel`, only when limits exist) — one `UsageBar` per limit feature, plus the standing caveat: **"الحد يمنع الإضافة الجديدة فقط. لا يُحذف ولا يُعطَّل أي عنصر قائم عند تغيير الباقة."**

**(d) ما تشمله باقتك** (`DashboardPanel`) — non-limit features grouped into seven categories (التشغيل · الأسطول · المبيعات والعملاء · المالية · التقارير والتحليل · التواصل والدعم · المنصة والتوسع), each a `Wrap` of `DashboardStatusChip`s. Chip tooltip: «متاحة في باقتك» / «غير متاحة في باقتك الحالية» / «تتطلب تفعيل ميزة أخرى أولًا». Closes with a locked-icon well: **"لترقية الباقة أو رفع أي حد، تواصل مع إدارة المنصة. تغيير الباقة لا يتم ذاتيًا في هذا الإصدار."**

**(e) الفواتير** (`DashboardPanel`) — a plain `Column` of dense `ListTile`s: invoice number · `period_start → period_end` (+ «استحقاق …» when due) · amount · `InvoiceStatusChip`. Empty: `DashboardEmptyState` "لا توجد فواتير" / "لم تصدر أي فاتورة اشتراك لهذا المكتب بعد."

### 5. Data Model — **keep these six concepts separate**

| Concept | Type | Source | What it is |
|---|---|---|---|
| **CURRENT PLAN** | `LicenseSummary` | `office_entitlements` → `license` | `planKey`, `planNameAr`, `status`, `billingCycle`, `price`, `currency`, `trialEndsAt`, `periodStart`, `periodEnd`, `graceEndsAt`, `autoRenew`, `contractRef`, `suspendedReason` |
| **AVAILABLE PLANS** | — | — | **`[NOT IMPLEMENTED]` on the office side.** The office cannot see what else exists. Plans live only in the platform console |
| **USAGE / ENTITLEMENTS** | `ResolvedFeature` | `office_entitlements` → `features` | `key`, `value`, `valueType` (`boolean`/`limit`/`enum`/`config`), **`source`**, `blockedBy`, `nameAr`, `categoryKey`, `unitAr`, `expiresAt`, `used`, `remaining`, `isPublic`, `enforced`, `sortOrder` |
| **BILLING HISTORY** | `OfficeInvoice` | `office_invoices` RPC | `invoiceNumber`, `total`, `currency`, `status`, `periodStart/End`, `issuedAt`, `dueAt`, `paidAt`, `lineItems` |
| **TRANSACTION HISTORY** | — | — | **`[NOT IMPLEMENTED]`.** `payment_method`, `payment_ref`, `recorded_by` exist on `office_invoices` server-side and are **deliberately excluded** from the office's payload |
| **LICENSE INFORMATION** | the `status` field | | `trialing` · `active` · `past_due` · `grace` · `suspended` · `cancelled` · `expired` · `none` |

**`OfficeInvoice` is deliberately thinner than the platform's `PlatformInvoice`:** no office reference (it is always this office), no `recorded_by`, no internal notes. *"The office reads its licence and its invoices; it does not read the platform's decision trail (§17.7)."* Invoice statuses reaching the office: `issued` · `paid` · `overdue` · `void` · `refunded` — **drafts are filtered out by the RPC.**

**Two limit meter kinds** (documented in the platform's usage panel but **never explained on the office's own screen** `[UI GAP]`):
- **stock** — a COUNT of live rows. Deleting a driver **returns** the quota. Self-healing, cannot drift.
- **flow** — an accumulating counter per period. Deleting a trip does **not** return the quota (otherwise a 100-trip plan would run 1,000).

**`ResolvedFeature.source`** — `kill_switch` | `license_hold` | `override` | `plan` | `default`. The single field that answers *why*. **The office's screen never shows it.** `[UI GAP]`

**`enforced` vs declared** — `OfficeBillingLoaded.included()` filters to `isPublic && enforced`, so a `declared` feature (catalogued and sellable but with no code behind it) is left out entirely. From the code: *"offering an upgrade for something the code cannot deliver is the one thing this screen must never do."* This is a genuinely well-designed rule and must be preserved.

### 6. User Actions

| Action | Trigger | Result |
|---|---|---|
| **Load / retry** | mount, or `DashboardErrorState` retry | `EntitlementService.refresh()` **then** `office_invoices()` |
| — | — | **That is the complete action inventory.** No upgrade, no download, no payment, no filter, no sort, no pagination |

> `load()` deliberately **refreshes** rather than reading cache: *"this is the screen an owner opens because they just paid or just upgraded, and a stale licence document here would tell them the money never landed."*

> **`[UI GAP]`** — `GetOfficeInvoicesUseCase` accepts `limit`/`offset` and the RPC clamps to 200; the cubit calls `_getInvoices()` with the default 50 and no pager exists. An office with >50 invoices silently loses its history.

### 7. Workflows

**Reading your own account**
```
open → EntitlementService.refresh() → office_entitlements RPC (resolver)
     → failure ⇒ full-screen "تعذر تحميل بيانات الباقة." (no partial render)
     → office_invoices(50, 0)
     → failure ⇒ full-screen, but with the repository's *named* sentence when it
       can explain it ("حسابك غير مرتبط بمكتب.")
```

**How a licence actually changes state** — every transition below is a *platform* action or the (currently unscheduled) lifecycle job; the office only observes:
```
trialing ──trial_ends_at passed──────────────► expired ──plan.downgrade_to──► active (free)
active   ──invoice overdue───────────────────► past_due  (fully operational, banner only)
past_due ──grace_days elapsed────────────────► grace     (fully operational, urgent banner)
grace    ──warn_days elapsed─────────────────► suspended (READ-ONLY: creation blocked, delisted)
any      ──platform_set_license_status───────► suspended | cancelled | active
any      ──platform_assign_plan──────────────► trialing | active   (assigning a plan LIFTS a hold)
active   ──period_end && !auto_renew─────────► expired
```

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` ✔ |
| **Error** | `DashboardErrorState` + retry ✔. Two distinct messages: "تعذر تحميل بيانات الباقة." (entitlements) vs the repository's sentence (invoices) |
| **Empty (invoices)** | `DashboardEmptyState` ✔ |
| **Empty (limits)** | The whole الاستخدام panel is omitted when `limits.isEmpty` — **silently**, with no "your plan has no limits" statement `[UI GAP]` |
| **No licence** | `status = 'none'` → `statusLabelAr` = «بدون ترخيص», plan name `—`, banner hidden (`none` is not in `needsAttention`) `[UI GAP]` — an office with no licence at all gets the quietest screen |
| **Over limit** | `ResolvedFeature.isOverLimit` exists; `UsageBar` receives `used`/`limit`. Whether an over-limit state is visually called out depends on `UsageBar` internals; **there is no explanatory notice** the way the platform side has one |
| **Held (suspended/cancelled/expired)** | Banner only. The feature chips still render from the resolver, which will already have downgraded them via `source = 'license_hold'` — **but the chip does not say that is why** `[UI GAP]` |
| **Partial** | Entitlements and invoices are fetched sequentially inside one try; a failure in either produces a full-screen error. **A failed invoice fetch takes the plan panel down with it** `[UI GAP]` — the opposite of the pattern platform_admin uses for its analytics slice |

### 9. Validation & Business Rules

**Implemented**
- Read-only screen; no validation surface.
- `office_invoices` excludes `draft` and clamps `limit` to `[1, 200]`.
- Entitlement resolution ladder (source, highest first): **kill_switch → license_hold → override → plan → default**.
- Dependency gate: a feature whose prerequisite is off resolves blocked, with **both** facts reported (`source` says where the value came from, `blockedBy` says what defeated it) — *"showing only one of them looks like the system ignored the operator."*
- `limit` values are a non-negative integer or the literal `'unlimited'`. **Never `-1`, never null.**
- Limits gate **creation only**. Nothing existing is ever deleted or disabled by a plan change. Stated on screen. ✔
- Suspension **degrades to read-only; it never blacks out.** Sold tickets, running trips and captain sign-in all continue.
- `past_due` and `grace` are **fully operational** states — they warrant a banner, not a block.
- Enforcement is live in production: `platform_settings.enforcement_mode = 'enforcing'` since migration `20260808100000` (default also changed to `'enforcing'`). `EntitlementContext.allows()` returns `true` unconditionally while the mode is `off`/`shadow`.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` Currency is per-licence (`LicenseSummary.currency`, default EGP) and per-invoice. Nothing states what happens if they differ. No FX handling exists.
- `[BUSINESS RULE UNCLEAR]` `refunded` is a valid invoice status the office can see; **no refund flow exists anywhere in the console.** `platform_void_invoice` explicitly refuses paid invoices ("عكس مبلغ محصَّل استرداد وليس تعديلًا") — so `refunded` is reachable only by direct SQL.
- `[BUSINESS RULE UNCLEAR]` `contractRef` is parsed onto `LicenseSummary` and never displayed on either side.
- `[UNCLEAR]` `graceEndsAt` is parsed and never shown, even though "مهلة أخيرة" is precisely the state where a date matters most.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `office_entitlements` | RPC (resolver) | The whole entitlement document + `license` summary |
| `office_invoices(int,int)` | RPC, SECURITY DEFINER | Invoice history, drafts excluded |
| `office_licenses` | table (Realtime) | Watched by `EntitlementService` for live plan/status changes |
| `office_feature_overrides` | table (Realtime) | Watched — an override granted elsewhere updates this screen live |
| `platform_plan_features`, `platform_features` | tables (Realtime) | Watched — plan edits and kill switches propagate live |
| `platform_settings.enforcement_mode` | column | Whether any of it is enforced |

### 11. UI Requirements

- **Answer "what do I owe and when" above the fold.** Today the strongest visual weight goes to the plan *name*; the amount due and the next date are peers of it.
- **The banner is the most important element on the screen and it is on the wrong screen.** It should live in the shell/Home and route here; here it should be a full status block with the date (`graceEndsAt`, `periodEnd`, `trialEndsAt`) and, for held states, `suspendedReason`.
- **Separate the six concepts visually**: current plan · what's included · usage · invoices. Never blend a feature chip with a usage bar with an invoice row.
- **Usage deserves the primary treatment**, not a collapsed panel: it is the only part of this screen that changes daily and the only part that predicts a refusal. Show `used / limit`, remaining, and the meter kind (stock vs flow) — the "why didn't my number go down" question is guaranteed.
- **Explain *why* a feature is off.** `source` and `blockedBy` are already in the payload. "غير متاحة في باقتك الحالية" and "موقوفة على مستوى المنصة" and "معلّقة بسبب حالة الاشتراك" are three different sentences with three different remedies.
- **Invoices are a table, not a `ListTile` list** — they carry number, period, due date, amount, status and (potentially) line items. Use `OpsDataTable` + `DashboardPagerBar` like every other financial list in the console.
- **Line items are fetched and never rendered.** An invoice detail (drawer or expand) showing `line_items` is the natural home.
- **"Contact the platform" must be an actual affordance**, not a sentence in a well — the office's own `phone`/`email` are not the platform's, and no contact detail appears anywhere.
- **Money formatting must match the console** — `licensingMoney` here, `formatMoney` in platform_analytics, `'$rounded ج.م'` — reconcile.

### 12. UX Problems

1. **The plan panel and the invoice list fail together.** A billing outage hides the plan.
2. **`status: 'none'` (no licence) produces the calmest screen in the module.**
3. **No invoice pagination** despite RPC support; >50 invoices are lost.
4. **No invoice detail** — `lineItems` is parsed and discarded.
5. **Feature chips do not say why they are off**, though the resolver said.
6. **The usage panel disappears entirely** when a plan has no limits, with no statement.
7. **`graceEndsAt` / `suspendedReason` never rendered** — the two facts an owner in trouble needs most.
8. **Every licence notification's deep link (`/settings/billing`) is dead.**
9. **The banner has an `onOpenBilling` affordance that is never used**, because it only renders on the destination.
10. **No "available plans" surface at all** — the office cannot see what an upgrade would buy, which makes the "contact us" CTA a dead end.

### 13. Recommended Information Architecture

```
الباقة والفوترة
├── حالة الاشتراك      ← banner-grade block: status · dates (trial/period/grace) · reason
│                        · amount · cycle · auto-renew · [تواصل مع المنصة]
├── الاستخدام والحدود  ← per-limit meters: used / limit / remaining · stock|flow · over-limit callout
├── ما تشمله باقتك     ← features by category, each stating WHY when off (source + blockedBy)
│   └── ما يمكن إضافته  ← optional: purchasable-but-off, as an upgrade conversation
└── الفواتير           ← OpsDataTable + pager + status filter
    └── تفاصيل الفاتورة ← line items · period · due · paid · [تنزيل]  (download = [NOT IMPLEMENTED])
```
---

## 4.4 المستخدمون والصلاحيات (Office Users & Permissions)

### 1. Purpose

The office's **staff directory and account provisioning**. It answers: who can sign into this office's console, as what, and is their account live. It is also the only surface in the product that can **mint a login**, and the only one that reveals a password — once.

The migration that enables it ([`20260815100000_office_staff_provisioning.sql`](supabase/migrations/20260815100000_office_staff_provisioning.sql)) states the split explicitly:

> **SQL owns MEMBERSHIP** — which office, which role, which username, and every rule that keeps an office from locking itself out. *The office is never a parameter: it is `current_office_id()`, resolved from the caller's own JWT.*
> **The Edge Function owns the one step SQL cannot do** — creating the `auth.users` row (needs the Auth Admin API, needs the service-role key, which must never exist in a Flutter binary).

### 2. Users / Roles

- `DashboardPermission.permissions` → **owner only** in the UI. Two routes render it: `/permissions` (sidebar) and `/users` (hidden).
- Server: every mutation opens with `assert_office_staff_admin()` → `not_an_office_user` if no office, `dashboard_admin_required` if not the owner.
- Reads: `get_dashboard_users()` requires only `current_office_id() is not null` — **any active office user can list the roster server-side** (§2.3).
- The Edge Function writes the membership **under this session's own JWT**, so the Dashboard gains no authority through it.

> **Every mutation goes through an RPC rather than a direct table write.** RLS *would* allow the writes (`office_users_admin_manage` covers them) — but *"a policy sees one row at a time and cannot express the rule that actually matters: an office must never be left without an active owner."*

### 3. Entry Points

Sidebar: النظام → المستخدمون والصلاحيات → `/permissions`. `/users` is an equivalent hidden alias. Nothing else links here.

### 4. Main Screen — information architecture

`UsersScreen` → `BlocProvider(UsersCubit..load())` → `_UsersView`, a `ListView`:

**(a) `DashboardModuleHeader`** «المستخدمون والصلاحيات» / "حسابات لوحة التحكم الخاصة بمكتبك — أنشئ حساباً لكل موظف وحدّد ما يراه."
- Secondary action: **«تحديث»** (`OutlinedButton.icon`)
- **Primary action: «إضافة مستخدم»** (`FilledButton.icon`)
- `pinned:` a `DashboardCollapsibleSection.bare` («البحث والتصفية», `sectionId: users.filters`) whose collapsed summary reads `['بحث: …', 'الدور', 'N/M مستخدم']`

**(b) `_UsersToolbar`** (inside the collapsible) — `DebouncedSearchField` ("بحث بالاسم أو اسم الدخول أو الدور...") + a **الدور** dropdown (كل الأدوار / المالك / خدمة العملاء) + a `DashboardStatusChip` "N/M مستخدم". Responsive: stacks below 760px.

**(c) The roster** — **not a table**: a stack of `AppCard` rows (`_UserAccessRow`), each:
`CircleAvatar` (2-char initials, tinted by active state) · displayName + «(أنت)» · username (monospace) · "منذ N يوم" · «معطّل» chip when disabled · an **inline role `DropdownButton`** · a `⋯ PopupMenuButton` (تعيين كلمة مرور جديدة · تعطيل/تفعيل الحساب).

Two distinct empty states (both `DashboardEmptyState` ✔): "لا يوجد مستخدمون مسجلون بعد" and "لا توجد نتائج مطابقة".

**(d) `StaffCredentialsPanel`** — a **full-screen state**, not a dialog. When `UsersCredentialsIssued` is emitted it **replaces the entire screen** until dismissed, because *"the password exists in no log and no table, so losing it to a rebuild would lose the only copy."*

### 5. Data Model

**`AppUser`** — the `office_users` row.

| Field | Meaning |
|---|---|
| `id` | The **`office_users` row id** — the *membership*. **Every action names this**, never `userId` |
| `userId` | The `auth.users` account behind it |
| `username` | What the operator types at sign-in. A **login name, never an address** |
| `fullName` | Display name |
| `role` | `DashboardRole` |
| `status` | `active` \| `disabled` |
| `email` | The synthetic `<username>@office.ewt.internal` address. **Nobody ever types or reads it** |
| `createdAt` | |

> The `id` / `userId` split is load-bearing: *"every server-side rule ('is this row in my office?', 'is this the last owner?') is a statement about the membership, not about the login."*

**`StaffAccountRequest`** — `username`, `fullName`, `role` (**defaults to `supportAgent`** — "an unset role must never mean owner"), `password` (**blank ⇒ generate server-side**). Deliberately holds **no `officeId` and no `status`**: *"a request object that could carry an office id would be a request object someone eventually populates — and it is the one value on this wire worth tampering with."*

**`StaffCredentials`** — `username`, `temporaryPassword?` (**null when the owner chose the password** — the server does not echo a secret it was handed), `isReset`.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? | Permission |
|---|---|---|---|---|---|---|---|
| **Create account** | «إضافة مستخدم» → dialog → «إنشاء الحساب» | fullName, username, role, generate-password switch, password | see §9 | Edge Function creates `auth.users` → `office_create_staff` binds the membership → **refetches** the list (never appends: "the row the server wrote carries the id, timestamp and synthetic address only it knows") → `UsersCredentialsIssued` | dialog is the confirm | no | owner |
| **Reset password** | `⋯` → «تعيين كلمة مرور جديدة» → dialog | generate switch, or a ≥10-char password | ≥10 chars if manual | `office_staff_reset_target` (authorises under the caller's JWT) → Auth Admin API → `UsersCredentialsIssued` | dialog states "كلمة المرور الحالية … ستتوقف عن العمل فوراً" | **yes — the old password dies immediately** | owner |
| **Change role** | Inline dropdown on the row | new role | server: `invalid_role`, `cannot_change_own_role`, `last_admin_required` | `office_update_staff_role` returns the updated row → **swapped in place**, no refetch | **no** `[UI GAP]` | **yes — promoting to المالك grants every permission including user management** | owner |
| **Disable account** | `⋯` → «تعطيل الحساب» | — | server: `cannot_disable_self`, `last_admin_required` | `office_set_staff_status(disabled)`; refused at sign-in from the moment the row is written | **yes** — AlertDialog "لن يتمكن «X» من تسجيل الدخول بعد الآن. يمكنك إعادة تفعيل الحساب في أي وقت." | reversible | owner |
| **Enable account** | `⋯` → «تفعيل الحساب» | — | Re-activation is **metered by `trg_quota_operator_reactivate`** against `max_admin_users` | `office_set_staff_status(active)` | no (correct — non-destructive) | no | owner |
| **Search / filter** | toolbar | — | — | In-memory over `userId`, `username`, `fullName`, `email`, `role.label` | — | — | — |
| **Refresh** | «تحديث» | — | — | Reload | — | — | — |
| **Delete account** | — | — | — | **`[NOT IMPLEMENTED]` — deliberately** | | | |

> **There is no delete, by design:** *"Removing an `office_users` row orphans an `auth.users` row that still holds the username — `uq_office_users_username` is global — so the name could never be reused, and the office would lose the audit trail of who acted while they worked there. Disabling is the reversible, honest operation."* **The design must never offer a delete.**

**Self-guards, rendered inert in the UI rather than left to fail:** the signed-in operator's own row has its role dropdown `onChanged: null` and its «تعطيل الحساب» menu item `enabled: false`. Matched **on username**, because `uq_office_users_username` is unique platform-wide. *"Showing live controls that are guaranteed to fail is worse than not showing them."*

### 7. Workflows

**Creating a colleague's login**
```
«إضافة مستخدم» → dialog (barrierDismissible: false)
  → local StaffAccountRequest.validate()  — a bad username never costs a round trip,
    and never reaches the Edge Function, which would create an auth user and then
    have to compensate for it
  → POST office-manage-user {action: create, username, role, full_name?, password?}
      ├─ office_staff_username_available(username)   → username_taken (409)
      ├─ Auth Admin API create user  (role: 'office_user' — load-bearing metadata)
      └─ office_create_staff(user_id, username, role, full_name)  [under the caller's JWT]
  → success ⇒ refetch roster ⇒ UsersCredentialsIssued
  → the DIALOG closes on exactly one signal: UsersCredentialsIssued
  → the SCREEN is replaced by StaffCredentialsPanel (full width)
  → «حفظت البيانات — إغلاق» → back to the roster
```
*The dialog stays open across a failed submission on purpose* — closing on submit would throw away the per-field errors and leave the owner with a snackbar and an empty form to retype. The refusal is rendered **inside** the dialog (`_FailureBanner`), because a snackbar posted to the scaffold under a modal barrier is invisible.

**Resetting a password**
```
⋯ → «تعيين كلمة مرور جديدة»
  → showStaffPasswordDialog returns: null = cancelled, '' = generate, 'xxx' = chosen
    (empty rather than null for "generate" because cancelling and generating are
     different decisions)
  → office_staff_reset_target(office_user_id)  ← authorisation answered HERE, under the
    caller's JWT, so the service-role key can never be pointed at another office
  → Auth Admin API updates the password
  → UsersCredentialsIssued (isReset: true)
```

**The three lockout rules** (SQL, verbatim intent):
1. An admin may not change their **own** role — `cannot_change_own_role`.
2. An admin may not disable their **own** account — `cannot_disable_self`.
3. The **last active `dashboard_admin`** may not be demoted or disabled — `last_admin_required`.

Rule 3 is documented as a deliberate backstop that is *currently unreachable* given rules 1 and 2, kept because *"an office with no active owner cannot be repaired from inside the product at all, so the invariant is worth asserting twice."*

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` ✔ |
| **Empty** | `DashboardEmptyState` — "لا يوجد مستخدمون مسجلون بعد" ✔ |
| **No search results** | `DashboardEmptyState` with a search-off icon ✔ |
| **Error (load)** | `DashboardErrorState` + retry ✔ |
| **Submitting** | `UsersLoaded(isSubmitting: true)` — form disabled, button spinner, **the list stays exactly where it was** |
| **Action success** | One-frame `UsersActionSuccess` → snackbar; the row is swapped in place from the server's own returned row, *"so there is nothing to refetch and no window where the screen shows a value the database disagrees with"* |
| **Action failure** | `UsersActionFailure` carries the same list **and** `fieldErrors` keyed exactly as `validate()` keys them, so the form can mark the offending input |
| **Credentials issued** | A distinct **full-screen** state that must be explicitly dismissed |
| **Permission denied** | Server code → Arabic: `dashboard_admin_required` → "إدارة المستخدمين متاحة لمالك المكتب فقط." |
| **Quota exceeded** | `LicensingGuard` intercepts first; `LicensingFailure` is matched **before** the generic mapper in `UsersCubit._message` — *"falling through would print `Instance of 'LicensingFailure'` at the exact moment an office hits its operator limit"* |
| **Offline** | `_invokeManage` catch-all → "تعذر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى." ✔ |

### 9. Validation & Business Rules

**Username** — validated in **three** places (Dart, Edge Function, and `office_create_staff`), because *"the RPC is directly callable by any office owner, so it cannot trust either layer above it."*
- Regex `^[a-z0-9][a-z0-9._-]*$`, length 3–32, lowercased and trimmed.
- **Unique platform-wide** (`uq_office_users_username` on `lower(username)`) — a taken name is a normal outcome, not a surprise.
- `office_staff_username_available()` deliberately looks **outside** the caller's office and answers only "is this name free" — never who holds it, which office, or whether they are active.
- **Immutable after creation** — stated in the helper text; there is no rename path.

**Full name** — optional, ≤ 120 chars.
**Password** — optional; when supplied, ≥ 10 chars. Blank ⇒ generated server-side and returned **exactly once**.
**Role** — `dashboard_admin` | `support_agent`; defaults to `support_agent` at every layer.
**Status** — always `active` on create: *"provisioning a pre-disabled account is not a product need, and it would sidestep the reactivation quota."*
**Already-assigned user** — `staff_user_already_assigned`. Deliberately *not* modelled on `link_office_user()`, whose `ON CONFLICT (user_id) DO UPDATE` would **move** an operator from another office into this one.

**Licensing** — untouched and unbypassed. `trg_quota_office_users` meters the INSERT against `max_admin_users`; `trg_quota_operator_reactivate` meters re-activation; `trg_readonly_office_users` refuses writes on a read-only licence. *"These functions are SECURITY DEFINER for the office lookup, not to escape those triggers — triggers fire regardless of the invoking role."*

**The full server error vocabulary** (each mapped to Arabic in `SupabaseUsersDatasource._messageForCode`): `dashboard_admin_required`, `not_an_office_user`, `not_authenticated`, `username_taken`, `invalid_username`, `invalid_full_name`, `weak_password`, `invalid_role`, `cannot_change_own_role`, `cannot_disable_self`, `last_admin_required`, `staff_user_already_assigned`, `staff_not_found` / `staff_user_not_found`, `auth_user_creation_failed`, `password_reset_failed`.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` Only **two** roles exist. The catalogue has a `custom_roles` feature key — no implementation exists. Any design must not imply a third role.
- `[UNCLEAR]` A disabled operator's rows stay for the audit trail, but **no audit trail surface exists for office staff actions** (unlike the platform's `platform_audit_log`).
- `[UNCLEAR]` The role dropdown's description text lives in `staff_account_form.dart` (`_roleDescription`) and is shown **only in the create dialog** — not next to the inline role dropdown on the roster, where the change actually happens.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `get_dashboard_users()` | RPC, SECURITY DEFINER | The roster (id, user_id, username, full_name, email, role, status, created_at) |
| `office-manage-user` | Edge Function | `create` and `reset_password` (holds the service-role key; used for exactly three calls: create user, update password, delete user) |
| `office_create_staff(uuid,text,text,text)` | RPC | Binds an existing auth user to the **caller's** office |
| `office_update_staff_role(uuid,text)` | RPC | Role change + lockout rules |
| `office_set_staff_status(uuid,text)` | RPC | Enable/disable + lockout rules |
| `office_staff_reset_target(uuid)` | RPC | Resolves membership → auth user id, under the caller's JWT |
| `office_staff_username_available(text)` | RPC | Pre-flight, platform-wide |
| `assert_office_staff_admin()` | internal predicate | The single gate in front of all five |
| `office_has_other_admin(uuid,uuid)` | internal predicate | `last_admin_required` |
| `office_staff_row(office_users)` | internal | **One row shape** for create / role / status, so the UI maps once and replaces in place |
| `trg_quota_office_users`, `trg_quota_operator_reactivate`, `trg_readonly_office_users` | triggers | Licensing |
| `resolve_office_user_login`, `current_office_context` | RPCs | Both require `status = 'active'` — a disabled operator cannot sign in |

### 11. UI Requirements

- **This is a directory, and it is currently drawn as a card stack.** Six other list modules use `OpsDataTable` + `DashboardResultsHeader` + `DashboardPagerBar`. A roster with name, login, role, status, created and actions is a table.
- **Role change must confirm.** It is the single most consequential action here — promoting to المالك grants user management itself — and it is currently a one-tap inline dropdown with no confirmation, no reason, and no undo. Disabling (reversible) confirms; promoting (which the promoted user can then use to lock you out) does not.
- **Explain the roles where the choice is made.** `_roleDescription` is good copy trapped in the create dialog.
- **The credential reveal is right and must be preserved**: full-screen, explicit dismissal, monospace selectable values, per-field copy, and a red warning that it will not be shown again. Do not turn it into a toast or a dialog.
- **Show the licensing headroom.** `max_admin_users` is metered on create and re-activation; a "٥ من ٨ مقاعد" counter turns a hard refusal into an expected one. `DashboardCapNotice` exists for this.
- **Status deserves a queue tab, not a chip** — نشط / معطّل are the two states an operator scans by.
- **Never show a delete.** Disable is the removal.
- **Distinguish membership from account.** Nothing in the UI explains why an account cannot be renamed or deleted; one line would.
- Secondary/hidden: `userId`, the synthetic email, `createdAt` precision.

### 12. UX Problems

1. **Role promotion is unconfirmed and irreversible-in-practice.**
2. **Cards where the console uses tables**; no sort, no pagination, no results header.
3. **Role semantics are explained only at creation**, never at change.
4. **No quota visibility** — the operator meets `max_admin_users` as a surprise refusal.
5. **Two routes (`/permissions`, `/users`) for one screen**, with the sidebar label duplicated on a hidden item.
6. **Search matches `userId`** (a raw UUID the operator can never see) but the roster does not display it.
7. **`fieldErrors` are plumbed through `UsersLoaded` and `UsersActionFailure`** but the roster's inline role dropdown has nowhere to show them — only the dialog does.
8. **No audit of who changed whose role**, in a module whose whole subject is authority.
9. Hand-rolled form (see §3.3).

### 13. Recommended Information Architecture

```
المستخدمون والصلاحيات
├── Header: title · [تحديث] · [إضافة مستخدم]  · seat counter "N من M مقعد"
├── Queue tabs: الكل · نشط · معطّل
├── Filter bar: search · role  (DashboardFilterBar)
├── Results header: "N مستخدم" · sort
├── Table (OpsDataTable): الاسم · اسم الدخول · الدور · الحالة · تاريخ الإضافة · ⋯
│   └── ⋯ : تغيير الدور (confirmed) · تعيين كلمة مرور جديدة · تعطيل/تفعيل
├── Pager
├── Dialog: إضافة مستخدم        (shared form kit; stays open on failure)
├── Dialog: تعيين كلمة مرور     (states the old password dies immediately)
└── Full-screen: بيانات الدخول  ← the one-time reveal (unchanged)
```
---

## 4.5 الإعدادات (Settings)

### 1. Purpose

**As implemented: a theme switch, a disclaimer, and a duplicate sign-out.** The whole module is 144 lines in one file with no cubit, no domain layer and no data layer.

Its own second card states the intent honestly: *"إعدادات الصلاحيات وتبديل التطبيقات الداخلية لا تظهر في واجهة الإنتاج. يتم التحكم بها من إعدادات النشر والإدارة."* — i.e. the settings that would belong here are managed outside the product.

`[PARTIALLY IMPLEMENTED]` — this is a placeholder wearing a module's clothes.

### 2. Users / Roles

`DashboardPermission.settings` → **owner only**. A support agent cannot reach it, and therefore cannot change the console's theme. `[UI GAP]` — the theme is a per-operator preference gated behind an ownership permission.

Nothing on the screen is office-scoped or server-persisted. `DashboardThemeRepository` writes to **`SecureStorage`** under `dashboard_theme_mode` — device-local, per-install, not per-account.

### 3. Entry Points

Sidebar: النظام → الإعدادات → `/settings`. Nothing links here.

### 4. Main Screen — information architecture

A `ListView` with a `DashboardModuleHeader` («الإعدادات» / "إعدادات عامة للوحة التشغيل وتجربة المستخدم.") and **three `AppCard`s**:

1. **مظهر اللوحة** — a `SegmentedButton<ThemeMode>` with exactly two segments: **فاتح** / **داكن**.
2. **صلاحيات التشغيل** — an icon + a paragraph. **Pure text; no control.**
3. **تسجيل الخروج** — a `ListTile` in error colour, "إنهاء الجلسة الحالية", confirmed by an `AlertDialog` ("هل تريد إنهاء جلستك الحالية؟" · إلغاء / خروج) then `DashboardAuthCubit.signOut()`.

### 5. Data Model

**`DashboardThemeState`** — `themeMode: ThemeMode`, `isLoading: bool`, `errorMessage: String?`.
**Persisted value** — one string in secure storage: `'light'` | `'dark'` | `'system'`.

> **`[UI GAP]` — `ThemeMode.system` is supported by the repository and the cubit and is the initial state, but the `SegmentedButton` offers only two options and coerces `system` → `light` for display:** `state.themeMode == ThemeMode.dark ? dark : light`. An operator on system-follow sees "فاتح" selected and can never get back to system once they touch it.

> `DashboardThemeState.isLoading` and `errorMessage` are set by the cubit and **never read by any widget**. `[UI GAP]`

### 6. User Actions

| Action | Trigger | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|
| **Switch theme** | `SegmentedButton` | none | Optimistic emit, then `SecureStorage.write`. **A write failure is emitted as `errorMessage` and never displayed** | no | no |
| **Sign out** | `ListTile` | none | `AlertDialog` → `signOut()` → session cleared, entitlements cleared, `DashboardAuthSignedOut` | **yes** ✔ | ends the session (recoverable by signing in) |

That is the complete action inventory.

### 7. Workflows

```
theme:    tap segment → emit(mode) → repository.saveThemeMode → SecureStorage
sign-out: tap → AlertDialog → signOut() → repository.signOut()
                                        → DashboardSession.clear()
                                        → EntitlementService.clear() (+ unwatch Realtime)
                                        → login screen
```

The **same sign-out** exists in the shell's top bar (`_DashboardTopBar`, tooltip «تسجيل الخروج», its own confirmation dialog at `dashboard_shell.dart:1301`). Two implementations of one action, both confirmed, in two places. `[UI GAP]`

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | None. The screen is synchronous; `DashboardThemeCubit.load()` runs at app start, not here |
| **Empty** | Not applicable |
| **Error** | **Silently swallowed** — `errorMessage` is never rendered |
| **Success** | Immediate segment change |
| **Permission denied** | Unreachable — the nav gate is the only guard |
| **Offline** | Irrelevant; nothing here touches the network except sign-out |

### 9. Validation & Business Rules

**Implemented:** none beyond the sign-out confirmation.

**Absent / unclear**
- `[NOT IMPLEMENTED]` No language/locale control, though the app ships `AppLocalizations` and `l10n.yaml`.
- `[NOT IMPLEMENTED]` No density, date-format, currency-format, timezone, or notification-preference control.
- `[NOT IMPLEMENTED]` No "reset collapsed sections" control, though `DashboardSectionStateStore` persists a per-section collapse state across the whole console — currently unresettable.
- `[NOT IMPLEMENTED]` No office-level operational settings (grace periods, default filters, working hours…).
- `[BUSINESS RULE UNCLEAR]` The card says operational permissions "يتم التحكم بها من إعدادات النشر والإدارة" — there is no such surface in the product. This is a statement about a deployment process, shown to an office owner who has no access to it.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `SecureStorage` (`flutter_secure_storage`) | local | `dashboard_theme_mode` |
| `supabase.auth.signOut()` | Auth | End the session |

**No tables, no RPCs, no views, no realtime.** This is the only module in either section with zero backend surface.

### 11. UI Requirements

The design question here is **what this module should be**, because today it is nearly empty while carrying a top-level sidebar row.

Two honest options:

- **(A) Retire it.** Move the theme toggle into the shell's top-bar user menu (next to the sign-out already there) and delete the sidebar row. This is the truthful option given the content.
- **(B) Make it real.** Give it the settings that genuinely exist but are scattered or unreachable:
  - Appearance: **three** modes (فاتح / داكن / حسب النظام) — the repository already supports it.
  - Interface: reset all collapsed sections (`DashboardSectionStateStore`); reset remembered filters (`DashboardFilterMemory`).
  - Session: signed-in identity, office, role, `isPlatformAdmin`, and sign-out — the *only* place the operator can see who they are signed in as.
  - Office operations: whatever office-level preferences the product decides to own.
  - About: app version, environment/flavor, a support contact.

Either way: **do not leave a top-level destination whose only working control is a two-way theme switch.** And whichever is chosen, the theme must be reachable by a support agent.

### 12. UX Problems

1. **A sidebar destination with essentially no content** — one control, one paragraph, one duplicate.
2. **Duplicated sign-out** with two independent confirmation dialogs.
3. **`ThemeMode.system` is unreachable** despite full support underneath.
4. **Theme is gated behind an owner-only permission** although it is a per-device preference.
5. **The "صلاحيات التشغيل" card explains a control the reader cannot reach**, in a product that has no such control.
6. **Errors are swallowed** — a failed secure-storage write is silent.
7. **No identity display** — nowhere does the console state "you are signed in as X of office Y with role Z" in a stable, readable place.

### 13. Recommended Information Architecture

```
الإعدادات   (only if kept — otherwise fold into the top-bar user menu)
├── الحساب والجلسة   ← who you are · office · role · [تسجيل الخروج]   (single source)
├── المظهر           ← فاتح / داكن / حسب النظام
├── الواجهة          ← reset collapsed sections · reset remembered filters
└── حول التطبيق      ← version · environment · support contact
```
---

# 5. Section 2 — المنصة

> Every module in this section is `platformOnly: true` and drawn only when `OfficeContext.isPlatformAdmin`.
> That flag is **a hint for the shell, nothing more** — every RPC behind these screens re-checks
> `is_platform_admin()` server-side, so a forged flag lands on a screen whose every action is refused.

---

## 5.1 مكاتب المنصة (Platform Offices)

### 1. Purpose

EWT's tenant directory and the **only** surface that can see offices no client can. From the entity's own header:

> *"`platform_list_offices()` is the only surface that returns draft, paused and suspended offices: RLS on `offices` shows an operator their own row plus the listed ones, which is deliberately the wrong set for the platform, since the offices needing attention are exactly the ones nobody can see."*

It does three jobs: **onboard a new office with its first administrator**, **decide which offices the client marketplace shows**, and **watch how every office is actually trading**.

### 2. Users / Roles

- `DashboardPermission.platformOffices` + `platformOnly: true`.
- Every RPC calls `assert_platform_admin()` / `is_platform_admin()`.
- Onboarding runs through the **`platform-create-office` Edge Function** (needs the Auth Admin API for the `auth.users` row); the office data it writes is still written by `platform_create_office` **under the caller's JWT**, so the Dashboard gains no authority it does not already have.

### 3. Entry Points

- Sidebar: المنصة → مكاتب المنصة → `/platform-offices`.
- **Outbound hand-off**: «الميزات والحدود» on any office card *and* in the details panel calls `onOpenFeatures(officeId)` → `_openOfficeFeatures` in the shell → `_openRoute('/platform-licenses')` + `PlatformLicensingCubit.openOffice(officeId)`. The hand-off is a route change **plus a selection**, because the licensing console is one long-lived cubit shared by three destinations — *telling it which office to open is the navigation*. `openOffice` waits for a load already in flight, so the jump lands even when التراخيص has never been visited this session.
- **Inbound**: the attention queue's rows call `cubit.openDetails(officeId)` in place.

### 4. Main Screen — information architecture

`MasterDetailLayout` (`masterFlex: 3`, `detailFlex: 4`) — the **detail is wider than the master**. The master is a `ListView`:

**(a) `DashboardModuleHeader`** «مكاتب المنصة» / "أداء كل مكتب على المنصة، وإنشاء مكتب نقل جديد بحساب مسؤوله الأول، والتحكم في ظهوره داخل سوق العملاء."
Actions: **«مكتب جديد»** (primary) · **«تحديث»**.

**(b) `PlatformOverviewPanel`** — the analytics half, five stacked blocks:
1. **`_WindowSelector`** — `SegmentedButton` over **7 / 30 / 90 يوم**, plus a "generated at" stamp.
2. **`_HeadlineKpis`** — 6 `DashboardKpiCard`s: إيراد آخر N يوم · حجوزات آخر N يوم · مكاتب نشطة تجارياً · رحلات متاحة للحجز · مدفوعات بانتظار المراجعة · إشغال المقاعد.
3. **`_AttentionQueue`** — every flagged office, worst first, each row opening that office. **Computed over the *unfiltered* office list on purpose**: *"a queue that hid problems because the operator was searching for something else would be worse than no queue."*
4. **`_TrendAndLeaders`** — a daily-bookings line chart across the platform + a ranked bar chart «المكاتب الأعلى إيراداً».
5. **`_PortfolioBreakdown`** — 13 counts: إجمالي · نشطة · معروضة في السوق · قيد التجهيز · مسحوبة · موقوفة · بانتظار العرض · معروضة بلا رحلات · بلا مسؤول نشط · رحلات فات موعدها · تذاكر دعم مفتوحة · طلبات كباتن معلقة · مكاتب جديدة خلال N يوم.

**(c) `PlatformOfficeFilters`** — search + **status** + **listing status** + **activity** + **sort** + clear, with a result/total count. `hasMetrics` disables the activity facet until analytics lands.

**(d) The list** — `PlatformOfficeCard` per office: logo/name/slug · activity chip · listing chip · status chip · 5 lifetime `_Stat`s (مشغّلون · سائقون · مركبات · مسارات · رحلات) · 5 windowed `_Metric`s (إيراد المدة · حجوزات المدة · رحلات قادمة · إشغال · تقييم) · owner label · **inline actions**: «الميزات والحدود» · «سحب من السوق» / «عرض في السوق» · «إيقاف» / «تفعيل».

**(e) The details panel** (`PlatformOfficeDetailsPanel`) — header (name + slug + close), then a **full-width primary button «الميزات والحدود المتاحة لهذا المكتب»** placed above everything else deliberately, then five sections:
`بيانات المكتب` (identity + profile completeness) · `التشغيل` (counts) · `الأداء خلال N يوم` (windowed metrics — **omitted entirely if analytics has not loaded**) · `السوق` (marketplace preview + listing actions) · `مسؤولو المكتب` (operator roster).

### 5. Data Model

**`PlatformOffice`** (from `platform_list_offices`) — `id`, `name`, `slug`, `description`, `serviceAreas`, `status`, `listingStatus`, `rating`, `ratingsCount`, `operators`, `drivers`, `routes`, `vehicles`, `trips` (**lifetime** — the cheapest answer to "has this office ever traded"), `ownerName?`, `ownerUsername?` (**the office's first active `dashboard_admin`; null means nobody can sign in — a state worth seeing rather than papering over**), `logoUrl?`, `phone?`, `email?`, `listedAt?`, `createdAt?`, `updatedAt?`.

Derived, and load-bearing for the UI:
- `blockersToListing` — **mirrors the RPC's `office_profile_incomplete` guard exactly**: `status != 'active'` → «المكتب غير نشط»; empty description → «وصف المكتب مفقود»; empty service areas → «لم تُحدَّد مناطق الخدمة». So the publish button is disabled **with a reason** instead of failing on press.
- `profileFields` — **five** fields (الوصف · مناطق الخدمة · الشعار · رقم الهاتف · البريد الإلكتروني). *"The blockers say what is forbidden; this says what is thin, which is the more useful thing to show before pressing publish."* (Note: the office's own screen counts **four** — see §4.2.)

**`PlatformOfficeDetails`** — wraps `PlatformOffice` (one definition of "is listed"), plus:
- `counts: PlatformOfficeCounts` — operators, drivers, vehicles, routes, trips, bookings, reviews. **Magnitudes only, never the rows behind them.**
- `operators: List<PlatformOfficeOperator>` — username, fullName, role, status, createdAt. **No email, no password path** — *"dashboard logins are synthetic addresses that receive no mail, so surfacing one would leak a login handle while telling the reader nothing."*
- `marketplace: PlatformOfficeMarketplacePreview?` — read from the **same sanitised `public_offices` view the Client app reads**. Null is not missing data, it is the answer: a passenger sees nothing. `marketplaceAbsenceReason` names *which axis* is at fault, because *"a withdrawn office needs publishing, a suspended one needs reinstating first."*

Server-side exclusions are explicit: no operator emails or passwords, no join code, no captain phone numbers, no client PII, no payment credentials, no booking rows.

**`PlatformAnalytics`** (from `platform_office_analytics(p_window_days)`) — `windowDays`, `totals: PlatformTotals` (28 fields), `trend: List<PlatformTrendPoint>` (**quiet days present as zeros — the server generates the calendar**), `offices: Map<officeId, PlatformOfficeMetrics>`, `generatedAt`.

**`PlatformOfficeMetrics`** — 30 fields including `upcomingTrips` (dated today or later **and** still open — what a passenger can actually buy), `staleTrips` (past-dated and still open, **never auto-closed by design**), `paymentsAwaitingReview` / `paymentsAwaitingAmount` (**a workload signal, never counted as revenue**), `revenueTotal`/`revenueRecent` (**summed from approved booking payments, not from `operation_trips.revenue`, which is unmaintained and reads 0 platform-wide**), `activeAdmins`, `lastBookingAt`, `averageRating`.

Derived verdicts: `activityLevel ∈ {active «نشط», idle «خامل», never «لم يبدأ»}`; `cancellationRate` is **lifetime, not windowed** (*"a cancellation habit is a property of how the office operates"*); `occupancyRate` is **null when no seats were offered** — *"0% would claim nobody bought, when in fact nothing was for sale."*

**`OfficeAttention`** — the flag list, with severity `critical` > `warning` > `info`:

| Severity | Flag | Condition |
|---|---|---|
| critical | لا يوجد مسؤول نشط | `activeAdmins == 0` |
| critical | معروض بدون رحلات قادمة | `isListed && upcomingTrips == 0` |
| warning | مدفوعات بانتظار المراجعة | `paymentsAwaitingReview > 0` |
| warning | رحلات فات موعدها | `staleTrips > 0` |
| warning | توقف عن النشاط | `isIdle` (traded before, not in window) |
| warning | نسبة إلغاء مرتفعة | `cancellationRate ≥ 0.3 && totalBookings ≥ 5` |
| warning | تقييم منخفض | `reviewsTotal ≥ 3 && averageRating < 3` |
| info | لم يبدأ العمل بعد | `totalBookings == 0 && ageDays ≥ 7` |
| info | طلبات كباتن معلقة | `pendingCaptainRequests > 0` |
| info | تذاكر دعم مفتوحة | `openTickets > 0` |

**`OfficeOnboardingRequest` / `OfficeOnboardingResult`** — see §6/§9. The result carries **two one-time reveals**: the generated password **and** the join code, neither readable again through any platform surface.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Onboard an office** | «مكتب جديد» | office identity (name, slug?, description, logo URL, phone, email, service areas) + first admin (username, full name, password?) | Local `validate()`, again in the Edge Function, again in the RPC | Office created `active` + **`draft`**; admin created; join code minted → `PlatformAdminOnboarded` full-screen reveal | dialog | no |
| **Publish** («عرض في السوق») | card **and** panel | — | Disabled unless `canBeListed`; server re-checks `office_profile_incomplete` / `office_not_active` | `listing_status = 'listed'` → the office appears in `public_offices` | **card: NO. panel: YES** `[UI GAP]` | passengers can now book it |
| **Withdraw** («سحب من السوق») | card **and** panel | — | — | `listing_status = 'unlisted'`; the office keeps working | **card: NO. panel: YES** `[UI GAP]` | **yes — instantly removes a live merchant from the marketplace** |
| **Suspend** («إيقاف») | card **and** panel | — | — | `status = 'suspended'` — **locks the office's own staff and captains out** | **yes**, both | **yes, severely** |
| **Activate** («تفعيل») | card **and** panel | — | — | `status = 'active'` | no | no |
| **Set `paused` / `archived`** | — | — | — | **`[NOT IMPLEMENTED]`** — `SetOfficeStatusUseCase` accepts all four and `PlatformOfficeFilters` offers all four as *filters*, but only `active`/`suspended` are reachable as actions | | |
| **Open details** | Card tap / attention row | — | — | Panel opens **before** the fetch resolves so the operator sees which office they picked; a late-landing fetch for a different office is dropped | no | no |
| **Open feature board** | «الميزات والحدود» | — | — | Cross-module hand-off to التراخيص | no | no |
| **Change window** | 7/30/90 | — | clamped `[1,365]` | **Only analytics refetches** — *"refetching the office list would make a chart control flicker the whole screen"* | no | no |
| **Search / filter / sort / clear** | filter bar | — | — | **All in memory**, over the already-fetched list | — | — |
| **Refresh / retry analytics** | «تحديث» / retry | — | — | Full reload / analytics only | — | — |

> **In-memory filtering is a deliberate, documented exception**: *"bookings and trips grow without bound and are filtered server-side for that reason, but offices are the platform's own tenants — onboarded one at a time by a human… A platform with a thousand offices is a different business, and will want pagination in the RPC when it arrives."*

> **Sorting**: `newest` (default — the RPC's own order, so adding sort does not silently rearrange a familiar screen) · `revenue` · `activity` · `idle` · `name`. The three metric-dependent sorts **fall back to `newest`** when analytics has not loaded, *"rather than producing an arbitrary order that looks deliberate."*

### 7. Workflows

**Onboarding**
```
«مكتب جديد» → dialog → local validate() (per-field errors)
  → POST platform-create-office { name, admin_username, slug?, description?, logo_url?,
                                  phone?, email?, service_areas?, admin_full_name?,
                                  admin_password? }
      ├─ Auth Admin API creates the auth user (service-role key, inside the function)
      └─ platform_create_office(...) under the CALLER's JWT — one transaction:
         office row (active + draft) · join code · first dashboard_admin membership
  → PlatformAdminOnboarded  ← full-screen: office name · slug · JOIN CODE · username
                               · temporary password (only if generated)
  → dismiss → list refetched → analytics reloaded
```
`_loadAnalytics` **deliberately refuses to emit over the credentials panel** (`_listOffices()` is stricter than `_offices()`): *"any of them reading `_offices` would silently replace that reveal with the list — losing the password to a background refresh the operator never asked for."* The analytics refresh therefore happens on dismissal.

**Publishing**
```
office is active + draft
  → operator opens the office → reads profile completeness + marketplace absence reason
  → «عرض في السوق» (disabled with a reason when blocked)
  → platform_set_office_listing(office, 'listed')
     └─ server re-checks: office_not_active | office_profile_incomplete
  → list refetched · open panel refetched · success snackbar · analytics reloaded
```
`_refreshSelection` swallows its own failure on purpose: *"the action it follows already succeeded, and reporting a stale panel as a failed publish would be a lie."*

**Two doors create an office** — this one, and **self-service sign-up** (`20260721160000_office_self_signup.sql`), where an operator registers with email + password + office name and lands in their own workspace with no platform admin in the loop. Both produce `active` + `draft`. *"That is the whole safety model."* `[Design note: the office list does not distinguish which door an office came through.]`

### 8. States

| State | Behaviour |
|---|---|
| **Loading (list)** | `DashboardLoading` ✔ |
| **Loading (analytics)** | The office list renders; the overview panel shows a bare `CircularProgressIndicator` in an `AppCard` `[UI GAP — not the shared loader]` |
| **Loading (detail)** | `DashboardLoading(rows: 3, showHeader: false)` inside the panel, with the office's name already in the header ✔ |
| **Empty (no offices)** | `DashboardEmptyState` + «مكتب جديد» action ✔ |
| **Empty (no matches)** | `DashboardEmptyState` + «مسح عوامل التصفية» ✔ |
| **Error (list)** | `DashboardErrorState` + retry ✔ |
| **Error (analytics)** | **Never takes the list down.** `_AnalyticsError` renders inline with a retry, and with `isStale: true` when older numbers are still on screen — *"'we could not measure the platform' is a smaller problem than 'we could not list it' and must not be reported as the same thing"* ✔ **This is the best partial-failure handling in either section and should be the model for the others.** |
| **Error (detail)** | Full panel error when nothing loaded; an `_InlineNotice` above the content when a refresh failed over good data ✔ |
| **Submitting** | `isSubmitting` disables every action on every card and in the panel |
| **Action success/failure** | One-frame `PlatformAdminActionSuccess` → snackbar; `PlatformAdminActionFailure` keeps the list and the form ✔ |
| **Onboarded** | Full-screen `OnboardingCredentialsPanel`, explicit dismissal ✔ |
| **Partial data** | `analytics == null` is modelled as **null, not `PlatformAnalytics.empty`** — *"an empty analytics object claims every office has zero bookings, which is a statement about the platform, not an admission that nothing was fetched"* ✔ |
| **Permission denied** | `platform_admin_required` → "هذه العملية متاحة لمسؤولي المنصة فقط." |
| **Offline** | Edge Function catch-all → "تعذر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى." |

### 9. Validation & Business Rules

**Onboarding, client-side** (`OfficeOnboardingRequest.validate`, re-run in the Edge Function and in the RPC):
- name 3–120 chars (required)
- slug optional; when present `^[a-z0-9]+(-[a-z0-9]+)*$`, 3–48 chars. **Blank ⇒ the RPC mints an opaque one**, because an Arabic office name cannot be transliterated into a slug worth making permanent
- description ≤ 500
- logo URL must start `https://`
- phone 7–20 chars
- email `^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$`
- ≤ 30 service areas
- admin username 3–32, `^[a-z0-9][a-z0-9._-]*$`
- admin full name ≤ 120
- admin password optional; ≥ 10 when present

**Decided by the server, never sent:** `office_id`, `role`, `status` (`active`), `listing_status` (`draft`), join code. *"A request object that could carry them would be a request object someone eventually populates."*

**Publishing** — `platform_set_office_listing` refuses `office_not_active` and `office_profile_incomplete` (description + service areas required). `SetOfficeListingUseCase` restricts the argument to `{draft, listed, unlisted}`; `SetOfficeStatusUseCase` to `{active, paused, suspended, archived}`.

**The two axes** — identical to §4.2. `isListed = status == 'active' && listingStatus == 'listed'`, matching `office_is_listed()`.

**Server error vocabulary**: `platform_admin_required`, `not_authenticated`, `slug_taken`, `username_taken`, `admin_user_already_assigned`, `invalid_username`, `invalid_slug`, `invalid_office_name` / `office_name_too_long`, `invalid_logo_url`, `invalid_email`, `invalid_phone`, `description_too_long`, `too_many_service_areas` / `invalid_service_area`, `weak_password`, `office_profile_incomplete`, `office_not_active`, `office_not_found`, `auth_user_creation_failed`, `join_code_generation_failed`, `onboarding_failed`.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` What `paused` and `archived` *mean* operationally, and who is meant to set them. They are constrained, filterable, and unreachable.
- `[BUSINESS RULE UNCLEAR]` Nothing states the review criteria for publishing beyond the mechanical `office_profile_incomplete` check — no reviewer, no notes, no rejection reason, no record of who published or when (beyond `listed_at`).
- `[UNCLEAR]` The office list carries **no licence information at all** (plan, status, hold). An office's commercial state lives one module away in التراخيص. `[UI GAP]` — see §6, Cross-Feature Relationships.
- `[UNCLEAR]` No pagination anywhere; the RPC returns every office.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `platform_list_offices()` | RPC | Every office, including draft/paused/suspended |
| `platform_office_analytics(p_window_days)` | RPC | Totals, trend, per-office metrics |
| `platform_office_details(p_office_id)` | RPC | One jsonb document: office + counts + operators + marketplace preview |
| `platform_set_office_listing(uuid,text)` | RPC | Publish / withdraw (+ profile guard) |
| `platform_set_office_status(uuid,text)` | RPC | Suspend / activate |
| `platform-create-office` | Edge Function | Onboarding (Auth Admin API + `platform_create_office`) |
| `public_offices` | view | The marketplace preview |
| `is_platform_admin()` | predicate | Every one of the above |

### 11. UI Requirements

- **Two axes, three verdicts.** Status (operational), listing (marketplace) and activity (trading) are independent. A card must let an operator read all three in one glance and must never blend them into one badge.
- **The attention queue is the module's real front door** and should keep primacy over the KPI wall. Severity ordering is already correct; the design should make critical genuinely alarming and info genuinely quiet.
- **Publish is a merchant-facing act; withdraw removes a live merchant.** Both must confirm, from **both** entry points. The card and the panel currently disagree.
- **Disable-with-a-reason is the right pattern** and already implemented for publish (`blockersToListing`). Keep it and surface the reason on the disabled control, not only in the panel.
- **`profileFields` (5) vs the office's own `missingMarketplaceFields` (4)** must be reconciled or explicitly labelled as different measures.
- **The card carries 10 numbers plus 3 chips plus 4 buttons.** That is a dense card doing a table's job. Consider: a table for scanning (name · owner · status · listing · activity · revenue · bookings · upcoming · flags), with the numbers living in the workspace.
- **Surface the licence on the office row.** "Which offices are suspended for non-payment" is a platform question that currently requires two modules.
- **The window selector governs only half the numbers.** Lifetime stats and windowed metrics sit side by side on the same card; label which is which (the details panel does this well — `الأداء خلال N يوم` — the card does not).
- **`paused`/`archived`**: either implement them as actions or remove them from the filter, so the console stops offering a filter for a state it cannot produce.
- **Preserve** the credential reveal, the null-analytics modelling, and the inline stale-analytics notice.

### 12. UX Problems

1. **Withdraw and publish confirm in the panel and not on the card** — the same destructive action, two behaviours.
2. **`paused` / `archived` are filterable but unreachable.**
3. **No licence/plan information on the office directory**, so the platform's two views of a tenant never meet.
4. **The card is over-loaded** — 10 metrics, 3 chips, 4 actions, in the *narrow* half of a 3:4 master/detail split.
5. **Lifetime and windowed numbers are visually undifferentiated on the card.**
6. **Two completeness definitions** across the office and platform sides.
7. **A bare `CircularProgressIndicator`** for the analytics panel instead of the shared skeleton.
8. **No pagination or server-side filtering** — acknowledged in code as a deliberate temporary choice.
9. **No record of who published/suspended an office and why** — unlike the licensing module, which audits every decision with a mandatory reason.
10. **The onboarding form is hand-rolled** (see §3.3) and is the longest form in either section.

### 13. Recommended Information Architecture

```
مكاتب المنصة
├── نظرة المنصة        ← window selector · headline KPIs · attention queue · trend · portfolio
├── الدليل             ← DashboardFilterBar (search · status · listing · activity · sort)
│   └── table/cards: name+owner · status · listing · activity · plan+licence · revenue · flags
└── مساحة عمل المكتب   ← full-width workspace (not a 3:4 pane)
    ├── الهوية والسوق   identity · completeness · marketplace preview · absence reason
    │                   · [عرض/سحب] (confirmed) · [إيقاف/تفعيل] (confirmed)
    ├── التشغيل         counts
    ├── الأداء          windowed metrics (labelled with the window)
    ├── المسؤولون       operator roster (+ "no active admin" alarm)
    └── الترخيص         plan · status · hold · [الميزات والحدود →]
```
---

## 5.2 الباقات والميزات (Plans & Features Catalog) — **financial**

### 1. Purpose

**Everything the platform can sell, in one destination.** These were two sidebar rows («الخطط والباقات», «كتالوج الميزات») folded into one, because *"a plan is a set of feature values, and a feature is meaningless until a plan carries it. Pricing one without reading the other is not a thing anyone does."*

The naming law is absolute and stated in the domain header:

> This domain says **`plan`, never `package`**, and **`license`, never `subscription`**. Both of those words already mean *passenger fare bundles* in four tables and one nav item, and a third meaning would make them unreadable in SQL, in Dart and in every future conversation about this system.

**The design must never use باقة/اشتراك ambiguously between the two meanings.**

### 2. Users / Roles

`DashboardPermission.platformLicensing` + `platformOnly`. Every RPC calls `assert_platform_admin()`. Reads and writes are both platform-admin-only; there is no read-only platform role.

### 3. Entry Points

- Sidebar: المنصة → الباقات والميزات → `/platform-catalog`.
- Shares one long-lived `PlatformLicensingCubit` with التراخيص and الفوترة والسجل.
- **No inbound deep link.** The feature catalog is referenced constantly by التراخيص (the office feature board renders `catalog.features`) but never navigated to from it.

### 4. Main Screen — information architecture

`PlatformCatalogScreen` is a **tab host**: two page-level tabs — **الباقات** (count = `plans.length`) and **الميزات** (count = `catalog.features.length`) — rendered by `LicensingTabs` **inside the section's own header**, so the switch is always in the same place whichever half is open.

> **One deliberate exception:** while a plan is open in its workspace, the page-level switch **disappears**. *"A page-level tab strip above a workspace that has its own tabs is two navigations competing for the same glance"* — the workspace carries «كل الباقات» to return to the gallery, and to the switch with it.

#### Tab 1 — الباقات (`PlansSection`)

**Gallery → workspace, not split pane.** *"A plan is a product, and the console reads it the way a pricing page does."*

- **`_GalleryHeader`** — title «الباقات والميزات», the page-level tab strip, **«باقة جديدة»**, and a stat line: `N نشطة` · `N مكتب مشترك` · `N مطبَّقة بكود`.
- **Gallery** — `_PlanCard`s sorted **active → draft → archived** (*"the order an operator reasons about plans in, rather than insertion order"*), each carrying name, tagline, status chip, `_PlanPrice` (given real visual weight — *"the figure a plan is sold at, given the weight it has in the decision"*), trial badge, office count, and per-card actions: **فتح · تعديل · نسخ · نشر/أرشفة**.
- **Filters** — plan search + status filter (local `_planQuery`, `_planStatusFilter`, **not** `DashboardFilterBar`).

- **`_PlanWorkspace`** (full width) — «كل الباقات» back link, header with plan identity + **معاينة** + **تعديل**, then three tabs:
  - **الميزات** — `_FeatureEditor`: category blocks (**flat, not collapsible** — *"a plan is edited by sweeping the whole catalog, and a column of folded headers turns 'set the limits' into fifteen clicks before the first one"*), a feature search, a category filter, and a **«المعدّلة فقط»** toggle. Each `_FeatureEditRow` shows the value control, a «موقوفة على مستوى المنصة» mark for kill-switched features, and a clear-to-default action.
  - **المكاتب** — `_PlanOffices`: every office currently on this plan. Empty: "لا يوجد مكتب على هذه الباقة".
  - **السجل** — `_PlanRevisions`: the snapshot trail.
  - **A floating save bar** over all three, with an **optional** note field.
  - **`_PreviewPanel`** — «معاينة الصلاحيات الفعلية»: the resolver's own output for a hypothetical office on this plan.

#### Tab 2 — الميزات (`FeaturesSection`)

**Master/detail, deliberately** — *"you browse a reference in a split pane because you skim many rows and read one; you edit in a workspace because editing needs the room."*

- **`_CatalogHeader`** — stat line: `N ميزة في الكتالوج` · `N مطبَّقة بكود` · `N معلنة ولا كود يطبّقها` · `وضع التطبيق`.
- **`_CatalogToolbar`** — one line, everything named: search · a segmented **enforcement** switch (`enforced` / `declared`) · **التصنيف** dropdown (with per-category counts) · **الحالة** dropdown · clear. *"Nothing about the filter state is hidden, and nothing about it costs a fold."*
- **`_FeatureList`** — grouped by category (flat headings, not collapsible), each `_FeatureRow` carrying a `_FeatureDot` (enforced-and-live / declared-only / killed) and `_RowMark`s («موقوفة», «معلنة فقط»).
- **`_FeatureDetail`** — **three** panels (reduced from five): *what it is* · *where it bites* · *what it is doing to the platform right now* (the impact map).

Active filters are **spelled out, never counted**: *"'٣ عوامل تصفية' makes the operator reopen the panel to find out which three, and a hidden filter is how a feature looks like it was deleted."*

### 5. Data Model

**`CatalogFeature`** — one catalogued capability.

| Field | Meaning |
|---|---|
| `key` | The stable identifier code branches on |
| `nameAr`, `nameEn`, `descriptionAr` | |
| `categoryKey` | One of 7 seeded categories |
| `valueType` | **`boolean`** (تشغيل/إيقاف) · **`limit`** (حد رقمي) · **`enum`** (مستوى) · **`config`** (إعداد) |
| `defaultValue` | The bottom rung of the resolution ladder |
| `status` | `active` نشطة · `hidden` مخفية · `deprecated` مهجورة · **`disabled` موقوفة على مستوى المنصة — the platform-wide KILL SWITCH: the feature resolves to its default for everyone, whatever any plan or override says** |
| `isEnforced` | **Derived by a trigger from real `FeatureGate` rows.** *"Real data, not a doc comment: the migration that creates a gate inserts the row… so the console's badge can never claim more than the code delivers"* |
| `unitAr`, `isPublic`, `sortOrder` | |
| `meterKind` | **`stock`** (COUNT of live rows — deleting returns quota) or **`flow`** (accumulating counter — deleting does NOT refund) |
| `meterPeriod` | For flow meters |
| `allowedValues` | For `enum` |
| `gates` | `FeatureGate{kind ∈ trigger/rpc/rls/view/ui, ref, note}` — **where the flag is actually enforced in the code** |
| `requires` / `requiredBy` | The dependency graph |
| `planCount`, `overrideCount` | Reach |
| `impact` | `Map<value, officeCount>` — how many offices currently resolve to each value |

**47 features** in the catalog (26 have Dart constants in `FeatureKeys`; *"a Dart constant is only warranted where code branches on one"*). `FeatureKeys` is deliberately **not an enum**: *"the catalog is data and can grow without a deploy, so a closed Dart type would be a lie about the system's own extensibility."*

**`LicensingPlan`** — `id`, `key`, `nameAr`, `nameEn`, `taglineAr`, `status` (`draft`/`active`/`archived`), `isPublic`, `priceMonthly?`, `priceYearly?`, `currency` (EGP), `trialDays`, `downgradeToKey?`, `officeCount`, `featureCount`, `revision`, `notes`, `sortOrder`.

> **A plan is a template with no behaviour.** *"It cannot contain logic, conditions or code; anything a plan 'does' is a value the resolver reads. That is exactly what makes plans safe to edit live — and edits DO propagate immediately, because the resolver reads plan values at resolution time and there is no per-office copy to keep in sync."*

**`PlanDetail`** — `plan`, `values: Map<featureKey, Object?>`, `offices: List<PlanOfficeRef>`, `revisions: List<PlanRevision>`.

> **Presence vs value is the module's subtlest rule:** *"A key that is ABSENT means 'fall through to the catalog default', which is a different statement from setting it false."* The plan editor's `_changedKeys` compares **both** `containsKey` and the value, because removing a key is an edit and both sides stringify to `null` naively.

**`PlanRevision`** — `revision`, `createdAt`, `reason`, `snapshot` (with `features` = the map **before** the edit). Written **before** anything changes, *"so a revision is always the state that was replaced rather than the state that replaced it."*

**Seeded plans**: `founder`, `starter`, `professional`, `enterprise`, plus `restricted` (the hold plan).

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Create plan** | «باقة جديدة» → `plan_editor_dialog` | key · name_ar · name_en · tagline · status · is_public · price_monthly · price_yearly · trial_days · reason | key pattern & required (new only); prices numeric; trial days integer | `platform_save_plan` | dialog | no |
| **Edit plan details** | «تعديل» (card or workspace) | same, key locked | same | `platform_save_plan` (snapshots a revision first) | dialog | no |
| **Edit plan feature values** | Workspace → الميزات → save bar | complete value map + **optional** note | Server validates every value against the feature's schema | `platform_save_plan{features}` — **replaces the map wholesale** | **no — and correctly so** | **`[SIGNIFICANT]` propagates instantly to every subscribed office** |
| **Clone plan** | «نسخ» | new key + new name | key pattern | `platform_clone_plan` → **a draft copy** | dialog | no |
| **Publish plan** (`draft`→`active`) | card action | — | — | `savePlanDetails{status}` | **yes** — "تصبح الباقة قابلة للتعيين للمكاتب" | no |
| **Archive plan** | card action | — | — | `savePlanDetails{status: archived}` | **yes**, and the copy **counts the affected offices**: *"المكاتب الـN المشتركة تكمل عليها بلا أي تغيير، ولا يمكن تعيينها لمكتب جديد بعد الأرشفة"* (or "لا مكتب عليها الآن، فلا يتأثر أحد") | reversible |
| **Preview plan** | «معاينة» | — | — | `platform_preview_plan` → the resolver's own output | no | no |
| **Set feature status** | Feature detail → 4 `ChoiceChip`s | `active`/`hidden`/`deprecated`/**`disabled`** | — | `platform_set_feature_status` → reloads **catalog *and* health** (*"disabling a feature can instantly create a 'sold but not delivered' row on an active plan"*) | **`disabled` only — and the copy is exemplary** (see below). `hidden`/`deprecated`/`active` apply on one tap | **`disabled` is a platform-wide kill switch** |
| **Search / filter catalog** | toolbar | — | — | Pure in-memory narrowing; **none of them refetch** | — | — |
| **Compare plans** | — | — | — | **`[NOT IMPLEMENTED]`.** `platform_compare_plans` RPC exists, `ComparePlansUseCase` exists — **the cubit does not take it and nothing calls it** | | |
| **Create/edit a feature** | — | — | — | **`[NOT IMPLEMENTED]`.** `platform_upsert_feature` RPC + repository + datasource all exist; **no use case, no cubit method, no UI**. Features can only be added by migration | | |

> **The kill-switch confirmation is the best destructive-action copy in the console and should be the template for every other one.** It names the consequence, the default the feature will fall back to, the exact reach, and the cascade:
> *"سيتجاوز هذا الإيقاف كل باقة وكل استثناء، وترجع «‹الميزة›» إلى قيمتها الافتراضية (‹القيمة›) لدى كل المكاتب فورًا. مُدرجة حاليًا في N باقة، ولها M استثناء مكتبي. ويسقط معها أيضًا: ‹التابعات›."* — with an error-coloured confirm button.

> **Saving a plan stopped being a negotiation, on purpose:** *"Every save used to open a modal demanding an eight-character reason. `platform_save_plan` requires none, the revision snapshot is written either way, and the modal was the reason nobody wanted to touch a plan. The note now lives inline in the save bar and is optional."* When blank, the cubit substitutes `'تعديل قيم الباقة من وحدة التحكم'`.

> **Unsaved-changes guard:** leaving a plan with `changedCount > 0` opens "تعديلات غير محفوظة — على هذه الباقة N تعديل لم يُحفظ. الخروج منها يتخلّى عنها." (البقاء هنا / تجاهل والخروج). The buffer lives in the **section**, not the panel, *"because the section has to be able to refuse to leave a plan while the buffer is dirty."*

**Fields the RPC accepts that the dialog never sends** `[UI GAP]`: `currency`, `sort_order`, `notes`, and — most consequentially — **`downgrade_to_plan_id`**. That last is what `platform_run_licensing_lifecycle` reads to perform an automatic downgrade after expiry. **There is no UI anywhere to set a plan's downgrade target.**

### 7. Workflows

**Repricing / re-scoping a plan**
```
gallery → open plan → الميزات tab
  → sweep categories, set booleans / limits / enums (draft buffer, presence-aware)
  → optional note in the save bar → حفظ
  → platform_save_plan:
       1. snapshot the CURRENT state into platform_plan_revisions (before anything changes)
       2. upsert platform_plans
       3. delete every platform_plan_features row whose key is absent from the payload
       4. upsert every key in the payload
  → message: "تم الحفظ. سرى التغيير فورًا على كل مكتب مشترك في هذه الباقة،
              وحُفظت النسخة السابقة في السجل."
  → every subscribed office's EntitlementService sees the platform_plan_features
    Realtime change and re-resolves — live, without a deploy
```

**Killing a feature platform-wide**
```
الميزات → select feature → status = disabled
  → platform_set_feature_status
  → the resolver's TOP rung: every office resolves to the catalog default,
    whatever any plan or override says
  → catalog + health reloaded → a "مُباعة بلا كود" / sold-but-declared signal may appear
```

**The resolution ladder (memorise this — three modules depend on it):**
```
kill_switch  →  license_hold  →  override  →  plan  →  default
```
Plus a **dependency gate** applied after: a feature whose prerequisite is off is defeated, and **both** facts are reported (`source` = where the value came from, `blockedBy` = what defeated it) because *"showing only one of them looks like the system ignored the operator."*

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `LicensingScreenFrame` → `DashboardLoading` ✔ |
| **Error (load)** | `DashboardErrorState` + retry ✔ |
| **Busy (action)** | A 3px `LinearProgressIndicator` pinned to the top of the frame — non-blocking ✔ |
| **Action success / failure** | `showLicensingFeedback` snackbar **over** the screen. *"An action error must never replace the screen — the operator needs to still see what they were editing."* ✔ |
| **Empty (no plans)** | `DashboardEmptyState` + «باقة جديدة» ✔ |
| **Empty (no matching feature)** | `DashboardEmptyState` + clear-filters ✔ |
| **Empty (plan has no offices)** | `DashboardEmptyState` ✔ |
| **Dirty buffer** | Save bar with a live changed-count; discard guard on exit ✔ |
| **Declared feature** | `_RowMark` «معلنة فقط» + `_FeatureDot`, so nobody sells a switch that does nothing ✔ |
| **Kill-switched feature** | «موقوفة على مستوى المنصة» in the plan editor row ✔ |
| **Partial** | Section loads are independent (`_section` swallows errors and never shows a spinner over the console) |
| **Permission denied** | "هذه الشاشة متاحة لمديري المنصة فقط." |

### 9. Validation & Business Rules

**Server-side value validation** (each with mapped Arabic):
`feature_value_null` (*"لا يمكن ترك القيمة فارغة — احذف الصف بدلاً من ذلك"*) · `feature_value_type_mismatch` · `feature_value_invalid_limit` (*"رقمًا صحيحًا غير سالب أو «بلا حدود»"*) · `feature_value_below_min` · `feature_value_above_max` · `feature_value_not_allowed` · `feature_schema_incomplete` (*"الميزة من نوع «مستوى» بلا قائمة قيم مسموحة"*) · `feature_dependency_cycle` (*"هذه التبعية تُنشئ حلقة مغلقة"*) · `unknown_feature` · `feature_key_required` · `plan_not_found` · `duplicate key value`.

**Rules**
- A limit is **a non-negative integer or the literal `'unlimited'`. Never `-1`, never null** — *"`-1` is a magic number arithmetic silently accepts, and null is indistinguishable from 'no row', which is a different rung."*
- Plan feature values are **replaced wholesale**; an absent key means "catalog default".
- A revision is snapshotted **before** every save.
- **Archiving keeps existing licences resolving** and only stops new assignment (`plan_archived` is raised by `platform_assign_plan`, not by the resolver).
- `isEnforced` is derived from real gate rows by a trigger — the console cannot over-claim.
- Every licensing table has SELECT policies but **no INSERT/UPDATE/DELETE policy for anyone**; the only write path is a `security definer` RPC that audits itself.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` `isPublic` on a plan («معروضة للمكاتب») — there is no office-facing plan gallery anywhere in the product, so what "public" *shows it to* is undefined today.
- `[BUSINESS RULE UNCLEAR]` `currency` is per plan and per licence but is never settable and never varies from EGP. No FX model exists.
- `[UNCLEAR]` `PlanRevision` is displayed as a list; whether a revision can be **restored** is not implemented (`snapshot.features` is parsed and available).
- `[UNCLEAR]` Feature `status = 'hidden'` — `OfficeFeatureBoard` filters `status != 'hidden'` out, but the catalog's own status filter still offers «مخفية». What hidden means to a *plan* is not stated.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `platform_feature_catalog()` | RPC | Categories + 47 features + gates + dependencies + impact |
| `platform_upsert_feature(jsonb)` | RPC | **Unused** |
| `platform_set_feature_status(text,text)` | RPC | Status incl. the kill switch |
| `platform_list_plans()` | RPC | Gallery |
| `platform_plan_detail(uuid)` | RPC | Plan + values + offices + revisions |
| `platform_save_plan(jsonb)` | RPC | Create/edit + revision snapshot + wholesale feature replace |
| `platform_clone_plan(uuid,text,text)` | RPC | Draft copy |
| `platform_preview_plan(uuid)` | RPC | Resolver output for a hypothetical office |
| `platform_compare_plans(uuid[])` | RPC | **Unused** |
| `platform_plans`, `platform_plan_features`, `platform_plan_revisions`, `platform_features`, `platform_feature_gates`, `platform_feature_dependencies`, `platform_feature_categories` | tables | |
| `platform_plan_features`, `platform_features` | Realtime | Live propagation to every office |

### 11. UI Requirements

- **Plan = product page. Feature = reference entry.** The two halves want different layouts and already have them (gallery/workspace vs master/detail). Keep that.
- **Price is the headline of a plan card.** Monthly and yearly must be comparable at a glance; the trial length is a badge, not a field.
- **Reach must be visible before an edit, not after** — «N مكتب مشترك» on the card, and the affected count in every status confirmation (archive already does this; publishing and value-saving do not).
- **"Sold but not delivered" is the module's integrity signal.** A `declared` feature switched on by an `active` plan is a promise the code does not keep; it must be impossible to miss in the plan editor.
- **Presence vs `false`** needs a literal control: "اتبع الافتراضي" is a third state alongside on/off, and the editor's clear-action must read that way.
- **`downgrade_to_plan_id` must become editable** — it is the target of the automatic-downgrade path and is currently unreachable.
- **A plan-comparison view is already served by the backend** and would answer the module's most natural question ("what does Professional add over Starter?").
- **Feature gates are the module's credibility.** `kind` + `ref` (`trigger:trg_quota_office_users`, `rpc:office_dispatch_notification`) should be readable in the detail, as they are.
- **Every value change is instant and platform-wide.** The save bar must say so before the press, not only in the success message.
- **Standardise the filter toolbars** — the plan gallery and the feature catalog have two different, both bespoke, filter implementations.

### 12. UX Problems

1. **No plan comparison**, though the RPC exists.
2. **Features cannot be created or edited**, though the RPC exists — the catalog is read-only except for status.
3. **`downgrade_to_plan_id` is unreachable**, silently disabling automatic downgrade.
4. **Currency, sort order and plan notes** are accepted by the server and absent from the editor.
5. **`hidden` and `deprecated` apply on one tap with no confirmation**, though both change what the catalog offers (`hidden` features are filtered out of every office feature board). Only `disabled` confirms.
6. **Two bespoke filter toolbars** in one destination, neither the shared `DashboardFilterBar`.
7. **Revisions are visible but not restorable.**
8. **`isPublic` has no consumer** — a control with no effect.
9. **The save bar's note is optional and unlabelled as to consequence** — an untitled revision in a trail that exists to be read later.

### 13. Recommended Information Architecture

```
الباقات والميزات
├── الباقات (default)
│   ├── Gallery: cards (price · trial · office count · status) · [باقة جديدة] · filter bar
│   └── Plan workspace (full width)
│       ├── الميزات   category sweep · presence-aware editor · [معاينة] · save bar (+ note)
│       ├── المكاتب   who is on this plan  → open in التراخيص
│       ├── السجل     revisions (+ restore?)
│       └── التسعير والهوية  price · trial · downgrade target · currency · visibility
└── الميزات
    ├── Toolbar: search · enforced|declared · category · status
    ├── List (grouped by category, dot + marks)
    └── Detail: ما هي · أين تُطبَّق (gates) · الأثر (impact + plans + overrides) · [الحالة]
```
---

## 5.3 التراخيص (Office Licences) — **financial**

### 1. Purpose

**Every office's licence, and the one screen that answers "why does this office have this?"** From the screen's own header:

> *"The answer lives in the `source` of each resolved feature: which rung of the ladder produced the value. That single field is the difference between a two-minute support conversation and a twenty-minute one."*

It absorbed the former «الاستخدام» sidebar row: *"the platform-wide usage screen drew the same meters this workspace already had, one office per panel, as its own sidebar row… the platform-wide question it used to answer — who is over a limit — is the «تجاوزت حدًّا» signal below, which names the offices and the metrics instead of asking anyone to scan."*

### 2. Users / Roles

`DashboardPermission.platformLicensing` + `platformOnly`. Every RPC calls `assert_platform_admin()`. The write path is RPC-only (no licensing table accepts a direct write from any role) and **every write audits itself**.

### 3. Entry Points

- Sidebar: المنصة → التراخيص → `/platform-licenses`.
- **From مكاتب المنصة** — «الميزات والحدود» on an office card or in the details panel: route change **plus** `openOffice(officeId)`, which waits on an in-flight load so the jump lands even on a cold console.
- From the alert strip: each signal's rows open the named office in place.

### 4. Main Screen — information architecture

**Directory → workspace** (not master/detail). *"The same shape the plan gallery uses, and for the same reason: browse in a grid, work full width."*

#### Directory (`_LicenseDirectory`)

**(a) `_DirectoryHeader`** «التراخيص» + a stat strip: `N مكتب مرخَّص` · `N ترخيص نشط` · `N فترة تجريبية` · `N تجاوز حدًّا` · `N محجوب عن السوق`.

**(b) `_EnforcementModeBar`** — the **platform kill switch**. A `SegmentedButton` over **معطّل / ظل / مفعّل**, with the copy *"الإرجاع إلى «معطّل» يعيد سلوك المنصة كما كان فورًا وبلا نشر إصدار جديد."*

> **`[MAJOR UX RISK]` This control has NO confirmation.** One tap moves the entire platform between `off`, `shadow` and `enforcing`. It is the single most consequential control in the console and the only destructive one with no guard — while archiving a single plan, killing a single feature and suspending a single licence all confirm with detailed copy. Compare: `platform_update_settings` is called with a canned reason `'تغيير وضع التطبيق من وحدة التحكم'`.

**(c) Search + status filter** — `_statusLabels`: الكل · نشطة · تجريبية · متأخرة · مهلة · موقوفة · منتهية. Local `_query`, plus `state.licenseStatusFilter` on the cubit.

**(d) `_AlertStrip`** — **six signals, and an empty one takes no space**: *"Six cards that are mostly empty is not a health strip, it is a wall. An empty signal is good news and takes no space; a signal with rows becomes a count you can press to see exactly which offices it means."* One open at a time.

| Signal | Source |
|---|---|
| متأخرة أو موقوفة | `health.pastDue` |
| تجاوزت حدًّا | `health.overLimit` |
| مكاتب بلا ترخيص | `health.officesWithoutLicense` |
| تجارب تنتهي قريبًا | `health.trialsEnding` |
| استثناءات تنتهي قريبًا | `health.overridesExpiring` |
| **مُباعة بلا كود** | `health.soldButDeclared` — *"a `declared` feature switched on by an active plan — a promise the code does not keep. Surfaced rather than tolerated: shipping flags that silently do nothing is how a licensing system loses credibility"* |

**(e) `_OfficeCard`** — one office, the way the plan gallery shows one plan. *"The row it replaced carried a name, a plan and a status chip; everything else about the licence — what it costs, when it renews, whether it is trialing out this week — needed the detail pane. The card carries the commercial facts, so the directory answers most questions without opening anything."* Chips: `N استثناء` · `تجاوز N حدًّا` · `محجوب عن العملاء`.

#### Office workspace (`_OfficeWorkspace`, full width)

**`_OfficeHeader`** — «كل المكاتب» back link · office name · `LicenseStatusChip` · plan name (or «بلا باقة») · hold chip («محجوب عن العملاء» / «قراءة فقط»), then **every action always visible** (*"the actions used to live behind a `⋯` in a panel header — «تعيين باقة», the single most common operation on this screen, took two clicks and prior knowledge of where it hid"*):

- **«تعيين باقة» / «تغيير الباقة»** (primary)
- **«تمديد التجربة»** (only while `trialing`)
- **«استئناف»** (when held) *or* **«إيقاف مؤقت»** (otherwise, error-toned)
- **«إصدار فاتورة»**

…then a field grid: الدورة · السعر · تنتهي التجربة *(if trialing)* · نهاية المدة · تجديد تلقائي · سبب الإيقاف *(if suspended)*.

**Four tabs** — «الميزات والحدود» (default) · «الاستخدام» · «الاستثناءات» · «الفوترة والنشاط».

> *"The office opens on its features. «الميزات والحدود» is the first tab and the reason most operators come here… It replaced a read-only «الميزات الفعّالة» list beside an «الاستثناءات» tab whose only way to change anything was a dialog with a forty-seven-item dropdown — two tabs to answer one question, and neither of them where the answer was acted on."*

**The save bar floats over all four tabs**, not inside the feature tab: *"Unsaved feature edits survive a look at the invoices, and a change buffer that disappears the moment the operator checks something else is a change buffer that loses work."*

#### `OfficeFeatureBoard` («الميزات والحدود»)

- **A draft, not a live switch.** Every control writes into an edit buffer the *screen* owns; nothing reaches the server until «تطبيق». *"The operator sees the full set of changes, states the reason once for the decision they actually made, and applies them together."*
- **It never pretends.** A kill-switched feature, or one held down by the licence's own status (`source ∈ {kill_switch, license_hold}`), renders **disabled and says which rung is holding it** — *"a switch that silently snaps back is worse than one that refuses."* A `declared` feature carries «غير مفعّلة بعد».
- Stat strip: `N ميزة مفعّلة` · `N ميزة متوقفة` · `N استثناء لهذا المكتب` · `N حد متجاوَز`.
- Toolbar: search · a **labelled** category picker · five lenses — **الكل · مفعّلة · متوقفة · حدود · استثناءات**.
- Rows are grouped by category in **flat** blocks (same reasoning as the plan editor).
- **`_RowStory`** — the one line under a feature's name: where its value came from (`source`), what it is costing the office (usage), and **«إرجاع لقيمة الباقة»** — the reset action.
- `resolveOfficeFeatureChanges` reduces the buffer to edits that would actually change something: *"A switch flipped and flipped back is not a change, and neither is a reset on a feature that has no override to remove… a save bar that counts gestures instead of decisions teaches the operator to ignore it."*
- Rows with `feature.status == 'hidden'` are excluded entirely.

### 5. Data Model

**`OfficeLicenseRow`** (directory) — `officeId`, `officeName`, `officeSlug`, `listingStatus`, **`licensingHold`** (`none` | `read_only` | `delisted` — *"the denormalised consequence of `status`, and the only licensing term `office_is_listed()` reads"*), `planKey`, `planNameAr`, `status`, `billingCycle`, `price`, `currency`, `trialEndsAt`, `periodEnd`, `autoRenew`, `overrideCount`, **`overLimitCount`**.

> `overLimitCount` is *"a real, legitimate state and not an error: limits gate creation, never existence, so an office that downgraded keeps every row it had and simply cannot add more. Showing the number honestly beats pretending compliance."*

**`OfficeLicenseDetail`** — `officeId`, `officeName`, `licensingHold`, `listingStatus`, **`entitlements: EntitlementContext`** (*"produced by the same resolver the office itself reads — so the console and the tenant can never disagree"*), `overrides`, `invoices`, `activity`, plus derived `overLimits` (*"shown, never silently corrected — resolving an over-limit by deleting a tenant's operational data is not something the platform gets to do"*).

**`FeatureOverride`** — `featureKey`, `nameAr`, `categoryKey`, `valueType`, `value`, **`planValue`** (what the plan would have resolved to; the direction rendered ▲/▼), **`reason`** (*"never empty: the table's own CHECK requires at least eight characters. An override with no stated reason becomes a permanent unexplained exception, because in two years nobody dares remove it"*), `expiresAt`, **`expired`** (*"an expired override stops applying but is NOT deleted — the row is the record that the concession happened"*), `createdAt`.

> Overrides **both grant and revoke** — the brief's own example is disabling API access on an Enterprise contract — so `isUpgrade` reads the direction from `planValue` rather than assuming one.

**`OfficeFeatureEdit`** — `.set{featureKey, nameAr, value, expiresAt?}` or `.reset{featureKey, nameAr}`.
> **Reset ≠ writing `false`:** *"one says 'this office has no exception here', the other says 'this office has an exception, and it says no'. They diverge the moment the plan changes."*

**`UsageMetric`** — `key`, `nameAr`, `used`, `limit?` (null = unlimited), `unitAr`, **`meterKind`** (stock/flow), with `isOver` and `ratio`.

**`LicensingHealth`** — `enforcementMode` + six row-lists (see the alert strip).
**`LicensingSettings`** — `enforcementMode`, `restrictedPlanKey`, `defaultSignupPlanKey`, `graceDays` (7), `warnDaysBefore` (7).

**Licence statuses**: `trialing` فترة تجريبية · `active` نشطة · `past_due` متأخرة السداد · `grace` مهلة أخيرة · `suspended` موقوفة · `cancelled` ملغاة · `expired` منتهية · `none` بدون ترخيص.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Assign / change plan** | «تعيين باقة» | plan + cycle (شهرية/سنوية) | `plan_not_found`, **`plan_archived`** | `platform_assign_plan`; **assigning a plan LIFTS a hold** (`suspended_at`/`suspended_reason` cleared, status recomputed) | dialog (plan picker) | changes what an office may do |
| **Suspend licence** | «إيقاف مؤقت» | **reason ≥ 8 chars** | `reason_required` | `status = 'suspended'` → read-only + delisted | **yes**, with excellent copy + 3 suggested reasons | **yes** |
| **Restore** | «استئناف» | reason | — | `status = 'active'` | yes, + suggestions | no |
| **Extend trial** | «تمديد التجربة» | reason | `not_trialing`, `reason_required` | `platform_extend_trial(office, **14**, reason)` | yes, + suggestions | no |
| **Issue invoice** | «إصدار فاتورة» | — | `license_not_found` | `platform_issue_invoice` — **idempotent per (office, period)** | **no** `[UI GAP]` | creates a billable record |
| **Apply feature edits** | Save bar «تطبيق» | the buffer + **one reason ≥ 8 chars** | `reason_required` client-side (`_showReasonError`) and server-side | **Per-row RPCs in a loop**, stopping at the first refusal: *"طُبِّق N من M ثم توقّف عند «‹الميزة›» — ‹السبب›"* | no (the reason field *is* the guard) | changes what the office may do, instantly |
| **Reset a feature** | «إرجاع لقيمة الباقة» | (buffered) | — | `platform_clear_override` | no | no |
| **Change enforcement mode** | Segmented bar | — | — | `platform_update_settings{enforcement_mode}` | **NO** `[MAJOR UX RISK]` | **platform-wide** |
| **Filter / search** | header | — | — | Status filter on the cubit; text query local | — | — |
| **Start a trial from scratch** | — | — | — | **`[NOT IMPLEMENTED]`.** `platform_start_trial` RPC + repository + datasource exist; **no use case, no cubit method, no UI**. Trials arrive only via `platform_assign_plan{trial_days}` — which the dialog never sends | | |
| **Run the lifecycle job** | — | — | — | **`[NOT IMPLEMENTED]`.** `runLifecycle()` exists on the cubit with the comment *"'Run now' for the nightly jobs. Far more useful than waiting for a schedule while investigating one customer's state"* — **and is called from nowhere** | | |
| **Edit licensing settings** | — | — | — | **`[NOT IMPLEMENTED]`.** `updateSettings()` handles `graceDays`, `warnDaysBefore`, `restrictedPlanKey`, `defaultSignupPlanKey`; only the enforcement-mode bar calls it, and only with that one key | | |

> **`[UI GAP]` — `platform_assign_plan` accepts a rich options bag the dialog never sends:** `reason`, `trial_days`, `price_override`, `currency`, `auto_renew`, `contract_ref`, `notes`. `AssignPlanChoice` is `({String planId, String cycle})` and the cubit is called with `options: {}`. So **a negotiated price, a contract reference, a trial length and an auto-renew choice are all unreachable from the console** — every one of them is a field the licence row carries and the office billing screen renders.

> **`[UI GAP]` — trial extension is hard-coded to 14 days** (`cubit.extendTrial(officeId, **14**, reason)`), with the dialog title «تمديد الفترة التجريبية ١٤ يومًا». The RPC takes any positive integer.

> **Batching is client-side on purpose:** *"There is no bulk RPC and there should not be: each row is its own audited decision, and a server that took them as one blob could not tell the trail which of them the operator meant. So the batching is here — one reason, one refresh, one message — while the record downstream stays per feature."*

### 7. Workflows

**Granting an exception to one office**
```
التراخيص → office → «الميزات والحدود»
  → lens: الكل / مفعّلة / متوقفة / حدود / استثناءات
  → flip switches, type limits — all into a draft buffer
  → save bar shows the real change count (flip-and-flip-back is not a change)
  → type ONE reason ≥ 8 chars → «تطبيق»
  → buffer dropped BEFORE the call ("once the batch is away the board draws the
    server's answer — including the rows a partial failure did not reach")
  → per-row platform_set_override / platform_clear_override, each audited
  → office detail + licence list + health all refetched
  → every affected office's EntitlementService sees the office_feature_overrides
    Realtime change and re-resolves live
```
Leaving the office with a dirty buffer opens: *"تغييرات غير محفوظة — على «‹المكتب›» N تغيير لم يُطبَّق. الخروج من المكتب يتخلّى عنها."*

**Suspending for non-payment (manual, today)**
```
«إيقاف مؤقت» → reason dialog (≥8 chars, 3 suggestions):
  "المكتب سيتحوّل إلى وضع القراءة فقط: لا إنشاء رحلات أو سائقين أو خطوط،
   ويختفي من سوق العملاء. التذاكر المُباعة والرحلات الجارية ودخول الكباتن
   تكمل كالمعتاد."
  → platform_set_license_status(office, 'suspended', reason)
  → licensing_hold = 'delisted'  → office_is_listed() false → the office leaves public_offices
  → audit row + operational alert to the office ('/settings/billing' — dead link)
```

**The lifecycle that should be automatic**
```
platform_run_licensing_lifecycle():
  trial warnings (warn_days_before)  → push_operational_alert 'trial_ending'
  trial expiry                        → status = expired
  period end && !auto_renew           → status = expired
  invoice past due_at                 → invoice.status = overdue
                                      → licence past_due  (FULLY OPERATIONAL, banner only)
  past_due + grace_days elapsed       → grace            (FULLY OPERATIONAL, urgent banner)
  grace + warn_days elapsed           → suspended        (READ-ONLY — the one transition
                                                          that changes what the office can do,
                                                          and it changes CREATION only)
  expired + plan.downgrade_to_plan_id → active on the successor plan, cycle 'free',
                                        no period end, no auto-renew, nothing billed
```
> **`[BACKEND GAP + UI GAP] — none of this runs.** There is no `pg_cron` schedule for it (migration `20260729090000` states "No pg_cron on this project"), and `runLifecycle()` has no UI trigger. Every state past `active`/`trialing` is currently reachable only by a manual `platform_set_license_status`. Dunning, grace, automatic suspension and automatic downgrade are implemented and dormant.

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` via `LicensingScreenFrame` ✔ |
| **Busy** | Top `LinearProgressIndicator`; actions disabled ✔ |
| **Error (load)** | `DashboardErrorState` + retry ✔ |
| **Action error** | Snackbar over the screen — **never replaces it** ✔ |
| **Partial batch failure** | *"طُبِّق N من M ثم توقّف عند …"* — names the row it stopped on **in the operator's own words**, not as `max_drivers` ✔ **This is the best partial-failure message in the console.** |
| **Empty (no licences)** | `DashboardEmptyState` ✔ |
| **Empty (no overrides)** | `DashboardEmptyState` "لا توجد استثناءات" ✔ |
| **Empty (no limits)** | `DashboardEmptyState` "لا توجد حدود على هذه الباقة — كل عدّاد في هذه الباقة بلا سقف، فلا شيء يُقاس هنا" ✔ |
| **Health clean** | Signals with no rows render as nothing at all ✔ |
| **Locked feature row** | Disabled **with the rung named** (kill switch / licence hold) ✔ |
| **Declared feature** | «غير مفعّلة بعد» ✔ |
| **Dirty buffer** | Persistent save bar across all four tabs + discard guard on office change and on exit ✔ |
| **Office switch** | `_syncOffice` re-points and **drops the draft**, bumping `_draftGeneration` so text fields rebuild from real values ✔ |
| **Enforcement off/shadow** | `EntitlementContext.allows()` returns true unconditionally — *"the console must not pretend otherwise; hiding a module the backend would happily serve is its own kind of bug"* ✔ |

### 9. Validation & Business Rules

**Implemented**
- **Reason ≥ 8 chars** for: suspend, cancel, extend trial, set override, clear override. Enforced by the RPC *and* by a table CHECK on `office_feature_overrides.reason`. `promptForReason` takes a `minLength` (default 8) and offers **suggestion chips**.
- `platform_assign_plan` refuses an **archived** plan.
- `platform_extend_trial` refuses a non-trialing licence (`not_trialing`).
- **Suspension DEGRADES; it never blacks out.** Read-only + delisted; sold tickets, running trips and captain sign-in all continue.
- **`licensing_hold`** (`none`/`read_only`/`delisted`) is the denormalised consequence of `status` and the **only** licensing term `office_is_listed()` reads.
- **Limits gate creation only.** Over-limit is shown, never corrected.
- `stock` meters are counted at read time (self-healing); `flow` meters accumulate and **do not refund on delete** (*"or an office on a 100-trip plan would run 1,000 by deleting each one when it finished"*).
- An expired override is **kept, not deleted**.
- Resolution ladder: `kill_switch → license_hold → override → plan → default`, then the dependency gate.
- Enforcement modes: `off` (nothing enforced) / `shadow` (*"تُسجَّل التجاوزات ولا يُمنع شيء. أي تسجيل هنا يعني أن حدًّا مضبوطًا خطأ، لا أن مكتبًا يتحايل"*) / `enforcing` (*"تُطبَّق الحدود الآن على الإنشاء الجديد فقط"*). **Production is `enforcing`.**
- Audit is **append-only**: `audit_is_append_only` — *"the API roles cannot UPDATE or DELETE it, and a trigger refuses both even for the table owner."*

**Unclear**
- `[BUSINESS RULE UNCLEAR]` `cancelled` is a settable status (and requires a reason) but nothing in the product describes cancellation as a lifecycle — no offboarding, no data retention statement, no final invoice.
- `[BUSINESS RULE UNCLEAR]` `restrictedPlanKey` and `defaultSignupPlanKey` exist in settings, are read into the entity, and have **no UI and no documented consumer visible in the dashboard**.
- `[UNCLEAR]` `office_assign_default_license()` exists in the lifecycle migration — presumably what gives a self-signed-up office its first licence — but nothing in the console surfaces which offices got one, or which plan is the default.
- `[UNCLEAR]` Whether an override may be *scheduled* (`expiresAt` is settable in `OfficeFeatureEdit.set`) — the board's UI for choosing an expiry date is not evident in the row controls.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `platform_list_licenses()` | RPC | Directory rows (incl. `override_count`, `over_limit`, `licensing_hold`) |
| `platform_office_license(uuid)` | RPC | The full office document (entitlements + overrides + invoices + activity) |
| `platform_assign_plan(uuid,uuid,text,jsonb)` | RPC | Assign/change; **lifts holds** |
| `platform_set_license_status(uuid,text,text)` | RPC | Suspend / cancel / restore |
| `platform_start_trial(uuid,uuid,int)` | RPC | **Unused** |
| `platform_extend_trial(uuid,int,text)` | RPC | +14 days (hard-coded caller) |
| `platform_set_override(uuid,text,jsonb,text,timestamptz)` | RPC | Grant/revoke an exception |
| `platform_clear_override(uuid,text,text)` | RPC | Hand a feature back to the plan |
| `platform_bulk_set_overrides(...)` | RPC | **Exists server-side; deliberately unused** — see the batching note |
| `platform_usage_report()` | RPC | Per-office meters (incl. `meter_kind`) |
| `platform_licensing_health()` | RPC | The six signals |
| `platform_settings_read()` / `platform_update_settings(jsonb)` | RPC | Enforcement mode + grace/warn days + default plans |
| `platform_run_licensing_lifecycle()` | RPC | **Unscheduled and unwired** |
| `office_licenses`, `office_feature_overrides` | tables + Realtime | Live propagation to tenants |
| `platform_audit_log` | RPC | The decision trail (read on the الفوترة والسجل screen) |

### 11. UI Requirements

- **`source` is the module's reason for existing.** Every value the board shows must be able to say which rung produced it, in one line, without a click. `_RowStory` already does this — protect it.
- **The kill switch needs a guard proportional to its blast radius.** A typed confirmation naming the affected office count, at minimum. It is currently the least-guarded control in the console.
- **The commercial facts on a licence are richer than the UI collects.** Negotiated price, contract reference, auto-renew and trial length are all columns the office's own billing screen renders — and none of them can be set. The assign dialog should become a proper licence form.
- **Trial extension must take a number.**
- **"Issue invoice" creates a billable record and must confirm**, stating the period and the amount it will bill.
- **The alert strip is the right pattern** (empty signals take no space, non-empty ones become pressable counts). Apply it elsewhere.
- **Reason-with-suggestions is the right dialog**; every consequential platform action should use it.
- **Show the dormant lifecycle.** If the job does not run, the console should either offer «تشغيل الآن» (the cubit method exists) or state plainly that dunning is manual — right now the health signals imply an automation that is not there.
- **Surface licensing settings** (grace days, warn days, default plans) somewhere; they govern every date the health strip computes.
- **Directory needs the shared list shape** — search, status, sort, results header, pager — instead of a bespoke query + one filter.

### 12. UX Problems

1. **The platform kill switch has no confirmation.**
2. **Assign-plan collects 2 of 9 fields** the RPC accepts; price override, contract ref, auto-renew and trial length are unreachable.
3. **Trial extension is hard-coded to 14 days.**
4. **«إصدار فاتورة» fires immediately** with no preview of period or amount.
5. **The lifecycle engine never runs** — the six health signals describe states the system cannot reach on its own.
6. **`platform_start_trial` is dead**; trials can only begin through an option the dialog never sends.
7. **Licensing settings are unreachable** although they drive every threshold on screen.
8. **No pagination or sort** on the licence directory.
9. **The office's own «الاستخدام» tab and the office-billing screen draw the same meters differently** — one explains stock vs flow, the other does not.
10. **Bespoke filters again** — a third distinct filter implementation inside one shared cubit.

### 13. Recommended Information Architecture

```
التراخيص
├── وضع التطبيق          ← enforcement mode (GUARDED) + grace/warn settings + [تشغيل دورة الحياة]
├── إشارات               ← the six health signals (empty ones invisible)
├── الدليل               ← DashboardFilterBar (search · status · hold · over-limit) + sort + pager
│                          rows: office · plan · status · cycle · price · renewal · overrides · over-limit
└── مساحة عمل المكتب
    ├── الترخيص          identity · status · hold · dates · price · contract ref · auto-renew
    │                    [تعيين/تغيير الباقة (full licence form)] [تمديد التجربة (N days)]
    │                    [إيقاف/استئناف (reason)] [إصدار فاتورة (preview → confirm)]
    ├── الميزات والحدود   the board (draft · lenses · source story · one reason · save bar)
    ├── الاستخدام         meters (stock/flow labelled) · over-limit callouts
    ├── الاستثناءات       the record: value · plan value · direction · reason · expiry · expired
    └── الفوترة والنشاط   this office's invoices + its slice of the audit trail
```
---

## 5.4 الفوترة والسجل (Platform Billing & Audit Trail) — **financial**

### 1. Purpose

**What the platform charged, and what the platform decided.** Two sidebar rows folded into one destination, with a stated reason:

> *"They belong together because they are the same kind of thing: append-only records of what already happened, consulted when a question comes up rather than worked in daily… They also answer each other. 'Why was this office invoiced at this figure' is a billing question whose answer — the plan assignment, the override, the cycle change — is an audit row; keeping the switch between them in the page header makes that a single press instead of a round trip through the sidebar."*

And the module states its own limitation on screen: *"فواتير اشتراك المكاتب في المنصة. **التحصيل يدوي في هذا الإصدار: الفاتورة سجلّ، والسداد يُسجَّل عند وصوله.**"*

> **There is no payment gateway, no card capture and no automatic collection.** An invoice here is a record a gateway later plugs into. *"Saying so on the screen is what stops someone assuming a 'paid' chip means money moved by itself."*

### 2. Users / Roles

`DashboardPermission.platformLicensing` + `platformOnly`. Every RPC calls `assert_platform_admin()`. The audit trail is **append-only for everyone including the table owner**.

### 3. Entry Points

Sidebar: المنصة → الفوترة والسجل → `/platform-billing`. Two page-level tabs (`LicensingTabs`): **الفواتير** (count `billing.invoiceCount`) and **سجل التغييرات** (count `audit.length`).

An office's own invoices also appear inside التراخيص → office workspace → «الفوترة والنشاط»; this screen is the platform-wide ledger.

### 4. Main Screen — information architecture

#### Tab 1 — الفواتير (`InvoicesSection`)

**(a) `LicensingConsoleHeader`** — title, the "manual collection" subtitle, the tab strip, one action **«تشغيل دورة التجديد»**, and a 4-figure stat line (*"The four figures used to be `DashboardKpiCard`s — four boxes, each with a border and a shadow, for four numbers nobody drills into. They are a stat line now… which is a third of the page returned to the invoice table."*):

| Stat | Meaning |
|---|---|
| إيراد شهري متكرر — من التراخيص النشطة | **MRR at list price, from ACTIVE licences only** — trials and held offices excluded *because neither is billing anybody today* |
| مسدَّد | `totals.paid` |
| صادر وغير مسدَّد | `totals.issued` |
| متأخر | `totals.overdue` (error-toned when > 0) |

**(b) تجديدات خلال ٣٠ يومًا** (`DashboardPanel`, only when non-empty) — office · plan key · period end · amount · a تلقائي/يدوي chip.

**(c) الفواتير** (`DashboardPanel` + **`OpsDataTable`**, page size **15**) — the only `OpsDataTable` in the licensing console:

| Column | flex |
|---|---|
| رقم الفاتورة | 2 |
| المكتب | 3 |
| المدة (`period_start → period_end`) | 3 |
| المبلغ (numeric) | 2 |
| الحالة (`InvoiceStatusChip`) | 2 |
| *(actions)* | 2 |

Row actions: **«تسجيل سداد»** (when `isPayable`) · **«إبطال»** (when not paid and not already void).

Empty: `DashboardEmptyState` "لا توجد فواتير بعد — تصدر الفواتير مع التجديد الدوري، أو يدويًا من بطاقة المكتب في شاشة التراخيص."

#### Tab 2 — سجل التغييرات (`AuditSection`)

Presented as a **day-grouped trail, not a grid.** From the file:

> *"The grid it replaced spent five of its seven columns on machine references (`max_captains`, `true`, a bare office uuid) and dashes, printed a date but never a time, and never showed the one thing an audit row exists for — the value before and after. Every row here reads as a sentence, and the evidence behind it opens in place."*

- **Server-side filters**: **entity type** (الكل · التراخيص · الاستثناءات · الباقات · قيم الباقات · الميزات · الفواتير · الإعدادات) and **period** (كل الفترة · اليوم · ٧ أيام · ٣٠ يومًا). *"Both filters are server-side: the RPC returns the most recent rows that match, so narrowing is also how the operator reaches past the read cap."*
- **Client-side search** across subject, office, actor, reason, entity ref, action label and entity label.
- **Progressive disclosure**, `_step = 30` more per press, over a `_serverCap = 100` read limit *"named here so the screen can say so out loud instead of implying it is showing everything."*
- `AuditLabels` resolves feature keys and plan ids into human names using the catalog and plan list the shared cubit already holds.

### 5. Data Model — **keep these four apart**

| Concept | Type | Notes |
|---|---|---|
| **BILLING OVERVIEW (aggregates)** | `BillingOverview` | `issued`, `paid`, `overdue`, `invoiceCount`, **`mrr`** (active licences only), `invoices`, `renewals` |
| **INVOICES (the ledger)** | `PlatformInvoice` | `id`, `invoiceNumber`, `officeId?`, `officeName?`, `total`, `currency`, `status`, `periodStart/End`, `issuedAt`, `dueAt`, `paidAt`, **`paymentMethod?`**, **`lineItems`** |
| **PAYMENTS (transactions)** | — | **No separate entity.** A payment is a *mutation of the invoice row*: `status='paid'`, `paid_at`, `payment_method`, `payment_ref`, `recorded_by`. **`[BACKEND GAP]` there is no payments table, no partial payment, no multiple payments per invoice** |
| **AUDIT (the decision trail)** | `LicenseAuditEntry` | `id`, `entityType`, `entityRef`, `action`, `createdAt`, `officeName?`, **`actorLabel`** (*"denormalised on write, so the trail still reads correctly after the actor is removed"*), `reason`, `oldValue`, `newValue` |

**Invoice statuses** (6): `draft` مسودة · `issued` صادرة · `paid` مسددة · `overdue` متأخرة · `void` ملغاة · `refunded` مستردة.
`isPayable = status ∈ {issued, overdue, draft}`.

> **`lineItems` is open-ended by design:** *"add-ons, overage, proration and coupons all land here as items rather than as columns."* The invoice insert builds a default single item `{type: 'plan', label: 'اشتراك المنصة — ‹plan›', qty: 1, unit, amount}`. **The UI never renders line items on either the platform or the office side.** `[UI GAP]`

**Audit actions** (16 mapped): `created` · `updated` · `deleted` · `enabled` · `disabled` · `plan_changed` · `limit_changed` · `override_created` · `override_removed` · `trial_started` · `trial_extended` · `renewed` · `suspended` · `restored` · `cancelled`.
**Audit entity types** (9 mapped): `feature` · `category` · `plan` · `plan_feature` · `license` · `override` · `invoice` · `usage` · `settings`.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Record payment** | Row → «تسجيل سداد» | **method** as free text (`promptForReason` with `minLength: 3`, suggestions: تحويل بنكي · نقدًا · محفظة إلكترونية · شيك) | `invoice_not_payable` | `platform_record_payment(id, method, **null**)` → `status='paid'`, `paid_at=now()`, `payment_method`, `recorded_by=auth.uid()`. Reloads billing, licences **and health** (*"the registration lifts any restriction caused by lateness"*) | the prompt is the confirm | **irreversible — `platform_void_invoice` refuses a paid invoice** |
| **Void invoice** | Row → «إبطال» | **reason** ≥ 8 chars (3 suggestions) | `invoice_not_voidable` — *"لا يمكن إبطال فاتورة مسددة — عكس مبلغ محصَّل استرداد وليس تعديلًا"* | `status='void'`, audited | yes, with the consequence stated | yes |
| **Run renewal cycle** | Header → «تشغيل دورة التجديد» | — | — | `platform_run_billing_cycle()` → issues renewal invoices for licences in `active`/`past_due`/`grace`. Message: "تم إصدار N فاتورة تجديد." | **no** `[UI GAP]` | **creates billable records across every eligible office** |
| **Filter audit** | Entity type / period | — | — | Server-side refetch | — | — |
| **Search audit** | Search field | — | — | Client-side over loaded rows | — | — |
| **Show more** | «عرض المزيد» | — | — | +30 rows, up to the 100-row server cap | — | — |
| **Page invoices** | `OpsDataTable` pager | — | — | Client-side over the loaded set | — | — |
| **Filter invoices** | — | — | — | **`[NOT IMPLEMENTED]` in the UI.** `platform_billing_overview(p_filters)` accepts `office_id` and `status`, and `PlatformLicensingCubit.loadBilling({officeId, status})` plumbs them — **no control ever passes either** | | |
| **Issue an invoice** | — | — | — | Not here — it lives on the office header in التراخيص | | |
| **Refund** | — | — | — | **`[NOT IMPLEMENTED]`.** `refunded` is a displayable status reachable only by direct SQL | | |

> **`[UI GAP]` — `payment_ref` is never captured.** `platform_record_payment(p_invoice_id, p_method, p_reference, p_paid_at)` takes a reference **and** a payment date; the UI passes `null` for the reference and never offers the date. `PlatformInvoice.paymentMethod` is parsed and **never rendered**. A manually collected payment therefore has no traceable reference anywhere in the product.

### 7. Workflows

**Billing an office (entirely manual today)**
```
التراخيص → office → «إصدار فاتورة»
  → platform_issue_invoice(office, period_start?, period_end?, options?)
     · period defaults from the licence (period_start, period_end, or +1 month/year by cycle)
     · amount = options.amount ?? license.price_override ?? plan.price_(monthly|yearly) ?? 0
       ("The negotiated price wins over the list price; a 'free' or 'custom' cycle with no
         negotiated price bills zero rather than guessing.")
     · line_items = options.line_items ?? one 'plan' item
     · total = subtotal - discount + tax
     · invoice_number from platform_next_invoice_number()
     · plan_snapshot recorded
     · ON CONFLICT (office_id, period_start, period_end) WHERE status <> 'void' DO NOTHING
       — idempotent per period: "the renewal job may run twice without double-billing anyone"
  → push_operational_alert 'invoice_issued' → '/settings/billing'  (dead link)

الفوترة والسجل → find the invoice → «تسجيل سداد» → type the method → paid
```

> **`[UI GAP]`** — every one of the `options` levers (`amount`, `discount`, `tax`, `line_items`, `notes`) and both period arguments are unreachable: the cubit calls `_issueInvoice(officeId)` with no options and the UI has no form. Every invoice the console can create is a single-line, full-list-price, default-period invoice.

**Answering "why was this office billed this?"**
```
الفواتير → note the office and period
  → سجل التغييرات → entity type = التراخيص or قيم الباقات → search the office name
  → read the sentence + old/new values + the mandatory reason + the actor
```

**Who writes the trail** — *"Written by database triggers rather than by application code, because an audit log a caller can forget to write is not an audit log."* Reasons reach it through `set_config('bmt.licensing_reason', …, true)` set by each RPC before it mutates.

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` (frame) ✔ |
| **Busy** | Top `LinearProgressIndicator` ✔ |
| **Error (load)** | `DashboardErrorState` + retry ✔ |
| **Action error** | Snackbar over the screen ✔ |
| **Empty (invoices)** | `DashboardEmptyState` naming both ways an invoice is created ✔ |
| **Empty (renewals)** | The whole panel is omitted ✔ |
| **Empty (audit)** | `DashboardEmptyState` |
| **Section refresh failure** | `_section()` swallows it silently — *"a background section refresh must never surface an error banner or a spinner over the whole console"* ✔ |
| **Read cap** | The audit screen names its own 100-row cap rather than implying completeness ✔ |
| **Permission denied** | "هذه الشاشة متاحة لمديري المنصة فقط." |

### 9. Validation & Business Rules

**Implemented**
- **Payment method** ≥ 3 chars (free text).
- **Void reason** ≥ 8 chars.
- `invoice_not_payable` — only `draft`/`issued`/`overdue` accept a payment.
- `invoice_not_voidable` — **a paid invoice can never be voided**. Reversing collected money is a refund, not an edit.
- Invoice issuance is **idempotent per (office, period_start, period_end) where status <> 'void'`**.
- Amount precedence: explicit option → `license.price_override` → plan list price for the cycle → **0** (never a guess).
- `total = subtotal - discount + tax`; currency from the licence, default EGP.
- `due_at = issued_at + v_due days`; `platform_run_licensing_lifecycle` marks `issued` invoices `overdue` past `due_at`.
- **MRR counts ACTIVE licences only.**
- The renewal cycle issues for licences in `active`, `past_due`, `grace`.
- Audit is append-only (`audit_is_append_only`), with `actorLabel` denormalised on write.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` **No partial payments, no payment history per invoice, no credit notes.** A payment is one mutation of the invoice row.
- `[BUSINESS RULE UNCLEAR]` `refunded` exists as a status with no path to reach it and no refund record anywhere.
- `[BUSINESS RULE UNCLEAR]` Tax and discount are columns with no UI, no rate configuration and no rule — a VAT model is implied and absent.
- `[BUSINESS RULE UNCLEAR]` Multi-currency is modelled (per licence, per invoice) and never varies. No FX, no reporting currency.
- `[UNCLEAR]` `platform_next_invoice_number()` — the numbering scheme (per year? per office? global?) is not surfaced anywhere.
- `[UNCLEAR]` `draft` invoices are `isPayable` in the Dart entity but **filtered out of the office's own view** by `office_invoices`. What a draft is *for* is not stated.

### 10. Backend Dependencies

| Dependency | Kind | Purpose |
|---|---|---|
| `platform_billing_overview(jsonb)` | RPC | Totals + MRR + invoices + upcoming renewals. **Accepts `office_id` / `status` filters the UI never sends** |
| `platform_issue_invoice(uuid,timestamptz,timestamptz,jsonb)` | RPC | Idempotent per period |
| `platform_record_payment(uuid,text,text,timestamptz)` | RPC | Manual collection |
| `platform_void_invoice(uuid,text)` | RPC | Void with a reason |
| `platform_run_billing_cycle()` | RPC | Renewal invoices |
| `platform_audit_log(jsonb,int,int)` | RPC | The trail, server-filtered, capped at 100 |
| `platform_next_invoice_number()`, `platform_plan_snapshot(uuid)` | internal | Numbering + the plan as it stood |
| `office_invoices`, `platform_audit` | tables | |
| **no `pg_cron`** | — | Renewals run only when a human presses «تشغيل دورة التجديد» |

### 11. UI Requirements

- **Money is the primary hierarchy.** MRR, outstanding and overdue are the three numbers a platform operator opens this for; overdue must be the loudest.
- **The invoice table is the right shape** and is the only place in the licensing console using `OpsDataTable`. Extend it with the shared results header, filters (office · status · period) and `DashboardPagerBar`.
- **An invoice needs a detail view.** `lineItems`, `plan_snapshot`, `paymentMethod`, `paidAt`, `dueAt` and the audit rows for that invoice are all available and none are shown.
- **Recording a payment is an accounting act.** It needs method **+ reference + date**, not a free-text single field — and the reference is the only thing that would let anyone reconcile.
- **Voiding is correctly guarded**; keep the copy that explains why a paid invoice cannot be voided.
- **«تشغيل دورة التجديد» must preview before it bills.** "سيتم إصدار N فاتورة بإجمالي X" then confirm. It currently issues across the whole platform on one tap.
- **Issuing an invoice needs a form** — period, amount (defaulting to the negotiated or list price), discount, tax, line items, notes. Every one of those is server-supported.
- **The audit trail's sentence-per-row design is excellent.** Keep the day grouping, the old→new evidence, the mandatory reason and the honest read cap. Add: an office facet, an actor facet, and a link from an audit row to the entity it describes.
- **Cross-link the two tabs**: an invoice row should be able to jump to its own audit rows and vice versa — the module's stated reason for existing.
- **State the manual-collection limitation once, prominently**, and keep it: it is the single most important thing a reader must not misunderstand.

### 12. UX Problems

1. **The renewal cycle bills the whole platform with no preview and no confirmation.**
2. **Payment reference and payment date are unreachable**, making manual collection unreconcilable.
3. **`paymentMethod` is stored and never displayed.**
4. **No invoice detail; `lineItems` is parsed and discarded.**
5. **No invoice filters** despite full RPC support (`office_id`, `status`).
6. **Invoice issuance has no form** — every invoice is single-line, list-price, default-period.
7. **`refunded` is a dead status** with no path and no record.
8. **Tax and discount exist with no configuration or explanation.**
9. **No cross-link between the two tabs** that were merged precisely because they answer each other.
10. **Audit search is client-side over a 100-row window**, so searching narrows what is already loaded rather than what exists — the entity/period facets do reach further, but the search box silently does not.

### 13. Recommended Information Architecture

```
الفوترة والسجل
├── الفواتير
│   ├── Header: MRR · مسدَّد · صادر · متأخر  + [إصدار فاتورة] [تشغيل دورة التجديد (preview→confirm)]
│   ├── تجديدات قادمة  (30 days)
│   ├── Filter bar: search · office · status · period
│   ├── OpsDataTable + results header + pager
│   └── Invoice detail (drawer): line items · plan snapshot · dates
│                                · [تسجيل سداد: method + reference + date] · [إبطال (reason)]
│                                · → its audit rows
└── سجل التغييرات
    ├── Facets: entity type · period · office · actor   (all server-side)
    ├── Day-grouped trail: sentence · actor · reason · old → new
    └── Row → the entity it describes (plan / licence / office / invoice)
```
---

## 5.5 برنامج الإحالة (Referral Programme) — **financial**

### 1. Purpose

The **customer-acquisition loop**: every client gets a referral code at sign-up; a new customer who signs up with someone's code and then completes their first paid booking earns **both parties** a reward. This module configures the reward, and reports on the programme.

It is a **platform** module, not an office one, and the code comment in the shell states exactly why:

> *"The referral programme carries no `office_id` — `referrals`, `referral_codes` and `referral_rewards` are platform-wide, and `referral_rewards` only accepts writes from `is_platform_admin()`. An office owner opening this would be reading the whole platform's numbers, so it belongs to EWT's own console and nowhere else."*

### 2. Users / Roles

- `DashboardPermission.referrals` + `platformOnly: true`.
- `FeatureKeys.referrals` (`'referrals'`) exists in the catalogue — but the nav item declares **no `feature:`**, so licensing does not gate this module. `[UNCLEAR]`
- Writes: `referral_rewards_write` / `referral_rewards_insert` policies both require `is_platform_admin()` **and** `id = 1`. `anon` has INSERT/UPDATE/DELETE revoked; `authenticated` has DELETE revoked.
- Reads: **`referral_rewards_read` is `using (true)` for `anon, authenticated`** — the reward configuration is world-readable, deliberately (client apps need to show what a referral is worth).

> ### `[BACKEND GAP]` — **the most serious finding in this audit**
>
> The other three referral tables carry only *self-scoped* read policies, and **no platform-admin read policy was ever added**:
>
> ```sql
> create policy referral_codes_select_own      on referral_codes
>   for select using (auth.uid() = user_id);
> create policy referrals_select_involved      on referrals
>   for select using (auth.uid() = referrer_id or auth.uid() = referred_id);
> create policy rrt_select_own                 on referral_reward_transactions
>   for select using (auth.uid() = user_id);
> ```
>
> `SupabaseReferralDatasource` reads all three **directly**. A platform admin is not a referrer or a referred user, so those queries return **zero rows** for them. Concretely:
>
> | Surface | Source | Result for a platform admin |
> |---|---|---|
> | سجل الإحالات | `from('referrals')` | **empty** |
> | حركات المكافآت | `from('referral_reward_transactions')` | **empty** |
> | أكواد الإحالة (KPI) | `from('referral_codes').count()` | **0 or 1** |
> | قيد الانتظار / أتمّوا أول طلب / مكافآت مُنحت | derived from `referrals` | **all 0** |
> | مكافآت المُحيلين / المدعوين / الإجمالي | derived from `referral_reward_transactions` | **all 0** |
> | المتصدّرون — الهاتف / الكود | `clients`, `referral_codes` lookups | **blank** |
> | المتصدّرون — إجمالي / قيد الانتظار / آخر إحالة | derived from `referrals` | **all 0 / null** |
> | إجمالي الإحالات / معدل التحويل | `referral_analytics` **view** | **correct** — a view runs as its owner and bypasses RLS |
> | المتصدّرون — الاسم / مكتملة / المكافآت | `referral_leaderboard` **view** | **correct**, same reason |
>
> **So three of the five tabs render empty and the Overview shows a mix of correct view-derived figures and zeroed table-derived figures, with nothing distinguishing them.** The datasource's own `_isMissingRelation` guard does not fire — RLS returns an empty set, not an error, so the screen reports "no data" rather than "not permitted."

### 3. Entry Points

Sidebar: المنصة → برنامج الإحالة → `/referrals`. No inbound or outbound links.

### 4. Main Screen — information architecture

`ReferralManagementScreen` = `DashboardModuleHeader` («برنامج الإحالات» / "تابع أداء الإحالات وأدر إعدادات المكافآت والمتصدّرين والسجل.", one action **«تحديث»**) with a **scrollable 5-tab `TabBar` pinned into the header**, and a `TabBarView`.

| Tab | Content |
|---|---|
| **نظرة عامة** | **9 `DashboardKpiCard`s**: أكواد الإحالة · إجمالي الإحالات · قيد الانتظار · أتمّوا أول طلب · مكافآت مُنحت · معدل التحويل · مكافآت المُحيلين · مكافآت المدعوين · إجمالي المكافآت الموزعة. Then two charts in `DashboardPanel`s: a **donut** «توزيع حالات الإحالة» and a **donut** «توزيع المكافآت» (referrer vs referred) |
| **إعدادات المكافآت** | The one write surface — see §6 |
| **المتصدّرون** | Search + `OpsDataTable`: المرتبة · العميل · الهاتف · الكود · إجمالي · مكتملة · قيد الانتظار · المكافآت · آخر إحالة |
| **سجل الإحالات** | Search + **status `FilterChip`s** (كل الحالات + 4 statuses) + **reward-status chips** (كل المكافآت / ممنوحة / قيد الانتظار) + `OpsDataTable`: الكود · المُحيل · المدعو · الحالة · المكافأة · حالة المكافأة · التاريخ · (detail) → an AlertDialog «تفاصيل الإحالة» |
| **حركات المكافآت** | Search + role chips (الكل / referrer / referred) + `OpsDataTable`: المستخدم · الدور · نوع المكافأة · القيمة · الحالة · رقم الإحالة · التاريخ |

### 5. Data Model

**`ReferralRewardConfig`** — the **singleton row `referral_rewards.id = 1`**: `enabled`, `rewardType` ∈ `{points, wallet, coupon, loyalty}`, `rewardValue` (to the **referrer**), `referredValue` (welcome reward to the **referred**), `currency`, `couponCode?`, `updatedAt`.
A missing row falls back to a hard-coded default: `enabled: true, wallet, 50 / 25, EGP`. `[UNCLEAR]` — showing an invented configuration as if it were stored.

**`ReferralRecord`** (`referrals`) — `id`, `code` (`referral_code`), `referrerId`/`referrerName`, `referredId`/`referredName`, `status`, `rewardType`, `rewardValue`, `rewardStatus`, `firstOrderId?`, `createdAt`, `firstOrderAt?`, `rewardedAt?`.

**`ReferralStatus`** — the lifecycle, matching the DB CHECK:

| Enum | DB | Meaning |
|---|---|---|
| `pendingRegistration` | `pending_registration` | Code recorded, no account yet |
| `registered` | `registered` | The referred user has an account |
| `firstOrderCompleted` | `first_order_completed` | First paid booking landed |
| `rewardGranted` | `reward_granted` (also accepts legacy `completed`) | Both rewards paid |

`isSuccessful = firstOrderCompleted ∨ rewardGranted` · `isPending = pendingRegistration ∨ registered`.

**`ReferralRewardTransaction`** (`referral_reward_transactions`, an **immutable ledger**) — `id`, `referralId`, `userId`/`userName`, `role` ∈ `{referrer, referred}`, `rewardType`, `rewardValue`, `status` (default `granted`), `createdAt`.

**`ReferralLeaderboardItem`** — `rank`, `referrerId`, `name`, `phone`, `code`, `totalReferrals`, `completedReferrals`, `pendingReferrals`, `rewardsEarned`, `lastReferralAt?`. **Assembled from five sources**: the `referral_leaderboard` view + an aggregate over `referrals` + a `clients` phone lookup + a `referral_codes` lookup — four of which are RLS-blocked (see §2).

**`ReferralAnalytics`** — `totalCodes`, `totalReferrals`, `pendingReferrals`, `firstOrderCompleted`, `rewardGranted`, `conversionRate` (0–100), `referrerRewards`, `referredRewards`, `totalRewards`.

### 6. User Actions

| Action | Trigger | Inputs | Validation | Result | Confirm? | Destructive? |
|---|---|---|---|---|---|---|
| **Save reward config** | إعدادات المكافآت → «حفظ الإعدادات» | enabled · rewardType · referrer value · referred value · currency · coupon code | Form validation on the two numeric fields; `couponCode` sent **only** when `rewardType == 'coupon'` and non-empty | `upsert referral_rewards {id: 1, …, updated_at}` | — | **changes what every future referral pays out, platform-wide** |
| **Disable the programme** | The `SwitchListTile` → off | — | — | Local state only until Save | **yes** — "سيتوقف منح مكافآت الإحالة للمستخدمين الجدد حتى يتم تفعيل البرنامج مرة أخرى." ✔ | reversible |
| **Refresh** | «تحديث» | — | — | Reloads all five datasets sequentially | — | — |
| **Search / filter** | per-tab | — | — | **All in memory** over the loaded rows (history: 1000 cap; transactions: 1000 cap; leaderboard: 50) | — | — |
| **View referral detail** | History row | — | — | `AlertDialog` «تفاصيل الإحالة» | — | — |
| **Grant / revoke a reward manually** | — | — | — | **`[NOT IMPLEMENTED]`** | | |
| **Invalidate a fraudulent referral** | — | — | — | **`[NOT IMPLEMENTED]`** | | |
| **Create / issue a code** | — | — | — | **`[NOT IMPLEMENTED]`** — codes are minted by an `auth.users` trigger only | | |

> **The save action is a single button that changes platform-wide payout economics, and it does not confirm.** Only *disabling* the programme confirms. Changing `rewardValue` from 50 to 5000 does not. `[UI GAP]`

### 7. Workflows

**The referral lifecycle (entirely trigger-driven — the dashboard only observes)**

```
1. SIGN-UP        trigger on_auth_user_created_referral → handle_new_user_referral()
                  a) always mints a unique code:  <PREFIX>-<4 hex>, PREFIX = first 6 letters
                     of the name uppercased, or 'BMT' if fewer than 3 letters
                  b) if raw_user_meta_data.referral_code is present and resolves to a
                     different user with no existing referral for this user
                     → insert referrals(status: 'registered', registered_at: now())

2. LATE ENTRY     redeem_referral_code(p_code) RPC — the "enter it later" path.
                  Refuses: unauthenticated · invalid_code · self_referral · already_referred

3. CONVERSION     trigger on_booking_paid_referral → grant_referral_reward()
                  fires on INSERT or UPDATE OF status on operation_bookings
                  guard: new.status ∈ ('confirmed','approved')
                  guard: a referral exists for this client in ('registered','pending_registration')
                  guard: it is the client's FIRST paid booking
                  → referrals.status = 'first_order_completed', first_order_id, first_order_at
                  → if config.enabled:
                       insert 2 rows into referral_reward_transactions (referrer + referred)
                       credit loyalty_accounts:
                          wallet|coupon → wallet_balance += value
                          points|loyalty → points_balance += value::int
                       referrals.status = 'reward_granted', reward_status = 'granted', rewarded_at
                       insert 2 English-language rows into public.notifications
```

> **`[UNCLEAR]` — the reward credits `loyalty_accounts.wallet_balance` / `points_balance`, not the newer wallet subsystem** (`wallet_*` tables with a ledger and its five laws). Whether these two money stores are reconciled anywhere is not visible from this module.

> **`[UNCLEAR]` — the reward notifications are written in English** ("Referral reward earned 🎉", "Welcome reward unlocked 🎁") into a wholly Arabic product, and use a **`type`** column while `office_dispatch_notification` writes **`category`**.

> **`[UNCLEAR]` — the conversion trigger fires on `operation_bookings.status ∈ ('confirmed','approved')`.** Booking statuses were remapped in 2026-07 to `reserved`/`confirmed`; whether `approved` is still a live value is not verifiable from this module, and if the guard no longer matches, **no referral would ever convert**.

**Configuring the reward**
```
إعدادات المكافآت → toggle / type values → «حفظ الإعدادات»
  → upsert referral_rewards id=1  (RLS: is_platform_admin() AND id = 1)
  → takes effect on the NEXT conversion; nothing retroactive
```

### 8. States

| State | Behaviour |
|---|---|
| **Loading** | `DashboardLoading` ✔ |
| **Error (load)** | `DashboardErrorState` + retry ✔ |
| **Saving** | `isSaving` → the save button shows «جارٍ الحفظ...» |
| **Action success** | `ReferralActionSuccess` → snackbar «تم حفظ إعدادات المكافآت» ✔ |
| **Action failure** | **`ReferralError` — a full-screen error that destroys the settings form.** `[UI GAP]` The only module in this audit that breaks the console's "an action error never replaces the screen" law |
| **Missing relation** | Every read is wrapped: `42P01` / `PGRST205` / `42703` → empty lists and a default config, *"so the screen stays usable before the migration is applied"* |
| **RLS-emptied** | **Indistinguishable from "no data yet."** The screen says "there are no referrals" when the truth is "you are not permitted to read them" |
| **Empty** | Per-tab; `OpsDataTable` handles zero rows |
| **Partial** | `load()` awaits five calls **sequentially in one try** — a failure in any one produces a full-screen error and loses the other four `[UI GAP]` |

### 9. Validation & Business Rules

**Implemented**
- One configuration row, platform-wide (`id = 1`, enforced by the INSERT policy).
- `rewardType ∈ {points, wallet, coupon, loyalty}`; `couponCode` persisted only for `coupon`.
- Currency defaults to `EGP` when the field is blank.
- **A customer can be referred only once** — `uq_referrals_referred` unique index on `referred_id`.
- **Self-referral is refused** (`v_referrer <> new.id`, and `self_referral` in the RPC).
- **The reward fires only on the referred user's FIRST paid booking**, checked by an explicit `not exists` over their other confirmed/approved bookings.
- Codes are unique (`uq_referral_codes_code`), one per user (`uq_referral_codes_user_id`), generated in a retry loop.
- `referral_reward_transactions.role ∈ {referrer, referred}` (CHECK).
- Both reward rows are written in the same trigger, so referrer and referred rewards cannot diverge.
- `status` CHECK restricts the four lifecycle values.
- Existing users were backfilled with codes at migration time.

**Fraud / abuse prevention — what exists and what does not**
- ✔ One referral per referred user (DB-unique).
- ✔ No self-referral.
- ✔ Reward gated on a real, first, paid booking.
- ✘ `[NOT IMPLEMENTED]` No device, phone or payment-instrument fingerprinting.
- ✘ `[NOT IMPLEMENTED]` No cap on referrals per referrer, no cooling-off, no rate limit.
- ✘ `[NOT IMPLEMENTED]` No clawback if the first booking is later cancelled or refunded — `grant_referral_reward` never reverses.
- ✘ `[NOT IMPLEMENTED]` No manual invalidation, no review queue, no blocklist.
- ✘ `[NOT IMPLEMENTED]` No expiry on a pending referral.

**Unclear**
- `[BUSINESS RULE UNCLEAR]` `rewardType` values `points` and `loyalty` behave identically in the trigger (both credit `points_balance`); `wallet` and `coupon` also behave identically (both credit `wallet_balance`). **`coupon_code` is stored and never used by any code path.** Four named types, two behaviours, one dead field.
- `[BUSINESS RULE UNCLEAR]` `pending_registration` is a valid status the schema allows and **no code path ever writes** — both entry points insert `registered`.
- `[BUSINESS RULE UNCLEAR]` `referral_reward_transactions.status` defaults to `'granted'` and is never anything else; the UI has a «الحالة» column and a «حالة المكافأة» filter for a field with one value.
- `[BUSINESS RULE UNCLEAR]` A config change is not retroactive, and nothing on screen says so.
- `[UNCLEAR]` No audit trail for referral configuration changes — unlike every other financial surface in المنصة, which audits with a mandatory reason.

### 10. Backend Dependencies

| Dependency | Kind | Purpose | Reachable by a platform admin? |
|---|---|---|---|
| `referral_rewards` (id = 1) | table | The config | **yes** (read: `using(true)`; write: `is_platform_admin()`) |
| `referral_analytics` | **view** | totals · successful · conversion rate · rewards distributed | **yes** (definer semantics) |
| `referral_leaderboard` | **view** | referrer · name · successful_count · total_rewards | **yes** |
| `referrals` | table | The lifecycle records | **NO — RLS self-scoped** |
| `referral_codes` | table | Codes | **NO — RLS self-scoped** |
| `referral_reward_transactions` | table | The reward ledger | **NO — RLS self-scoped** |
| `clients` | table | Name/phone lookups | **NO — self-scoped** |
| `handle_new_user_referral()` | trigger fn | Mint code + record referral | — |
| `redeem_referral_code(text)` | RPC | Late code entry | — |
| `grant_referral_reward()` | trigger fn | Conversion + payout + notifications | — |
| `loyalty_accounts` | table | Where the money actually lands | — |

### 11. UI Requirements

- **Fix the data question before the design question.** Three tabs and six KPIs are structurally empty; designing around them would be designing around zeros. Until a platform read policy (or a definer RPC, the pattern the rest of المنصة uses) exists, the screen must at minimum **distinguish "no data" from "not permitted."**
- **Nine KPI cards is a wall.** The programme has three questions: *is it working* (conversion), *what is it costing* (total paid, split referrer/referred), *who is driving it* (top referrers). Everything else is supporting detail.
- **Make the funnel a funnel.** `registered → first_order_completed → reward_granted` is a three-stage conversion, currently drawn as a donut of unordered statuses.
- **Cost is the number the platform cares about.** "مكافآت المُحيلين / المدعوين / الإجمالي" should read as spend, with a period selector — there is currently **no date range anywhere in this module**.
- **Changing payout economics must confirm**, naming the old and new values, the way archiving a plan names the affected office count.
- **State that changes are not retroactive.**
- **Give the reward types honest labels** — four names, two behaviours, and a coupon field that does nothing.
- **The lifecycle needs a state legend.** Four statuses × a separate reward status × a transaction status is three status vocabularies on one screen.
- **A referral detail should show the chain**: code → referrer → referred → first booking → the two ledger rows.
- **Adopt the shared list shape** for the three tables (filter bar, results header, pager) — the module already uses `OpsDataTable` but pairs it with three bespoke chip toolbars.
- **This module should reuse the platform's own conventions**: an audited configuration change with a mandatory reason, an alert-strip signal for anomalies, and a period selector — all three exist one module away.

### 12. UX Problems

1. **Three of five tabs are structurally empty for the intended user** (RLS), and the screen presents that as "no data".
2. **Six of nine Overview KPIs read 0** for the same reason, side by side with two that are correct — with nothing to tell them apart.
3. **A save failure destroys the settings form** (full-screen error) — the only module here that does this.
4. **Changing payout amounts is unconfirmed**; only disabling the programme confirms.
5. **A default configuration is invented and shown as stored** when no row exists.
6. **Five sequential fetches in one try** — any single failure loses all five datasets.
7. **No date range**, so no cost-over-time, no cohort view, no trend — in a module whose subject is a marketing spend.
8. **Three status vocabularies**, one of which (`transaction.status`) has exactly one possible value.
9. **`couponCode` is collected and never used** by any code path.
10. **No fraud controls, no clawback, no manual intervention** of any kind — nothing can be corrected from the console.
11. **1000-row client-side caps** with in-memory search on the two ledgers.
12. **No audit** of who changed the payout, in a section where every other financial action is audited with a mandatory reason.

### 13. Recommended Information Architecture

```
برنامج الإحالة
├── نظرة عامة
│   ├── Period selector
│   ├── 3 headline figures: معدل التحويل · التكلفة الإجمالية · إحالات ناجحة
│   ├── Funnel: مسجّل → أتمّ أول طلب → مُنحت المكافأة
│   └── Cost split (referrer vs referred) over time
├── الإعدادات        ← reward type · referrer value · referred value · currency
│                      · enable switch · [حفظ (confirmed, showing old → new)] · last changed by/when
├── المتصدّرون       ← filter bar + table + pager
├── سجل الإحالات     ← filter bar (status · reward status · period) + table + pager
│   └── تفاصيل الإحالة  ← the chain: code → referrer → referred → first booking → ledger rows
└── حركات المكافآت   ← filter bar (role · type · period) + table + pager
```
---

# 6. Cross-Feature Relationships

This section exists because the ten screens must feel like **one platform**, not ten apps. Every relationship below is real and traceable in the code or schema.

## 6.1 The spine

```
                        ┌──────────────────────────┐
                        │  platform_features (47)  │  ← الباقات والميزات (الميزات tab)
                        │  + gates + dependencies  │
                        └────────────┬─────────────┘
                                     │ values assigned per plan
                                     ▼
                        ┌──────────────────────────┐
                        │   platform_plans (5)     │  ← الباقات والميزات (الباقات tab)
                        │   + plan_features        │
                        │   + plan_revisions       │
                        └────────────┬─────────────┘
                                     │ assigned to an office
                                     ▼
   ┌───────────────┐    ┌──────────────────────────┐    ┌─────────────────────────┐
   │   offices     │◄───┤    office_licenses       ├───►│ office_feature_overrides│
   │ مكاتب المنصة  │    │       التراخيص           │    │  التراخيص → الميزات     │
   │ ملف المكتب    │    │  status · cycle · price  │    │  per-office exceptions  │
   └───────┬───────┘    └────────────┬─────────────┘    └───────────┬─────────────┘
           │                         │                              │
           │                         ▼                              │
           │            ┌──────────────────────────┐                │
           │            │    office_invoices       │  ← الفوترة والسجل / الباقة والفوترة
           │            └──────────────────────────┘                │
           │                         │                              │
           │                         └──────────┬───────────────────┘
           │                                    ▼
           │                    ┌────────────────────────────────┐
           │                    │  office_entitlements() resolver │
           │                    │  kill_switch → license_hold →   │
           │                    │  override → plan → default      │
           │                    └────────────┬───────────────────┘
           │                                 │  EntitlementContext
           │                                 ▼
           │                    ┌────────────────────────────────┐
           │                    │  Every module in every section │
           │                    │  (sidebar gates + write gates) │
           │                    └────────────────────────────────┘
           ▼
   ┌───────────────┐    ┌──────────────────────────┐
   │ office_users  │───►│  DashboardRole (2)       │  ← المستخدمون والصلاحيات
   │               │    │  → DashboardPermission   │
   └───────────────┘    └──────────────────────────┘

   ┌──────────────────────────────────────────────────────────────┐
   │ platform_audit  ← every licensing write, trigger-written     │  ← الفوترة والسجل
   │ operational_alerts ← every event needing attention           │  ← الإشعارات
   └──────────────────────────────────────────────────────────────┘
```

## 6.2 The relationships, stated

| Relationship | Cardinality | Where it lives | Enforced by |
|---|---|---|---|
| **Plan → Features** | 1 : N (a plan holds a value per feature; an **absent** key = catalog default) | `platform_plan_features` | `platform_save_plan` replaces the map wholesale |
| **Feature → Gate** | 1 : N | `platform_feature_gates` | A trigger derives `enforcement_status` from gate rows |
| **Feature → Feature** | N : N (`requires` / `requiredBy`) | `platform_feature_dependencies` | `feature_dependency_cycle` guard; resolver's dependency gate |
| **Office → Licence** | **1 : 1** (`ON CONFLICT (office_id)`) | `office_licenses` | `platform_assign_plan` upserts by office |
| **Licence → Plan** | N : 1 | `office_licenses.plan_id` | `plan_archived` refuses assigning an archived plan |
| **Office → Override** | 1 : N (one per feature) | `office_feature_overrides` | Mandatory reason ≥ 8 chars (CHECK) |
| **Office → Invoice** | 1 : N | `office_invoices` | Unique per `(office_id, period_start, period_end) where status <> 'void'` |
| **Office → Operators** | 1 : N | `office_users` | Unique `username` **platform-wide**; ≥ 1 active `dashboard_admin` |
| **Operator → Auth account** | 1 : 1 | `office_users.user_id` | `staff_user_already_assigned` — an operator belongs to exactly one office |
| **Office → Alerts** | 1 : N | `operational_alerts.office_id` | RLS `office_id = current_office_id()` |
| **Plan → Downgrade plan** | N : 1 | `platform_plans.downgrade_to_plan_id` | Read by the lifecycle job. **No UI sets it** |
| **Referral → Client** | N : 1 (referrer), 1 : 1 (referred) | `referrals` | `uq_referrals_referred` |
| **Referral → Transactions** | 1 : 2 | `referral_reward_transactions` | Both rows written in one trigger |

## 6.3 The four hand-offs that already exist

1. **مكاتب المنصة → التراخيص.** «الميزات والحدود» on an office card or panel → route change **plus** `PlatformLicensingCubit.openOffice(officeId)`. The only cross-module hand-off in either section, and the model for the rest.
2. **الإشعارات → any module.** `alert.actionUrl` → `_openRoute`. Three of the emitted URLs are dead (`/settings/billing`, `/live-trips`, `/support`).
3. **Any module → the upgrade card.** `LicensingGuard` → `licensingRefusals` → the shell raises `showLicensingRefusal` on top of whatever the module already said. One wiring point.
4. **ملف المكتب → the shell.** A successful profile save calls `DashboardAuthCubit.refreshContext()` so the office name and logo in the chrome stop being stale.

## 6.4 The hand-offs that are missing

| From | To | Why it should exist |
|---|---|---|
| مكاتب المنصة (row) | التراخيص (licence) | The office directory shows **no licence state at all** — "which offices are suspended for non-payment" needs two modules today |
| التراخيص (office) | مكاتب المنصة (office) | The licence workspace shows no operational status, no listing state, no owner |
| الفوترة والسجل (invoice) | التراخيص (office) | An invoice row names an office and cannot open it |
| الفوترة والسجل (invoice) | سجل التغييرات | The two tabs were merged *because they answer each other* and do not link |
| الباقات والميزات (plan → المكاتب tab) | التراخيص | The plan lists its offices and cannot open one |
| الباقة والفوترة (office) | — | The office cannot see available plans, so "contact the platform" is a dead end |
| الإشعارات (licence alert) | الباقة والفوترة | `/settings/billing` is not a route |
| المستخدمون (quota) | الباقة والفوترة | `max_admin_users` refuses silently; nothing points at the plan that would lift it |

## 6.5 Shared vocabulary that must stay consistent

| Concept | Appears in | Rule |
|---|---|---|
| **Office operational status** (`active`/`paused`/`suspended`/`archived`) | ملف المكتب, مكاتب المنصة | Same 4 Arabic labels on both sides — **already consistent** ✔ |
| **Marketplace listing** (`draft`/`listed`/`unlisted`) | ملف المكتب, مكاتب المنصة | Same 3 Arabic labels — *"so both sides of the platform name the same state alike"* ✔ |
| **Licence status** (8 values) | الباقة والفوترة, التراخيص | Same labels via `LicenseSummary.statusLabelAr` / `OfficeLicenseRow.statusLabelAr` — **two independent copies of the same switch** `[risk of drift]` |
| **Invoice status** (6 values) | الباقة والفوترة, الفوترة والسجل | Two independent copies (`OfficeInvoice.statusLabelAr`, `PlatformInvoice.statusLabelAr`) `[risk of drift]` |
| **Profile completeness** | ملف المكتب (4 fields), مكاتب المنصة (5 fields) | **Already divergent** `[UI GAP]` |
| **Money format** | `licensingMoney()` (licensing), `formatMoney()` (platform_analytics), `'ج.م'` literals | **Three implementations** `[UI GAP]` |
| **`plan` vs `package`** | Everywhere | `plan`/باقة = platform licence tier. **Never** the passenger fare bundle, which owns the words in four tables and a sidebar item |
| **`license` vs `subscription`** | Everywhere | `license` = office↔platform. `subscription` = passenger fare product |
| **Reason ≥ 8 chars** | التراخيص, الفوترة والسجل | `promptForReason(minLength: 8)` with suggestion chips — the console's standard for consequential platform actions ✔ |

## 6.6 The three axes, restated for design

Every "can I?" in these sections resolves through three **independent** questions, and a good UI answers whichever one said no:

| Axis | Source | Refusal reads | Remedy |
|---|---|---|---|
| **Role** | `DashboardPermissions.permissionsFor(role)` | «ليس لديك صلاحية… تواصل مع مالك المكتب» | Ask your owner |
| **Entitlement** | `EntitlementContext.allows(featureKey)` | «هذه الميزة غير متاحة في باقتك الحالية» | Upgrade |
| **Quota** | DB triggers vs `limit` features | «وصلت إلى حد الباقة لهذا العنصر» + real numbers | Upgrade, or free a slot (stock meters only) |

Plus two more that behave like refusals and are **not** the same thing:
- **Licence hold** (`suspended`/`cancelled`/`expired`) → «الحساب في وضع القراءة فقط» — *creation* blocked, everything existing continues.
- **Dependency block** → «هذه الميزة تتطلب تفعيل ميزة أخرى أولًا» — with `blockedBy` naming which.

**Never collapse these five into one "not allowed" state.** The whole three-predicate architecture exists so the console can tell them apart.
---

# 7. Global UX Requirements

These are the system-level rules the ten screens should share. They are derived from what the *rest* of the console already does well and from the specific inconsistencies found above. **No colours, typography or spacing here** — this is the UX system, not the visual one.

## 7.1 The list-module shape (currently used by 0 of 10)

Six other modules wear one composition. These ten should too, wherever they show a list:

```
DashboardModuleHeader (icon · title · subtitle · primary action · secondary actions · KPI summary)
   ↓
DashboardQueueTabs        (when the list has meaningful queues: status, state)
   ↓
DashboardFilterBar        (search · named filter dropdowns · sort · clear · active-filter labels)
   ↓
DashboardResultsHeader    ("N نتيجة" · sort · row-level bulk actions)
   ↓
OpsDataTable  |  card list
   ↓
DashboardPagerBar         (total label · page control)
```

Rules the existing implementations already encode and that must carry over:
- **Filters are named, not inferred.** A dropdown always shows its axis label, never just its current value.
- **Active filters are spelled out, never counted.** «٣ عوامل تصفية» hides which three; a hidden filter is how a row looks deleted.
- **A collapsed filter section must summarise itself** (`collapsedSummary` on `DashboardCollapsibleSection`).
- **Counts are `N/M`** — filtered over total — so narrowing never looks like data loss.

**Where this applies here:** المستخدمون (roster), مكاتب المنصة (directory), التراخيص (directory), الفوترة والسجل (invoices + audit), برنامج الإحالة (3 tables), الباقة والفوترة (invoices), الإشعارات (feed).

## 7.2 The form shape (currently used by 0 of 10)

`core/widgets/forms/` provides `DashboardFormController`, `DashboardFormField`, `DashboardFormSection`, `DashboardFormFeedback` — with the label-is-a-name rule, one validation definition per field, completion counting, jump-to-error, and signature-based dirty state with a discard guard.

**Six hand-rolled forms should adopt it:** `office_identity_form`, `staff_account_form`, `office_onboarding_form`, `plan_editor_dialog`, `notification_composer`, `referral_settings_tab`.

Rules that must survive the migration:
- **Per-field server errors.** `fieldErrors` keyed exactly as the request object's `validate()` keys them, so a rejection marks the offending input rather than showing one message with no anchor.
- **A dialog stays open across a failed submission**, and shows the refusal **inside** itself — a snackbar under a modal barrier is invisible.
- **Validate locally before the network** when the failure is knowable, especially where a round trip would create-then-compensate.

## 7.3 State handling — the console's four laws

1. **An action error never replaces the screen.** A failed *load* → `DashboardErrorState`. A failed *action* → a notice over the intact screen, carrying the last good data **and whatever was typed**. *(Broken today only by `ReferralCubit.saveConfig`.)*
2. **A section refresh never spins the whole console.** `PlatformLicensingCubit._section()` swallows background failures on purpose.
3. **Partial data is modelled as null, not as zero.** `PlatformAdminLoaded.analytics` is nullable because *"an empty analytics object claims every office has zero bookings, which is a statement about the platform, not an admission that nothing was fetched."*
4. **Independent failures fail independently.** Losing analytics must not lose the office list. *(Broken today in الباقة والفوترة — invoices and entitlements fail together — and in برنامج الإحالة — five sequential fetches in one try.)*

**Stale data must say it is stale**, not disappear: `_AnalyticsError(isStale: true)` renders an inline notice over the older numbers. That is the model.

## 7.4 Empty, loading, error — one set each

Use `DashboardLoading` (with skeleton `rows` where a shape is known), `DashboardEmptyState` (icon · title · message · optional action), `DashboardErrorState` (message · retry). **Three modules currently roll their own** (الإشعارات fully; مكاتب المنصة for its analytics panel).

**Distinguish four different "nothing here" states — they are not one state:**

| State | Message shape | Example |
|---|---|---|
| **Never had any** | Explain what would create the first one | "لم تصدر أي فاتورة اشتراك لهذا المكتب بعد." |
| **Filtered to zero** | Offer to clear | "لا مكتب يطابق التصفية" + «مسح عوامل التصفية» |
| **Not permitted** | Say so | **Missing everywhere.** برنامج الإحالة shows RLS-emptied tables as "no data" |
| **Failed to load** | Retry | `DashboardErrorState` |

## 7.5 Confirmation — the rule these sections do not currently follow

**Confirm any action that is irreversible, outward-facing, or affects parties beyond the current screen.** The console already has the right template — the feature kill switch — and should apply it consistently:

> Name the action · name the consequence in plain Arabic · **name the reach in real numbers** · error-tone the confirm button when destructive.

| Action | Today | Should be |
|---|---|---|
| Kill a feature platform-wide | ✔ exemplary (names default, plan count, override count, cascade) | keep as the template |
| Archive a plan | ✔ names the affected office count | keep |
| Suspend a licence | ✔ reason ≥ 8 + consequence + suggestions | keep |
| Suspend an office | ✔ confirms | keep |
| Disable a staff account | ✔ confirms | keep |
| Disable the referral programme | ✔ confirms | keep |
| **Change enforcement mode** | ✘ **none** | typed confirmation + affected office count |
| **Run the renewal cycle** | ✘ none | preview: "N فاتورة بإجمالي X" → confirm |
| **Issue an invoice** | ✘ none | preview period + amount → confirm |
| **Change a staff role** | ✘ none | confirm, naming what the new role can reach |
| **Broadcast a notification** | ✘ none | confirm, naming the audience size — unrecallable |
| **Mark all alerts read** | ✘ none | confirm with the count |
| **Change referral payout values** | ✘ none | confirm, old → new |
| **Withdraw an office from the marketplace (card)** | ✘ none (the panel confirms) | confirm from both |
| **Save plan feature values** | ✘ none | at minimum, state "يسري فورًا على N مكتب" in the save bar |

**Reason-with-suggestions** (`promptForReason(minLength, suggestions: [...])`) is the console's standard for consequential platform actions. Extend it; do not invent a second pattern.

## 7.6 Destructive-action vocabulary

- **There is no delete anywhere in these sections, by design.** Staff are *disabled*, plans are *archived*, overrides *expire*, invoices are *voided*, offices are *suspended*. The design must not introduce a delete affordance, and should say why where it matters ("الحساب يبقى للسجل").
- **Reversibility must be legible.** Disable ⇄ enable, suspend ⇄ restore, archive ⇄ activate are reversible; record-payment and broadcast are not.
- **One-time secrets get a full screen, never a toast.** Both credential reveals already do this (staff creation, office onboarding). Preserve the shape: warning band, monospace selectable values, per-field copy, explicit «حفظت البيانات — إغلاق».

## 7.7 Status and financial formatting

- **One status-chip system.** `DashboardStatusChip` + `AppStatusTone` (`success`/`warning`/`error`/`info`/`neutral`/`special`) — **never** chart-palette blends. `LicenseStatusChip` and `InvoiceStatusChip` are specialisations and should stay the only two.
- **One label table per status vocabulary.** Licence status and invoice status each have two independent Dart copies today (office side, platform side). Unify.
- **One money formatter.** Currently `licensingMoney()`, `formatMoney()` and inline `'ج.م'`. Money must render identically in الباقة والفوترة, الفوترة والسجل, التراخيص, مكاتب المنصة and برنامج الإحالة.
- **One date formatter** (`licensingDate`) and one relative-time formatter — الإشعارات and المستخدمون each have their own.
- **Distinguish lifetime from windowed figures** wherever both appear on one surface (the office card in مكاتب المنصة mixes them silently; the details panel labels its window correctly).
- **Never show 0% for "nothing was offered."** `occupancyRate` returns null for a reason; the design must have a `—` treatment.

## 7.8 Permission handling

- **Hide vs lock vs refuse are three different things:**
  - **Role-forbidden** → the nav item is not drawn at all.
  - **Purchasable but unlicensed** (`isPublic && enforced`) → drawn **locked**, tapping raises the upgrade card. *"Hiding a purchasable feature makes it unsellable, showing an unpurchasable one is noise."*
  - **Refused at write time** → the upgrade card with the real verdict, over whatever the screen already said.
- **Read-only is a mode, not an absence.** ملف المكتب's `_ReadOnlyNotice` is the template: state who *can* do it.
- **Never render a control that is guaranteed to fail.** المستخدمون already inerts the self-row's role picker and disable action for exactly this reason. الإشعارات violates it (broadcast for a non-platform-admin).
- **A quota should be visible before it refuses.** `DashboardCapNotice` exists; use it wherever a `limit` feature gates a create button.

## 7.9 Navigation and cross-linking

- **Every entity reference should be a link.** An office name in an invoice row, a plan name on a licence card, a feature key in an audit row, an office in a health signal — all are dead text today except in مكاتب المنصة.
- **Cross-module hand-off pattern:** route change **plus** selection (`_openOfficeFeatures`). Reuse it; do not invent route arguments for a shell that has none.
- **`action_url` must be a registered route.** Three emitted values are not. Any new alert type must use a `DashboardRoutes` constant.
- **Collapse the `/permissions` + `/users` duplication.**

## 7.10 Workspace and draft conventions

The licensing console established these and they should govern every editing surface in both sections:

- **Browse in a grid or a split pane; edit in a full-width workspace.** *"You browse a reference in a split pane because you skim many rows and read one; you edit in a workspace because editing needs the room."*
- **A draft buffer is owned by the surface that owns navigation away from it**, so leaving can refuse.
- **The change count must count decisions, not gestures.** Flip-and-flip-back is not a change.
- **Category blocks in an edit sweep are flat, not collapsible** — folding turns "set the limits" into fifteen clicks.
- **The save bar floats above tabs**, so a draft survives a look at something else.
- **A page-level tab strip never sits above a workspace that has its own tabs.**
- **Partial batch failure names where it stopped, in the operator's words.**

## 7.11 Copy conventions

- **Arabic, and specific.** Server machine codes are translated once in the datasource; the UI never shows `quota_exceeded` or a `PostgrestException`. *(الإشعارات violates this.)*
- **Say the consequence, not the mechanism.** "الحساب في وضع القراءة فقط: لا يمكن إنشاء رحلات… التذاكر المُباعة والرحلات الجارية تكمل كالمعتاد" — not "status = suspended".
- **State limitations out loud.** "التحصيل يدوي في هذا الإصدار", "تغيير الباقة لا يتم ذاتيًا في هذا الإصدار", "الحد يمنع الإضافة الجديدة فقط" are all doing real work.
- **Name the read cap** rather than implying completeness (the audit trail does this; the alert feed does not).
- **Never promise what the code does not deliver** — the `declared` vs `enforced` distinction exists precisely for this and must be preserved in every feature surface.
---

# 8. Screen Inventory

Every meaningful surface discovered, including dialogs and full-screen states. "Screen" here means *a distinct thing a user navigates to or is placed in*, not a widget.

| Section | Feature | Screen | Purpose | Main User | Primary Action | Important Data | Status |
|---|---|---|---|---|---|---|---|
| النظام | الإشعارات | **مركز الإشعارات — الوارد** | Read and clear inbound operational alerts | Owner + Support agent | تعليم كمقروء / فتح التنبيه | type · title · body · time · read state · action_url · (unused: priority, data) | Implemented; bespoke states; type filter built-but-unwired |
| النظام | الإشعارات | **مركز الإشعارات — إرسال إشعار** | Push a notification to one user or broadcast | Platform admin (broadcast) / office (single) | إرسال إشعار | target app · broadcast flag · recipient uuid · category · title · body | `[PARTIALLY IMPLEMENTED]` — broadcast defaults on and is platform-only; recipient is a raw UUID |
| النظام | ملف المكتب | **ملف المكتب** | Edit the marketplace shopfront; read platform-owned facts; hold the join code | Owner | حفظ بيانات المكتب | name · logo · description · phone · email · service areas · slug · status · listing · rating · join code | Implemented; hand-rolled form; no dirty guard |
| النظام | ملف المكتب | *(dialog)* File picker → logo upload | Put a logo in the platform's own bucket | Owner | رفع صورة الشعار | bytes · mime · 2 MB cap | Implemented |
| النظام | الباقة والفوترة | **الباقة والفوترة** | See the plan, what it includes, usage, and invoices | Owner | *(read-only — «تواصل مع إدارة المنصة»)* | plan · status · cycle · price · renewal · trial · limits+usage · feature chips · invoices | Implemented, read-only; no invoice detail or pager |
| النظام | المستخدمون والصلاحيات | **دليل المستخدمين** | The office's staff roster | Owner | إضافة مستخدم | name · username · role · status · created | Implemented as cards, not a table |
| النظام | المستخدمون والصلاحيات | *(dialog)* إضافة مستخدم | Mint a colleague's login | Owner | إنشاء الحساب | full name · username · role · generate-or-set password | Implemented; stays open on failure ✔ |
| النظام | المستخدمون والصلاحيات | *(dialog)* تعيين كلمة مرور جديدة | Reissue a password | Owner | تغيير | generate switch · password | Implemented |
| النظام | المستخدمون والصلاحيات | **بيانات الدخول** *(full-screen)* | One-time credential reveal | Owner | حفظت البيانات — إغلاق | username · temporary password | Implemented ✔ (the model) |
| النظام | الإعدادات | **الإعدادات** | Theme, a disclaimer, and a duplicate sign-out | Owner | — | theme mode | `[PARTIALLY IMPLEMENTED]` — a stub |
| المنصة | مكاتب المنصة | **دليل المكاتب** | Every tenant + platform-wide analytics + the attention queue | Platform admin | مكتب جديد | status · listing · activity · owner · counts · windowed metrics · attention flags | Implemented; in-memory filtering by design |
| المنصة | مكاتب المنصة | **تفاصيل المكتب** *(detail pane)* | One office in full | Platform admin | الميزات والحدود المتاحة لهذا المكتب | identity · completeness · counts · performance · marketplace preview · operators | Implemented |
| المنصة | مكاتب المنصة | *(dialog)* مكتب جديد | Onboard an office + its first admin | Platform admin | إنشاء | office identity + admin username/name/password | Implemented; hand-rolled form |
| المنصة | مكاتب المنصة | **بيانات المكتب الجديد** *(full-screen)* | One-time reveal: join code + password | Platform admin | تم | office · slug · join code · username · temp password | Implemented ✔ |
| المنصة | الباقات والميزات | **معرض الباقات** | What the platform sells | Platform admin | باقة جديدة | name · price (monthly/yearly) · trial · office count · status | Implemented |
| المنصة | الباقات والميزات | **مساحة عمل الباقة** | Edit a plan's feature values, see its offices and revisions | Platform admin | حفظ (with optional note) | complete feature value map · offices · revisions · preview | Implemented; dirty guard ✔ |
| المنصة | الباقات والميزات | *(dialog)* محرر الباقة | Plan identity, pricing, trial, visibility, status | Platform admin | حفظ | key · names · tagline · prices · trial days · is_public · status | Implemented; missing currency / sort / notes / **downgrade target** |
| المنصة | الباقات والميزات | *(dialog)* نسخ الباقة | Clone as a draft | Platform admin | نسخ | new key · new name | Implemented |
| المنصة | الباقات والميزات | **كتالوج الميزات** *(master/detail)* | Every sellable capability, its gates, dependencies and reach | Platform admin | *(status change)* | key · type · default · status · enforced · gates · requires · impact | Implemented; feature **creation** not implemented |
| المنصة | التراخيص | **دليل التراخيص** | Every office's commercial state + health signals + the kill switch | Platform admin | *(open an office)* | plan · status · cycle · price · renewal · overrides · over-limit · hold | Implemented; **kill switch unguarded** |
| المنصة | التراخيص | **مساحة عمل المكتب — الميزات والحدود** | Set what one office may use | Platform admin | تطبيق (one reason) | 47 features · resolved value · source · override · usage | Implemented ✔ (the best editor in either section) |
| المنصة | التراخيص | **… — الاستخدام** | This office's meters | Platform admin | — | used / limit / unit / meter kind / over-limit | Implemented |
| المنصة | التراخيص | **… — الاستثناءات** | The record of exceptions granted | Platform admin | — | value · plan value · direction · reason · expiry · expired | Implemented |
| المنصة | التراخيص | **… — الفوترة والنشاط** | This office's invoices + audit slice | Platform admin | — | invoices · activity | Implemented |
| المنصة | التراخيص | *(dialog)* تعيين باقة | Assign / change the plan | Platform admin | تعيين | plan · cycle | `[PARTIALLY IMPLEMENTED]` — 2 of 9 server fields |
| المنصة | التراخيص | *(dialog)* سبب — إيقاف / استئناف / تمديد | Capture the mandatory reason | Platform admin | إيقاف / استئناف / تمديد | reason ≥ 8 + suggestions | Implemented ✔ |
| المنصة | الفوترة والسجل | **الفواتير** | The platform's billing ledger | Platform admin | تشغيل دورة التجديد | MRR · paid · issued · overdue · renewals · invoice table | Implemented; no filters, no detail |
| المنصة | الفوترة والسجل | *(dialog)* تسجيل سداد | Record a manual payment | Platform admin | تسجيل | method (free text) | `[PARTIALLY IMPLEMENTED]` — no reference, no date |
| المنصة | الفوترة والسجل | *(dialog)* إبطال فاتورة | Void with a reason | Platform admin | إبطال | reason ≥ 8 | Implemented ✔ |
| المنصة | الفوترة والسجل | **سجل التغييرات** | The append-only decision trail | Platform admin | *(filter)* | day-grouped sentences · actor · reason · old → new | Implemented ✔ |
| المنصة | برنامج الإحالة | **نظرة عامة** | Programme performance and cost | Platform admin | — | 9 KPIs + 2 donuts | `[PARTIALLY IMPLEMENTED]` — 6 of 9 KPIs read 0 under RLS |
| المنصة | برنامج الإحالة | **إعدادات المكافآت** | Configure the payout | Platform admin | حفظ الإعدادات | enabled · type · referrer value · referred value · currency · coupon | Implemented; unconfirmed; error replaces the screen |
| المنصة | برنامج الإحالة | **المتصدّرون** | Top referrers | Platform admin | — | rank · name · phone · code · totals · rewards · last | `[PARTIALLY IMPLEMENTED]` — RLS blanks 5 of 9 columns |
| المنصة | برنامج الإحالة | **سجل الإحالات** | Every referral | Platform admin | — | code · referrer · referred · status · reward · date | `[BACKEND GAP]` — empty under RLS |
| المنصة | برنامج الإحالة | *(dialog)* تفاصيل الإحالة | One referral | Platform admin | — | the record | Implemented |
| المنصة | برنامج الإحالة | **حركات المكافآت** | The reward ledger | Platform admin | — | user · role · type · value · status · referral · date | `[BACKEND GAP]` — empty under RLS |

**Totals: 10 features · 36 distinct screens/surfaces** (18 primary screens, 8 dialogs, 2 one-time full-screen reveals, 8 workspace tabs).

---

# 9. UI Priority Matrix

Priority reflects **how often it is used × how much damage a bad design does**, not how much work it needs.

## P0 — Critical, must be excellent

| Screen | Why |
|---|---|
| **التراخيص — دليل التراخيص + مساحة عمل المكتب** | The commercial heart of the SaaS. It is where money, access and trust are decided, it holds the **unguarded platform kill switch**, and it is the only screen that can answer "why does this office have this?" A design error here costs revenue or wrongly restricts a paying tenant. |
| **مكاتب المنصة — دليل + تفاصيل** | The platform's front door. It is the only view of tenants nobody else can see, it carries the attention queue that drives daily platform work, and its actions (publish / withdraw / suspend) directly change what passengers can buy. |
| **الباقة والفوترة (office)** | The tenant's only view of what they pay for and what they may use. Every upgrade conversation starts here, and the office's understanding of a suspension is formed here. Currently the weakest financial surface in the product. |
| **المستخدمون والصلاحيات** | Access control. An unconfirmed role promotion, or a lockout, is unrecoverable from inside the product. Also the only surface that reveals a secret. |

## P1 — Important

| Screen | Why |
|---|---|
| **الباقات والميزات — معرض + مساحة عمل الباقة** | Changes propagate **instantly to every subscribed office**. Used less often than التراخيص but with a wider blast radius per action. |
| **الباقات والميزات — كتالوج الميزات** | The reference every other licensing surface reads, and the home of `enforced` vs `declared` — the platform's honesty guarantee. |
| **الفوترة والسجل — الفواتير** | Where money is recorded. Manual collection makes accuracy entirely a UI responsibility; the missing payment reference is a real accounting problem. |
| **ملف المكتب** | The tenant's shopfront — it is literally what passengers see. Also the home of the captain join code, a credential with no rotation path. |
| **الإشعارات — الوارد** | The console's "what happened" surface, driving the bell for every operator including support agents. 11 of 17 alert types are currently indistinguishable. |

## P2 — Supporting

| Screen | Why |
|---|---|
| **الفوترة والسجل — سجل التغييرات** | Consulted when a question arises, not worked daily — its own header says so. Already well designed; needs facets and cross-links, not a rebuild. |
| **الإشعارات — إرسال إشعار** | Low frequency, high blast radius. Needs a correctness fix (permissions, recipient picker, confirmation) more than a visual one. |
| **برنامج الإحالة — نظرة عامة + الإعدادات** | Genuinely important commercially, but **blocked on a backend fix**. Designing rich analytics over structurally empty tables would be wasted work; the settings tab is worth doing now. |
| **التراخيص — الاستخدام / الاستثناءات / الفوترة والنشاط tabs** | Supporting evidence behind the feature board, correctly placed behind tabs. |

## P3 — Rare / admin-only

| Screen | Why |
|---|---|
| **الإعدادات** | One working control. Either retire it or rebuild it — do not invest in polishing a stub. |
| **برنامج الإحالة — المتصدّرون / سجل الإحالات / حركات المكافآت** | Structurally empty for the intended user until RLS is addressed. |
| **مكتب جديد (onboarding dialog)** | Used a handful of times per month by one or two people. Correctness over polish. |
| **Credential reveal screens (×2)** | Rare by definition, already correct. **Do not redesign them** beyond aligning tokens. |
| **نسخ الباقة / محرر الباقة dialogs** | Infrequent platform maintenance. |
---

# 10. Implementation Gaps & Risks

**Documented, not fixed.** Every item is traceable to a file, an RPC or a migration.

## 10.1 Missing functionality

| # | Gap | Evidence | Impact |
|---|---|---|---|
| M1 | **The licensing lifecycle engine never runs.** `platform_run_licensing_lifecycle()` has no `pg_cron` schedule (migration `20260729090000`: *"No pg_cron on this project"*) and `PlatformLicensingCubit.runLifecycle()` is called from nowhere | `20260807130000_licensing_lifecycle.sql`; grep of `presentation/` | Trial expiry, dunning (`past_due` → `grace` → `suspended`), invoice overdue marking and automatic downgrade **never happen**. The six health signals describe states the system cannot reach on its own |
| M2 | **A plan's downgrade target cannot be set.** `platform_save_plan` accepts `downgrade_to_plan_id`; `plan_editor_dialog._submit()` never sends it | `plan_editor_dialog.dart:291-309` | The automatic-downgrade path is unreachable even if M1 were fixed |
| M3 | **Features cannot be created or edited.** `platform_upsert_feature` exists through repository and datasource; no use case, no cubit method, no UI | grep `upsertFeature` | The 47-feature catalog is migration-only |
| M4 | **`platform_start_trial` is dead.** RPC + repository + datasource exist; no use case, no cubit method | grep `startTrial` | A trial can begin only via `platform_assign_plan{trial_days}`, which the assign dialog never sends — so **no trial can be started from the console at all** |
| M5 | **Plan comparison is dead.** `platform_compare_plans` RPC + `ComparePlansUseCase` exist; the cubit does not take the use case | `platform_licensing_cubit.dart` constructor | "What does Professional add over Starter?" is unanswerable |
| M6 | **Licensing settings are unreachable.** `updateSettings()` handles `graceDays`, `warnDaysBefore`, `restrictedPlanKey`, `defaultSignupPlanKey`; only the enforcement bar calls it, with one key | `platform_licenses_screen.dart:409` | Every threshold the health strip computes is unconfigurable |
| M7 | **The join code cannot be rotated.** `office_rotate_join_code()` is implemented, guarded, granted — and called from nowhere in `lib/` | grep `office_rotate_join_code` | A leaked join code cannot be invalidated |
| M8 | **No invoice detail, no `lineItems` rendering**, on either side | `invoices_section.dart`, `office_billing_screen.dart` | Add-ons, overage, proration and coupons all land in `line_items` and are invisible |
| M9 | **Invoice issuance has no form.** `platform_issue_invoice` accepts period start/end, `amount`, `discount`, `tax`, `line_items`, `notes`; the cubit sends none | `platform_licensing_cubit.issueInvoice` | Every console-created invoice is single-line, list-price, default-period |
| M10 | **Payment reference and payment date are never captured.** `platform_record_payment(id, method, reference, paid_at)`; the UI passes `null` for reference and omits the date | `invoices_section.dart:_recordPayment` | Manual collections cannot be reconciled |
| M11 | **No refund path.** `refunded` is a displayable invoice status on both sides; `platform_void_invoice` explicitly refuses paid invoices | `office_license.dart`, `20260807120000` | The status is reachable only by direct SQL |
| M12 | **No available-plans surface for the office.** «تواصل مع إدارة المنصة» is the CTA and there is nothing to contact them about | `office_billing_screen.dart` | Upgrades have no in-product funnel |
| M13 | **No referral fraud controls, clawback, or manual intervention.** No caps, no rate limits, no invalidation, no reversal when a first booking is cancelled | `20260620090000_referral_system.sql` | A cancelled first booking keeps its payout |
| M14 | **Alert type filter built and unwired** | `OperationalAlertsCubit.filterByType`, `OperationalAlertsLoaded.filtered` | A 100-row unfiltered feed |
| M15 | **No invoice filters** despite `platform_billing_overview(p_filters{office_id,status})` and a plumbed `loadBilling({officeId,status})` | `invoices_section.dart` | The platform ledger cannot be narrowed |
| M16 | **`ThemeMode.system` unreachable** — supported by repository and cubit, absent from the two-segment control | `settings_screen.dart:41-52` | |
| M17 | **No office-staff audit trail**, in the module whose subject is authority — while every platform action is audited | — | Nobody can answer "who promoted this person" |

## 10.2 Partial implementation

| # | Item | Detail |
|---|---|---|
| P1 | **Notification composer** | Broadcast defaults ON and requires `is_platform_admin()`; single-send requires the `push_notifications` entitlement (`false` on `starter`) and shows no locked state; recipient is a raw UUID with no picker; `actionUrl` and `data` on the entity are never exposed |
| P2 | **Assign-plan dialog** | Collects `planId` + `cycle`; the RPC accepts `reason`, `trial_days`, `price_override`, `currency`, `auto_renew`, `contract_ref`, `notes` |
| P3 | **Trial extension** | Hard-coded to 14 days (`extendTrial(officeId, 14, reason)`) |
| P4 | **Office status actions** | `SetOfficeStatusUseCase` accepts `active`/`paused`/`suspended`/`archived`; `PlatformOfficeFilters` offers all four as filters; only `active`/`suspended` are reachable as actions |
| P5 | **الإعدادات** | A theme toggle, a paragraph, and a duplicate sign-out |
| P6 | **Office invoices** | `GetOfficeInvoicesUseCase(limit, offset)` and an RPC clamping to 200; the cubit calls the 50 default with no pager |
| P7 | **`joinCodeRotatedAt`** | On the entity, always null — the column is behind the same privilege revoke and `office_join_code()` returns only the code |
| P8 | **`LicenseBanner`** | Carries an `onOpenBilling` affordance and is rendered only on the billing screen itself, without it |
| P9 | **`DashboardThemeState.isLoading` / `errorMessage`** | Set and never read |
| P10 | **`ResolvedFeature.source` / `blockedBy`** | Rendered richly on the platform side; never shown on the office's own billing screen |

## 10.3 UI inconsistencies

| # | Inconsistency | Evidence |
|---|---|---|
| U1 | **0 of 10 modules use `DashboardFilterBar` / `DashboardResultsHeader` / `DashboardPagerBar`**, while 6 other modules do | measured, §3.3 |
| U2 | **0 of 10 use the shared form kit**, while 3 other modules do; **6 hand-rolled forms** | measured, §3.3 |
| U3 | **الإشعارات uses bespoke loading, empty and error views** instead of the three shared ones | `operational_alerts_view.dart` |
| U4 | **مكاتب المنصة uses a bare `CircularProgressIndicator`** for the analytics panel | `platform_overview_panel.dart:52` |
| U5 | **Withdraw/publish confirm in the details panel and not on the office card** | `platform_office_card.dart:232` vs `platform_office_details_panel.dart:726` |
| U6 | **Two profile-completeness definitions** — office counts 4 fields, platform counts 5 | `office_profile.dart` vs `platform_office.dart` |
| U7 | **Three money formatters** — `licensingMoney`, `formatMoney`, inline `'ج.م'` | across modules |
| U8 | **Two independent copies each** of the licence-status and invoice-status label tables | office vs platform entities |
| U9 | **Two relative-time formatters** (`AlertTile._relative`, `users_screen._formatRelativeDate`) | |
| U10 | **Phone validated in the platform onboarding form (7–20 chars) and not at all in the office's own form** — same column | |
| U11 | **Duplicate sign-out** with two independent confirmation dialogs | shell + settings |
| U12 | **Two routes for one screen** (`/permissions`, `/users`) | `dashboard_shell.dart:814,902` |
| U13 | **Four distinct bespoke filter toolbars** inside the licensing console alone (plans, features, licences, feature board) | |
| U14 | **Cards where the console uses tables** — المستخدمون, مكاتب المنصة, التراخيص directories | |

## 10.4 Business-rule ambiguity

| # | Question the code cannot answer |
|---|---|
| B1 | What do `paused` and `archived` office statuses *mean*, and who sets them? |
| B2 | What are the review criteria for publishing an office beyond the mechanical `office_profile_incomplete` check? Who publishes, and is the decision recorded? |
| B3 | Referral `rewardType` has four names and two behaviours (`points`≡`loyalty`, `wallet`≡`coupon`), and `couponCode` is stored and never used |
| B4 | `pending_registration` is a valid referral status that no code path writes |
| B5 | `referral_reward_transactions.status` has exactly one possible value, and a UI column and filter for it |
| B6 | Tax and discount exist as invoice columns with no rate configuration, no UI and no stated rule |
| B7 | Multi-currency is modelled per licence and per invoice, never varies, and has no FX or reporting-currency model |
| B8 | No partial payments, no payment history per invoice, no credit notes — a payment is one mutation of the invoice row |
| B9 | `LicensingSettings.restrictedPlanKey` / `defaultSignupPlanKey` have no UI and no visible consumer in the dashboard |
| B10 | `LicensingPlan.isPublic` («معروضة للمكاتب») has no office-facing plan gallery to be public *to* |
| B11 | `contract_ref` is carried on the licence and displayed nowhere |
| B12 | No retention or archival rule for `operational_alerts` |
| B13 | `draft` invoices are `isPayable` in Dart and filtered out of the office's view by the RPC — what a draft is *for* is unstated |
| B14 | A referral config change is not retroactive, and nothing says so |
| B15 | The referral reward credits `loyalty_accounts.wallet_balance` / `points_balance`, not the newer wallet subsystem — whether the two money stores reconcile is not visible |
| B16 | `cancelled` is a settable licence status with no offboarding, retention or final-invoice process |
| B17 | Feature `status = 'hidden'` — the office feature board excludes hidden features; what hidden means to a *plan* is unstated |

## 10.5 Backend limitations

| # | Limitation |
|---|---|
| L1 | **`referrals`, `referral_codes`, `referral_reward_transactions` have no platform-admin read policy.** The dashboard reads them directly, so a platform admin gets **empty sets, not errors** — three tabs and six KPIs render as "no data" when the truth is "not permitted" |
| L2 | **No `pg_cron`** on the project (stated in `20260729090000`), so every scheduled job is manual |
| L3 | **No payment gateway.** Collection is manual and the screen says so |
| L4 | **`clients` RLS is self-scoped**, so the referral leaderboard's phone lookups return nothing for a platform admin |
| L5 | **Storage objects are orphaned** when a logo is replaced or removed — no cleanup path |
| L6 | `platform_bulk_set_overrides` exists and is deliberately unused (the per-row audit is the point) — noted so nobody "optimises" the loop away |
| L7 | `StorageException` drops Postgres `DETAIL`, so a storage-quota refusal arrives with its code but without its numbers |
| L8 | The conversion trigger fires on `operation_bookings.status ∈ ('confirmed','approved')` — statuses were remapped in 2026-07; if `approved` is no longer produced, **no referral would ever convert** `[needs verification against live data]` |

## 10.6 Permission & security observations

| # | Observation |
|---|---|
| S1 | **`get_dashboard_users()` and `office_invoices()` are granted to any office user server-side**; the owner-only restriction on المستخدمون and الباقة والفوترة is client-side only. Writes are correctly gated |
| S2 | **The composer's broadcast is platform-wide, not office-scoped**, and appears inside what reads as an office console |
| S3 | **The enforcement-mode kill switch has no confirmation** and no reason capture beyond a canned string |
| S4 | **Role promotion is unconfirmed** — a promoted owner can then lock out the promoter |
| S5 | `EntitlementContext.unknown` **fails open**. Deliberate and documented (the server is the boundary); worth restating so nobody "hardens" it into a lockout |
| S6 | `OfficeContext.isPlatformAdmin` is a **hint only**; every platform RPC re-checks server-side. The design must not treat the flag as authority |
| S7 | Column-level privileges on `offices` — not RLS — are what keep `join_code`, `status` and `listing_status` out of an office's reach. Naming an ungranted column fails the **whole statement** |
| S8 | The audit trail is **append-only for everyone, including the table owner** — removing evidence requires a schema change, which is itself visible |

## 10.7 Data-consistency risks

| # | Risk |
|---|---|
| D1 | Two profile-completeness definitions for one office (U6) |
| D2 | Two copies each of the licence- and invoice-status label tables (U8) — silent drift on the next status added |
| D3 | Three money formatters (U7) — the same amount can render differently on two screens |
| D4 | `platform_list_offices` returns every office with no pagination; filtering is in memory. Acknowledged in code as a deliberate temporary choice |
| D5 | Referral history and transactions are capped at 1000 rows client-side, with in-memory search |
| D6 | The audit search box is client-side over a 100-row window while its facets are server-side — searching narrows what is loaded, not what exists |
| D7 | `revenueTotal` is summed from approved booking payments because `operation_trips.revenue` is unmaintained and reads 0 platform-wide — any new revenue surface must use the same source |

## 10.8 UX risks

| # | Risk |
|---|---|
| X1 | **The platform kill switch is one tap** — the highest-blast-radius control with the weakest guard |
| X2 | **«تشغيل دورة التجديد» bills every eligible office** with no preview and no confirmation |
| X3 | **Broadcast defaults ON** for a user who cannot perform it, on an unrecallable action |
| X4 | **Raw exception strings reach operators** on notification send failure |
| X5 | **RLS-emptied tables read as "no data"** — an operator will conclude the referral programme has no participants |
| X6 | **ملف المكتب has no unsaved-changes guard**, while every peer editor does |
| X7 | **Mark-all-read is irreversible and unconfirmed** (there is no "mark unread") |
| X8 | **11 of 17 alert types render identically as «عام»**, including every licence alert |
| X9 | **Three notification deep links are dead routes** |
| X10 | **`refreshContext()` / list refetch can wipe in-progress typing** in ملف المكتب (`ValueKey(updatedAt)`) |
| X11 | **A support agent cannot reach الإعدادات**, and therefore cannot change the theme |
| X12 | **A referral save failure destroys the form** — the only module breaking the console's own law |

## 10.9 Technical risks

| # | Risk |
|---|---|
| T1 | `PlatformLicensingCubit.load()` makes **nine round trips** — deliberately unoptimised (*"the alternative is a lazy per-tab load that makes the health counts wrong until the operator visits every screen"*) |
| T2 | `applyFeatureEdits` issues **one RPC per feature edit** sequentially, stopping at the first refusal — deliberate, for per-row audit fidelity |
| T3 | The shell holds one `PlatformLicensingCubit` for the whole session; three routes share it. Any redesign that splits those routes must keep the shared instance |
| T4 | `_syncDraft` / `_syncOffice` **assign during `build` without `setState`** — idempotent per selection, but fragile to reordering |
| T5 | The alert badge subscription is open for the entire session; its stream errors are swallowed (`onError: (_) {}`), so a dropped Realtime connection silently freezes the badge |
| T6 | `EntitlementService` opens one Realtime channel per office watching **four** tables; two of them (`platform_plan_features`, `platform_features`) are unfiltered and fire for **every** office's plan edit |
---

# 11. CLAUDE DESIGN HANDOFF

Read this section alone and you can design all ten features without opening the Flutter code. Everything here is derived from §4–§10.

## 11.0 Ground rules for the whole handoff

- **Language:** Arabic UI, RTL. Preserve every Arabic label quoted in this document — they are the product's existing vocabulary and several are load-bearing legal/commercial statements.
- **Two audiences, one shell:** النظام is the tenant's; المنصة is EWT's. They share chrome and must not share a voice — the tenant is being *informed*, the platform operator is *deciding*.
- **Three refusal axes** (role / entitlement / quota) plus **licence hold** and **dependency block**. Five distinct refusals; never one "not allowed".
- **Reuse the console's existing system**: `DashboardModuleHeader`, `DashboardFilterBar`, `DashboardResultsHeader`, `OpsDataTable`, `DashboardPagerBar`, `DashboardQueueTabs`, `DashboardPanel`, `DashboardCollapsibleSection`, `DashboardKpiCard/Grid`, `DashboardStatusChip` (+ `AppStatusTone`), `DashboardEmptyState`, `DashboardLoading`, `DashboardErrorState`, `MasterDetailLayout`, `DashboardCapNotice`, the charts, and the **form kit** in `core/widgets/forms/`.
- **Do not design:** a delete action anywhere; a self-service checkout; a third dashboard role; an office-side plan change.
- **Preserve untouched:** the two one-time credential reveals, the `declared` vs `enforced` honesty rule, the kill-switch confirmation copy, the audit trail's day-grouped sentence rows, the alert strip's invisible-when-empty signals.

---

## Feature 1 — الإشعارات

**User goal.** "Tell me what needs my attention, let me clear it, and let me reach my customers."
**Primary user.** Office owner **and support agent** (the only النظام module a support agent can open). Broadcast is platform-admin only.
**Primary screen.** مركز الإشعارات — a live inbox, with the composer promoted out of a peer tab into a guarded primary action.

**Key information.** Alert **type family** (17 emitted types, not 6) · **priority** (`low`/`normal`/`high`/`urgent`, currently fetched and discarded) · read state · title · body · relative time · the `data` payload as evidence (`trip_id`, `invoice_id`, `ticket_id`) · unread count.
**Primary actions.** فتح التنبيه (marks read + routes) · تعليم كمقروء · **تعليم الكل كمقروء (confirmed, with a count)**.
**Secondary actions.** Filter by family / read state / priority · search · إرسال إشعار (a guarded composer).
**Important states.** Loading (shared skeleton) · empty ("nothing needs you" is good news) · error + retry · **realtime-stale** (the badge freezes silently today) · sending · **licence-locked composer** (`push_notifications` off on `starter`) · **role-locked broadcast**.
**Important filters.** Type family · read/unread · priority. *(The type filter already exists in state — wire it.)*
**Important details.** The `data` payload; the destination the `action_url` points at; whether the recipient has opted out of the category.
**Important relationships.** Alerts are written **only** by DB triggers, scoped by `office_id`. `action_url` is the console's only deep-link mechanism — **three emitted values are dead routes**.

**Critical UX considerations.**
- Broadcast is **unrecallable and platform-wide**. It must never be the default, must state its audience size, and must confirm.
- The recipient control must be a **person picker**, never a UUID field.
- Give the 11 unmapped types real identities, grouped into families.
- Priority must be visible; it is the difference between "a ticket opened" and "your account is now read-only".
- Group the feed by day; the 100-row cap must be stated, not implied.
- Use the three shared state views.

**Recommended IA.** `الوارد` (header + filter bar + day-grouped feed + detail) with `إرسال إشعار` as a primary action opening a two-step composer (audience → message) ending in a reach-stating confirmation.

---

## Feature 2 — ملف المكتب

**User goal.** "Make my office look right to passengers, and give my drivers the code they need."
**Primary user.** Office owner (read-only rendering exists for others but the nav gate blocks them).
**Primary screen.** ملف المكتب — an overview of platform-owned facts, an editable shopfront, and a credential card.

**Key information.** **Two independent status axes** — operational (`نشط`/`متوقف مؤقتًا`/`موقوف`/`مؤرشف`) and marketplace (`قيد التجهيز`/`معروض في السوق`/`مسحوب من السوق`) — plus the conjunction that decides visibility · rating + count (trigger-maintained) · profile completeness · the **captain join code** · name, logo, description, phone, email, service areas · the immutable slug.
**Primary actions.** حفظ بيانات المكتب · رفع صورة الشعار · نسخ كود الانضمام.
**Secondary actions.** تحديث · إضافة/إزالة منطقة خدمة · إزالة الشعار · **تدوير كود الانضمام** *(backend ready, UI missing)*.
**Important states.** Loading · error+retry · **saving** vs **uploading** (deliberately distinct — an upload is not a save) · action success (snackbar + shell refresh) · action failure (form intact) · **read-only** (state who *can* edit) · broken logo URL (visible before saving) · join code unavailable (must not read as "no code exists").
**Important filters.** None — this is a single record.
**Important details.** `listingExplanation` (three long, genuinely useful paragraphs); what the passenger's card actually looks like; what still blocks publishing.
**Important relationships.** `offices` ← the same row `public_offices` exposes to passengers, and the same row مكاتب المنصة publishes. The join code is what routes a captain's `submit_captain_request` to this office.

**Critical UX considerations.**
- The two axes are the concept operators most often misread. Make the difference unmissable and keep the explanatory copy.
- Completeness must be a **checklist that navigates**, not a percentage.
- The office is told it is not listed but **never told what would make it listable** — the platform's criterion (description + service areas + active) is hidden from it.
- The join code is a **credential**: mask/reveal, copy, last-rotated, rotate-with-confirmation.
- Use the **form kit** with a dirty guard; the module currently has none.
- Reconcile the 4-field vs 5-field completeness split with مكاتب المنصة.

**Recommended IA.** `نظرة عامة` (status axes · rating · completeness checklist · marketplace preview) → `بيانات المكتب` (form kit: الهوية / التواصل / التغطية + save bar) → `كود الانضمام` (credential card).

---

## Feature 3 — الباقة والفوترة *(financial)*

**User goal.** "What am I paying for, what does it let me do, how much have I used, and what do I owe?"
**Primary user.** Office owner. **Read-only by design** — there is no checkout.
**Primary screen.** الباقة والفوترة.

**Key information — six concepts, never blended.**
1. **CURRENT PLAN** — name · status (8 values) · cycle · price · currency · trial end · period end · grace end · auto-renew · suspension reason.
2. **USAGE / ENTITLEMENTS** — per-limit `used / limit / remaining`, unit, **meter kind (stock vs flow)**, over-limit.
3. **INCLUDED FEATURES** — by category, each stating **why** when off (`source`: kill switch / licence hold / plan / default; plus `blockedBy`).
4. **BILLING HISTORY** — invoices: number · period · due · amount · status (5 values; drafts excluded) · line items.
5. **AVAILABLE PLANS** — *does not exist*; the design should mark the place where an upgrade conversation belongs.
6. **TRANSACTION HISTORY** — *deliberately withheld* from the office (`payment_method`, `recorded_by`, internal notes are platform-only).

**Primary actions.** None — the CTA is **contact**, not purchase. Make it an actual affordance.
**Secondary actions.** Retry · page invoices *(server supports it; no pager today)* · open an invoice detail *(not implemented)*.
**Important states.** Loading · error (two distinct messages) · empty invoices · **no limits on this plan** (currently the panel vanishes silently) · **no licence at all** (`status = 'none'` currently produces the calmest screen) · over-limit · held (read-only).
**Important filters.** Invoice status · period.
**Important details.** `lineItems` · `graceEndsAt` · `suspendedReason` · `contractRef` — all parsed, none rendered.
**Important relationships.** The resolver's document is the **same one** the platform's التراخيص reads, so the two can never disagree. Realtime keeps it live.

**Critical UX considerations.**
- **Say the rules out loud** — they are already written and they are good: *"الحد يمنع الإضافة الجديدة فقط. لا يُحذف ولا يُعطَّل أي عنصر قائم عند تغيير الباقة."* and, for suspension, *"التذاكر المُباعة والرحلات الجارية ودخول الكباتن تعمل كالمعتاد."*
- **Usage is the part that changes daily** and predicts every refusal — it deserves primary treatment, with stock-vs-flow explained.
- **Explain why a feature is off.** Three causes, three remedies.
- The **banner** currently only renders on this screen; it belongs in the shell.
- Invoices belong in a table with a pager and a detail.
- `status = 'none'` and a held licence must both be loud.

**Recommended IA.** `حالة الاشتراك` → `الاستخدام والحدود` → `ما تشمله باقتك` (+ `ما يمكن إضافته`) → `الفواتير` (table + pager + detail).

---

## Feature 4 — المستخدمون والصلاحيات

**User goal.** "Give my colleagues the right access, and take it away safely."
**Primary user.** Office owner only.
**Primary screen.** A staff directory.

**Key information.** Display name · **login name** (immutable, unique platform-wide) · role (**exactly two**: المالك / خدمة العملاء) · status (نشط / معطّل) · joined date · «(أنت)» on the signed-in row · **seat usage against `max_admin_users`**.
**Primary actions.** إضافة مستخدم.
**Secondary actions.** تغيير الدور *(must confirm)* · تعيين كلمة مرور جديدة · تعطيل/تفعيل · بحث · تصفية بالدور · تحديث.
**Important states.** Loading · empty (never had any) · no search results · error+retry · submitting (list stays put) · action success (row swapped in place from the server's own row) · action failure (list + form + per-field errors survive) · **credentials issued (full screen)** · **quota exceeded** (licensing verdict with real numbers) · permission denied · offline.
**Important filters.** Role · **status** (should be queue tabs) · search across name, login, role.
**Important details.** What each role can actually reach — good copy exists but only in the create dialog. The membership-vs-account distinction that explains why nothing can be renamed or deleted.
**Important relationships.** `office_users` is the office's boundary: one operator ↔ one office (`staff_user_already_assigned`), usernames unique **platform-wide**, and **at least one active owner always** (three lockout rules).

**Critical UX considerations.**
- **Never design a delete.** Disable is the removal, and the reason ("الحساب يبقى للسجل") should be visible.
- **Role promotion must confirm** — it grants user management itself, and the promoted person can lock the promoter out. Today disabling (reversible) confirms and promoting does not.
- **Preserve the one-time reveal exactly**: full screen, warning band, monospace selectable values, per-field copy, explicit dismissal.
- **Preserve the inert self-row controls** — never render a control guaranteed to fail.
- **Show the seat count** so `max_admin_users` stops being an ambush.
- Move to the shared table + queue tabs + filter bar + pager; move the form into the form kit.

**Recommended IA.** Header (+ seat counter, + إضافة مستخدم) → queue tabs (الكل / نشط / معطّل) → filter bar → table (⋯ menu) → pager. Dialogs: إضافة مستخدم, تعيين كلمة مرور. Full-screen: بيانات الدخول.

---

## Feature 5 — الإعدادات

**User goal.** Today: "switch the theme". Honestly: "see who I am signed in as and control my own console".
**Primary user.** Owner (a support agent cannot reach it — which is itself the problem, since the theme is a per-device preference).
**Primary screen.** الإعدادات — currently a stub.

**Key information.** Theme mode (**three** values are supported; two are offered) · signed-in identity, office and role · app version/environment.
**Primary actions.** None today.
**Secondary actions.** Switch theme · sign out *(duplicated in the top bar with its own dialog)*.
**Important states.** None modelled; `isLoading` and `errorMessage` are set and never read.
**Important filters.** None.
**Important details.** Nothing beyond the above exists.
**Important relationships.** Theme persists to device-local `SecureStorage`, not to the account. Sign-out clears the session **and** the entitlement document and its Realtime channel.

**Critical UX considerations.**
- **Decide what this is.** Either retire the destination and move the theme into the top-bar user menu, or make it real: appearance (3 modes) · interface resets (collapsed sections, remembered filters) · account & session (the only place identity is stated) · about.
- **Do not polish a stub** — it is P3 either way.
- Whatever happens, the theme must be reachable by a support agent, and the duplicate sign-out should collapse to one.

**Recommended IA.** `الحساب والجلسة` → `المظهر` → `الواجهة` → `حول التطبيق` — *if kept*.

---

## Feature 6 — مكاتب المنصة

**User goal.** "Which tenants exist, which are healthy, and which should passengers see?"
**Primary user.** Platform admin.
**Primary screen.** A tenant directory over a platform analytics overview, with an office workspace.

**Key information.** **Three independent verdicts per office**: operational status · marketplace listing · trading activity (`نشط`/`خامل`/`لم يبدأ`) · owner (null = **nobody can sign in**) · lifetime counts · windowed metrics (revenue, bookings, upcoming trips, occupancy, rating) · **profile completeness** and **publish blockers** · the marketplace preview as a passenger sees it.
**Primary actions.** مكتب جديد (onboard office + first admin) · عرض في السوق / سحب من السوق · إيقاف / تفعيل · الميزات والحدود (hand-off to التراخيص).
**Secondary actions.** Window 7/30/90 · search · filter (status · listing · activity) · sort (الأحدث / الأعلى إيراداً / الأكثر نشاطاً / الأطول خمولاً / الاسم) · clear · refresh · retry analytics.
**Important states.** Loading · **analytics loading/failed without taking the list down** (the console's best partial-failure handling — reuse it) · empty · no matches · detail loading (office already named) · detail refresh failure (inline notice over good data) · submitting · **onboarded (full-screen reveal of join code + password)**.
**Important filters.** Status · listing · **activity** (needs analytics) · search across name, slug, service areas, owner · 5 sorts.
**Important details.** The attention queue (10 flag types, 3 severities) · the marketplace absence reason · the operator roster · the publish blockers.
**Important relationships.** One office ↔ one licence (in التراخيص, **not shown here**) · one office ↔ N operators · offices are created by **two doors** (platform onboarding and self-service sign-up), both landing `active` + `draft`.

**Critical UX considerations.**
- **The attention queue is the front door**, not the KPI wall.
- **Publish and withdraw must confirm from both entry points** — the card and the panel disagree today.
- **Keep disable-with-a-reason** (`blockersToListing`) and surface the reason on the disabled control.
- **Label lifetime vs windowed** figures — the card mixes them silently.
- **Add the licence to the row** so "which offices are suspended for non-payment" stops needing two modules.
- `paused` / `archived` are filterable and unreachable — resolve one way or the other.
- The office card is doing a table's job in the narrow half of a 3:4 split.
- **Preserve** the null-analytics modelling, the stale-analytics inline notice, and the credential reveal.

**Recommended IA.** `نظرة المنصة` (window · KPIs · attention queue · trend · portfolio) → `الدليل` (filter bar + table + pager, incl. licence) → `مساحة عمل المكتب` (الهوية والسوق / التشغيل / الأداء / المسؤولون / الترخيص).

---

## Feature 7 — الباقات والميزات *(financial)*

**User goal.** "Define what we sell, and price it."
**Primary user.** Platform admin.
**Primary screen.** One destination, two halves: a **plan gallery → plan workspace**, and a **feature catalog master/detail**.

**Key information.**
*Plans* — key · Arabic/English name · tagline · status (`draft`/`active`/`archived`) · public flag · monthly & yearly price · currency · **trial days** · **downgrade target** *(unreachable today)* · office count · feature count · revision number.
*Features* — key · Arabic/English name · description · category (7) · **value type** (`boolean` تشغيل/إيقاف · `limit` حد رقمي · `enum` مستوى · `config` إعداد) · default value · status (4, incl. the **kill switch**) · **enforced vs declared** · unit · public flag · **meter kind** (stock/flow) · allowed values · **gates** (where the flag actually bites in code) · dependencies both ways · plan count · override count · **impact map** (offices per resolved value).
*Plan values* — the map, where **an absent key means "catalog default"**, a different statement from `false`.

**Primary actions.** باقة جديدة · حفظ قيم الباقة (with an optional note) · نشر / أرشفة (confirmed, naming the affected office count) · نسخ · معاينة الصلاحيات الفعلية · إيقاف ميزة على مستوى المنصة (confirmed, exemplary copy).
**Secondary actions.** Edit plan details · filter/search plans · filter/search features (category · enforcement · status) · «المعدّلة فقط» in the editor.
**Important states.** Loading · error+retry · busy (top progress bar, non-blocking) · action feedback as a snackbar **over** the screen · empty (plans / features / plan-has-no-offices) · **dirty buffer** with a live change count and a discard guard · **declared feature** («معلنة فقط») · **kill-switched feature** («موقوفة على مستوى المنصة»).
**Important filters.** Feature: search · enforced|declared · category · status. Plan: search · status.
**Important details.** Gates (`kind:ref`) · dependency graph · impact map · revision snapshots · the resolver preview.
**Important relationships.** `PLAN → FEATURES → LIMITS → OFFICE → LICENCE`. A plan edit **propagates instantly** to every subscribed office — there is no per-office copy.

**Critical UX considerations.**
- **A plan is a product page; a feature is a reference entry.** Two layouts, already correct.
- **"Sold but not delivered" is the module's integrity signal** — a `declared` feature on an `active` plan must be impossible to miss.
- **Presence vs `false` needs a literal third control**: "اتبع الافتراضي".
- **Every value change is instant and platform-wide** — say so in the save bar, before the press.
- **Make `downgrade_to_plan_id` editable** — it is the target of automatic downgrade.
- **Plan comparison is already served by the backend** and answers the module's most natural question.
- `hidden` and `deprecated` apply on one tap; only `disabled` confirms.
- Use the kill-switch confirmation as the **template for every destructive confirmation in the console**.

**Recommended IA.** `الباقات` (gallery → workspace: الميزات / المكاتب / السجل / التسعير والهوية) · `الميزات` (toolbar → grouped list → detail: ما هي / أين تُطبَّق / الأثر).

---

## Feature 8 — التراخيص *(financial)*

**User goal.** "What does this office have, why does it have it, and change it."
**Primary user.** Platform admin.
**Primary screen.** A licence directory → a full-width office workspace with four tabs.

**Key information.** Licence status (8) · **licensing hold** (`none`/`read_only`/`delisted`) · plan · cycle · price · trial end · period end · auto-renew · suspension reason · **override count** · **over-limit count** · and, per feature, **`source`** — which rung of the resolution ladder produced the value.
**Primary actions.** تعيين/تغيير الباقة · إيقاف مؤقت / استئناف (reason ≥ 8 + suggestions) · تمديد التجربة · إصدار فاتورة · **تطبيق** a batch of feature edits under one reason.
**Secondary actions.** إرجاع لقيمة الباقة (reset an override) · search · status filter · open a health signal's office list · switch enforcement mode *(needs a guard)*.
**Important states.** Loading · busy · error+retry · action error **over** the screen · **partial batch failure naming where it stopped, in the operator's words** · empty (licences / overrides / limits) · **health clean** (empty signals take no space) · **locked feature row** naming the rung holding it · **declared feature** · dirty buffer across all four tabs · office switch drops the draft.
**Important filters.** Licence status (7) · search · the six health signals as pressable counts · five board lenses (الكل / مفعّلة / متوقفة / حدود / استثناءات) + category.
**Important details.** The override record (value vs plan value, direction, reason, expiry, **expired-but-kept**) · usage meters with stock/flow · this office's invoices and audit slice.
**Important relationships.** Licence ↔ office is 1:1. Overrides are per office per feature, **grant or revoke**, always with a reason. The resolver's ladder is `kill_switch → license_hold → override → plan → default`, then a dependency gate.

**Critical UX considerations.**
- **`source` is the reason this module exists.** Every value must be able to say where it came from without a click.
- **The enforcement kill switch needs a guard proportional to its blast radius** — it is the least-protected control in the console.
- **The assign dialog collects 2 of 9 fields** — negotiated price, contract reference, auto-renew and trial length are all real licence columns rendered on the office's own screen and settable nowhere.
- **Trial extension must take a number**, not a hard-coded 14.
- **«إصدار فاتورة» creates a billable record** — preview the period and amount.
- **Surface the dormant lifecycle**: either offer «تشغيل الآن» or state that dunning is manual. The health signals currently imply an automation that does not run.
- **Keep**: the alert strip's invisible-when-empty rule, the draft-buffer-with-one-reason model, the partial-failure message, the "suspension degrades, never blacks out" copy.

**Recommended IA.** `وضع التطبيق` (guarded) → `إشارات` → `الدليل` (filter bar + table + pager) → `مساحة عمل المكتب` (الترخيص / الميزات والحدود / الاستخدام / الاستثناءات / الفوترة والنشاط).

---

## Feature 9 — الفوترة والسجل *(financial)*

**User goal.** "What did we charge, was it paid, and who decided what."
**Primary user.** Platform admin.
**Primary screen.** Two tabs: an invoice ledger and an append-only decision trail.

**Key information.**
*Invoices* — number · office · period · **amount** · status (6) · issued/due/paid dates · payment method *(stored, never shown)* · **line items** *(open-ended by design; never rendered)*.
*Aggregates* — **MRR from active licences only** · paid · issued-and-unpaid · overdue · upcoming 30-day renewals.
*Audit* — day-grouped sentences: actor (denormalised) · action (16) · entity type (9) · **mandatory reason** · **old → new values** · office.

**Primary actions.** تسجيل سداد · إبطال (reason ≥ 8) · تشغيل دورة التجديد.
**Secondary actions.** Filter audit (entity type · period — **server-side**) · search audit (client-side) · show more (+30, cap 100) · page invoices.
**Important states.** Loading · busy · error+retry · action feedback over the screen · empty invoices (naming both creation paths) · empty renewals (panel omitted) · **background section refresh failures are silent by design** · **the read cap is named, not implied**.
**Important filters.** *(needed)* office · invoice status · period. The RPC already accepts `office_id` and `status`.
**Important details.** Line items · plan snapshot · payment method/reference/date · the audit rows behind an invoice.
**Important relationships.** Invoice ↔ office ↔ licence ↔ plan snapshot. The two tabs were merged **because they answer each other** — and they do not link.

**Critical UX considerations.**
- **Say the limitation, always:** *"التحصيل يدوي في هذا الإصدار: الفاتورة سجلّ، والسداد يُسجَّل عند وصوله."* Nothing here means money moved by itself.
- **Recording a payment is an accounting act** — method + **reference** + date. The reference is the only thing that would make it reconcilable, and it is currently hard-coded null.
- **«تشغيل دورة التجديد» bills the whole platform on one tap** — it needs a preview and a confirmation.
- **Issuing an invoice needs a form** (period, amount, discount, tax, line items, notes — all server-supported).
- **Keep the void guard's copy**: *"عكس مبلغ محصَّل استرداد وليس تعديلًا."*
- **Keep the audit trail's design** — sentence rows, day grouping, old→new evidence, the honest cap. Add office/actor facets and links from a row to the entity it describes.
- **Cross-link the two tabs.**

**Recommended IA.** `الفواتير` (KPIs + [إصدار فاتورة] [تشغيل دورة التجديد ✓] → renewals → filter bar → table → pager → invoice detail drawer) · `سجل التغييرات` (facets → day-grouped trail → row → entity).

---

## Feature 10 — برنامج الإحالة *(financial)*

> **Read §5.5 §2 before designing this.** Three of the five tabs and six of the nine KPIs are **structurally empty** for the platform admin because `referrals`, `referral_codes` and `referral_reward_transactions` have no platform-admin read policy. Design the settings tab and the shape of the analytics; do not invest in rich data views over tables that return nothing until that is resolved.

**User goal.** "Is the referral programme working, what is it costing us, and who is driving it?"
**Primary user.** Platform admin (never an office — the tables carry no `office_id`).
**Primary screen.** Five tabs today; three questions really.

**Key information.**
*Config (the one write surface)* — enabled · reward type (`points`/`wallet`/`coupon`/`loyalty` — **four names, two behaviours**) · referrer value · referred (welcome) value · currency · coupon code *(stored, never used)*.
*Funnel* — `registered → first_order_completed → reward_granted` (+ a `pending_registration` status nothing ever writes).
*Cost* — referrer rewards · referred rewards · total.
*People* — top referrers with code, phone, totals, rewards, last referral.
*Ledger* — two immutable rows per conversion (referrer + referred).

**Primary actions.** حفظ الإعدادات *(must confirm — it changes platform-wide payout economics)*.
**Secondary actions.** تعطيل البرنامج (already confirms ✔) · تحديث · per-tab search and chip filters · view a referral's detail.
**Important states.** Loading · error+retry · saving · action success · **action failure currently replaces the screen — must not** · missing-relation fallback (returns empties) · **RLS-emptied (must be distinguishable from "no data")**.
**Important filters.** *(needed)* **a period selector — there is none anywhere in the module** · status · reward status · role.
**Important details.** The chain behind one referral: code → referrer → referred → first booking → the two ledger rows.
**Important relationships.** Entirely trigger-driven: a code is minted at sign-up; a referral is recorded at sign-up or via `redeem_referral_code`; both rewards are paid by a trigger on the referred user's **first** confirmed booking, crediting `loyalty_accounts`.

**Critical UX considerations.**
- **Distinguish "not permitted" from "no data"** — today an admin will conclude the programme has no participants.
- **Nine KPI cards is a wall.** Three questions: is it converting, what does it cost, who drives it.
- **Make the funnel a funnel**, not a donut of unordered statuses.
- **Cost needs a time axis** — this is a marketing spend with no trend view.
- **Changing payout values must confirm, old → new.** Only disabling confirms today.
- **Be honest about reward types** — four labels, two behaviours, one dead field.
- **Three status vocabularies** on one screen, one of which has a single possible value.
- **No fraud controls, no clawback, no manual correction exist.** Do not imply them.
- Adopt the platform's own conventions: audited config change with a reason, an alert-strip signal for anomalies, a period selector — all three exist one module away.

**Recommended IA.** `نظرة عامة` (period · 3 headline figures · funnel · cost split over time) · `الإعدادات` (form kit + confirmed save + last-changed-by) · `المتصدّرون` / `سجل الإحالات` / `حركات المكافآت` (filter bar + table + pager, with a permission-aware empty state).

---

## 11.1 The five refusal states, for the whole handoff

Design one visual family with five distinct members. Never collapse them.

| Refusal | Copy already in the product | Remedy the UI should offer |
|---|---|---|
| **Role** | «ليس لديك صلاحية تنفيذ هذه العملية. تواصل مع مالك المكتب.» | Who to ask |
| **Not licensed** | «هذه الميزة غير متاحة في باقتك الحالية.» | The upgrade card (already exists) |
| **Dependency blocked** | «هذه الميزة تتطلب تفعيل ميزة أخرى أولًا.» | Name the prerequisite (`blockedBy`) |
| **Quota exceeded** | «وصلت إلى حد الباقة لهذا العنصر.» + real `used`/`limit`/`plan` | Upgrade, or free a slot (stock meters only) |
| **Licence hold** | «حساب المكتب في وضع القراءة فقط بسبب حالة الاشتراك. ما هو قائم يكمل كالمعتاد.» | Settle the invoice; state what still works |

Plus **locked-but-purchasable** (`isPublic && enforced`): drawn in the sidebar and on the screen, tappable, raising the upgrade card. *Hiding a purchasable feature makes it unsellable; showing an unpurchasable one is noise.*

## 11.2 Design acceptance checklist

A design for these two sections is done when:

- [ ] Every list wears the same shape: header → (queue tabs) → filter bar → results header → table/cards → pager.
- [ ] Every form uses the shared form kit, with per-field server errors and a dirty guard.
- [ ] Loading, empty, error and **not-permitted** are four distinct, shared states.
- [ ] Every irreversible or outward-facing action confirms, naming its reach in real numbers.
- [ ] The five refusal states are visually distinct and each leads somewhere.
- [ ] Money, dates, relative times and every status vocabulary render identically across all ten screens.
- [ ] Lifetime and windowed figures are never mixed without labels.
- [ ] Every entity reference is a link, and every `action_url` resolves to a real destination.
- [ ] No delete affordance exists anywhere.
- [ ] The two one-time credential reveals remain full-screen with explicit dismissal.
- [ ] `declared` vs `enforced` is legible wherever a feature appears.
- [ ] Nothing implies an automation that does not run (licensing lifecycle), a payment that moved by itself (manual collection), or data that exists but is unreadable (referrals).
