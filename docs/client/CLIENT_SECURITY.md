# Client App — Security & Data Privacy

> Audited 2026-07-30 against the live database. Every finding below was measured,
> not inferred. Fixes landed in
> `supabase/migrations/20260730090000_client_trust_hardening.sql` and are
> re-verified by `supabase/tests/client_trust_regression.sql` (11 probes).

---

## 1. Threat model

The Client App ships two credentials:

- the **anon key**, embedded in every install — assume it is public;
- an **authenticated JWT** per signed-in rider — assume any rider is hostile.

Therefore: Flutter-side filtering is never a security boundary. Every rule below
is enforced by RLS or by a SECURITY DEFINER function.

---

## 2. Findings — fixed

### 2.1 🔒 `support_attachments` had RLS disabled — CRITICAL

```sql
select relrowsecurity from pg_class where relname = 'support_attachments';
-- false
```

The table carried two correct ownership-scoped policies. They had never been
enforced, because nobody ran `enable row level security`. `SELECT`, `INSERT` and
`UPDATE` were also granted to `anon`.

Consequences, all reachable:

- Anyone holding the shipped anon key could list every support attachment on the
  platform — `ticket_id`, `file_name` and `file_url`.
- Any signed-in rider could attach files to, or alter attachments on, anybody's
  ticket.
- The Client's own `SupabaseSupportDatasource.getTicketAttachments(ticketId)`
  filters on `ticket_id` alone and trusts RLS for ownership, so passing another
  rider's ticket id returned their files directly through the app.

**Fixed:** RLS enabled, `anon` revoked, and an office policy added mirroring
`support_tickets_office` so the Dashboard keeps its access.

### 2.2 🔒 Any rider could send any user a notification — CRITICAL

```sql
select policyname, roles, with_check from pg_policies
 where tablename = 'notifications' and cmd = 'INSERT';
-- "Service role insert notifications" | {public} | true
```

`INSERT` was granted to `anon` and `authenticated`, and the policy checked
nothing. Any rider could write a notification addressed to any other user with
an arbitrary title, body and `action_url`. Because both the in-app inbox and
`FcmService` navigate on notification content, this was a phishing primitive
pointed at the platform's own customers ("Payment rejected — tap to re-enter
your card").

`service_role` bypasses RLS outright and never needed the policy. Every
in-database writer (`push_notification`, `confirm_seat_booking_v2`,
`approve_payment`, the trigger engine, `platform_broadcast_notification`) is
SECURITY DEFINER and likewise unaffected.

**Fixed:** the `{public}` policy dropped and replaced with
`notifications_staff_insert`, gated on `current_office_id() is not null or
is_platform_admin()` — which is what the Dashboard's dispatch datasource runs as.
`anon` revoked. Two duplicate `{public}` SELECT/UPDATE policies removed.

### 2.3 🔒 Price tampering through legacy booking RPCs — CRITICAL

Three SECURITY DEFINER functions were still executable by `authenticated` and
inserted `operation_bookings.payment_amount` straight from a client parameter:

```
book_trip_seat(…16 args…)
confirm_seat_booking(…17 args…)
confirm_seat_booking_v2(… p_receipt_url)   -- the 19-arg overload
```

`20260710090000_authoritative_booking_pricing` made the *current* path resolve
the fare server-side, but it created a new function rather than replacing the old
ones. A rider could `POST /rest/v1/rpc/confirm_seat_booking` with
`p_payment_amount = 1` and hold a legitimate-looking booking the operator would
approve for 1 EGP.

The 19-arg `v2` overload did price server-side, but predates `20260713090000`'s
stop-id namespace fix and prices some stop pairs wrong. Two overloads of one name
is also an ambiguity trap for any future caller.

**Fixed:** all three dropped. Exactly one `confirm_seat_booking_v2` remains — the
22-arg version, whose body documents that `p_payment_amount` "is intentionally
never read past this point".

### 2.4 🔒 Public storage buckets were publicly writable — HIGH

`documents` and `vehicle-images` granted `INSERT`, `UPDATE` **and `DELETE`** to
`public`. No app in this repo uploads to either, so anyone holding the anon key
could overwrite or erase every vehicle photo and document on the platform.

**Fixed:** the six `{public}` write policies replaced with office-staff /
platform-admin policies. Public read is unchanged — vehicle photos still render.

---

## 3. Findings — open, with remediation

### 3.1 🔒 `trip_seats.passenger_id` is readable by anyone — MEDIUM

`trip_seats_marketplace_read` lets `anon` and `authenticated` read every seat row
of any listed trip, and the row carries `passenger_id`. Pick a trip id off
`public_trips`, read its seats, and you learn which user id occupies which seat —
i.e. who is travelling where, without an account.

Not fixed here because neither available mechanism is safe in isolation:

- **Column privileges** would break the Dashboard, which selects `trip_seats(*)`
  as the same `authenticated` role.
- **A view** would work for reads but kills the realtime signal Home subscribes
  to on `trip_seats`; views are not in the realtime publication.

**Recommended fix (Dashboard-side, one migration):** drop the column. It is fully
redundant — `trip_passengers.seat_id` covers every populated row:

```sql
select count(*) filter (where s.passenger_id is not null)                  as with_passenger,
       count(*) filter (where s.passenger_id is not null and p.id is null) as orphans
  from trip_seats s left join trip_passengers p on p.seat_id = s.id;
-- 5 | 0
```

### 3.2 🔒 `support-attachments` bucket is public-read — MEDIUM

`storage.buckets.support-attachments.public = true`, with a `{public}` SELECT
policy on `storage.objects`. Riders upload complaint photos and payment proof
there.

§2.1 removed the ability to **enumerate** the URLs through PostgREST, which was
the practical dump vector. The objects themselves remain readable to anyone who
has a URL, and `storage.list()` still walks the bucket.

**Recommended fix:** make the bucket private and switch both the Client
(`SupabaseSupportDatasource.uploadAttachment` → `createSignedUrl` instead of
`getPublicUrl`) and the Dashboard (`SupabaseTicketsDatasource`) to signed URLs,
mirroring what `payment-receipts` already does correctly. It is a two-app change,
which is why it is not bundled into a Client-scoped migration.

---

## 4. Verified correct

| Surface | Control |
|---|---|
| `operation_bookings` | `bookings_client_read/insert` scoped to `client_id = auth.uid()`; office policy scoped to `current_office_id()` |
| `booking_payments` | same shape; client sees only their own |
| `payment-receipts` bucket | **private**; per-user folder policy `(storage.foldername(name))[1] = auth.uid()`; dashboard read gated on role |
| `operation_trips` | **closed to clients entirely**; `public_trips` view is the only trip surface, and it omits `revenue`, `driver_id`, `vehicle_id`, `notes`, occupancy internals |
| `trip_live_locations` | RLS on, scoped through a definer helper; closed since `20260729090000` |
| `clients` | self-read/write only; offices see a customer only where a booking or subscription links them |
| `loyalty_*`, `referrals`, `subscriptions`, `transport_subscriptions` | `client_id = auth.uid()` |
| `support_tickets`, `refund_requests` | client-owns + office-scoped |
| `trip_events` | passenger read is scoped to trips they booked; clients hold no insert |
| Paymob secrets | only in the Edge Function via Supabase secrets; the app receives a `checkout_url` and nothing else |
| Card settlement | believed only from our own DB (`card_payment_state`), never from the WebView's return value — that redirect is a URL the rider's device can rewrite |

## 5. Re-running the audit

```bash
supabase db query --linked -f supabase/tests/client_trust_regression.sql
```

Every row must read `OK`. `STILL EXPLOITABLE` or `BROKEN` is a regression.
