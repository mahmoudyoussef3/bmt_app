# Dashboard — Roles and Permissions

---

## 1. The two office roles

`DashboardRole` is a closed enum with exactly two members, and the server agrees —
`office_role()` returns `dashboard_admin` or `support_agent` and nothing else. Do not add
a third without changing both.

| Role | Arabic | DB value |
|---|---|---|
| `admin` | المالك | `dashboard_admin` |
| `supportAgent` | خدمة العملاء | `support_agent` |

Plus one orthogonal flag: **`isPlatformAdmin`**. It is not a role — it is an additional
capability layered on top of whatever office role the operator has, and it is checked
against the authenticated identity rather than the role, so the debug role switcher
cannot forge it.

---

## 2. المالك — the owner

Holds every `DashboardPermission`. Concretely, the owner is the only role that can:

- create, price, staff and cancel **trips**
- build and edit **routes and stations**
- manage the **fleet** — drivers, vehicles, assignments, documents
- approve **captain applications**
- see and export the **financial centre**
- create and cancel **subscriptions** and the office's package catalogue
- edit the **office profile** and its marketplace listing
- see the office's **plan, limits and invoices**
- **create, disable and reset staff accounts**
- read individual **reviews**

---

## 3. خدمة العملاء — the support agent

Holds seven permissions, and this list is the whole of it:

| Permission | What it opens |
|---|---|
| `liveOps` | العمليات المباشرة — see what is running (but not resolve incidents) |
| `bookings` | الحجوزات — the booking and receipt queue |
| `paymentVerification` | مراجعة المدفوعات — the same queue, narrower |
| `tickets` | الشكاوى — customer complaints |
| `reports` | التقارير |
| `notifications` | الإشعارات — inbox and dispatch |
| `customerWallets` | محفظة العملاء — **view only** |

Two permissions are deliberately *not* included even though the modules they belong to
are reachable:

- **`liveOpsIncidentAction`** — a support agent watches the incident queue but does not
  close incidents. Passed into `LiveOpsScreen` as `canResolveIncidents`.
- **`walletAdjustments` / `walletApprovals`** — a support agent can look up a customer's
  balance to answer "where is my money", but cannot move it or approve a refund. Passed
  into `WalletScreen` as `canAdjust` / `canApprove`.

This split — *see the module, not every action in it* — is the right pattern and should be
how new capabilities are added, rather than by inventing more roles.

### What a support agent must never see

- Driver personal data: national IDs, licence numbers, phone numbers
- Vehicle records and fleet assignments
- The financial centre, the office's plan, or its invoices
- Individual written reviews
- Staff accounts and credentials
- Anything belonging to another office

---

## 4. Platform admin

`isPlatformAdmin` adds the المنصة group: office onboarding and listing, the plan and
feature catalogue, every office's licence, platform billing and audit, and the referral
programme.

It is documented everywhere in the code as *"a hint for the shell, nothing more"* — every
RPC behind those screens re-checks `is_platform_admin()` server-side, so a forged `true`
reaches a screen whose every action is refused.

**One consequence to keep in mind:** `is_platform_admin()` appears as an OR branch in the
four report views and several policies, so a platform admin sees an unfiltered roll-up.
If an EWT staff member also operates an office, that office's Finance and Reports screens
will include other offices' rows. See `DASHBOARD_KNOWN_ISSUES.md` §1.

---

## 5. How a permission is enforced

```
DashboardPermissions.canAccess(role, permission)     ← the nav gate
        ↓  shown/hidden in the sidebar
_canOpenRoute(route)                                 ← the route gate, fails closed
        ↓  refused with a snackbar
Screen receives can<Action> flags                    ← the action gate
        ↓  control not rendered
RLS policy / trigger / assert_feature()              ← the real boundary
```

Only the last line is a security boundary. The first three are product design: they keep
an operator from being offered something the server will refuse.

**Except for fleet.** `drivers`, `vehicles`, `assignments` and the fleet document tables
carry role-agnostic policies (`for all to authenticated using (office_id =
current_office_id())`), so for those tables the client gate is currently the only gate.
This is tracked as the highest-priority open issue; the fix is a migration adding
`office_role() = 'dashboard_admin'` to the write side of those four policies, mirroring
what `wallet_policies` and `office_logo_storage` already do.

---

## 6. The debug role switcher

The sidebar shows a `SegmentedButton` for the role in `kDebugMode` only. It changes
`_role` — the client-side gate — and nothing else. The server still answers according to
the operator's real `office_role()`, so switching to المالك in a debug build and opening
Finance shows a screen whose queries are still evaluated against the real session.

It is a layout and copy tool, not an impersonation tool. `platformOnly` items are
deliberately gated on `widget.office.isPlatformAdmin` rather than `_role` so the switcher
cannot reach the platform console.
