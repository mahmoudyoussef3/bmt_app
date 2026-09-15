# Captain · Notifications (inbox + badge + FCM)

The captain-targeted slice of the shared `notifications` table, a live inbox, an unread badge in the
shell header, mark-as-read, and FCM device-token registration through the shared `FcmService`.
**The captain never sends a notification** — every row is written server-side by SQL triggers.
The contract is the client's (`../../client_api_doc/notifications/README.md`) with one difference:
the captain filters `target_app IN ('captain','all')`.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/notifications/`) |
|---|---|
| Screen | `presentation/pages/captain_notifications_page.dart` (route `CaptainRoutes.notifications = /captain/notifications`, opened from the bell `core/widgets/captain_notification_bell.dart`) |
| Cubits | `CaptainNotificationsCubit` (`presentation/cubit/captain_notifications_cubit.dart` — `startWatching()` :26-38, `markAsRead(id)` :40-46, `markAllAsRead()` :48-54, optimistic), `CaptainNotificationBadgeCubit` (`captain_notification_badge_cubit.dart` — app-lifetime singleton, subscribed at construction) |
| Use cases | `WatchCaptainNotificationsUseCase`, `WatchCaptainUnreadCountUseCase`, `MarkCaptainNotificationReadUseCase`, `MarkAllCaptainNotificationsReadUseCase` |
| Repo | `data/repositories/captain_notifications_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_captain_notifications_datasource.dart` (`SupabaseCaptainNotificationsDatasource`) |
| Model / entity | `data/models/captain_notification_model.dart` → `domain/entities/captain_notification.dart` (`CaptainNotificationCategory {trip, passenger, assignment, emergency, announcement, system, general}`, `CaptainNotificationPriority {low, normal, high, urgent}`) |
| Push (core) | `lib/core/notifications/fcm_service.dart` — wired in `lib/apps/captain/main.dart:46-72` (`FcmService.initialize(userId, appType:'captain', …)` on every session; `deactivateToken` on sign-out). **No `resolveDestination` is passed**, so a tapped push falls back to `pushNamed(data['action_url'])` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| N1 | Inbox (one-shot) | `GET notifications … target_app=in.(captain,all) … limit=100` | session | `GET /api/v1/captain/notifications` — **`NOT IMPLEMENTED` in the UI** (datasource method exists, no caller) |
| N2 | Inbox (live) | Realtime `.stream()` on `notifications` (`user_id=eq.`), filtered client-side | session | `GET /api/v1/captain/notifications` + SignalR `notification-received` |
| N3 | Unread badge (live) | second `.stream()` on `notifications`, counted client-side | session | `GET /api/v1/captain/notifications/unread-count` + push |
| N4 | Mark one read | `PATCH notifications?id=eq.` | session | `PATCH /api/v1/captain/notifications/{id}` |
| N5 | Mark all read | `PATCH notifications?user_id=eq.&is_read=eq.false` | session | `POST /api/v1/captain/notifications/read-all` |
| N6 | Register device token | `POST notification_tokens` (upsert) | session | `PUT /api/v1/me/devices/{token}` |
| N7 | Deactivate device token | `PATCH notification_tokens` | session | `DELETE /api/v1/me/devices/{token}` |

`user_id` in every call is `auth.currentUser.id` (the synthetic auth uid — see `../auth/`), **not** the
driver id. Server-side writers resolve the captain the same way (`captain_user_for_trip(trip)` →
`drivers.user_id`).

---

## N1 — `getNotifications()` (`supabase_captain_notifications_datasource.dart:22-33`)

```
GET /rest/v1/notifications?select=*&user_id=eq.<uid>&target_app=in.(captain,all)&order=created_at.desc&limit=100
```
Present in the datasource/repo interface, **never called** by a cubit (`NOT IMPLEMENTED` on the UI side).
Keep the endpoint — it is the obvious replacement for the stream's initial load.

## N2 / N3 — `watchNotifications()` (:36-53), `watchUnreadCount()` (:56-70)

```
Realtime row stream: table=notifications, primaryKey=[id], filter user_id=eq.<uid>, order created_at desc
```
Two independent streams (inbox page, badge). Both filter **client-side** to
`target_app == 'captain' || 'all'` (rows missing `target_app` default to `client` and are dropped);
the badge counts `!is_read` among them. `SUPABASE-SPECIFIC`: `.stream()` re-emits the full row set on
every change — the .NET side is an initial fetch + an incremental push.

## N4 / N5 — mark read (:73-74, :77-85)

```
PATCH /rest/v1/notifications?id=eq.<id>                       { "is_read": true }
PATCH /rest/v1/notifications?user_id=eq.<uid>&is_read=eq.false { "is_read": true }
```
Note N5 marks **all** the user's unread rows, including `target_app='client'` ones if the same auth
user somehow had any (it cannot, in practice). Errors are swallowed (optimistic UI stays).

`RLS` (`20260629300000_notification_system.sql:165-180`): select/update where `auth.uid() = user_id`.

## N6 / N7 — device token (`fcm_service.dart:79-97`, :139-159)

```
POST /rest/v1/notification_tokens   Prefer: resolution=merge-duplicates   (on_conflict=user_id,token)
{ "user_id": "<uid>", "token": "<fcm>", "platform": "ios"|"android", "app_type": "captain",
  "is_active": true, "updated_at": "<iso>" }

PATCH /rest/v1/notification_tokens?user_id=eq.<uid>&token=eq.<fcm>   { "is_active": false }
```
Called on every session start / token refresh, and on sign-out. `RLS` "Users manage own tokens"
(`user_id = auth.uid()`). Check constraints: `platform ∈ {android, ios, web}`, `app_type ∈ {client,
captain, dashboard}`.

---

## Rows the captain receives (server-side writers, `target_app='captain'`)

| Event | Trigger / function | `type` / `category` | Title | `data` | Priority |
|---|---|---|---|---|---|
| Assigned to a trip (`driver_id` set/changed) | `on_operation_trip_change` (`20260727160000_trip_lifecycle_authority.sql:741-749`) | `assignment` | `تم إسنادك لرحلة جديدة` | `{trip_id}`, `action_url: '/trips'` | high |
| Trip entered `boarding` | same :758-763 | `trip` | `بدأ صعود الركاب` | `{trip_id}` | normal |
| Trip entered `in_progress` | same :767-772 | `trip` | `بدأت الرحلة` | `{trip_id}` | normal |
| Trip cancelled | same :782-787 | `trip` | `تم إلغاء الرحلة` | `{trip_id}` | high |
| Manifest row inserted (payment approved) | `on_trip_passenger_insert` (`20260706140000:230-251`) | `passenger` | `راكب جديد على رحلتك` | `{trip_id, passenger_id}` | normal |
| Manifest row deleted | `on_trip_passenger_delete` (`20260706140000:255-282`) | `passenger` | `ألغى أحد الركاب حجزه` | `{trip_id}` | normal |

Suppressed when the office closes a stale trip (`bmt.trip_notify_suppress`). Trip completion notifies
riders only. No captain notification exists for incident acknowledgement/resolution
(`NEEDS BACKEND DECISION`).

**Deep links:** the only `action_url` ever written for the captain is `'/trips'`, which the router maps
to the shell (`CaptainRoutes.assignmentAlias`, `captain_app_router.dart:25-26`). Everything else opens
nothing on tap (no resolver). The .NET push payload should carry `{ trip_id }` and the app should
gain a resolver — out of scope for the backend, but the payload shape is.

## Notification row (what the app reads)

`id, title, body, category (unknown ⇒ general), is_read, created_at (→ local), action_url?, data (jsonb),
priority (unknown ⇒ normal)`; `type` and `target_app` are not read (the latter is only filtered on).

## Notes for the .NET team

1. Same table and same contract as the client; a `GET …?targetApp=captain` filter server-side replaces
   the client-side filtering — and stops the badge stream from receiving rider rows it then discards.
2. FCM delivery is not done by the app: whatever writes `notifications` must also push to the active
   `notification_tokens` for that user (`app_type='captain'`). Today that is Supabase-side (see the
   client doc's FCM section).
3. The auth uid ↔ driver mapping means one push audience per captain even though the identity the app
   reasons about is the driver row — the .NET token subject can simply be the driver id if the token
   store keys on it.
