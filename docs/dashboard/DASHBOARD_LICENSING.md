# Dashboard — Licensing and Entitlements

EWT sells the dashboard as SaaS. This is how that is expressed in code and in the
database. **Enforcing in production since 2026-08-07.**

---

## 1. Vocabulary — the naming law

Two words that are not interchangeable, and the code never mixes them:

- A **plan** is a named bundle the platform sells — a set of feature values.
- A **licence** is one office's instance of a plan, with its own status, period, price
  and overrides.

`plan_key` identifies the former; a licence row identifies the latter. Reviewers should
reject any change that uses one word for the other.

---

## 2. The three predicates

```
may = role_permits  ∧  office_entitled  ∧  quota_allows
```

ANDed, never merged. `_DashboardNavItem` carries `permission` and `feature` as two
separate fields because they change for different reasons — a role when staff change, an
entitlement when a contract changes — and merged, the console could no longer tell an
operator *which* of the two refused them.

---

## 3. The resolution ladder

Every feature resolves through five rungs, and the winning rung is returned as `source`:

| Rung | Wins when |
|---|---|
| `kill_switch` | The platform's one-row emergency override is set |
| `license_hold` | The licence is suspended / cancelled / expired |
| `override` | This office has a per-feature override on the feature board |
| `plan` | The office's plan says so |
| `default` | The catalogue's default |

`source` is not decoration. It is the entire answer to *"why does this office have this?"*,
and it is what makes التراخيص a two-minute support conversation instead of a twenty-minute
one.

`blocked_by` is set separately when a prerequisite defeated the value at the dependency
gate. Both facts are true at once — the override *was* applied, and a prerequisite still
killed it — and showing only one of them looks like the system ignored the operator.

---

## 4. Value types

| Type | Shape |
|---|---|
| `boolean` | on/off |
| `limit` | a non-negative integer, or the literal string `'unlimited'` |
| `enum` | e.g. `report_level`, `analytics_level` |
| `config` | e.g. `logo_max_kb` |

A limit is **never** `-1` and **never** null. `-1` is a magic number arithmetic silently
accepts; null is indistinguishable from "no row", which is a different rung of the ladder.

`FeatureKeys` holds ~26 Dart constants against a catalogue of 47. That is intentional: a
constant is only warranted where code branches on the key. The catalogue is data and can
grow without a deploy, which is also why `FeatureKeys` is a class of constants rather than
an enum — a closed Dart type would be a lie about the system's own extensibility.

---

## 5. Enforcement

**Write-side, by trigger.** `before insert` on `drivers`, `vehicles`, `operation_routes`,
`office_users`, `operation_trips`, `wallet_transactions`, `refund_requests`, `packages`,
`transport_packages`, plus captain and live-trip quotas. `assert_feature(key)` guards RPCs.

**Read-side, in three views.** `drivers_performance_view`, `vehicles_efficiency_view` and
`complaints_summary_view` carry `office_licensed('reports')` in their bodies — a genuine
server boundary, because those views exist for the reports module and nothing else.
`revenue_daily_view` is deliberately **not** gated: Finance reads it too, and withdrawing
it with `reports` would take down a module the office still holds.

Everything else is gated in the UI only, and the licensing migration records that honestly
as `ui`.

**Mode.** `enforcement_mode` is `off` | `shadow` | `enforcing`. While off or shadow the
server allows everything, so the console must not pretend otherwise — hiding a module the
backend would happily serve is its own kind of bug. `EntitlementContext.allows()` returns
true unconditionally unless the mode is `enforcing`.

---

## 6. Failing open, on purpose

`EntitlementContext.unknown` allows everything. This is the opposite of the usual security
default and it is deliberate: this object is a **UX hint**, the server is the boundary, and
a network blip that silently hid half an operator's console would be indistinguishable
from a downgrade they never agreed to.

The shell resolves the service only if it is registered, so a test mounting the shell with
a minimal DI graph gets `unknown` and a fully open console — the licensing axis must never
be what decides whether the console can be built at all.

---

## 7. Locked vs hidden

```
isLocked = is_public && enforced && !isOn
```

- **Locked** — drawn dimmed with a padlock, still tappable. The tap opens the upgrade card,
  which is how the owner learns what the module is and what it would cost. Hiding a
  purchasable module makes it unsellable.
- **Hidden** — not purchasable on any plan, or not gated at all. Showing it is noise.
- **`enforced` vs `declared`** — a `declared` feature is catalogued and sellable in
  principle but nothing gates it yet. It must never be presented to an office as something
  they are about to gain.

---

## 8. The refusal moment

```
datasource write
   └─ LicensingGuard.run(...)
        └─ server refuses
             └─ licensingRefusals.publish(failure)
                  └─ shell consumes it
                       ├─ refreshes the entitlement document
                       │    (the server just disagreed with what we hold,
                       │     so our copy is out of date by definition)
                       └─ shows the upgrade card over the module's own snackbar
```

Raised once, from the shell, rather than in every screen that can hit a limit — so a new
module cannot ship without an upgrade path.

---

## 9. The office's own view

`/office-billing` — «الباقة والفوترة», owner only. Plan, status, period, limits with usage
bars, included features, invoices.

**It deliberately cannot change the plan.** A checkout without a payment gateway would be
a lie, and a plan change has proration implications that need a real billing engine. The
call to action is contact, not purchase — and saying that plainly is better than a
disabled "upgrade" button that teaches the owner the console is broken.

Licence status drives a banner: `past_due` and `grace` are **fully operational** states
that need a banner, not a block. `suspended` / `cancelled` / `expired` are holds.

---

## 10. The platform's view

Three destinations, consolidated in August 2026 from seven:

| Destination | Job |
|---|---|
| الباقات والميزات | Plans and the feature catalogue — a plan is a set of feature values, so pricing one without reading the other is not a thing anyone does |
| التراخيص | Every office's licence; the office opens into a **full-width workspace with four tabs**, not a narrow detail pane |
| الفوترة والسجل | Invoices and the append-only audit trail, together because they answer each other |

The law learned from that consolidation: **browse → workspace**, never browse → narrow
pane holding six stacked collapsible panels. And screens host tabs; there is no
`sections/` layer between a screen and its content.

Some RPCs still require a written reason (overrides, holds). The «الميزات والحدود» feature
board batches an office's changes under one reason rather than asking per toggle.
