# Captain App — Feature Catalogue, User Stories & User Flows

> **Scope.** The Captain flavor of the EWT platform — `lib/apps/captain`, entry
> `lib/apps/captain/main.dart`, run with `--flavor captain`. Arabic-only, RTL-native.
>
> **Audience.** Product, operations and engineering. This document describes *what the
> app does and why*, in the language of the person using it. For architecture, security
> and the production-readiness audit see [`CAPTAIN_APP.md`](CAPTAIN_APP.md); for the
> delivery status of each feature see [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md).
>
> **Also in this set.** [`CAPTAIN_APP_USER_FLOWS.md`](CAPTAIN_APP_USER_FLOWS.md) (journeys
> as flow diagrams) · [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) (defect register) ·
> [`CAPTAIN_APP_RECOMMENDATIONS.md`](CAPTAIN_APP_RECOMMENDATIONS.md) (what to build next) ·
> [`CAPTAIN_APP_BUSINESS_SERVICES.md`](CAPTAIN_APP_BUSINESS_SERVICES.md) (what the platform
> could be sold as).
>
> **Last revised.** 2026-07-23 (third audit pass — see the bug register for what changed).

---

## 1. Who the captain is

The captain is a bus driver working for one transport office. They are:

- **On a phone, one-handed, often in daylight and often moving.** Every primary action
  is in the thumb zone; nothing critical is behind a scroll.
- **Not an operations user.** They cannot publish, price, cancel or reassign a trip.
  They execute the trip that operations gave them.
- **Bound to exactly one office.** Their identity, their trips and their message threads
  are all scoped to it, server-side.
- **Arabic-first.** The app is RTL-native, not a translated LTR layout.

The captain's day has one shape: *see today's trips → run the current one → close it out
→ repeat*. The app is built around that arc, and the home tab is named after it (**اليوم**).

---

## 2. Feature map

| # | Feature | Entry point | Purpose |
| --- | --- | --- | --- |
| 1 | Splash & routing gate | app launch | Decide which root the captain lands on |
| 2 | Authentication | login screen | Phone sign-in, remembered phone |
| 3 | Onboarding / access request | "كابتن جديد؟" | Self-service join, office-approved |
| 4 | Session & identity | implicit | Resolve *which driver / which office*, server-side |
| 5 | Today (assigned trips) | tab **اليوم** | The day's work, and the one trip to act on now |
| 6 | Trip execution | focus card → open | Run the trip: board, depart, complete |
| 7 | Passenger manifest | trip tools / trip card | The boarding door — who is aboard |
| 8 | Live location sharing | automatic while underway | Feed the client's tracking map |
| 9 | Report to operations | trip tools | Post a progress note to ops |
| 10 | Incidents & SOS | trip tools / SOS hold | Raise a problem or an emergency |
| 11 | Communication | trip tools / manifest | Captain ↔ operations, captain ↔ passenger |
| 12 | Notifications | bell on home | Assignments and announcements |
| 13 | Trip history | tab **السجل** | What was driven, and when |
| 14 | Profile | tab **حسابي** | Identity, vehicle, metrics, appearance, sign out |

---

## 3. Feature detail

Each feature below is given as: **user story → flow → screens → what the backend does →
rules worth knowing.**

### 3.1 Splash & routing gate

> **As a captain**, I want the app to open on the right screen without asking me
> anything, so that starting my day takes one tap.

**Flow**

```
Launch
 ├─ Supabase auth session present ─────────────► App shell (اليوم / السجل / حسابي)
 ├─ Local approved session only ───────────────► Welcome home
 │                                                └─ keeps retrying sign-in, swaps
 │                                                   into the shell on success
 ├─ A submitted access request ────────────────► Onboarding, resumed at "pending"
 └─ None of the above ─────────────────────────► Login (with a request-access entry)
```

**Rules**

- The gate is the app's only route guard. There are no per-route guards, because there is
  no reachable screen worth guarding once the root is correct.
- A sign-out drops the local session too, so the welcome-home upgrader cannot
  immediately sign the captain back in.

---

### 3.2 Authentication

> **As a returning captain**, I want to sign in with my phone number and stay signed in,
> so I am not re-authenticating on a bus every morning.

**Flow**

```
Login screen
  → phone + password
  → sign_in_captain
  → session established → app shell
  ✗ wrong credentials → inline Arabic error, field keeps focus
```

**Rules**

- **"Remember me"** caches the phone number locally. It is deliberately decoupled from
  sign-in itself, so the onboarding activation poll cannot clobber it.
- **Sign-out never clears the remembered phone.** Signing out is not "forget me".
- Sessions survive relaunch; the driver and office are re-resolved server-side rather
  than trusted from the device.
- The phone field is forced LTR while name fields follow the app's RTL — a phone number
  is an identifier, not prose.

---

### 3.3 Onboarding / access request

> **As a new captain**, I want to request access myself and be told where my request
> stands, so I am not waiting on a phone call to find out.

**Flow**

```
"كابتن جديد؟"
  → Request form: name, phone, office pick + join code
  → submit_captain_request → captain_requests row (pending)
  → Pending view ("طلبك قيد المراجعة")
      │
      ├─ Dashboard approves → activation poll (every 20 s) picks it up
      │                        → driver row active → operational session → shell
      └─ Dashboard rejects  → Rejected view → re-apply
```

**Rules — join codes**

- **The join code is authoritative.** If the code and the picked office disagree, the
  request is refused (`office_code_mismatch`) — a tampered office id cannot ride along
  with a valid code.
- A code matching no active office → `invalid_office_code`.
- More than one active office and **no** code → `office_code_required`. The server refuses
  to guess which queue a request belongs in.
- A single active office → the code is optional, for older builds.
- The public office directory the picker reads **excludes** join codes.

**Rules — approval**

- Onboarding cannot be bypassed. Without an active driver row bound to the auth user,
  no session resolves and no trips load.
- **A captain cannot approve themselves.** Approval is an office-user action in the
  Dashboard, under office-scoped access rules.

---

### 3.4 Session & identity

> **As the business**, I need every captain action to be attributable to the right driver
> and the right office, and I cannot rely on the phone to tell me which.

**Rules**

- Identity is **server-resolved, never client-supplied**. Every operation that needs to
  know "which driver / which office" resolves it from the authenticated user on the
  server.
- **Fails closed.** If the caller is not a driver, or the office is not active, identity
  resolution yields nothing and the captain is routed to login — it does not error into
  a half-working session.
- A second captain signing in on the same device cannot inherit the first's identity.
- Sign-out clears the cached identity **whether or not the network call succeeds**, so a
  failed sign-out cannot strand the device holding a stale captain.

---

### 3.5 Today — assigned trips (tab **اليوم**)

> **As a captain starting my shift**, I want to see the one trip I should act on now,
> with the rest of the day below it, so I don't have to work out what's next.

**Flow**

```
Open app → اليوم
  ├─ Focus card: the current or next trip, with a live countdown
  │    └─ "متابعة الرحلة" → Trip execution
  ├─ Day summary strip: trips, passengers, last arrival
  ├─ Quick actions (manifest / send location / report)
  ├─ Remaining trips, each openable, each offering the manifest
  └─ All trips done → "أحسنت، أنهيت رحلات اليوم" + next-trip prompt
```

**Rules**

- The list is **live**: new assignments arrive without a pull-to-refresh, and a banner
  announces them. A "seen trips" cache means the banner marks what is genuinely new
  rather than re-announcing the same trip each time the screen rebuilds.
- Completed trips never offer a "start" action — only the manifest.
- The focus card's countdown ticks locally; the stage it derives is recomputed from the
  clock, so a trip arms itself for boarding without the captain leaving and returning.

---

### 3.6 Trip execution

> **As a captain running a trip**, I want exactly one obvious next action at all times,
> and I want it reachable with my thumb without scrolling.

**The stage ladder**

```
awaitingRelease   (scheduled)              — operations hasn't published it yet
      │ operations publishes
awaitingWindow    (open_for_booking, > 30 min before departure)
      │ clock reaches departure − 30 min
readyToBoard      (open_for_booking, inside the window)
      │ captain: "بدء صعود الركاب"
boarding
      │ captain: "بدء الرحلة"
underway  ──────► finished    (captain: "إنهاء الرحلة", confirmed)
      └─────────► cancelled   (operations only — terminal)
```

**Screen anatomy**

| Region | Contents |
| --- | --- |
| Canopy | Stage colour + name, route, vehicle & plate, boarding/passenger facts |
| Next-stop banner | The stop the captain has not yet reported arriving at |
| Route timeline | Every stop, with arrivals marked |
| GPS status card | Whether position sharing is live, and the last fix |
| Tools | Manifest · Communication · Send location · Report to ops · Incident |
| Docked action bar | The stage's one action, plus SOS while underway |

**Rules**

- **The watch stream is the source of truth.** The screen subscribes to live changes on
  the trip, its passengers, its events and its location fixes. Counts and status never
  freeze at their tapped-in values; local state is optimistic only for the instant of
  button feedback and the stream corrects it.
- **Transitions are validated server-side.** The captain's status call asserts they own
  the trip before applying the change, and the transition graph rejects illegal moves.
  Ownership failures, unknown trips and illegal transitions each produce a distinct
  Arabic message.
- **Waiting stages are explained, not greyed out.** When the captain cannot act, the bar
  says what is being waited on ("بانتظار نشر الرحلة", "بانتظار موعد الصعود") rather than
  showing a dead button.
- **The docked bar holds one height at every stage**, including at enlarged system fonts,
  so a transition never reflows the page under the captain's thumb.
- **Completing is confirmed.** It is terminal and irreversible, so one mis-tap on a bumpy
  road cannot end a trip.
- **Station arrivals** write the same canonical event marker the Dashboard uses, so all
  three apps read one source of truth.

---

### 3.7 Passenger manifest

> **As a captain at the door**, I want to know who has boarded, who is still expected,
> and how to reach the person who hasn't shown up.

**Flow**

```
Trip tools → "كشف الركاب"
  ├─ Boarding tallies + progress bar (صعد / بانتظار / غائب / المتوقعون)
  ├─ Search by name, seat or pickup point
  ├─ Filter by status
  └─ Passenger card
       ├─ tap status → sheet → صعد / بانتظار / غائب
       ├─ call  (disabled when the booking carries no number)
       └─ chat  → per-passenger thread
```

**Rules**

- Statuses are exactly the ones the backend can store. A "late" status was removed
  because the column had nowhere to keep it — the card flipped, then the live refresh
  silently flipped it back. *A status the backend cannot hold is not a status.*
- **Cancelled bookings are not counted as people to wait for.** Boarding progress is
  measured against those actually expected, so a trip whose only absentees are
  cancellations reads as fully boarded — which it is.
- A passenger with no phone number gets a **disabled** call button, not a button that
  opens the dialer on nothing.
- "Nothing matched your search" and "nobody booked this trip" are different messages,
  because the captain acts differently on each.

---

### 3.8 Live location sharing

> **As a passenger's family**, I want the tracking map to keep moving.
> **As a captain**, I don't want to think about it.

**Flow**

```
Trip becomes underway
  → auto-sharing starts (kept alive for the whole trip)
     → immediate first fix, then one every 30 seconds
        → permission + service check
        → position acquired (high accuracy, 20 s limit)
        → fix written with the server-resolved driver and vehicle
  → trip completes / captain leaves the screen → sharing stops
```

**Rules**

- **Cadence: 30 seconds**, matching the platform tracking cadence. The client's map
  merges live inserts with a short poll fallback, so a denser producer cadence only
  sharpens the movement.
- **Starting twice does not double the rate** — the start is idempotent.
- A tick that overlaps a slow fix on bad signal is **skipped, not queued**.
- **An automatic failure is not a dead end**: the last good fix stays on screen, the
  reason is shown inline, and the next tick retries by itself. Permission denied,
  permanently denied, and location-services-off each say something different.
- The captain can also **send a fix manually at any time** — for when a passenger on the
  phone asks "where are you now?" and a 30-second-old fix isn't good enough.
- **Foreground only.** See the limitation in [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md).

---

### 3.9 Report to operations

> **As a captain**, I want to tell operations where I am without calling them.

**Flow**

```
Trip tools → "إبلاغ العمليات"
  → pick one: في الطريق إلى نقطة الانطلاق / وصل إلى نقطة الانطلاق / وصل إلى الوجهة
  → a note is posted to the trip's event log
```

**Rules**

- This is **a message, not a state change**, and the screen says so. It writes a
  narrative event; it does not move the trip's stage.
- The three options that shadow a real lifecycle transition (boarding, departed,
  completed) are deliberately **absent** — those are performed by the execution screen's
  primary action. Offering a look-alike here invited the captain to file the wrong one.

---

### 3.10 Incidents & SOS

> **As a captain in trouble**, I want help reachable in one gesture, and I don't want to
> raise it by accident.

**Flow**

```
Underway → SOS button (docked, beside the primary action)
  → press and hold 3 seconds (a ring fills as it arms)
  → Incident form, pre-set to "طوارئ"
  → describe → send → confirmation → back to the trip

Trip tools → "بلاغ طارئ"
  → same form, type chosen by the captain
    (مشكلة مع راكب / مشكلة في المركبة / تأخير / طوارئ / انسداد الطريق / أخرى)
```

**Rules**

- **The SOS is a deliberate hold, not a tap.** A plain tap explains the gesture instead
  of firing it — an SOS is not something to trip over on a bumpy road.
- It is **reachable without scrolling while underway**, and absent before the trip starts.
- A description shorter than 8 characters is refused — operations needs something to act on.
- The send button disables itself while submitting, so a double-tap cannot file twice.
- **Sending is confirmed out loud.** A silent close reads the same as a tap that did
  nothing, which is the wrong answer for someone who just reported an emergency.

---

### 3.11 Communication

> **As a captain**, I want to tell all my passengers one thing at once, message one of
> them directly, and hear from operations while I drive.

**Three channels**

| Channel | Reached from | Shape |
| --- | --- | --- |
| Broadcast to all passengers | Trip tools → التواصل | One thread per trip |
| One passenger | Manifest → passenger card → chat | Thread scoped to that passenger |
| Operations → captain | anywhere in the shell | A dismissible 5-second banner |

**Rules**

- Threads are scoped to the trip and enforced server-side: a captain sees only their own
  trips' threads, and an operator only their own office's.
- Quick replies ("أنا في الطريق", "وصلت المحطة", "سأصل خلال 5 دقائق"…) fill the composer
  so a captain isn't typing at the wheel.
- Each message is drawn on the side of whoever wrote it, from data carried with the
  message rather than guessed from a display name.
- An operations broadcast already sitting on the wire when the app starts is **not**
  re-announced — the captain is told about new traffic, not yesterday's.

---

### 3.12 Notifications

> **As a captain**, I want to know when a trip is assigned to me, without watching the app.

**Flow**

```
Bell on the home header (unread badge)
  → Notifications list (assignment / trip / passenger / emergency / announcement)
     ├─ tap a row → marked read
     └─ "قراءة الكل" → clears the badge
Push notification (app closed) → tap → routed into the app
```

**Rules**

- Notifications are **per-captain**: each sees only their own.
- The badge is driven by a live unread count, so it clears everywhere at once.
- Marking read is optimistic — the row greys out under the finger rather than after a
  round trip — and the live stream is the source of truth if the write fails.
- The push token is registered for the captain app on sign-in and deactivated on sign-out.

---

### 3.13 Trip history (tab **السجل**)

> **As a captain**, I want to look back at what I drove — to settle a question, or to
> check a date.

**Flow**

```
السجل
  ├─ Search by route or vehicle
  ├─ Date filters
  └─ Trip row → Detail
        ├─ Route, vehicle and plate
        ├─ Departure / arrival / duration
        ├─ Boarding outcome
        └─ Every stop, in order, with scheduled times
```

---

### 3.14 Profile (tab **حسابي**)

> **As a captain**, I want my own record — who I am, what I drive, how I'm doing — and
> the switches that belong to me.

**Contents**

| Block | Shows |
| --- | --- |
| Header | Name, avatar, rating pill |
| Metrics | Total trips, passengers carried, rating |
| Vehicle | Code, model, plate, capacity |
| Identity | Phone, employee code, licence number |
| Verification | Licence expiry and standing |
| Settings | Appearance (light / dark), sign out |

**Rules**

- **Identifiers resolve their own text direction.** A latin plate `ABC 1234` and an
  Egyptian plate `ط ن ج 4821` each lay out correctly on the same RTL screen. This is
  applied to identifiers only — plates, phones, licence and employee codes — never to
  sentences.
- No rating means **no pill**, and the header closes up rather than leaving a gap.

---

## 4. Cross-cutting behaviour

### 4.1 Navigation

- **Three tabs**, state preserved across switches: اليوم · السجل · حسابي.
- Navigation is **typed** at the call site, so passing the wrong argument to a screen is
  a compile error rather than a crash.
- Drill-in chevrons point **left**, which is forward in RTL.
- Turn-by-turn is handed to the device's maps app — Apple Maps on iOS, Google Maps
  elsewhere. The button renders **nothing** when a stop has no saved coordinates rather
  than offering one that would fail, and a device that cannot open either says so.

### 4.2 RTL & Arabic

The app is genuinely RTL-native, not a mirrored LTR layout:

- Directional padding and spacing throughout.
- **Data vs prose direction** is an explicit rule: identifiers resolve their own
  direction; prose inherits the app's.
- Time ranges are laid out as real widgets rather than one string, because
  `'07:05 → 08:30'` is exactly the shape Arabic reorders — the digits stay LTR, the arrow
  between them takes the paragraph's direction, and the line renders backwards.

### 4.3 Responsive & adaptive UI

- Key screens are pumped in tests at **320 / 390 / 430 pt** widths **and** at system font
  scales of **1.0, 1.3 and 1.6**, asserting no overflow.
- Long Egyptian four-part names and long station names are used as the realistic worst
  case, not short placeholder strings.
- Scrollable bodies use slivers; the floating bottom nav reserves space so page controls
  stay reachable.

### 4.4 Theme

Light and dark, chosen by the captain in the profile's appearance sheet and remembered
on the device. Stage colours carry a matching foreground so a label is legible on every
stage fill.

### 4.5 Connectivity

A banner surfaces loss of connectivity, so a captain reading a stale screen knows why.

---

## 5. End-to-end: a captain's day

```
07:10  Open app                 → signed in already, lands on اليوم
       Focus card               → "القاهرة – الإسكندرية، تغادر 08:00"، countdown running
07:15  Bell                     → "تم إسناد رحلة جديدة إليك"
07:30  Boarding window opens    → the bar arms itself: "بدء صعود الركاب"
07:32  Tap it                   → stage → boarding
       كشف الركاب               → 24 booked; mark them aboard as they board
       One passenger missing    → call from their card
07:58  "بدء الرحلة"             → stage → underway
                                → location sharing starts, a fix every 30 s
                                → SOS appears beside the primary action
08:20  Reach a stop             → mark arrived → timeline advances, ops sees the event
09:05  Delay on the road        → بلاغ طارئ → "تأخير" → described → confirmed
11:00  "إنهاء الرحلة"           → confirm → stage → finished
                                → sharing stops
11:02  اليوم                    → next trip becomes the focus card
18:40  Last trip done           → "أحسنت، أنهيت رحلات اليوم"
```

---

## 6. Where the rules live

| Question | Document |
| --- | --- |
| How is it built? What is the security model? | [`CAPTAIN_APP.md`](CAPTAIN_APP.md) |
| What is done, what is broken, what should we build? | [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) |
| How does the client consume the captain's location fixes? | [`LIVE_TRACKING_ENGINE.md`](LIVE_TRACKING_ENGINE.md) |
| What are the platform-wide trip states? | [`STATE_MACHINE.md`](STATE_MACHINE.md) |
| How did multi-office change identity and scoping? | [`MULTI_OFFICE_MIGRATION_AUDIT.md`](MULTI_OFFICE_MIGRATION_AUDIT.md) |
