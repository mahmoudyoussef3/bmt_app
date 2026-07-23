# Captain App — Delivery Status, Defects & Business Roadmap

> **Purpose.** One place to answer three questions: *what is finished*, *what is broken*,
> and *what should we build next and why*.
>
> **Companion documents.** [`CAPTAIN_APP_FEATURES.md`](CAPTAIN_APP_FEATURES.md) (what each
> feature does, with user stories and flows) · [`CAPTAIN_APP.md`](CAPTAIN_APP.md)
> (architecture, security model, audit record) ·
> [`CAPTAIN_APP_USER_FLOWS.md`](CAPTAIN_APP_USER_FLOWS.md) (journeys) ·
> [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) (defect register) ·
> [`CAPTAIN_APP_RECOMMENDATIONS.md`](CAPTAIN_APP_RECOMMENDATIONS.md) ·
> [`CAPTAIN_APP_BUSINESS_SERVICES.md`](CAPTAIN_APP_BUSINESS_SERVICES.md).
>
> **Last revised.** 2026-07-23 (third pass).
> **Verification at time of writing.** `flutter analyze lib/apps/captain test/apps/captain`
> → **0 issues**. `flutter test test/apps/captain` → **253 passing**.

---

## 1. Executive summary

The Captain App is **production-ready with one known limitation** (§4.2). Every feature in
its scope is implemented end-to-end — UI, state, domain and data — against Supabase, with
server-enforced identity and ownership.

**The third pass closed two live security holes and one silent failure of the app's
flagship feature.** All are verified fixed against the live database and the test suite:

- **Live location sharing stopped whenever the captain scrolled** the trip page — silently,
  while the card still claimed it was sharing every 30 seconds. The client's map went stale
  mid-trip (BUG-301).
- **Incident and SOS reports were readable, deletable and forgeable by anonymous
  visitors** — RLS was never re-enabled on `driver_trip_reports` after the multi-office
  sweep (BUG-302).
- **A captain could cancel their own trip** through a crafted RPC, releasing every seat and
  cancelling every booking. The migration existed but had not been applied; it now is
  (BUG-303).
- **Drill-in chevrons pointed backwards in RTL** across three surfaces, from an
  over-correction in the previous pass (BUG-304).

Full write-ups with the evidence for each are in
[`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md).

**One open risk remains** and is deliberately not fixed here: `trip_live_locations` has no
RLS, kept open so realtime delivery to client maps works (§4.3). Closing it needs
verification against a real subscribed client, which cannot be done from a SQL session.

---

## 2. Completed features

Every row below is implemented, wired end-to-end, and reachable from the UI.

| # | Feature | Backend | Tests | Notes |
| --- | --- | --- | --- | --- |
| 1 | Splash & auth routing gate | — | ✅ | Four roots, no bypass |
| 2 | Authentication (phone) | sign-in + session context RPC | ✅ | Persistent session; remember-me survives sign-out |
| 3 | Session & identity | session-context RPC (definer) | ✅ | Server-resolved; fails closed on paused office |
| 4 | Onboarding / access request | `captain_requests` + dashboard approval | ✅ | Join code authoritative; 20 s activation poll |
| 5 | Today / assigned trips | driver-scoped trips + realtime | ✅ | Focus card, day summary, new-assignment banner |
| 6 | Trip execution & lifecycle | ownership-checked status RPC | ✅ | Watch stream is truth; server validates transitions |
| 7 | Passenger manifest | `trip_passengers` + realtime | ✅ | Search, filters, status sheet, call, chat |
| 8 | Live location sharing | `trip_live_locations` insert | ✅ | 30 s cadence, idempotent, retry-on-failure |
| 9 | Report to operations | `trip_events` insert | — | Reframed as a message, not a state change (§3.4) |
| 10 | Incidents & SOS | `driver_trip_reports` insert | ✅ | 3-second armed hold; confirmed on send |
| 11 | Communication (chat) | `captain_messages`, scoped | ✅ | Broadcast + per-passenger + ops banner |
| 12 | Notifications | user-scoped notifications | ✅ | Bell, badge, list, mark-read, push |
| 13 | Trip history | trip history + stops | ✅ | Search, date filters, stop-by-stop detail |
| 14 | Driver profile | driver + vehicle | ✅ | Metrics, verification, appearance, sign out |
| 15 | Theme (light / dark) | local store | ✅ | RTL-native tokens |
| 16 | Connectivity banner | — | — | Surfaces loss of connection |

**Structural health**

- No dead routes — every registered screen has a real call site.
- No `TODO` / `FIXME` / `HACK` markers in the captain source.
- Every stream subscription and timer is cancelled on close.
- Analyzer: **0 issues** across `lib/apps/captain` and `test/apps/captain`.

---

## 3. Defects found and fixed (this pass)

All eight were found by reading the code and by pumping screens at real device sizes and
system font scales. Each is covered by a test that fails without the fix.

### 3.1 Chat messages were never identified as the captain's own — **functional, visible**

The message bubble decided which side to sit on by checking whether the sender's display
name contained `"Captain"` or `"السائق"`. The data layer labels rows `"أنت"` or
`"العمليات"` — so **neither branch ever matched**, and every message in every thread,
including the captain's own, rendered as an incoming message on the wrong side in the
wrong colour.

**Fix.** Authorship is now carried as data on the message from the row's sender type, and
the bubble reads that. *Rendering identity is not something to re-derive from a label.*

### 3.2 A status screen that looked like it could end a trip — **functional, dangerous**

The standalone status page was titled **"تحديث حالة الرحلة"** (update the trip's status)
and offered **"مكتمل"** among its options. It writes only a narrative event row; it never
touches the trip's real status. A captain could tap "مكتمل", watch it tick, and leave
believing the trip was finished — while the backend still had it running, the seats still
held, and the client's map still tracking.

**Fix.** The page is retitled **"إبلاغ العمليات"**, states plainly that it does not change
the trip's stage, and the three options that shadow a real lifecycle transition
(boarding / departed / completed) are removed. The tool entry that opens it was relabelled
to match.

### 3.3 Voice and image buttons that sent nothing — **functional, misleading**

The chat composer offered a microphone and an image button. Neither recorded nor attached
anything: they posted the literal strings `"Voice note"` and `"Image shared"` into the
thread. Operations received a message announcing an attachment that did not exist, and the
captain believed they had sent one.

**Fix.** Both removed until there is real media upload behind them. The message types
remain in the model so existing rows still render. (Re-adding them properly is
recommendation #8 in §6.)

### 3.4 Stale operations broadcasts re-announced on every launch — **UX**

The operations-message stream replays the newest matching row the moment it subscribes.
That first emission was treated as new, so **every app launch popped an operations
broadcast** — including one the captain had read days earlier.

**Fix.** The first emission is taken as the baseline of "already seen"; only genuinely new
traffic after it is announced.

### 3.5 Trip execution canopy overflowed at enlarged fonts — **layout**

At system font scales of 1.3 and 1.6 on a 320 pt phone, the stage chip in the trip canopy
overflowed the row by up to **51 pixels**, pushing against the back button.

**Fix.** The chip shrinks before the row breaks, and its label truncates rather than
displacing navigation.

### 3.6 The docked action bar changed height at enlarged fonts — **layout, by-design invariant broken**

The bar is built to hold one height across every stage, so a transition never reflows the
page under the captain's thumb. It held at the default font only: the waiting panel's two
lines grow with the system font, so at scale 1.6 it stood **112 px against the button's
89 px** — a 23 px jump at exactly the moment the captain is watching their thumb.

**Fix.** The bar's height now scales with the text and is shared by all four variants —
live button, waiting panel, terminal label and the in-flight spinner — so they cannot
disagree. Clamped so a very large accessibility setting cannot eat the screen. The
invariant is now asserted at every font scale, including the spinner.

### 3.7 Trip history time strip overflowed at enlarged fonts — **layout**

The departure/arrival strip overflowed by up to **32 pixels** at enlarged fonts: the two
endpoint labels were unconstrained, so no amount of shrinking the link between them could
save the row.

**Fix.** Both ends shrink, and their labels truncate; the clock values never wrap.

### 3.8 Failures that escaped as unhandled async errors — **robustness**

- **Marking a notification read** is fired from a tap handler that never awaits it. A
  network failure therefore surfaced as an unhandled async error. It is now swallowed
  deliberately — the live stream re-emits the true read state, so the only thing an error
  could add is a dialog over a notification list about a notification.
- **Opening the maps app** called out without checking the result. `launchUrl` both
  returns `false` and throws on a device with no handler, and neither was handled — the
  captain got a button that silently did nothing while the error went to the console. It
  now reports failure, and uses **Apple Maps on iOS** instead of bouncing into a browser.

---

## 4. Open defects & risks

### 4.1 ✅ A captain could cancel their own trip — **closed 2026-07-23**

The captain's status-change RPC gated on **ownership only**, not on the target status,
while the underlying transition graph permits `open_for_booking | boarding | in_progress →
cancelled` — a transition its own comments mark "ops" / "admin emergency only". Cancelling
a trip **cancels every open booking on it and releases every locked seat.**

**Proven live before the fix.** Impersonating a real captain against a real
`open_for_booking` trip inside `BEGIN … ROLLBACK`, the crafted `cancelled` call succeeded
and cancelled the trip's only booking.

**Status: fixed.** Migration `20260723090000_captain_status_transition_allowlist.sql` is
**applied to the linked database** and verified against the live function: crafted
`cancelled`, crafted `open_for_booking` and bogus statuses all raise
`status_not_allowed_for_captain`, while boarding → in_progress → completed all still
succeed. Details in [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) BUG-303.

### 4.2 🟠 Location sharing is foreground-only — **accepted limitation**

The app claims no background-location permission. Sharing runs while the trip-execution
screen is open and stops when the app is backgrounded or the screen locks.

**Consequence.** If the captain pockets the phone, the client's map goes stale until they
return to the screen. This is the single largest gap in tracking fidelity, and it is the
one most visible to paying customers.

**Status.** A deliberate product and privacy decision. See recommendation #1.

### 4.3 🟠 `trip_live_locations` has no row-level security — **open risk**

The table is kept open so live delivery to client maps works. Ownership is enforced at the
**write path** instead — verified this pass: the driver stamped on each fix is the
server-resolved captain from `CaptainIdentityProvider`, never a client-supplied id, and the
trip lookup is scoped by `driver_id`, so a captain cannot push positions onto a trip that
is not theirs.

**Residual risk.** `anon` holds full DML. Any visitor can read every vehicle position on
the platform, and any authenticated user could insert false positions into a customer's
tracking map.

**Why it was not closed in this pass.** Enabling RLS risks a silent outage on the most
customer-visible feature, and delivery cannot be verified from a SQL session. Trading a
known, contained risk for an unknown outage on the production-bound database was not the
right call to make unattended. See recommendation **R1** — it is the highest-priority open
item.

### 4.3b 🟠 Other tables with RLS off — **outside captain scope, reported**

The sweep that found BUG-302 checked every table. Eight more Client/Dashboard tables are in
the same state, including `support_messages` (which holds real data). They are listed in
[`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) RISK-306 and were **not touched** — this audit
was scoped to the Captain App. `admins` and `user_roles` are *not* privilege-escalation
vectors: authorisation resolves through `office_users` and `platform_admins`, both
RLS-enabled.

### 4.4 🟡 The trip chats page lists only the broadcast thread

"تواصل الرحلة" offers a single entry — message all passengers. Per-passenger threads exist
and work, but are reachable only from a passenger's card on the manifest. A captain
looking for "the conversation I had with the passenger in seat B3" has to know to go
through the manifest.

**Impact:** low — the manifest is the natural route. **Fix:** list the trip's active
threads on this page.

### 4.5 🟡 Thin test coverage remains on two surfaces

Communication, incidents and notifications gained cubit-level tests in this pass.
Still untested: the **onboarding request form's** widget layout and the **chat details
page's** widget layout. Both are exercised manually and neither carries complex logic.

---

## 5. Known limitations by design

These are **not defects**. They are choices, recorded so they are not "fixed" by accident.

| # | Limitation | Why | Revisit when |
| --- | --- | --- | --- |
| 1 | Foreground-only location | Battery and privacy; no background permission claimed | Client complaints about stale maps (see #1 in §6) |
| 2 | `trip_live_locations` open | Realtime delivery to client maps | A safe policy that preserves delivery is proven |
| 3 | Captain cannot cancel or publish | Those are operations decisions with financial consequences | Never — this is correct |
| 4 | No in-app turn-by-turn | The device's maps app does it better | Never — this is correct |
| 5 | No offline queue | Intercity routes have dead zones, but no data is lost — only delayed | Route telemetry shows meaningful dead time (see #7) |

---

## 6. Business & service recommendations

Ranked by business value. **None of these are implemented** — they are prioritised for a
product decision.

### Tier 1 — build next

| # | Feature | What the captain gets | What the business gets | Complexity |
| --- | --- | --- | --- | --- |
| 1 | **Background / foreground-service location** | Sharing keeps running with the phone pocketed | **The map stops going dark mid-trip.** This is the most customer-visible gap in the product; a tracking feature that silently stops is worse for trust than one that was never promised | High — Android foreground service, iOS background modes, store review, battery tuning |
| 2 | **Emergency escalation beyond a report** | Real help while driving — a call placed, ops paged, location pinned | Safety compliance and duty of care; the current SOS files a form and waits for someone to read it | Medium |
| 3 | **Captain earnings / payout view** | Sees what the day earned them | **Retention.** Drivers leave fleets that are opaque about pay; this is the single most requested feature in comparable products | Medium — needs a payout model first |

### Tier 2 — clear value, no urgency

| # | Feature | What the captain gets | What the business gets | Complexity |
| --- | --- | --- | --- | --- |
| 4 | **Performance & punctuality analytics** | Own on-time %, ratings trend, passengers carried | An objective quality signal, and the basis for an incentive scheme | Medium |
| 5 | **Document-expiry reminders** (licence, vehicle papers) | Warned before being pulled off duty | Fleet compliance; an expired licence discovered at a checkpoint is a cancelled trip and a fine | Low–Medium — the expiry data is already on the profile |
| 6 | **Trip completion proof** (photo or signature) | Protection in a dispute | Settlement evidence; reduces "the trip never ran" arguments | Medium |
| 7 | **Offline queue for status and location** | Survives dead zones on intercity routes | No lost fixes or transitions on the Cairo–Alexandria desert road | Medium |

### Tier 3 — polish

| # | Feature | Value | Complexity |
| --- | --- | --- | --- |
| 8 | **Real voice notes and photo attachments in chat** | Restores the two controls removed in §3.3, properly | Medium — needs storage, upload, playback |
| 9 | **Thread list on the trip chats page** | Closes §4.4 | Low |
| 10 | **Shift / availability declaration** | Lets a captain flag unavailability instead of phoning the office | Medium |
| 11 | **In-app fuel & maintenance log** | Fleet cost visibility from the person closest to the vehicle | Medium |

### Recommended sequence

```
Now      → Apply the status-allowlist migration (§4.1)          — hours, closes a live hole
Sprint 1 → #1 Background location                               — the customer-visible gap
Sprint 2 → #5 Document expiry  +  #9 Thread list                — cheap, compliance + polish
Sprint 3 → #2 Emergency escalation                              — safety
Then     → #3 Earnings (once a payout model exists)             — retention
```

---

## 7. Test coverage

**253 tests passing** across the captain suite (247 → 253 in this pass).

**Added in the third pass (+6):**

| File | Covers |
| --- | --- |
| `features/live_location/auto_share_scroll_survival_test.dart` | Sharing survives a 2500 px scroll; three scrolled-away intervals still produce three fixes. Both fail without the BUG-301 fix. |
| `captain_rtl_direction_test.dart` | The RTL mirroring rule re-derived from `matchTextDirection`; back/forward arrow semantics; the **rendered** direction of a real drill-in row; a source sweep asserting no captain file names a left chevron. |

| Area | Covered |
| --- | --- |
| Auth | Cubit states, sign-out lands idle, failed sign-out still lands idle, remembered phone survives sign-out, layout, LTR phone field |
| Onboarding | Request cubit, activation polling |
| Assigned trips | Cubit, home layout, nav clearance, day summary, focus countdown, awaiting view |
| Trip execution | Cubit, station-arrival use case, GPS card, layout across **all six stages × three widths × three font scales**, docked-bar height invariant incl. the spinner |
| Passenger manifest | Cubit, and layout across widths and font scales |
| Live location | Cadence asserted against the constant, idempotent start, failure/retry, stop, close |
| Communication | Authorship, empty/whitespace guard, trimming, load failure, broadcast replay suppression, duplicate suppression |
| Incidents | Submit lifecycle, failure never reports submitted, initial state |
| Notifications | Unread count, mark one, mark all, failure containment, stream error, post-close emissions |
| Trip history | Cubit, detail cubit, filters, labels, list and detail layout incl. font scales |
| Profile / theme / trip stages | Layout, identifier direction, long name, theme cubit, stage derivation |

**Layout testing note.** `flutter_test` substitutes a font whose glyphs are far wider than
Cairo's, so Arabic strings measure longer in tests than on a device. A layout that passes
here passes on hardware with room to spare — but a failure is not automatically a
user-visible bug. Check the real font before contorting a layout to satisfy a test.

---

## 8. Change log

### Third pass — 2026-07-23

**Fixed (4):**

| Defect | Class | Where |
| --- | --- | --- |
| Live sharing died on scroll — silently | Critical, functional | `trip_location_auto_share.dart` |
| Incident reports world-readable/deletable/forgeable | Critical, security | migration `20260723120000` |
| Captain could cancel their own trip | High, security | migration `20260723090000` (applied) |
| Drill-in chevrons backwards in RTL | Medium, UX | 3 call sites |

**Database:** two migrations applied to the linked database, each dry-run under
`BEGIN … ROLLBACK` with assertions before applying, and re-verified against the live
functions afterwards. No production data was modified — the exploit proofs ran inside
rolled-back transactions and the trip used was confirmed unchanged.

**Tests:** 247 → **253**. **Analyzer:** 0 issues.

**Corrected from the previous pass.** Pass 2 recorded the RTL chevron change as a fix; it
was an over-correction that double-mirrored an already-correct icon. Pass 2 also verified
the 30-second cadence — correctly — but nothing verified the *lifetime* of the widget
carrying it, which is how BUG-301 survived.

**Outstanding:** R1 (close `trip_live_locations` RLS with delivery verification) and R2 (an
operations inbox so filed incidents are read by someone).

### Second pass — 2026-07-23

**Fixed (8):** chat authorship · misleading status page · fake voice/image buttons · stale
ops broadcast replay · canopy overflow · docked-bar height invariant at enlarged fonts ·
history time-strip overflow · unhandled async failures in mark-read and maps launch.

**Added:** iOS Apple Maps handoff; confirmation on incident submit.

**Tests:** 174 → **247**. New files for communication, incidents and notifications — the
three features that previously had none.
