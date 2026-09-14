# Client · Notifications (inbox + push)

The in-app inbox, the unread badge on the bottom nav, mark-as-read, FCM device-token registration,
and how a tapped push/inbox row resolves to a screen. **The client never sends a notification** —
every row is written by SQL (triggers/RPCs via `push_notification()`), and the push itself is
delivered by FCM from the backend side.

## Overview

| Layer | Files |
|---|---|
| Screen | `lib/apps/client/features/notifications/presentation/screens/notifications_screen.dart` (tab in the shell) |
| Cubits | `NotificationsCubit` (`presentation/cubit/notifications_cubit.dart` — subscribes to the inbox stream; `markAsRead(id)`, `markAllAsRead()`), `NotificationBadgeCubit` (unread count stream) |
| Repo | `data/repositories/notifications_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_notifications_datasource.dart` |
| Model / entity | `data/models/client_notification_model.dart`, `domain/entities/client_notification.dart` (`NotificationCategory`, `NotificationPriority`), `domain/entities/notification_destination.dart` (`resolveNotificationDestination`) |
| Push (core) | `lib/core/notifications/fcm_service.dart` (`FcmService.initialize`, `_saveToken`, `deactivateToken`, foreground snackbar, tap routing), `fcm_background_handler.dart`; resolver adapter `presentation/client_push_destination.dart` |
| Wiring | `lib/apps/client/client_app.dart` `_listenAuth()` → `FcmService.initialize(userId, appType:'client', resolveDestination: clientPushDestination)` on every session; `deactivateToken` on sign-out |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| N1 | Inbox (one-shot) | `GET notifications … limit=100` | session | `GET /api/v1/me/notifications` |
| N2 | Inbox (live) | Realtime `.stream()` on `notifications` | session | `NEEDS BACKEND DECISION` (SignalR `notification-received`) |
| N3 | Unread count (live) | Realtime `.stream()` on `notifications` | session | `GET /api/v1/me/notifications/unread-count` + push |
| N4 | Mark one read | `PATCH notifications?id=eq.` | session | `PATCH /api/v1/me/notifications/{id}` |
| N5 | Mark all read | `PATCH notifications?user_id=eq.&is_read=eq.false` | session | `POST /api/v1/me/notifications/read-all` |
| N6 | Register device token | `POST notification_tokens` (upsert) | session | `PUT /api/v1/me/devices/{token}` |
| N7 | Deactivate device token | `PATCH notification_tokens` | session | `DELETE /api/v1/me/devices/{token}` |

---

## The notification row (what the app reads)

| Column | Type | Read as |
|---|---|---|
| `id` | uuid | `id` |
| `user_id` | uuid | filter only |
| `title`, `body` | text | shown verbatim (Arabic/English as written by SQL) |
| `type` | text | machine event name, e.g. `booking_received`, `payment_review`, `payment_approved`, `payment_rejected`, `booking_cancelled`, `trip_published`, `trip_departed`, `trip_completed`, `trip_cancelled`, `refund_request`, `support_ticket`, … (drives routing) |
| `category` | text | `booking | payment | trip | announcement | promotion | emergency | chat | subscription | system | general` (unknown ⇒ `general`); fallback to `type` when null |
| `priority` | text | `low | normal | high | urgent` (check constraint) |
| `is_read` | bool | |
| `created_at` | timestamptz | rendered local |
| `action_url` | text | route override — **always null in practice** (no writer populates it) |
| `data` | jsonb | `{ booking_id?, trip_id?, ticket_id?, subscription_id?, payment_id?, refund_id?, … }` |
| `target_app` | text | `client | captain | all` — not read by the app (RLS + `user_id` already scope it) |

`RLS` (`20260629300000_notification_system.sql:165-180`): select/update where `auth.uid() = user_id`; the insert policy is permissive (`with check (true)`) but the app never inserts — rows are written by `SECURITY DEFINER` SQL (`push_notification()` and direct inserts in the booking/payment RPCs).

---

## N1 — `getNotifications()` (`supabase_notifications_datasource.dart:21`)

```
GET /rest/v1/notifications?select=*&user_id=eq.<uid>&order=created_at.desc&limit=100
```

## N2 / N3 — live inbox and badge (`watchNotifications`, `watchUnreadCount`, lines 33 / 45)

```
supabase.from('notifications').stream(primaryKey:['id']).eq('user_id', uid).order('created_at', ascending:false)
supabase.from('notifications').stream(primaryKey:['id']).eq('user_id', uid)   → count(is_read == false)
```

`SUPABASE-SPECIFIC`: `.stream()` does an initial select and then applies Realtime CDC events to keep the
list in sync. Two independent streams are open while the shell is mounted (one per cubit).

**Proposed .NET:** `GET /api/v1/me/notifications?page=` + `GET /api/v1/me/notifications/unread-count`,
with a SignalR `notification-received { notification }` event to refresh both; or FCM data messages carrying the row.

## N4 / N5 — mark read (lines 58 / 63)

```
PATCH /rest/v1/notifications?id=eq.<id>                       { "is_read": true }
PATCH /rest/v1/notifications?user_id=eq.<uid>&is_read=eq.false { "is_read": true }
```

---

## Routing a tap — `resolveNotificationDestination()` (domain, shared by inbox and push)

Order of precedence (`notification_destination.dart`):

1. non-empty `action_url` ⇒ that route, with `{bookingId|tripId|ticketId}` args from `data`.
2. `data.ticket_id` ⇒ `/ticket_details` (arg: ticket id).
3. `type` starts with `support`/`refund` ⇒ `/support`.
4. `type` starts with `subscription`/`package` ⇒ `/my-subscription`.
5. `data.booking_id`: tracking-ish type (`tracking`, `departed`, `on_way`, `boarding`, `trip_started`, …) ⇒ `/tracking {bookingId}`; else `/trips/details {tripId: bookingId}`.
6. `data.trip_id` or `type` starts with `trip` ⇒ `/trips`.
7. otherwise `null` ⇒ non-tappable row.

**Contract for the backend:** keep writing `type` + the ids in `data`; `action_url` may be used to override.

---

## N6 / N7 — device tokens (`lib/core/notifications/fcm_service.dart`)

On every session (login or restore), after `FirebaseMessaging.requestPermission` and `getToken()`:

```
POST /rest/v1/notification_tokens?on_conflict=user_id,token
Prefer: resolution=merge-duplicates
{ "user_id":"<uid>", "token":"<fcm token>", "platform":"ios|android", "app_type":"client", "is_active":true, "updated_at":"<ISO>" }
```

Also on `onTokenRefresh`. On sign-out:

```
PATCH /rest/v1/notification_tokens?user_id=eq.<uid>&token=eq.<fcm token>    { "is_active": false }
```

Table (`20260629300000_notification_system.sql:38`): `id, user_id, token, platform, app_type, is_active, created_at, updated_at, unique(user_id, token)`.
Errors are swallowed on both writes.

**Push payload the app expects** (FCM `data`): the same keys as the row — `type`, `category`, `id`, `action_url?`, `booking_id?`, `trip_id?`, `ticket_id?` — all strings. `notification.title/body` for display. Foreground messages are shown as a snackbar with a "view" action.

**Proposed .NET:** `PUT /api/v1/me/devices/{token} { platform, appType }` / `DELETE /api/v1/me/devices/{token}`; the backend sends FCM with the `data` keys above.

## Notes for the .NET team

1. Sending moves to the backend: every SQL `push_notification(...)` call site (booking received, payment review/approved/rejected, cancellation, trip lifecycle, refunds, tickets) must be reproduced as an application event that writes the inbox row **and** fans out to active `notification_tokens` of the user.
2. `action_url` is unused; routing is derived from `type` + `data`. Do not invent new `type` strings without checking `resolveNotificationDestination`.
3. Limit 100 on the inbox, no paging.
