# Dashboard · Notifications (الإشعارات) — operational alerts inbox + dispatch

Two separate things:

1. **Operational alerts** — the office's inbox/bell (`operational_alerts` table). Rows are written
   **only by database triggers** (`push_operational_alert`) when something happens: a receipt to
   review, a refund request, a captain request, a ticket, a cancelled trip, a wallet freeze, a
   licensing state change. The dashboard reads, counts unread, and marks read.
2. **Dispatch** — the office sends a push/in-app notification to one rider or captain
   (`office_dispatch_notification`), or a platform admin broadcasts to everyone
   (`platform_broadcast_notification`). These write the `notifications` table the client/captain
   apps read; FCM delivery is handled by the notification event engine, not by the dashboard.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/notifications/`) |
|---|---|
| Screens | `presentation/screens/` (`DashboardRoutes.notifications` = `/notifications`); the bell + badge live in `core/routes/dashboard_shell.dart` |
| Cubits | `presentation/cubit/operational_alerts_cubit.dart`, `notifications_dispatch_cubit.dart` (`dispatch(draft)`) |
| Use cases | `domain/usecases/` (`WatchOperationalAlertsUseCase`, `WatchUnreadAlertsCountUseCase`, `MarkAlertReadUseCase`, `MarkAllAlertsReadUseCase`, `SendNotificationUseCase`) |
| Repos | `data/repositories/operational_alerts_repository_impl.dart`, `notifications_dispatch_repository_impl.dart` |
| **Datasources** | `data/datasources/supabase_operational_alerts_datasource.dart`, `supabase_notifications_dispatch_datasource.dart` |
| Model / entities | `data/models/operational_alert_model.dart`; `domain/entities/notification_draft.dart` (`NotificationTargetApp`, `DashboardNotificationCategory`, `NotificationDraft { title, body, category, targetApp, actionUrl, data, recipientUserId?, isBroadcast }`) |
| Permission | `DashboardPermission.notifications` (both roles); feature key `notifications`; dispatch asserts `push_notifications` server-side |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| A1 | Alerts feed (latest 100, live) | `.stream(primaryKey:['id']).order('created_at').limit(100)` on `operational_alerts` | `GET /api/v1/dashboard/alerts` + WebSocket `alerts.changed` |
| A2 | Unread count | `GET operational_alerts?select=id&is_read=eq.false` with `Prefer: count=exact` (re-run on every A1 event) | `GET /api/v1/dashboard/alerts/unread-count` |
| A3 | Mark read | `PATCH operational_alerts?id=eq. {is_read:true}` | `PATCH /api/v1/dashboard/alerts/{id}` |
| A4 | Mark all read | `PATCH operational_alerts?is_read=eq.false {is_read:true}` | `POST /api/v1/dashboard/alerts/read-all` |
| A5 | Send to one user | `POST rpc/office_dispatch_notification` | `POST /api/v1/dashboard/notifications` |
| A6 | Broadcast (platform admin) | `POST rpc/platform_broadcast_notification` | `POST /api/v1/platform/notifications/broadcast` |

`RLS`: `operational_alerts_office` (select, `office_id = current_office_id()`) and
`operational_alerts_office_update` (`20260721090200_multi_office_rls.sql:462-467`). No error mapping in the
alerts datasource; dispatch A5 runs under `LicensingGuard.run`.

---

## A1–A4 — Alerts (`supabase_operational_alerts_datasource.dart`)

Row → `OperationalAlertModel { id, type, title, body, data (jsonb), priority (normal|high|urgent), action_url, is_read, created_at }`.
`action_url` is a dashboard route (`/bookings`, `/wallet`, `/captain-requests`, `/tickets`, `/live-trips`, `/office-billing`, …)
the shell navigates to on tap. `SUPABASE-SPECIFIC`: the feed is a CDC stream; the count is re-queried on each event.

`BUSINESS RULE` — `push_operational_alert(p_type, p_title, p_body, p_data, p_priority, p_action_url, p_office_id)`
(`20260721090300_multi_office_rpcs.sql:623`, internal, not callable by apps): resolves the office from
`p_office_id`, else from `data.trip_id → booking_id → driver_id → request_id → subscription_id`; an
**unattributable alert is dropped silently** so a notification can never abort the business transaction.

Alert `type` values raised today (grep of `supabase/migrations`):

| type | Raised by | Route |
|---|---|---|
| `payment_review` | receipt submitted on a booking | `/bookings` |
| `booking_cancelled_by_client` | `cancel_booking_by_client` | `/bookings` |
| `trip_cancelled` | `on_operation_trip_change` (status → cancelled) | `/live-trips` |
| `captain_request` | `on_captain_request_insert` | `/captain-requests` |
| `support_ticket` | `on_support_ticket_insert` | `/tickets` |
| `refund_request` | `on_refund_request_change` (client- or agent-filed) | `/wallet` |
| `refund_batch` | `office_refund_trip_batch` | `/wallet` |
| `wallet_status`, `wallet_chain_divergence`, `wallet_<kind>` | wallet RPCs / `wallet_post_entry` | `/wallet` |
| `low_trip_rating` | `submit_trip_review` (rating ≤ threshold) | `/reviews` |
| `license_<status>`, `license_plan_changed`, `license_downgraded`, `license_past_due`, `license_grace`, `license_suspended`, `trial_ending`, `invoice_issued` | licensing triggers / platform RPCs | `/office-billing` |

**Proposed .NET:** `GET /api/v1/dashboard/alerts?page=` (latest first), `unread-count`, `PATCH {isRead}`,
`read-all`; a per-office push topic for the bell. Every domain event handler in .NET must call the same
"raise alert" service with the same `type`/`action_url` vocabulary.

---

## A5 — Send to one user: `insertForUser({userId, draft})` (`supabase_notifications_dispatch_datasource.dart:31`)

```
POST /rest/v1/rpc/office_dispatch_notification
{ "p_user_id": "<auth uid of a rider or captain>", "p_title": "…", "p_body": "…",
  "p_category": "booking|payment|trip|announcement|promotion|emergency|subscription|system|general",
  "p_target_app": "client|captain|all", "p_action_url": "<deep link>|null", "p_data": { … } }
→ 200 "<notification uuid>"
```
`BUSINESS RULE` (`20260808090000_licensing_enforcement_completion.sql`, §7.2): `not_an_office_user`,
`recipient_required`, `title_required`; `assert_feature('push_notifications')` (licensing codes);
**`recipient_not_in_office`** unless the user has a booking with the office, is one of its drivers, or is
one of its staff. Inserts `notifications { user_id, title, body, category, target_app, action_url, data, is_read:false }`;
the event engine's trigger on `notifications` fans out to FCM tokens. The old direct-insert policy
`notifications_staff_insert` (any office → any user) is gone.

**Proposed .NET:** `POST /api/v1/dashboard/notifications { recipientUserId, title, body, category, targetApp, actionUrl?, data? }` → `201 { id }`.
Keep the audience rule.

## A6 — Broadcast: `broadcastRpc(draft)` (line 52)

```
POST /rest/v1/rpc/platform_broadcast_notification { p_title, p_body, p_category, p_target_app, p_action_url, p_data }
→ 200 <int recipients>
```
`platform_admin_required` unless `is_platform_admin()`; delegates to `broadcast_notification` which inserts
one `notifications` row per user of the target app(s). Offered in the UI only when
`OfficeContext.isPlatformAdmin`.

## Notes for the .NET team

1. The dashboard never reads the `notifications` table — that is the rider/captain inbox. It reads
   `operational_alerts` only.
2. Alerts are fire-and-forget side effects of domain events; the .NET service that replaces each trigger
   must raise them with the same `type` and `action_url` or the bell's deep links break.
3. `data` payload keys the shell understands: `booking_id`, `trip_id`, `request_id`, `ticket_id`,
   `refund_id`, `client_id`, `batch_id`.
