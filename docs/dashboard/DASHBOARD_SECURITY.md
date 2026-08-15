# Dashboard — Security

---

## 1. The boundary

```
Flutter                       hints  ── DashboardPermissions
                                     ── EntitlementContext
                                     ── OfficeContext.isPlatformAdmin
────────────────────────────  the actual boundary  ────────────────────────
PostgreSQL                    RLS policies
                              BEFORE INSERT / UPDATE triggers
                              SECURITY DEFINER RPCs
                              assert_feature() guards
                              GRANT / REVOKE
```

Everything above the line exists so an operator is not offered something the server will
refuse. Nothing above the line is load-bearing — **except where noted in §3, which is the
open problem.**

---

## 2. Office isolation

Every office-scoped query resolves its office from `DashboardSession.officeId`, loaded once
at sign-in from `current_office_context`. It is never typed in, never passed through a
route, never inferred from a fetched row.

Reading it while signed out **throws**. That is deliberate: a query that silently fell back
to "no filter" would return every office's rows, so failing loudly is far safer than
defaulting.

Independently, RLS enforces the same boundary on ~40 tables via
`office_id = public.current_office_id()`. Neither layer is trusted to be the only one.

Datasources that carry no explicit `office_id` filter (bookings, finance, payment
verification, reports, reviews, tickets, notifications) rely entirely on RLS — which is
correct, because RLS is the real boundary and an app-side filter is a convenience.

---

## 3. CLOSED (writes) — fleet RLS is role-aware

**Applied 2026-08-15 by `20260815110000_fleet_role_authority`.** Writes to all five fleet
tables are now `dashboard_admin`-only. Reads are unchanged and stay open to both office
roles; the read-side PII split is still open and is described at the end of this section.
Verified by `supabase/tests/fleet_role_authority_regression.sql` — 37 probes, all green,
and the same suite fails 7 probes against the pre-migration schema.

What follows is the original finding, kept because it explains the shape of the fix.

`office_role()` exists and is used to separate owner from support agent on `offices`,
`office_users`, wallet policies, the captain join code and logo storage. It was **not**
used on:

- `drivers`
- `vehicles`
- `assignments`
- the fleet document tables

Those carry `for all to authenticated using (office_id = public.current_office_id())` —
office-scoped, but identical for both roles.

**Impact.** `drivers` holds phone numbers, national IDs and licence data. The permission
model says a support agent must never see it. Until this pass they could: the shell's
route lookup resolved an unregistered route to the home item, which permits everyone, and
`/drivers` and `/vehicles` were unregistered while being linked from a tile on the Home
screen every role sees. Tapping «إدارة الأسطول» was correctly refused; tapping «السائقون»
right next to it was not.

**Fixed on the client.** All renderable routes are registered, `_canOpenRoute` fails
closed, and `dashboard_shell_route_gate_test.dart` asserts a support agent is refused
`/fleet`, `/drivers`, `/vehicles` and `/assignments`.

**Fixed on the server too, as of `20260815110000_fleet_role_authority`.** Each `for all`
policy became one `select` policy carrying the original predicate verbatim, plus explicit
`insert` / `update` / `delete` policies with `and public.office_role() = 'dashboard_admin'`
added — 22 policies over five tables, mirroring what `20260806090000_wallet_policies`
already does:

```sql
-- Reads stay open to both roles; writes become owner-only.
drop policy if exists drivers_office_manage on public.drivers;

create policy drivers_office_read on public.drivers
  for select to authenticated
  using (office_id = public.current_office_id());

create policy drivers_office_write on public.drivers
  for all to authenticated
  using (office_id = public.current_office_id()
         and public.office_role() = 'dashboard_admin')
  with check (office_id = public.current_office_id()
              and public.office_role() = 'dashboard_admin');
-- …and the same shape for vehicles, assignments, fleet documents.
```

Splitting read from write is the conservative version — it closes the write hole without
risking a read regression in the trip planner or live ops, both of which join driver and
vehicle rows.

**Verified before applying.** Every reader was checked. `vehicle_documents` was folded in
as the fifth table: it is `driver_documents`' sibling, created by the same loop and
written by the same datasource method, so gating one and not the other would have left a
hole with a paper trail. All 25 SQL functions that touch these tables are
`SECURITY DEFINER` and bypass RLS; `public_driver_profiles` and `public_vehicle_profiles`
are `security_invoker=false` definer views and are likewise unaffected; the captain app's
only two non-definer reads are `drivers_self_read` and `vehicles_captain_read`, both
SELECT-only and both untouched. No support-agent workflow writes a fleet table, so nothing
legitimate was blocked.

### 3.1 STILL OPEN — a support agent can still *read* driver PII

Withholding reads needs a column-level split, and RLS cannot do it: RLS filters rows, not
columns, and both office roles arrive as the same Postgres role (`authenticated`) with the
office role living in a table, so column `GRANT`s cannot separate them either. It needs a
sanitised definer view plus rewrites of the four datasources that embed driver and vehicle
rows (live ops, bookings, payment verification, reports).

Restricting the rows instead is *not* an acceptable shortcut. RLS returns zero rows rather
than an error, so a support agent's Home would quietly report `0 مركبة / 0 سائق` for an
office with twelve of each — a fabricated metric, which this console refuses to do
everywhere else.

`fleet_role_authority_regression` probe 36 asserts the gap deliberately, so it stays
visible on every run until the view lands.

---

## 4. Auth

Name + password. The typed name is mapped to the account's login address by
`resolve_office_user_login`; the email never surfaces in the UI. Same indirection
`resolve_captain_login` uses for phone numbers, so the codebase keeps one pattern.

Self-service sign-up creates the auth user with the client SDK — no service-role key is
involved — and then calls `register_office`, which decides everything worth tampering with
server-side.

Staff provisioning is the split model: **SQL owns membership** (`office_users`), an **Edge
Function owns `auth.users`** because the client SDK cannot create another user. Three
lockout rules are enforced: an operator cannot change their own role, cannot disable
themselves, and removal is a disable rather than a delete.

**All three apps share one Supabase session per device.** A restored captain session has
broken client booking before, on a foreign-key check against `clients`. When debugging an
identity problem, check `auth.users` for the uid before believing the app.

---

## 5. Writes go through RPCs

Booking state transitions (`office_approve_payment`, `office_reject_payment`, reupload,
reassignment), wallet movements, licensing changes and platform administration are all
`SECURITY DEFINER` RPCs. The dashboard never writes booking status columns directly, so
seat holds, passenger records and notifications stay consistent and the change is audited.

The one module that writes columns directly is **الشكاوى** (`support_tickets`). It is
RLS-gated and the writes are low-risk (status, note, contacted-at), but it is the odd one
out and should move to RPCs if ticket workflow grows.

Notification dispatch is a good example of the pattern earning its place:
`office_dispatch_notification` replaced a direct insert that let any office user address
any user id on the platform. The RPC enforces the entitlement, that the recipient belongs
to this office, and that the licence is not in a read-only state — three things the insert
policy never could.

---

## 6. The platform admin OR-branch

`is_platform_admin()` appears as an OR term in the four report views and several policies,
so a platform admin sees an unfiltered roll-up. Correct for the platform console.

The side effect: **an EWT staff member who also operates an office will see platform-wide
totals inside that office's Finance and Reports screens.** `revenue_daily_view`,
`drivers_performance_view`, `vehicles_efficiency_view` and `complaints_summary_view` all
carry it. Anyone reading those numbers as one office's numbers is reading them wrong.

The clean fix is an explicit scope selector on those views rather than an implicit OR;
tracked in `DASHBOARD_KNOWN_ISSUES.md`.

---

## 7. Lower-severity findings

- **`referral_analytics` is granted to `authenticated`** while its migration comment says
  "platform admins only". It is a definer view over `referrals`, so RLS on the base table
  does not apply. Any signed-in user — including a Client-app passenger — can read
  platform-wide referral totals and rewards distributed. No PII; aggregate business
  metrics only. Fix: add `where public.is_platform_admin()` to the view body.
- **`TRUNCATE` is not gated by RLS.** ~45 tables remain exposed to a role holding the
  table privilege. Partially addressed by `20260808090200_truncate_grant_hygiene`.
- **Uncapped list queries.** Most dashboard reads have no `.limit()`. Not a
  confidentiality issue — RLS still scopes every row — but a denial-of-service and cost
  surface as offices grow. See `DASHBOARD_KNOWN_ISSUES.md` §2.

---

## 8. Reviewing a change that touches security

1. Does the client gate have a server-side counterpart? If not, say so out loud in the PR.
2. Is a new route registered in `_items` with the right `permission`?
3. Does a new table have RLS **and** the right role term?
4. Does a new write go through an RPC, or does it need to?
5. Does a new policy use `for all` where read and write should differ? (`for all` is how
   the `FOR ALL` bug class got in twice already.)
6. Is there a SQL regression test in `supabase/tests/`?
