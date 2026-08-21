# العملاء — Known Issues & Limits

What the module cannot do, and why. Everything here is a database limit or a
deliberate scope decision, not an oversight.

---

## 1. Data the office cannot see

| Missing | Cause | What it would take |
|---|---|---|
| **Loyalty points and loyalty balance** | `loyalty_accounts` RLS is `client_id = auth.uid()` — self-only | A new office-scoped SELECT policy, and a decision that a passenger's platform-wide points are an office's business. Not obviously true, so it was not assumed. |
| **Notification history** | `notifications.user_id`, no office scope | Nothing. This is the passenger's private inbox and should stay that way. |
| **Referral activity** | `referrals` has no `office_id` | The programme is platform-level. The office's view is المنصة → برنامج الإحالة. |
| **Per-ride usage timestamps** | `subscription_ride_usage` exists and is **empty** (0 rows) | The consumption path to populate it. Until then, "hasn't used their package in 12 days" cannot be stated and is not. `trips_used` gives the count but not the dates. |
| **Contact log** | No table records that an operator called a passenger | A new table. `support_tickets.customer_contacted_at` is the nearest thing and belongs to a ticket, not to the person. This was the gap `DASHBOARD_CUSTOMERS.md` named, and it is still open. |

---

## 2. Deliberate non-goals

- **No writes.** Approving a payment, adjusting a wallet and deciding a refund
  keep their audited homes. See `CLIENTS_OVERVIEW.md` §4.
- **No blocklist or fraud marking.** `clients.status` is the passenger's own
  account state; the office does not own it and this module does not offer to
  change it. A per-office block would need a new table and a decision about what
  it prevents.
- **No segmentation or saved views.** "Customers who booked three times last
  month" is still unanswerable. The four filters cover the questions asked
  daily; a query builder is a different feature.
- **No export.** Finance and محفظة العملاء own the export paths, and an
  unaudited customer-list download is a data-protection decision rather than a
  UI one.
- **No cross-module deep links.** Opening a customer's booking in الحجوزات would
  need the bookings module to accept a preset, which it does for the payment
  queue but not for a client id.

---

## 3. Sharp edges to know about

### `operation_bookings.subscription_id` points at the *other* subscriptions table

It is a foreign key into `transport_subscriptions`, **not** `subscriptions`. A
join written against the latter compiles, runs, and returns `NULL` on every row.
This cost a bug during implementation. See `CLIENTS_DATA_MODEL.md` §4.

### `OpsDataTable.currentPage` is zero-based

And `onPageChanged` emits zero-based. A one-based page number renders
*"صفحة 2 من 1"* on a single-page result.

### `DashboardLoading` defaults to a `ListView`

Nested inside another scrollable it throws *"Vertical viewport was given
unbounded height"*. Every skeleton inside the profile workspace passes
`scrollable: false`. This crashed the profile's loading state until a widget
test caught it.

### `clients.id` is a foreign key into `auth.users`

A test cannot fabricate a customer row. Cross-office isolation was proved by
stubbing the office context and reading a *real* other-office client inside a
rolled-back transaction.

### Directional glyphs must come from `DashboardIcons`

`dashboard_rtl_test` fails on a raw `Icons.chevron_*` anywhere under
`lib/apps/dashboard`. Note `paginationPrevious` is `chevron_left_rounded` —
Material mirrors it under RTL, so reaching for `chevron_right` because "back
points right in Arabic" produces a backwards control.

---

## 4. Performance notes

- The directory's base set is built from office-indexed tables and joined back
  to `clients`. The reverse would seq-scan every passenger on the platform.
- The five KPIs are five targeted queries rather than a slice of the directory
  CTE, so they describe the whole base and do not move when the list is filtered.
  On a large office this is five index scans per module open; if that becomes
  material, the answer is a materialised per-office counter table, not folding
  them back into the paged query.
- `office_customer_profile` is one round trip built from eight lateral joins.
  It is the only query on the critical path of opening a customer.
- Tabs are lazy and cached for the life of the workspace.
- No realtime subscription. Customer history is not a live feed; the module has
  a refresh button and re-reads the directory when the operator returns from a
  profile.

---

## 5. Verification status (2026-08-21)

| Check | Result |
|---|---|
| `flutter analyze` | 0 new issues (21 pre-existing elsewhere in the repo) |
| Customers suite | 109 assertions, all passing |
| Full dashboard suite | 1427 passing; 1 pre-existing failure in `trip_creation_driver_vehicle_test` (fails on a clean tree too) |
| RPCs against live data | All 7 verified in a rolled-back transaction before applying |
| Office isolation | Proved: all 5 detail RPCs return `not_authorized` for another office's client, and the directory does not list them |
| Capability gate | `dashboard_admin` allowed · `support_agent` allowed · unknown role `not_authorized` · non-office user `not_an_office_user` |
| `office_can` regression | All 9 wallet capabilities intact after adding `customers_view` |
| RTL / dark mode / text scale | Covered by widget tests at 1.0× and 1.6×, both themes |

---

## 6. Next, in rough priority order

1. **Contact log.** The oldest gap, and the one operators feel. A row per call
   or message, attached to the customer rather than to a ticket.
2. **Populate `subscription_ride_usage`.** Unlocks honest package-usage
   recency, which is the most valuable insight the data currently cannot support.
3. **Deep links into الحجوزات and محفظة العملاء** from a customer's rows, once
   those modules accept a client-id preset.
4. **Segmentation** — saved filter sets, and a "booked N times in period" filter.
5. **Loyalty visibility**, if and only if the product decides an office is
   entitled to a passenger's platform-wide points.
