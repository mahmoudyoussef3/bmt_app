# Dashboard — Feature Inventory

Every module the console can render, what it is for, and **what state it is actually in**.
Status verified by reading the code and the migrations on 2026-08-15, not by trusting a
nav item.

Status vocabulary:

| Status | Meaning |
|---|---|
| **Implemented** | Works end to end against real data |
| **Partial** | Works, but a named part of it does not |
| **UI only** | Renders; the data behind it is absent or fake |
| **Declared** | Catalogued/routed but does nothing yet |
| **Deprecated** | Superseded; kept only for compatibility |
| **Removed** | Deleted in this pass, recorded here so nobody looks for it |

---

## 1. Landing and analysis

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| الرئيسية | `/` | all | **Implemented** | Composition root over 9 sibling use cases. Tolerates per-feed failure and names what is missing. No datasource of its own. |
| نظرة تنفيذية | `/business-overview` | admin | **Implemented** | 12 feeds, 8 folding sections. Read-only by design — every tile navigates to the module that owns the decision. |
| التقارير | `/reports` | admin + support | **Partial** | 7 report types, all returning real rows since this pass. Drivers/vehicles/complaints have **no date dimension** in their views and say so. Export to PDF/Excel/CSV works and is licence-metered. |

**Removed in this pass:** `نظرة المالك على الإيرادات` (`/owner-overview`). It had no nav
item and no inbound link from any screen — unreachable since the نظرة تنفيذية rebuild.
Its figures are a strict subset of نظرة تنفيذية + المركز المالي, its datasource applied no
office filter of its own, and its own footer admitted it could not compute the metrics it
was named for.

---

## 2. التشغيل — Operations

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| العمليات المباشرة | `/live-ops` | all | **Implemented** | Active trips with honest tracking health (`live` / `stale` / `offline` / `unknown`), departure status, and the captain incident queue. Realtime trigger + steady poll. Only reader of `trip_live_locations` and `driver_trip_reports`. Resolving incidents is a separate permission. |
| الرحلات | `/trips` | admin | **Implemented** | The largest module (~10k lines). Creation wizard, list/grouped/timeline views, seat map, per-package pricing, passengers, cancellation, close-out. A trip takes a **driver**; the vehicle is derived from the assignment. |
| المسارات | `/routes` | admin | **Implemented** | Name-first route builder: a stop is a name, GPS is optional, the map is a dialog. Station ordering, dwell time, boarding rules, schedule calculation via the geo provider. |

---

## 3. المبيعات — Sales

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| الحجوزات | `/bookings` | all | **Implemented** | The daily driver. Queue, filters, receipt inspection, approve/reject/request-reupload, bulk actions, reassignment. All writes via audited `SECURITY DEFINER` RPCs — never direct column updates. |
| الاشتراكات | `/subscriptions` | admin | **Implemented** | Subscriptions plus a `plans/` sub-feature for the office's own package catalogue. Ride ledger, renewals, payment confirmation. |
| مراجعة المدفوعات | `/payment-verification` | all | **Implemented, redundant** | Not in the sidebar. Reads the same table and calls the same three RPCs as الحجوزات. See `DASHBOARD_AUDIT.md` — the recommendation is to fold it into الحجوزات as a queue preset. |

---

## 4. الأسطول — Fleet

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| إدارة الأسطول | `/fleet` | admin | **Implemented** | Tab host over four sub-features: السائقون · المركبات · التعيينات · الوثائق. |
| — السائقون | `/drivers` | admin | **Implemented** | Drill-in destination, not a sidebar row. Holds phone, national id, licence data. |
| — المركبات | `/vehicles` | admin | **Implemented** | Seat layout **is** capacity; the shared `core/widgets/vehicle_seats` renderer draws the cabin. |
| — التعيينات | `/assignments` | admin | **Implemented** | One active vehicle per driver, enforced by trigger. |
| — الوثائق | (tab) | admin | **Implemented** | Expiry tracking feeds the Home attention panel. |
| طلبات الكباتن | `/captain-requests` | admin | **Implemented** | Self-service captain applications → approve/reject. Office join code lives on ملف المكتب. |

---

## 5. المالية — Finance

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| المدفوعات (المركز المالي) | `/payments` | admin | **Implemented** | Four tabs: نظرة عامة · الحركات المالية · التحليلات · التقارير. **Read-only** — it reports, it never decides. Period bar is pinned because every figure on the page is scoped by it. Export to PDF/Excel/CSV. |
| محفظة العملاء | `/wallet` | admin + support | **Implemented** | Customer wallet directory + per-customer ledger, refund queue, adjustments. Adjusting and approving are two further permissions on top of viewing. Hash-chained ledger with a verification check. |

---

## 6. الدعم — Support

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| الشكاوى | `/tickets` | all | **Implemented** | Support tickets routed to the office (`office_id IS NULL` tickets belong to EWT and are invisible here). Status, internal notes, contact marking, agent assignment, attachments. Writes columns directly rather than via RPC — the one module that does. |
| التقييمات | `/reviews` | admin | **Implemented** | The **only** window onto individual written reviews anywhere in the platform. Driver/vehicle averages are public; the text is owner-only. |

---

## 7. النظام — System

| Module | Route | Role | Status | Notes |
|---|---|---|---|---|
| الإشعارات | `/notifications` | all | **Implemented** | Two halves: an inbound operational-alert inbox (feeds the top-bar bell) and a composer that dispatches to Client/Captain apps. Dispatch goes through `office_dispatch_notification`, which checks the entitlement, that the recipient belongs to this office, and that the licence is not read-only. |
| ملف المكتب | `/office-profile` | admin (support: read-only) | **Implemented** | The marketplace card passengers browse, the reputation, and the captain join code. |
| الباقة والفوترة | `/office-billing` | admin | **Implemented** | The office's own plan, limits with usage bars, and invoices. **Deliberately cannot change plan** — a checkout without a payment gateway would be a lie, so the CTA is contact, not purchase. |
| المستخدمون والصلاحيات | `/permissions`, `/users` | admin | **Implemented** | Staff account provisioning: SQL owns membership, an Edge Function owns `auth.users`. Three lockout rules; removal is a disable, never a delete. An operator cannot change their own role or disable themselves. |
| الإعدادات | `/settings` | admin | **Partial / redundant** | Contains a theme toggle (already in the top bar), a paragraph explaining that permissions are configured elsewhere, and sign-out (already in the sidebar footer). Nothing unique. |

---

## 8. المنصة — Platform (EWT staff only)

Gated on `platformOnly`, which is checked against the authenticated identity rather than
the switchable debug role, because these reach across offices.

| Module | Route | Status | Notes |
|---|---|---|---|
| مكاتب المنصة | `/platform-offices` | **Implemented** | Onboard an office, decide which offices the marketplace shows, per-office analytics. Hands off to التراخيص for a specific office's feature board. |
| الباقات والميزات | `/platform-catalog` | **Implemented** | Plans and the 47-entry feature catalogue in one destination — a plan is a set of feature values, so pricing one without reading the other is not a thing anyone does. |
| التراخيص | `/platform-licenses` | **Implemented** | Every office's licence, and the one screen that answers *why does this office have this* — via each resolved feature's `source`. Directory → full-width workspace with four tabs. |
| الفوترة والسجل | `/platform-billing` | **Implemented** | Invoices and the append-only audit trail, together because they answer each other. |
| برنامج الإحالة | `/referrals` | **Implemented, newly reachable** | Referral rewards, codes, leaderboard, transactions. Was fully built and completely unreachable — no nav item, no inbound link. Placed under المنصة because the referral tables carry **no `office_id`**: the programme is platform-wide, `referral_rewards` only accepts writes from `is_platform_admin()`, and showing it to an office owner would have leaked every office's numbers. |

---

## 9. Auth

| Screen | Status | Notes |
|---|---|---|
| Sign in | **Implemented** | Name + password. The name is mapped to the account's login address by `resolve_office_user_login`; the email never surfaces in the UI. |
| Sign up | **Implemented** | Self-service office registration, three fields. Creates an office that is `active` (its dashboard works at once) and `draft` (invisible to passengers until the platform publishes it) — and says so on the form, because an operator not told that reads an empty marketplace as a broken product. |

---

## 10. Cross-cutting: what is *not* here

Capabilities a transport office needs that the console does not currently provide. Each
is argued in `DASHBOARD_ROADMAP.md`:

- **A customer directory.** Customers exist only as names attached to bookings, tickets
  and wallets. There is no "show me this passenger" surface — support agents reconstruct
  a customer by searching three modules.
- **No-show and cancellation handling as first-class operations.** Seat states carry the
  facts; nothing reports on them.
- **Vehicle maintenance scheduling.** Documents track expiry; there is no service record.
- **Route performance over time.** Occupancy is computed per trip and per period, never
  trended per route across periods.
- **Any cash-movement or reconciliation surface.** Finance reports what was collected; it
  cannot tell an owner what is in the drawer.
