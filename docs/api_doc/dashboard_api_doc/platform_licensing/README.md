# Dashboard · Platform Licensing (الباقات والميزات · التراخيص · الفوترة والسجل)

The SaaS licensing console for **platform admins**: the feature catalogue (47 features, 17 enforced),
plans (a plan = a map of feature → value), each office's license (plan, status, trial, overrides,
usage), invoices/payments, usage report, the append-only audit log, enforcement settings and the
two scheduled jobs (lifecycle + billing cycle). **Every licensing table has SELECT policies but no
INSERT/UPDATE/DELETE policy for anyone**; reads and writes both go through `security definer` RPCs
so the console and the audit trail describe the same events. Built 2026-08-06/07, **enforcing in
production since 2026-08-07**.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/platform_licensing/`) |
|---|---|
| Screens | `presentation/screens/platform_catalog_screen.dart` (`/platform-catalog` — features + plans), `platform_licenses_screen.dart` (`/platform-licenses` — office workspace: license, overrides, usage), `platform_billing_screen.dart` (`/platform-billing` — invoices + audit + settings + jobs) |
| Cubit | `presentation/cubit/platform_licensing_cubit.dart` |
| Use cases | `domain/usecases/platform_licensing_usecases.dart` (one per RPC) |
| Repo | `data/repositories/platform_licensing_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_platform_licensing_datasource.dart` (`SupabasePlatformLicensingDatasource implements PlatformLicensingDatasource`) |
| Entities | `domain/entities/licensing_catalog.dart` (`FeatureCatalog`, `LicensingPlan`, `PlanDetail`, `LicensingSettings`, `LicensingHealth`), `office_license.dart` (`OfficeLicenseRow`, `OfficeLicenseDetail`, `BillingOverview`, `OfficeUsageRow`, `LicenseAuditEntry`) |
| Per-office switchboard | `presentation/widgets/office_feature_board.dart` → `PlatformLicensingCubit.applyFeatureEdits` (loops X16/X17 under one reason) |
| Permission | `DashboardPermission.platformLicensing` (admin role **and** `isPlatformAdmin`) |

Cross-cutting concepts (`../README.md` §1.2–§1.3): the resolved entitlement document (`office_entitlements`),
the six refusal codes, `may = role ∧ entitlement ∧ quota`, kill switch = `platform_settings.enforcement_mode`.

### Vocabulary

* **Feature** `value_type ∈ boolean | limit | enum | config`; `status ∈ active | hidden | deprecated | disabled`
  (`disabled` = kill switch); `meter_kind ∈ stock | flow`, `meter_period`; `enforcement_status ∈ enforced | declared`
  (derived from the gate registry, never set by hand); a **limit** value is a non-negative int or the string `'unlimited'` — never `-1`, never null.
* **Plan** `status ∈ draft | active | archived`; `key` (naming law: *plan/license*, never *package/subscription*).
* **License** `status ∈ trialing | active | past_due | grace | suspended | cancelled | expired`; `billing_cycle ∈ monthly | yearly | custom`.
* **Invoice** `status ∈ draft | issued | paid | overdue | void | refunded`.
* Resolution ladder for a feature value: `kill_switch → license_hold → override → plan → default` (reported as `source`).

## Operations (all `POST /rest/v1/rpc/<name>`, `platform_admin_required` unless noted)

| # | Operation | RPC (params) | Proposed .NET |
|---|---|---|---|
| **Catalogue** | | | |
| X1 | Feature catalogue | `platform_feature_catalog()` → `{ features[], categories[], gates[] }` | `GET /api/v1/platform/licensing/features` |
| X2 | Upsert feature | `platform_upsert_feature(p_payload { key, name_ar, name_en, description_ar, category_key, value_type, unit_ar, is_public, status, sort_order, meter_kind, meter_period, reason })` | `PUT /api/v1/platform/licensing/features/{key}` |
| X3 | Feature status (kill switch) | `platform_set_feature_status(p_key, p_status)` | `PATCH /api/v1/platform/licensing/features/{key}/status` |
| **Plans** | | | |
| X4 | List plans | `platform_list_plans()` | `GET /api/v1/platform/licensing/plans` |
| X5 | Plan detail | `platform_plan_detail(p_plan_id)` → plan + `features {key: value}` + subscriber count | `GET /api/v1/platform/licensing/plans/{id}` |
| X6 | Save plan | `platform_save_plan(p_payload { id?, key, name_ar, name_en, tagline_ar, price_monthly, price_yearly, currency, trial_days, is_public, status, sort_order, downgrade_to_plan_id, notes, reason, features {…} })` | `PUT /api/v1/platform/licensing/plans/{id}` |
| X7 | Clone plan | `platform_clone_plan(p_plan_id, p_new_key, p_new_name)` | `POST /api/v1/platform/licensing/plans/{id}/clone` |
| X8 | Compare plans | `platform_compare_plans(p_plan_ids uuid[])` | `GET /api/v1/platform/licensing/plans/compare?ids=` |
| X9 | Preview a plan's effect | `platform_preview_plan(p_plan_id)` (which offices gain/lose what) | `GET /api/v1/platform/licensing/plans/{id}/preview` |
| **Licenses** | | | |
| X10 | List licenses | `platform_list_licenses()` | `GET /api/v1/platform/licensing/licenses` |
| X11 | One office's license | `platform_office_license(p_office_id)` → license + resolved features + overrides + usage + invoices | `GET /api/v1/platform/licensing/offices/{officeId}` |
| X12 | Assign plan | `platform_assign_plan(p_office_id, p_plan_id, p_cycle, p_options { reason, price_override, currency, auto_renew, contract_ref, notes, trial_days })` | `POST /api/v1/platform/licensing/offices/{officeId}/plan` |
| X13 | License status | `platform_set_license_status(p_office_id, p_status, p_reason)` | `PATCH /api/v1/platform/licensing/offices/{officeId}/status` |
| X14 | Start trial | `platform_start_trial(p_office_id, p_plan_id, p_days)` | `POST /api/v1/platform/licensing/offices/{officeId}/trial` |
| X15 | Extend trial | `platform_extend_trial(p_office_id, p_days, p_reason)` | `POST /api/v1/platform/licensing/offices/{officeId}/trial/extend` |
| X16 | Set override | `platform_set_override(p_office_id, p_key, p_value jsonb, p_reason, p_expires_at?)` | `PUT /api/v1/platform/licensing/offices/{officeId}/overrides/{key}` |
| X17 | Clear override | `platform_clear_override(p_office_id, p_key, p_reason)` | `DELETE …/overrides/{key}` |
| X17b | Feature board (batch under one reason) | client-side loop of X16 / X17 per edited feature — `platform_bulk_set_overrides` exists in SQL but is **not called** | `PUT …/overrides { edits[], reason }` (one transaction) |
| **Billing** | | | |
| X18 | Billing overview | `platform_billing_overview(p_filters { office_id?, status? })` → `{ invoices[], issued, paid, overdue, amount, renewals[] }` | `GET /api/v1/platform/licensing/billing` |
| X19 | Issue invoice | `platform_issue_invoice(p_office_id, p_period_start?, p_period_end?, p_options { amount, discount, tax, due_days, notes, status, reason })` | `POST /api/v1/platform/licensing/invoices` |
| X20 | Record payment | `platform_record_payment(p_invoice_id, p_method, p_reference?, p_paid_at?)` | `POST …/invoices/{id}/payments` |
| X21 | Void invoice | `platform_void_invoice(p_invoice_id, p_reason)` | `POST …/invoices/{id}/void` |
| **Ops** | | | |
| X22 | Usage report | `platform_usage_report()` (per office, per limit: used / limit / remaining) | `GET /api/v1/platform/licensing/usage` |
| X23 | Audit log | `platform_audit_log(p_filters, p_limit, p_offset)` | `GET /api/v1/platform/licensing/audit` |
| X24 | Health | `platform_licensing_health()` (mode, offices per status, drift checks) | `GET /api/v1/platform/licensing/health` |
| X25 | Settings read / update | `platform_settings_read()`, `platform_update_settings(p_payload)` (`enforcement_mode`, grace days, …) | `GET/PUT /api/v1/platform/licensing/settings` |
| X26 | Run lifecycle job | `platform_run_licensing_lifecycle()` (trial → expired, past_due → grace → suspended…) | `POST /api/v1/platform/licensing/jobs/lifecycle` |
| X27 | Run billing cycle | `platform_run_billing_cycle()` (renewals → invoices) | `POST /api/v1/platform/licensing/jobs/billing` |

Definitions: `20260807100100_licensing_console.sql` (X1–X17, X22–X25), `20260807120000_licensing_billing.sql`
(X18–X21), `20260807130000` (X26–X27). Error codes mapped in `_messages` (line 306; keep them):
`platform_admin_required, reason_required (≥ 8 chars), unknown_feature, feature_key_required,
feature_value_null, feature_value_type_mismatch, feature_value_invalid_limit, feature_value_below_min,
feature_value_above_max, feature_value_not_allowed, feature_schema_incomplete, feature_dependency_cycle,
plan_not_found, plan_archived, license_not_found, not_trialing, trial_days_required, invoice_not_payable,
invoice_not_voidable, audit_is_append_only` (+ `duplicate key value`).

---

## `BUSINESS RULE` highlights the backend must keep

1. **Every write demands a reason** (`reason_required`, ≥ 8 chars) and writes an audit row
   (`platform_license_audit`, append-only by trigger `platform_audit_append_only`).
2. **`platform_save_plan` replaces the plan's feature map wholesale** — an omitted key is deleted, meaning
   "fall through to the catalogue default", which is *not* the same as `false`.
3. Feature values are validated against the feature's schema (`platform_validate_feature_value`: type,
   min/max, allowed enum values, `unlimited`), dependencies must be acyclic.
4. Assigning a plan: `plan_not_found`, `plan_archived`; sets `office_licenses { plan_id, billing_cycle,
   period_start/end, price_override, auto_renew, contract_ref }`; may start a trial (`trial_days`); raises
   the office alert `license_plan_changed` / `license_downgraded`.
5. License status changes project a **licensing hold** (`licensing_hold`) that the resolver reads as the
   `license_hold` rung: `suspended | cancelled | expired` ⇒ creation stops, reads/captains/in-flight trips
   continue (`max_live_trips` stays unlimited in the `restricted` fallback plan by design — a licensing state
   may never stop a bus). `past_due` / `grace` are fully operational + banner.
6. Overrides: per office, per key, optional expiry; the dependency gate can defeat an override
   (`blocked_by` in the resolved document).
7. Invoices: numbered by `platform_next_invoice_number()`; `record_payment` only on `issued|overdue`
   (`invoice_not_payable`) and moves the license out of `past_due`; `void` only when unpaid
   (`invoice_not_voidable` — a paid amount is refunded, not voided); `invoice_issued` alert to the office.
8. The two jobs are idempotent and are what a scheduler must call (there is no cron in Supabase today —
   the console has buttons).
9. Kill switch: `update platform_settings set enforcement_mode = 'off'` — every gate is mode-aware and the
   settings trigger re-projects holds for all offices.
10. Realtime: `office_licenses`, `office_feature_overrides`, `platform_plan_features`, `platform_features`
    are in the realtime publication so every office's `EntitlementService` refreshes live (§2.5 of the design).

## Notes for the .NET team

1. This is the one module whose data model is documented end-to-end in
   `docs/architecture/PLATFORM_LICENSING.md`; port the tables and the resolver (`platform_license_document`)
   before the console.
2. The per-office **entitlement document** (`office_entitlements`) is the read contract every dashboard
   screen consumes — its JSON shape is in `../office_billing/README.md` E1; do not change key names.
3. Enforcement in Supabase is **triggers on the business tables** (drivers, vehicles, routes, trips,
   office_users, storage.objects, notifications, exports) raising one of the six codes with a JSON
   `detail` verdict. In .NET this becomes a middleware/service call before each metered write, with the
   same six codes and the same verdict payload `{ allowed, reason, feature, limit, used, plan_key, blocked_by }`.
