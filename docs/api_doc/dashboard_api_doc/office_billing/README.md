# Dashboard · Office Billing (الباقة والفوترة)

The office's own view of its **license**: current plan, status banner, trial countdown, usage
meters (limit features with `used / limit`), included/locked features by category, the invoice
history, and an "upgrade request" the owner copies to send to EWT (no in-app purchase). The plan
and meters come from the session's **entitlement document** (already loaded at sign-in); only the
invoices are a fresh read. Rebuilt 2026-08-30.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/office_billing/`) |
|---|---|
| Screen | `presentation/screens/office_billing_screen.dart` (`DashboardRoutes.officeBilling` = `/office-billing`) |
| Cubit | `presentation/cubit/office_billing_cubit.dart` — takes `EntitlementContext` (from `EntitlementService`) + `GetOfficeInvoicesUseCase` |
| Use case | `domain/usecases/get_office_invoices_usecase.dart` |
| Repo | `data/repositories/office_billing_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_office_billing_datasource.dart` (`SupabaseOfficeBillingDatasource implements OfficeBillingDatasource`) |
| Model | `data/models/office_invoice_model.dart` |
| Views | `presentation/models/office_license_view.dart`, `office_invoice_view.dart`; widgets `office_subscription_card`, `office_limits_panel`, `office_features_panel`, `office_invoices_panel`, `office_invoice_detail_dialog`, `office_upgrade_request_dialog` |
| Permission | `DashboardPermission.officeBilling` (admin only) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| E1 | License + features + meters | **no call here** — `EntitlementService.context` (`POST rpc/office_entitlements`, loaded at sign-in and refreshed by realtime) | `GET /api/v1/dashboard/entitlements` |
| E2 | Invoices (paged) | `POST rpc/office_invoices {p_limit: 50, p_offset: 0}` | `GET /api/v1/dashboard/billing/invoices?page=` |
| E3 | Upgrade request | none — the dialog composes a text the owner copies (plan, feature, office) | `POST /api/v1/dashboard/billing/upgrade-requests` (recommended) |

---

## E1 — Entitlement document (`../README.md` §1.2)

`office_entitlements()` (`20260807100000_licensing_resolution.sql`) → `{ license { plan_key, plan_name_ar,
status, billing_cycle, price, currency, trial_ends_at, period_start, period_end, grace_ends_at, auto_renew,
contract_ref, suspended_reason }, features { <key>: { value, value_type, source, blocked_by, name_ar,
category_key, unit_ar, expires_at, used, remaining, meter_kind, is_public, enforcement_status, sort_order } },
enforcement_mode, resolved_at }`. Also available as `office_license_summary()` (license + limits only) —
not called by the app.

`BUSINESS RULE` (rendering rules the cubit applies): a meter row is shown only when the feature `isPublic
&& enforced` (this killed the «0 / 0» rows); `meter_kind` explains why a number did not go down
(`stock` = counts rows that exist now, self-healing on delete; `flow` = accumulates over the period —
deleting does not return quota); `needsAttention` statuses `past_due | grace | suspended | cancelled | expired`
drive the banner, `isHeld` (`suspended | cancelled | expired`) means read-only; `trialDaysLeft` from
`trial_ends_at`. Invoices failing to load must never take the plan card down (tolerant load).

## E2 — `getInvoices({limit, offset})` (`supabase_office_billing_datasource.dart:23`)

```
POST /rest/v1/rpc/office_invoices { "p_limit": 50, "p_offset": 0 }
→ 200 [ { id, invoice_number, period_start, period_end, line_items: [ {…} ], total, currency,
          status: issued|paid|overdue|void|refunded, issued_at, due_at, paid_at } ]   (newest first; drafts excluded)
```
`SECURITY DEFINER` (`20260807120000_licensing_billing.sql`), office from `current_office_id()`,
`p_limit` clamped 1..200. The office **cannot pay in-app**; payments are recorded by the platform
(`platform_record_payment`).

## Notes for the .NET team

1. The billing screen is mostly a projection of the entitlement document; expose that document once
   (`/dashboard/entitlements`) and make it the same JSON the shell's gates consume.
2. Keep the never-null / never-`-1` limit rule and the `source` rung — the screen explains *why* a feature is
   off or a limit is what it is.
3. Upgrade requests are out-of-band today (copied text). A real endpoint that raises a platform-side task
   would close the loop.
