# Captain — User Stories

> **Scope.** What a captain needs from the app, as stories with acceptance criteria that
> match what the system actually does on **2026-07-28**. A story marked ❌ is not
> implemented and says so; nothing here describes intent as if it were behaviour.
>
> **Companions.** [`CAPTAIN_LIFECYCLE.md`](CAPTAIN_LIFECYCLE.md) ·
> [`CAPTAIN_USER_FLOWS.md`](CAPTAIN_USER_FLOWS.md) ·
> [`CAPTAIN_OPERATIONAL_STATUS.md`](CAPTAIN_OPERATIONAL_STATUS.md)

Legend — ✅ implemented and verified · 🟠 implemented with a stated limitation · ❌ not built.

---

## 1. Access and identity

**✅ As a captain, I want to sign in with my phone number, so that I can start work without
being handed credentials by the office.**
- Phone + password; the session persists across app restarts.
- "Remember me" survives sign-out and is independent of the session itself.
- The phone field renders LTR inside the otherwise RTL layout.

**✅ As a captain, I want to stay signed in between shifts, so that I am not re-authenticating
at 5am at a depot with bad signal.**
- The Supabase session is restored at launch; identity is re-resolved from it server-side.
- No captain identity is cached locally, so a second captain on the same device never
  inherits the first one's trips.

**✅ As a new captain, I want to request access to an office myself, so that I can be onboarded
without a back-office account being created for me first.**
- Join code identifies the office and is authoritative.
- The request lands in the dashboard for approval; the app polls activation every 20 s.
- A rejected or pending request keeps the captain out of the operational shell.

**✅ As an operations manager, I want a deactivated captain to lose access immediately, so that
a dismissed driver cannot open a manifest tomorrow.**
- `current_driver_id()` filters `status = 'active'`; deactivation takes effect on the next
  request, with no cached identity to outlive it.

---

## 2. Seeing the day

**✅ As a captain, I want to see the trip I am on and the ones still ahead of me, so that I know
what my day looks like.**
- Today's assigned trips plus today's already-completed ones, so a finished day shows a
  summary rather than "no trips assigned".
- A focus card for the next trip with a live countdown to departure.

**✅ As a captain, I want to be told when a new trip is assigned to me, so that I do not have to
keep re-opening the app.**
- Push notification "تم إسنادك لرحلة جديدة", plus an in-app new-assignment banner backed by
  a locally tracked seen-set.
- Tapping the push lands on the captain shell (this route was broken until 2026-07-28).

**✅ As a captain, I want the trip list to update itself, so that a change made by the office
reaches me without a manual refresh.**
- Realtime subscription on `operation_trips` filtered to this driver, plus the tables that
  change a trip's counts.

---

## 3. Running a trip

**✅ As a captain, I want one obvious action at every point in the trip, so that I am not hunting
for a button while sitting at the wheel.**
- A single docked action bar: board → depart → complete.
- The bar holds one height across every stage and font scale, so the page never reflows
  under the captain's thumb at the moment they are reaching for it.

**✅ As a captain, I want to be stopped from starting a trip that operations has not released,
so that I do not tap something whose only outcome is an error.**
- `scheduled` renders a disabled panel naming what is being waited on, because the backend
  rejects `scheduled → boarding` outright.

**✅ As a captain, I want boarding to open only when departure is actually near, so that a trip
published this morning is not "boardable" all day.**
- The boarding window opens 30 minutes before departure; before that the panel says so and
  arms itself without the captain leaving the screen.

**✅ As a captain, I want ending a trip to require confirmation, so that one mis-tap on a bumpy
road cannot close it.**
- A confirm dialog guards `complete`, and the action is stated as irreversible.

**✅ As a captain, I want to know my trip was cancelled by the office, so that I stop driving to
a pickup nobody is waiting at.**
- Push notification, the execution screen falls to a terminal `cancelled` label, and
  position reporting stops on the same transition.

**❌ As a captain, I want to cancel a trip I cannot run.** *Not built, deliberately.*
Cancellation releases seats and cancels bookings; it is an operations decision with
financial consequences. The captain reports the problem instead (§6).

---

## 4. Passengers

**✅ As a captain, I want the list of who is booked on this trip, so that I know who I am waiting
for at each stop.**
- Name, seat, pickup and drop-off point, phone, and current boarding state.
- Search and status filters that survive a realtime refresh.

**✅ As a captain, I want to mark who boarded and who did not, so that the office and the fare
record reflect what actually happened.**
- Boarded / waiting / absent, applied optimistically and reconciled with the server.
- Completing the trip turns everyone the captain never boarded into a no-show, which is what
  makes this the financially meaningful act it is.

**✅ As a captain, I want to be unable to board a rider whose booking was cancelled, so that the
manifest cannot record a contradiction.**
- The control is hidden in the UI *and* refused by the database — a cancelled or completed
  rider is outside the update policy's `USING` clause.

**✅ As a captain, I want to call a passenger who has not shown up, so that I am not holding the
vehicle on a guess.**
- Direct dial from the passenger card, plus a per-passenger chat thread.

---

## 5. Being tracked

**✅ As a passenger, I want to watch the vehicle move on a map, so that I know when to be at my
stop.**
- The captain's app publishes a high-accuracy fix every 30 s for the whole time the trip is
  `in_progress`.

**✅ As a captain, I want to know whether my position is actually reaching the office, so that I
am not surprised by a phone call asking where I am.**
- The reporting card states health derived from the age of the last landed fix, not from
  whether a timer is running: live / acquiring / stale, with the failure reason inline.
- The GPS card independently reports the stored fix's age.

**✅ As a captain, I want to send my position on demand, so that I can answer "where are you
now?" without waiting for the next tick.**
- A manual send button alongside the automatic cadence.

**✅ As a captain, I want a clear instruction when location is unavailable, so that I can fix it
myself.**
- Distinct Arabic messages for: location services off, permission denied, permission
  permanently denied (with a pointer to app settings), and no vehicle assigned.

**🟠 As a captain, I want tracking to keep working with the phone in my pocket.** *Foreground
only.* No background location permission is claimed, so reporting stops when the app is
backgrounded or the screen locks. This is the largest remaining gap in tracking fidelity and
the most customer-visible one.

---

## 6. Incidents and emergencies

**✅ As a captain, I want to raise an emergency without navigating a menu, so that help is one
gesture away.**
- A three-second armed hold on the docked bar, visually and functionally distinct from a
  normal report, reachable without scrolling while the trip is underway.

**✅ As a captain, I want my report to be confirmed as sent, so that I am not left wondering.**
- Explicit confirmation on submit; a failure never reports success.

**✅ As an operations manager, I want an incident a captain filed to be impossible for them to
withdraw, so that the queue reflects everything that was raised.**
- Reports enter as `pending` and the captain has no `UPDATE` or `DELETE` path. Acknowledge,
  resolve and dismiss are operator verdicts. *Both self-resolution and deletion were possible
  until 2026-07-28.*

**❌ As a captain, I want an emergency to actually page someone.** *Not built.* SOS files a
report and waits for it to be read. Real escalation — a call placed, ops paged, location
pinned — is the top safety recommendation.

---

## 7. Talking to operations

**✅ As a captain, I want to message operations from inside the trip, so that I am not switching
to a phone call while driving.**
- Trip-scoped threads: a broadcast to all passengers, and per-passenger threads from the
  manifest.

**✅ As a captain, I want my own messages to appear as mine, so that a thread reads correctly.**
- Authorship travels as structured data from the row's `sender_type`, never re-derived from
  a display name.

**✅ As a captain, I want an instruction from operations to reach me even if they have said it
before, so that a repeated instruction is not swallowed as a duplicate.**
- The banner de-duplicates on message **identity**, not text. *Repeated instructions were
  suppressed until 2026-07-28.*

**✅ As a captain, I do not want yesterday's broadcast announced at me on every launch.**
- The stream's first replayed emission is taken as the "already seen" baseline.

**❌ As a captain, I want to send a voice note or a photo.** *Not built.* The two controls
that appeared to do this posted literal placeholder text and were removed; the message types
remain so historical rows still render.

---

## 8. After the trip

**✅ As a captain, I want to review the trips I have driven, so that I can check what happened on
a given day.**
- Searchable history with date filters and stop-by-stop detail.

**✅ As a captain, I want my profile, vehicle and verification state in one place.**
- Driver profile with metrics, vehicle, verification status, appearance and sign-out.

**❌ As a captain, I want to see what the day earned me.** *Not built; needs a payout model
first.* The most-requested feature in comparable products and a retention lever.

**❌ As a captain, I want to be warned before my licence or vehicle papers expire.** *Not
built.* The expiry data is already on the profile, so this is cheap.
