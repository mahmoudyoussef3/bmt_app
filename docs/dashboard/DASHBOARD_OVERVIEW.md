# EWT Dashboard — Overview

> The one document to read before touching dashboard code. It explains what the console
> is for, who sits in front of it, and the rules that hold it together. Everything here
> was verified against `lib/apps/dashboard/`, `supabase/migrations/` and the test suite
> on **2026-08-15**; where the code and older documents disagree, the code won.

---

## 1. What the Dashboard is

EWT is a **multi-office transportation marketplace**. Independent transport offices sell
seats on fixed-route trips; passengers buy them in the Client app; captains drive them
with the Captain app. The Dashboard is the **operator's console** — the only surface on
which an office actually runs its business, and the only surface on which EWT runs the
platform.

It is one Flutter web/desktop app with two audiences layered inside it:

| Audience | Who | What they get |
|---|---|---|
| **Office** | The transport office's own staff | Everything under التشغيل / المبيعات / الأسطول / المالية / الدعم / النظام, scoped to their office and nothing else |
| **Platform** | EWT's own staff | The above **plus** المنصة — office onboarding, plans, licences, billing, the referral programme |

There is no separate admin app. The same binary serves both; the difference is one
server-verified flag (`is_platform_admin()`) and one nav group.

**Entry point:** `lib/main_dashboard.dart` → `DashboardApp` → auth gate → `DashboardShell`.

---

## 2. The business the Dashboard drives

```
Office  ──(is licensed to run)──▶  Plan / entitlements
  │
  ├─▶ Routes ──▶ Stations (ordered, named, GPS optional)
  │                 │
  ├─▶ Fleet ────────┤
  │    ├─ Vehicles (seat layout = capacity)
  │    ├─ Drivers  (captains, onboarded by request)
  │    ├─ Assignments (a driver holds exactly one vehicle)
  │    └─ Documents (licences, permits, expiry)
  │                 │
  └─▶ Trips ◀───────┘   a trip takes a DRIVER; the vehicle is derived
        │                from that driver's active assignment
        │
        ├─▶ Seats / Pricing (one fare, expanded to every stop pair;
        │                    packages are flat multiples of it)
        │
        ├─▶ Bookings ──▶ Payment receipt ──▶ Approve / Reject
        │                                       │
        │                                       ├─▶ Seat confirmed
        │                                       └─▶ Money recognised
        │
        ├─▶ Boarding (station-by-station, driven by the Captain app)
        │
        └─▶ Completion ──▶ Reviews, Finance, Reports
                              │
                              ├─▶ Refunds ──▶ Customer wallet
                              └─▶ Wallet ledger (credits, cashback, payouts)
```

Two things about this chain are easy to get wrong and are worth stating up front:

1. **A trip is assigned a driver, not a vehicle.** The vehicle is resolved from the
   driver's active fleet assignment and snapshotted onto the trip. Trying to set a
   vehicle directly is refused by a trigger.
2. **`operation_trips.revenue` is dead.** Nothing writes it. Trip revenue is always the
   sum of that trip's earned bookings. Any code reading that column is reporting zero.

---

## 3. Who uses it, and what they may do

Two office roles exist. They are not configurable — `DashboardRole` is a closed enum,
and the server's `office_role()` returns the same two values.

| Role | Arabic | DB value | Job |
|---|---|---|---|
| `admin` | المالك | `dashboard_admin` | Owns the office: everything |
| `supportAgent` | خدمة العملاء | `support_agent` | Answers customers: queues and reads only |

`DashboardPermissions.permissionsFor(supportAgent)` is the authoritative list and holds
exactly seven entries: live ops, bookings, tickets, reports, payment verification,
notifications, customer wallets. Anything not on that list — fleet, drivers, vehicles,
routes, trips, subscriptions, finance, office profile, billing, staff management — is
the owner's alone.

### The three-predicate composition law

Access is never one check. It is three, ANDed, and they are deliberately never merged:

```
may = role_permits  ∧  office_entitled  ∧  quota_allows
       │                │                   │
       │                │                   └─ limits (max_drivers, max_trips_per_month …)
       │                └─ the plan's feature switches (trips, wallet, reports …)
       └─ DashboardPermissions / office_role()
```

They stay separate because a merged system cannot answer *"why can't I do this?"* — and
that is the one question a licensing UI must always be able to answer. `_DashboardNavItem`
carries `permission` and `feature` as two fields for exactly this reason.

### What the client-side gate is, and is not

Everything in the Flutter layer — `DashboardPermissions`, `EntitlementContext`,
`OfficeContext.isPlatformAdmin` — is a **hint for the shell**. Every write behind it is
re-checked server-side by RLS, a trigger, or an `assert_feature()` guard.

**One important exception, and it is a live gap.** Fleet RLS (`drivers`, `vehicles`,
`assignments`, fleet documents) is written as `for all to authenticated using (office_id
= current_office_id())` — office-scoped but **role-agnostic**. `office_role()` is used
for offices, office_users, wallet and logo storage, but not for fleet. So for fleet, the
client gate is currently the *only* thing keeping a support agent out of driver national
IDs and licence data. See `DASHBOARD_SECURITY.md` §3.

---

## 4. The shell

`DashboardShell` (`core/routes/dashboard_shell.dart`) is the whole navigation system.
There is no `Navigator` route table: the shell holds a `_route` string and a `switch`
that builds the module, wrapping it in whatever `BlocProvider` it needs.

Consequences worth knowing:

- **Switching modules disposes the previous one.** Every module reloads from scratch on
  every visit. There is no module-level cache.
- **`_items` is the single source of truth** for the nav gate *and* the top-bar title.
  A route the shell can render must appear there, or it is unreachable-by-name and
  ungated. Hidden destinations carry `inSidebar: false`.
- **`_canOpenRoute` fails closed.** An unregistered route is refused, not defaulted.
- The sidebar draws **locked** rows for modules the office could buy but has not
  (`isLocked`), because hiding a purchasable module makes it unsellable.

### Navigation, as shipped

```
الرئيسية                      operator's console — today, and what needs doing
نظرة تنفيذية                  executive read — how the business is performing
التقارير                      analytical reports + export

التشغيل      العمليات المباشرة · الرحلات · المسارات
المبيعات     الحجوزات · الاشتراكات
الأسطول      إدارة الأسطول · طلبات الكباتن
المالية      المدفوعات · محفظة العملاء
الدعم        الشكاوى · التقييمات
النظام       الإشعارات · ملف المكتب · الباقة والفوترة · المستخدمون والصلاحيات · الإعدادات
المنصة       مكاتب المنصة · الباقات والميزات · التراخيص · الفوترة والسجل · برنامج الإحالة
             (platform admins only)
```

Plus five registered-but-undrawn destinations, reached by drilling into a card:
`/drivers`, `/vehicles`, `/assignments`, `/payment-verification`, `/users`.

---

## 5. The finance model

Finance is **read-only reporting**. It never approves, verifies or refunds — those
decisions live in the modules that own the workflow (Bookings, Wallet). Its four tabs:

| Tab | Question |
|---|---|
| نظرة عامة | Where does the money stand this period? |
| الحركات المالية | Show me every individual movement |
| التحليلات | What shape is it, by method and by day? |
| التقارير | Give me the income statement, and a file of it |

The accounting rules that must not be reinvented:

- **Net revenue = total collected − executed refunds.** Pending and cancelled amounts
  are *memo lines*, shown but excluded.
- **A refund is not a second ledger row.** It is mirrored onto the booking it reverses;
  counting it separately double-subtracts.
- **Refund requests are a liability signal, not revenue movement.** They sit outside the
  ledger until executed.
- **Wallet balances are a liability, not income.** The wallet subsystem keeps its own
  ledger and its own three statements; Finance reads the position, it does not compute it.

---

## 6. The licensing model

Live and **enforcing in production since 2026-08-07**.

- A **plan** is a named bundle; a **licence** is one office's instance of a plan. The
  words are not interchangeable and the code never mixes them.
- Resolution walks a ladder, and the winning rung is reported as `source`:
  `kill_switch → license_hold → override → plan → default`. That single field is the
  difference between a two-minute support call and a twenty-minute one.
- Enforcement is **write-side**: `before insert` triggers on drivers, vehicles, routes,
  office_users, trips, wallet transactions, refund requests, packages. Plus
  `assert_feature()` for RPCs, and a genuine **read** gate inside three reports views.
- `EntitlementContext.unknown` **fails open** — deliberately, and opposite to the usual
  security default. This object is a UX hint; the server is the boundary. A network blip
  that silently hid half an operator's console would be indistinguishable from a
  downgrade they never agreed to.
- Refusals surface once, from the shell, via `licensingRefusals` — so a new module cannot
  forget to have an upgrade path.

---

## 7. Office isolation

Every office-scoped query resolves its office from `DashboardSession.officeId`, which is
loaded once at sign-in from the `current_office_context` RPC. It is never typed in,
never passed through a route, never inferred from a fetched row. Reading it while signed
out **throws** rather than returning null, because a query that quietly dropped its
filter would return every office's rows.

The database enforces the same boundary independently through RLS on ~40 tables. Neither
layer is trusted to be the only one.

**Platform admins see across offices by design.** `is_platform_admin()` appears as an OR
branch in the report views and several policies. This is correct for the platform
console — and it means an EWT staff member who *also* operates an office will see
platform-wide totals inside that office's Finance and Reports screens. See
`DASHBOARD_KNOWN_ISSUES.md`.

---

## 8. Design system

Non-negotiable, because the console is one product and not twenty screens:

- **Chrome belongs to the shell.** A module renders its content; the shell owns the
  sidebar, top bar, title, notifications bell and theme.
- **`DashboardModuleHeader`** opens every module — icon, title, subtitle, actions, and an
  optional `pinned` strip for controls that scope the whole page.
- **`OpsDataTable`** is the only table. Sticky header, proportional columns, integrated
  pagination, RTL-correct. Directional icons are named with LTR semantics and left to the
  framework to mirror.
- **`DashboardCollapsibleSection` / `DashboardPanel`** — every major block folds, and
  remembers its fold for the session via `DashboardSectionStateStore`.
- **`MasterDetailLayout`** for directory→inspector modules (wallet, fleet, licensing).
- **Action errors never replace the screen.** A refused action is a snackbar over a page
  that keeps the operator's filters and selection. Only a failed *initial load* may show
  `DashboardErrorState`.
- **Partial data is named, not faked.** A composition screen that lost one of its feeds
  renders `DashboardPartialDataNotice` and shows the rest. A zero is a claim.
- **RTL throughout**, Arabic-only copy, `EdgeInsetsDirectional` over `EdgeInsets`.

---

## 9. Honesty rules

The console reports on real money and real buses. These rules are load-bearing:

1. **Never invent a trend.** If there is no comparison period, show the figure alone.
2. **Never show a computed zero as a measurement.** If the source cannot answer, say the
   source cannot answer.
3. **Never offer a control that cannot reach the query.** A filter that changes nothing
   teaches the operator the console is broken.
4. **Never present a `declared` licensing feature as something the office is about to
   gain.** `enforcement_status` distinguishes catalogued from enforced.
5. **Name what is missing.** `unavailable` sets and scope notes exist for this.

---

## 10. Where to look next

| Question | Document |
|---|---|
| How is the code laid out? | `DASHBOARD_ARCHITECTURE.md` |
| What exists, and does it work? | `DASHBOARD_FEATURES.md` |
| Who may do what? | `DASHBOARD_USER_ROLES.md` |
| What is in the sidebar and why? | `DASHBOARD_NAVIGATION.md` |
| How does a booking become money? | `DASHBOARD_BUSINESS_FLOWS.md` |
| What are the accounting rules? | `DASHBOARD_FINANCE.md` |
| How does an operator run today? | `DASHBOARD_OPERATIONS.md` |
| What can be reported and exported? | `DASHBOARD_REPORTS.md` |
| Where does customer data live? | `DASHBOARD_CUSTOMERS.md` |
| How are buses and drivers managed? | `DASHBOARD_FLEET.md` |
| How are routes and stations built? | `DASHBOARD_ROUTES.md` |
| How does the SaaS licensing work? | `DASHBOARD_LICENSING.md` |
| What are the UI rules? | `DASHBOARD_UX_GUIDELINES.md` |
| What are the security boundaries? | `DASHBOARD_SECURITY.md` |
| What is broken right now? | `DASHBOARD_KNOWN_ISSUES.md` |
| What should be built next? | `DASHBOARD_ROADMAP.md` |
| What did the 2026-08-15 audit find? | `DASHBOARD_AUDIT.md` |
