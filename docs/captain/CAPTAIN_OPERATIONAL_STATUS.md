# Captain App — Operational Status

> **Phase 5 audit, 2026-07-28.** Feature-by-feature verdict against the live database.
>
> **Verification at time of writing.** `flutter analyze lib` → **0 issues**.
> `flutter test test/apps/captain` → **284 passing**.
> `supabase/tests/captain_authority_regression.sql` → 6 must-work paths OK, 17 exploits
> blocked, cross-driver isolation clean.
>
> **Companions.** [`CAPTAIN_LIFECYCLE.md`](CAPTAIN_LIFECYCLE.md) ·
> [`CAPTAIN_USER_STORIES.md`](CAPTAIN_USER_STORIES.md) ·
> [`CAPTAIN_USER_FLOWS.md`](CAPTAIN_USER_FLOWS.md)

Categories — **Completed** · **Completed with limitations** · **Bug found and fixed** ·
**Bug found — unresolved** · **Missing** · **Future recommendation**

---

## 1. Status matrix

| Feature | Status | Bugs this phase | Risk | Recommendation |
| --- | --- | --- | --- | --- |
| Authentication | Completed | — | Low | — |
| Session & identity | Completed | — | Low | Server-resolved, fails closed on deactivation |
| Onboarding / access request | Completed | — | Low | — |
| Today / assigned trips | Completed | — | Low | — |
| Trip state machine | Completed | — | Low | Allowlist binding on both wrappers; raw setter ungranted |
| Trip execution UI | Completed | — | Low | — |
| Passenger manifest | **Bug found and fixed** | BUG-503 | Low (was High) | Captain may now only set status, on non-terminal riders |
| Live tracking — pipeline | Completed with limitations | — | **Medium** | Foreground-only remains the top product gap |
| Live tracking — health UX | **Bug found and fixed** | BUG-505 | Low (was Medium) | Health now derived from fix freshness |
| Live tracking — write path | **Bug found and fixed** | BUG-504 | Low (was **Critical**) | `anon` DML revoked; authorship enforced by trigger |
| Live tracking — read path | Completed with limitations | — | **Medium** | R1 still open: positions readable platform-wide |
| Navigation to stop | Completed | — | Low | Platform-correct, failure surfaced |
| Incidents & SOS | **Bug found and fixed** | BUG-501 | Low (was **Critical**) | Captain can no longer resolve or delete own report |
| Audit trail (`trip_events`) | **Bug found and fixed** | BUG-502 | Low (was High) | Append-only to the captain; lifecycle codes reserved |
| Communication — authorship | **Bug found and fixed** | BUG-506 | Low (was Medium) | `sender_type` no longer client-assertable |
| Communication — ops banner | **Bug found and fixed** | BUG-507 | Low (was Medium) | De-duplicates on identity, not text |
| Notifications — delivery | Completed | — | Low | — |
| Notifications — tap routing | **Bug found and fixed** | BUG-508 | Low (was High) | `/trips` alias added; the most common push no longer throws |
| Notifications — deep link to a trip | **Missing** | — | Low | `action_url` plumbed but unconsumed; see §4 |
| Trip history | Completed | — | Low | — |
| Profile / theme | Completed | — | Low | — |
| Arabic RTL & responsive | Completed | — | Low | Covered at 3 widths × 3 font scales |
| Offline resilience | Completed with limitations | — | Low | No queue by design; nothing lost, only delayed |
| Earnings / payout | **Missing** | — | — | Future recommendation — needs a payout model |
| Document-expiry reminders | **Missing** | — | — | Future recommendation — data already on the profile |
| Emergency escalation | **Missing** | — | **Medium** | SOS files a form; nothing pages a human |

---

## 2. Defects found and fixed this phase

Every exploit was proven against the linked database while impersonating a real captain,
inside `BEGIN … ROLLBACK`, **before** the fix was written, and re-verified after.

### BUG-501 — A captain could close or delete their own SOS · **Critical, security**

`driver_trip_reports_captain_rw` was `FOR ALL`, gated only on `driver_id = current_driver_id()`.

- **Proven:** `UPDATE … SET status='resolved'` → *EXPLOITABLE — 1 row(s) updated*;
  `DELETE` → *EXPLOITABLE — evidence destroyed*.
- **Impact:** the incident lifecycle added in `20260727090000` exists so a human operator
  takes ownership of an alarm. A captain could take an SOS out of the queue before any
  operator saw it, or remove the record that it was ever raised. This is precisely the
  failure the queue exists to prevent.
- **Also:** filing was scoped only by driver, not by trip — a captain could attach a report
  to **any** trip id on the platform, including another office's.
- **Fix:** captain policies split into SELECT (own) + INSERT (own trip, `status = 'pending'`).
  No UPDATE, no DELETE. Triage stays with operations.
- **Verified:** self-resolve and delete both *blocked*; filing on a foreign trip and filing
  pre-resolved both *blocked*; filing a normal incident still *OK*.

### BUG-502 — A captain could forge and delete the trip audit trail · **High, integrity**

`trip_events_captain_rw` was `FOR ALL`.

- **Proven:** inserting a row with `event_code='trip_departed'` → *EXPLOITABLE — forged*;
  deleting an audit row → *EXPLOITABLE — audit row destroyed*.
- **Impact:** `20260727160000` made `trip_events` the trip's authoritative audit trail and
  Live Ops reads it. A captain could fabricate a departure record or erase a real one.
- **Fix:** SELECT (own trips) + INSERT restricted to non-lifecycle `event_code`. The five
  codes `update_trip_status` writes are reserved; the captain's own narrative rows take the
  column default `'other'` and are unaffected.
- **Near-miss worth recording:** the first draft required `event_code IS NULL`. The column is
  `NOT NULL DEFAULT 'other'`, so that rule would have blocked **all** station-arrival
  marking. The dry run caught it before it reached the database.

### BUG-503 — A captain could erase or rewrite the manifest · **High, integrity**

`trip_passengers_captain_rw` was `FOR ALL`.

- **Proven:** `DELETE FROM trip_passengers WHERE trip_id = <own>` → *EXPLOITABLE — 1
  passenger(s) erased*.
- **Impact:** the manifest is the record of who paid to be on the vehicle, and completing a
  trip converts it into completed/no-show outcomes. A captain could delete a paying rider,
  invent one, or rewrite a rider's name, phone or seat.
- **Fix:** SELECT + UPDATE only. The update policy's `USING` excludes `cancelled` and
  `completed` riders (so a cancelled booking cannot be boarded — previously only a UI guard),
  its `WITH CHECK` restricts new values to `reserved`/`confirmed`/`no_show`, and
  `enforce_captain_manifest_scope()` restricts the **columns** a captain may change, which
  RLS cannot express.
- **Verified:** boarding a rider still *OK*; rewriting a phone → `captain_may_only_set_passenger_status`;
  cancelling a rider and deleting the manifest both *blocked*. The completion cascade
  (boarded → `completed`, unboarded → `no_show`) still runs correctly through the new guards.

### BUG-504 — Anyone with the anon key could forge or erase every vehicle position · **Critical, security**

`trip_live_locations` runs without RLS by design so realtime delivery works — but `anon`
held `INSERT`, `UPDATE`, `DELETE` and `TRUNCATE` on it.

- **Proven:** as `anon`, the table was fully writable and 14 live fixes were readable.
- **Impact:** the anon key ships inside the client app. Erase the table and every customer's
  tracking map goes dark mid-trip; insert rows and a customer watches their bus drive
  somewhere it is not. This is the most customer-visible surface in the product.
- **Fix:** write DML revoked from `anon`; `UPDATE`/`DELETE`/`TRUNCATE` revoked from
  `authenticated` (positions are append-only). `enforce_live_location_authorship()` now
  stands in for the missing policy on the write path: the caller must be an active captain,
  must own the trip, and `driver_id` is **overwritten** with the server-resolved value.
- **Read path deliberately untouched** — `SELECT` still open to both roles, so realtime
  delivery is unchanged. Verified after applying: anon writes *blocked*, anon reads *OK*.

### BUG-505 — The tracking card claimed a cadence it was not achieving · **Medium, UX**

The card said "مشاركة الموقع تلقائياً كل 30 ثانية" for as long as a `Timer` existed.

- **Impact:** a captain in a tunnel, or whose location permission was revoked mid-trip, read
  a card promising the client's map was live while every send had failed for twenty minutes
  — with the GPS card *directly beneath it* saying "قديم". Two cards on one screen
  disagreeing about the same fact.
- **Fix:** `LocationSharingStatus.evaluate` derives health from the age of the last landed
  fix — off / acquiring / live / stale — and the card renders that, ticked so it notices
  staleness while the captain is looking at it. The threshold is `kAutoLocationInterval × 3`,
  derived from the cadence so the two cannot drift apart.
- **Covered by** 10 new domain tests including both sides of the boundary.

### BUG-506 — A captain could post as operations · **Medium, integrity**

`captain_messages_driver` was `FOR ALL` with no constraint on `sender_type`.

- **Proven:** inserting `sender_type='operations'` into the captain's own thread → *EXPLOITABLE*.
- **Impact:** `sender_type` is exactly what the app reads to decide authorship. A captain
  could fabricate what reads on both ends as an instruction from the office, and could edit
  or delete messages operations had already sent.
- **Fix:** SELECT (own trips) + INSERT with `sender_type = 'driver'` **and**
  `sender_id = auth.uid()`. No UPDATE or DELETE — neither side of an operational thread may
  be rewritten after the fact.

### BUG-507 — A repeated instruction from operations never reached the captain · **Medium, functional**

The ops banner suppressed any message whose **body text** matched the last one shown.

- **Impact:** an operator sending "قف عند المحطة القادمة" a second time — which almost
  always means the first was not acted on — produced no banner at all.
- **Fix:** the stream now carries the row id (`OpsBroadcast`), and de-duplication is on
  identity. The same row re-emitted is still one announcement; a genuinely new message with
  identical text is two.
- **Test correction:** the existing test asserted the buggy behaviour ("the same body twice
  is one announcement"). It was rewritten to the correct contract and a new test added for
  the repeated-instruction case.

### BUG-508 — The most common push notification threw on tap · **High, functional**

`FcmService._onTap` calls `pushNamed(action_url)` verbatim.
`on_operation_trip_change` stamps `action_url = '/trips'` on the captain's
"تم إسنادك لرحلة جديدة" notification — the push a captain receives most often.
`/trips` matched no captain route, so `CaptainAppRouter.generateRoute` returned `null` and
Flutter threw *"Could not find a generator for route"*.

- **Fix:** `CaptainRoutes.assignmentAlias` maps `/trips` onto the captain shell, following
  the precedent already set in `ClientRoutes._serverAliases` for the same class of bug.
  Resolved in the router rather than by rewriting the trigger, because rows carrying the
  string already exist.
- **Guard:** a test asserts a genuinely unknown path still returns `null`, so the alias
  cannot quietly become a catch-all.

---

## 3. What was already correct

Not claimed as this phase's work — verified and left alone:

- **The trip state machine and its authority model.** The status allowlist
  (`20260723090000`) is applied and binding on **both** wrappers, and `update_trip_status`
  is not granted to `authenticated`. Crafted `cancelled`, crafted `open_for_booking` and the
  raw setter were all refused.
- **Cross-driver and cross-office isolation.** Reads of another driver's trip and manifest
  returned 0 rows; moving another driver's trip raised `not_your_trip`.
- **Identity resolution.** Server-derived throughout, filtered on `status = 'active'`, with
  no client-supplied `driver_id` or `office_id` anywhere.
- **No direct writes to `operation_trips`** from the Captain App — the write-authority
  trigger added in Phase 3 was never at risk of breaking it.
- **The 30-second cadence, its start/stop conditions, and its scroll survival.**
- **Navigation.** Coordinates validated, platform-correct URLs, and `launchUrl`'s two
  distinct failure modes both handled.
- **Every docked action corresponds to a real backend transition** — no fake buttons, no
  controls offering a transition the state machine would reject.
- **Arabic RTL and responsive layout**, including the docked-bar height invariant across
  every stage at font scales 1.0 / 1.3 / 1.6.

---

## 4. Open items

| Ref | Item | Severity | Note |
| --- | --- | --- | --- |
| R1 | `trip_live_locations` readable platform-wide | **Medium** | Unchanged. The **write** hole is closed; reads stay open so realtime delivery is not risked. Closing it means enabling RLS, which cannot be proven safe for delivery from a SQL session. |
| R2 | Foreground-only location | **Medium** | The largest tracking-fidelity gap and the most customer-visible. Needs an Android foreground service and iOS background modes. |
| R3 | No emergency escalation | **Medium** | SOS files a report and waits for it to be read. |
| R4 | No notification deep link into a trip | Low | `action_url` and `data.trip_id` reach the domain entity and are dropped; an in-app tap only marks read. Needs a load-trip-by-id path. |
| R5 | Trip chats page lists only the broadcast thread | Low | Per-passenger threads work but are reachable only from the manifest. |
| R6 | No voice/photo attachments | Low | The placeholder controls were removed; real media needs storage and upload. |
| R7 | `AssignedTripStatus` has no `cancelled` member | Low | Unreachable today — the trips query filters cancelled out — but `_status()` maps the value to `scheduled`, so if the filter ever widens a cancelled trip would render as "awaiting release" with a live boarding button. |
| R8 | Onboarding form and chat details lack widget tests | Low | Neither carries complex logic. |

---

## 5. Test coverage

**284 passing** (from 265, of which 1 was failing before this phase).

| Added this phase | Covers |
| --- | --- |
| `features/live_location/location_sharing_health_test.dart` | Health from freshness: off / acquiring / live / stale, both sides of the boundary, threshold derived from the cadence, Arabic age formatting |
| `captain_notification_route_test.dart` | The backend's `/trips` action_url resolves; unknown paths still return null |
| `features/communication/captain_communication_test.dart` (extended) | A repeated operations instruction reaches the captain both times |

Existing coverage retained: auth, onboarding, assigned trips, trip execution (all six stages
× three widths × three font scales), docked-bar height invariant, manifest, live-location
cadence and scroll survival, communication authorship and replay suppression, incidents,
notifications, trip history, profile, theme, RTL direction rules.

**Database:** `supabase/tests/captain_authority_regression.sql` — 25 assertions, transactional,
self-cleaning.

---

## 6. Database changes

| Migration | Status | Content |
| --- | --- | --- |
| `20260728120000_captain_authority.sql` | **Applied and verified** | Captain policies on `driver_trip_reports`, `trip_events`, `trip_passengers`, `captain_messages`; manifest column trigger; `trip_live_locations` write revokes + authorship trigger |

Applied after a full dry run under `BEGIN … ROLLBACK` with 19 assertions, which caught one
regression (the `event_code IS NULL` rule) before it reached the database. The office and
dashboard paths — incident acknowledge/resolve, manifest edit and delete, live-fix reads,
messaging — were tested under office impersonation and are unaffected. No production data was
modified: every exploit proof and rehearsal ran inside a rolled-back transaction.

---

## 7. Recommended next phase

**Phase 6 — Client tracking and the trip_live_locations read path (R1).**

The captain side of tracking is now trustworthy: the cadence is verified, health is honestly
reported, and the write path is authenticated and owned. The remaining risk is entirely on
the **read** side, and it is the last open item on the platform's most customer-visible
feature. It needs what this phase could not do from a SQL session — a real subscribed client
— to prove that enabling RLS preserves realtime delivery.

Doing it as its own phase also lets R2 (background location) be evaluated against real client
complaints about map staleness, since both land on the same surface.
