# Captain App — Architecture, Features & Production Readiness

> Scope: the **Captain** flavor of the EWT platform (`lib/apps/captain`, entry
> `lib/apps/captain/main.dart`, run with `--flavor captain`). Arabic-only, RTL-native.
> Audience: engineers and operators extending or operating the Captain App.
>
> This document is the outcome of a full production-readiness audit (2026-07-23).
> It records what exists, how it works, what was verified, the accepted trade-offs,
> and the roadmap. It is a companion to `LIVE_TRACKING_ENGINE.md` (client-side
> presentation of the fixes captains produce), `STATE_MACHINE.md`, and
> `MULTI_OFFICE_MIGRATION_AUDIT.md`.
>
> **This is the engineering reference.** Two companions split off the other audiences:
>
> | Document | Answers |
> | --- | --- |
> | [`CAPTAIN_APP_FEATURES.md`](CAPTAIN_APP_FEATURES.md) | What each feature does, for whom, with user stories and end-to-end flows |
> | [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) | What is complete, what is defective, and the prioritised business roadmap |
> | [`CAPTAIN_APP_USER_FLOWS.md`](CAPTAIN_APP_USER_FLOWS.md) | The journeys, as the captain experiences them, with flow diagrams |
> | [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md) | Every defect found, with the evidence that proved it and the guard that keeps it fixed |
> | [`CAPTAIN_APP_RECOMMENDATIONS.md`](CAPTAIN_APP_RECOMMENDATIONS.md) | What to build next, ranked by business value |
> | [`CAPTAIN_APP_BUSINESS_SERVICES.md`](CAPTAIN_APP_BUSINESS_SERVICES.md) | What the captain platform could be sold as |
>
> A second pass on 2026-07-23 fixed eight further defects (three functional, three
> layout, two robustness) and took the suite from 174 to 247 tests.
>
> A **third pass** on 2026-07-23 closed two live security holes on the database and one
> silent failure of live tracking, and corrected an RTL "fix" from the second pass that
> had pointed three surfaces backwards. Suite: **253 tests**. Details in
> [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md); the sections below are updated to match.

---

## 1. Architecture at a glance

Feature-first Clean Architecture, one directory per feature under
`lib/apps/captain/features/<feature>/{data,domain,presentation}`, on the platform's
standard stack: **Cubit + sealed/immutable state**, `get_it` DI (a captain-scoped
container, `captainGetIt`, wired in `core/di/captain_di.dart`), and **Supabase**
(Postgres + RPC + Realtime) as the data plane instead of Dio/Retrofit. Presentation
depends only on domain use cases; data implements the domain repositories and maps
rows to entities.

```
UI (Page/Widget)
  → context.read<Cubit>().action()
    → UseCase(...)                     // domain
      → Repository (interface, domain) ← implemented in data/
        → DataSource → Supabase (RPC / table / Realtime channel)
  ← entity / stream
UI rebuilds via BlocBuilder / reacts via BlocListener
```

**Identity is server-resolved, never client-supplied.** Every operation that needs
to know "which driver am I / which office" goes through `CaptainIdentityProvider`
(`core/session/`), which reads a warm `CaptainOfficeSession` or restores it from the
`captain_session_context()` RPC — resolved from `auth.uid()` on the server. No screen
sends a `driver_id` or `office_id` it chose.

### App shell & roots

`main.dart` picks the root via `_CaptainAuthGate`:

| Condition | Root |
| --- | --- |
| Supabase auth session present | `CaptainAppShell` (operational: اليوم / السجل / حسابي tabs) |
| Local approved session only | `CaptainWelcomeHome` → keeps trying to establish an operational session, swaps into the shell on success |
| A submitted access request | Onboarding flow, resumed at the pending state |
| None of the above | Login (with a request-access entry) |

The gate listens for `signedOut` and drops the local session with it, so a sign-out
can't be immediately undone by the welcome-home upgrader.

---

## 2. Feature inventory & status matrix

| Feature | Status | Backend | UI | Tests | Notes |
| --- | --- | --- | --- | --- | --- |
| Authentication (phone) | ✅ Completed | `link_current_captain_driver`, `captain_session_context` | login, remember-me | ✅ | Server-resolved identity; persistent session |
| Session / identity | ✅ Completed | `captain_session_context` (SECURITY DEFINER) | — | ✅ (indirect) | De-dupes restore; fails closed on paused office |
| Onboarding / access request | ✅ Completed | `captain_requests` table, dashboard approve/reject | request → pending → approved/rejected | ✅ | 20 s activation poll upgrades local→operational session |
| Home / "اليوم" (assigned trips) | ✅ Completed | `operation_trips` (driver-scoped) + Realtime | focus card, day summary, quick actions | ✅ | Live watch; new-assignment banner; seen-trips cache |
| Trip lifecycle / execution | ✅ Completed | `captain_update_trip_status` (ownership-checked) | canopy + docked action bar | ✅ | Watch stream is source of truth; server validates transitions |
| Passenger manifest | ✅ Completed | `trip_passengers` + Realtime | list, filters, status sheet | ✅ | Boarding door for the trip |
| Live location sharing | ✅ Completed | `trip_live_locations` insert | auto-share status card | ✅ | Automatic for the whole live trip; the card's only button is a retry, shown when publishing is failing (see §6) |
| Trip history | ✅ Completed | `operation_trips` history + stops | list, filters, detail | ✅ | Search + date filters |
| Notifications | ✅ Completed | `notifications` (user-scoped) | bell, list, ops broadcast snackbar | ✅ | Per-user isolation via `user_id = auth.uid()` |
| Communication (chat) | ✅ Completed | `captain_messages` (office-scoped RLS) | chats, chat details | ✅ | Driver↔office threads scoped by trip |
| Incident / SOS report | ✅ Completed | incident insert | report form, SOS button | ✅ | Reachable without scrolling while underway |
| Driver profile | ✅ Completed | `drivers` + vehicle | profile, metrics, appearance | ✅ | Rating pill, verification card, sign-out |
| Theme (light/dark) | ✅ Completed | local store | appearance sheet | ✅ | RTL-native tokens |
| Report to operations | ✅ Completed | `trip_events` insert | `StatusUpdatePage` | — | Reframed as a message, not a lifecycle control — see §12 |

Legend: ✅ Completed · ⚠️ Completed, gap noted · 🟡 Partial · ❌ Missing · 💡 Improvement.

**No dead routes:** every screen registered in `CaptainAppRouter` has ≥1 real
`CaptainNav` call site. **No `TODO`/`FIXME`/`HACK` markers** in the captain source.

---

## 3. Authentication & session flow

```
Launch
  → Supabase currentSession?
      yes → CaptainAppShell (FCM token registered for appType 'captain')
      no  → local approved session? → WelcomeHome (poll sign-in) → shell on success
            pending request?         → Onboarding (pending)
            else                     → Login / Request access
```

- **Login** is phone-based (`sign_in_captain_usecase`). "Remember me" caches the
  phone locally, decoupled from the sign-in itself so the activation poll can't
  clobber it; **sign-out never clears remember-me**.
- **Session restoration:** Supabase sessions survive relaunch; `CaptainIdentityProvider`
  restores driver+office server-side via `captain_session_context()`. A second
  captain on the same device cannot inherit the first's id — the previous lazy-singleton
  cache that caused this was replaced by the session provider.
- **Fail-closed:** `captain_session_context()` returns NULL (routes to login), not an
  error, when the caller is not a driver or the office is not `active`.
- **Sign-out** clears both the Supabase session and the local session, and deactivates
  the FCM token.

---

## 4. Onboarding flow

Self-service, no SMS. See `project_captain_onboarding` for history.

```
Request access (name, phone, office pick + join code)
  → captain_requests row (pending)
  → Dashboard: approve / reject
     approved → CaptainActivationCubit polls sign-in every 20 s
                → driver row active → operational session → shell
     rejected → rejected view → re-apply
```

**Join-code semantics** (`submit_captain_request`, migration `20260721100200`) — verified:

- The **join code is authoritative**. If a code is supplied and the caller-supplied
  `p_office_id` disagrees with the office the code resolves to, the request is rejected
  (`office_code_mismatch`) — a tampered office id cannot ride along with a valid code.
- A code matching no active office → `invalid_office_code`.
- More than one active office and **no** code → `office_code_required` (the RPC refuses
  to pick a queue rather than landing the request arbitrarily).
- Single active office → code optional, for backwards compatibility with older builds.
- The pre-code 3-arg overload was explicitly **dropped**, so no stale signature can
  bypass code validation.
- `public_offices` (the anon directory the picker reads) **excludes** join codes.
- The request records `office_code_verified`, and dashboard approval is still mandatory.

Other guarantees:

- Onboarding cannot be bypassed: without an active `drivers` row bound to the auth
  user, `captain_session_context()` yields nothing and no assigned trips load.
- A captain cannot approve themselves — approval is a dashboard (office-user) action
  under office-scoped RLS.

---

## 5. Trip lifecycle & state machine

The captain vocabulary (`core/trips/captain_trip_stage.dart`) maps the backend
`operation_trips.status` onto stages, splitting the two pre-departure backend states
so the app never offers "start" on an unreleased trip:

```
awaitingRelease   (scheduled)         — ops hasn't published; nothing to do
      │ dashboard publishes
awaitingWindow    (open_for_booking, > 30 min out)
      │ clock reaches departure − 30 min
readyToBoard      (open_for_booking, within window)
      │ captain: start boarding
boarding          → underway (start trip) → finished (complete)
                                          → cancelled (terminal)
```

- **Source of truth:** `TripExecutionCubit` subscribes to
  `watchTripExecutionSnapshotUseCase` — a Realtime channel over `operation_trips`,
  `trip_passengers`, `trip_events`, and `trip_live_locations`, debounced 250 ms, that
  re-fetches the aggregate snapshot. Status, boarded/passenger counts, and arrived
  stations never freeze at their tapped-in values.
- **Transitions are server-validated.** Board/start/complete call
  `captain_update_trip_status(p_trip_id, p_new_status)` — a SECURITY DEFINER wrapper
  that asserts `current_driver_id()` owns the trip before delegating to
  `update_trip_status` (which enforces the legal transition graph). The raw
  `update_trip_status` is **not** granted to `authenticated`. Invalid transition,
  unknown trip, and "not your trip" map to distinct Arabic errors.
- **Station arrivals** insert the canonical `trip_events` marker
  (`kStationArrivalEventTitle`) — the exact convention the Dashboard uses — so all
  three apps read one source of truth. It deliberately does not flip the main action
  button into a loading state.
- **UI reflects backend truth:** local state is optimistic only for the immediate
  button feedback; the watch stream corrects it.

---

## 6. Live tracking architecture ⭐

The Captain App is the **producer**; the Client tracking screen is the consumer via
Supabase Realtime + an 8 s poll fallback (see `LIVE_TRACKING_ENGINE.md`).

```
Trip underway (status = in_progress)
  → TripLocationAutoShare(enabled: true)   [kept mounted across the whole trip]
    → LiveLocationCubit.startAutoSharing(tripId)
       → immediate fix, then Timer.periodic(kAutoLocationInterval = 30 s)
          → SendLocationUpdateUseCase
             → ensure location service + permission
             → resolve driverId server-side; scope trip lookup by driver_id (ownership)
             → Geolocator.getCurrentPosition(high, 20 s limit)
             → INSERT trip_live_locations {lat,lng,heading,speed,accuracy,recorded_at,driver_id,vehicle_id}
  → Trip completes / captain leaves screen → stopAutoSharing() (timer cancelled)
```

### Cadence — verified

- **Interval: 30 seconds** (`kAutoLocationInterval = Duration(seconds: 30)`), matching
  the platform tracking cadence documented in `SYSTEM_FLOW.md`. *This was corrected
  from a drifted 60 s value during this audit; the client consumer already tolerates a
  denser cadence, so this only sharpens the map.*
- Verified by `live_location_cubit_test.dart` under `fakeAsync`: immediate first fix,
  then one send per `kAutoLocationInterval`, asserted against the constant so the test
  tracks the contract rather than a literal.
- **The interval is only worth the widget's lifetime.** `TripLocationAutoShare` owns the
  timer through a `BlocProvider` it creates, and sits inside the execution page's
  `SliverList` — which disposes children scrolled past its cache extent. Until the third
  pass, scrolling down to check the route tore the provider down and stopped sharing
  **silently**, while the card claimed on rebuild that it was still sharing every 30 s
  (BUG-301). It now holds itself alive with `AutomaticKeepAliveClientMixin` while — and
  only while — a trip is under way, guarded by
  `auto_share_scroll_survival_test.dart`. *A verified cadence proves nothing if nothing
  verifies the lifetime of the thing carrying it.*
- **Duplicate protection:** `startAutoSharing` is idempotent (`if (_autoTimer != null) return`)
  — starting twice does not double the rate (test-covered). A `_sending` guard skips a
  tick that overlaps a slow (bad-signal) fix instead of queueing it.
- **Stop is real:** `stopAutoSharing` and `close()` both cancel the timer
  (test-covered: no sends after stop).
- **Failure handling:** an automatic tick that fails keeps the last good fix on screen,
  shows the reason inline, and the next tick retries by itself; a manual send failure
  surfaces as an error state. Permission denied / permanently denied / service-off each
  produce a distinct Arabic message.

### Accepted trade-offs (documented, not bugs)

1. **Foreground only.** The app claims **no** background-location permission. Sharing
   runs while the trip-execution screen is open; it stops when the app is backgrounded
   or the screen is locked. This is a deliberate product/privacy decision. Consequence:
   if the captain leaves the app, the client map goes stale until they return. See §12
   for the background-tracking recommendation.
2. **`trip_live_locations` has no RLS**, by design — the table is kept open so Realtime
   delivery to clients works. Ownership is enforced at the write path instead: the
   driver stamped on each fix is the server-resolved captain, and the trip lookup is
   scoped by `driver_id`, so a captain cannot push positions onto a trip that is not
   theirs. Any authenticated user could in principle insert arbitrary rows; this is the
   known limitation carried from the multi-office work (`project_live_tracking`).

---

## 7. Navigation architecture

- **Bottom-nav shell** with three tabs in an `IndexedStack` (state preserved across
  tab switches): اليوم (assigned trips), السجل (history), حسابي (profile).
- **Typed navigation:** call sites use `context.open<Screen>(...)` (the `CaptainNav`
  extension); the single cast from `settings.arguments` lives in `CaptainAppRouter`, so
  a wrong argument is a compile error at the call site.
- **Route guards are structural:** the auth gate, not per-route guards, decides the
  root. Onboarding cannot be bypassed (no active driver row → no operational session).
- Screens self-provide their cubits (each is reachable both as a route and, in a couple
  of cases, hosted inline by the auth gate).

### External navigation (maps)

`NavigateToStopButton` hands turn-by-turn off to the device's maps app rather than
rendering navigation in-app:

- URL: `https://www.google.com/maps/search/?api=1&query=<lat>,<lng>` — **coordinate
  ordering verified correct** (`latitude,longitude`, which is what Google Maps expects).
- Opened with `LaunchMode.externalApplication`.
- Renders **nothing** when the stop has no saved coordinates, rather than offering a
  button that would fail.
- Target is the next stop the captain has not yet reported arrived at.

Both gaps noted in the first pass are now closed:
- iOS uses `https://maps.apple.com/?daddr=` so the handoff lands in Apple Maps instead of
  bouncing into a browser; every other platform keeps the Google Maps universal URL.
- The launch result is checked and a failure is reported to the captain. `launchUrl` both
  returns `false` and throws on a device with no handler, and neither was handled — the
  button silently did nothing while the error went to the console.

---

## 8. Notifications & alerts

- **Push:** `FcmService` registers a token for `appType: 'captain'` on auth, deactivates
  it on sign-out. Tap-routing is handled through the app navigator key.
- **In-app:** `CaptainNotificationBadgeCubit` (unread count) + notifications list, both
  scoped `user_id = auth.uid()` — a captain sees only their own notifications.
- **Operations broadcast:** `CaptainNotificationCubit` surfaces ops messages as a
  dismissible 5 s snackbar in the shell.
- **Office isolation:** notifications are per-user; captain↔office chat threads
  (`captain_messages`) are RLS-scoped so a driver sees only their own trips' threads and
  an operator only their own office's trips.

---

## 9. Security / RLS model

Verified against the multi-office hardening migrations
(`20260721100000_multi_office_security_hardening.sql`,
`20260721130000_captain_session_context_and_messages.sql`).

| Concern | Enforcement |
| --- | --- |
| Driver identity | Server-resolved (`captain_session_context`, `current_driver_id()`); never client-supplied |
| Office identity | Derived from the driver's office server-side; fails closed on non-active office |
| Trip status changes | `captain_update_trip_status` asserts caller owns the trip **and** that the target status is captain-legal; raw RPC revoked from `authenticated` |
| Another captain's trip | Ownership check → `not_your_trip`; location writes scoped by `driver_id` |
| Captain messages | RLS: driver sees own trips' threads; operator sees own office's trips |
| Notifications | RLS/query scoped to `user_id = auth.uid()` |
| Self-approval | Impossible — approval is an office-user (dashboard) action |
| Platform-admin / payment config | Not reachable from the captain flavor |

### Table-level RLS (verified policy bodies, migration `20260721090200`)

| Table | Captain's access |
| --- | --- |
| `drivers` | `drivers_self_read`: `user_id = auth.uid()` — own row only. Office CRUD is `office_id`-scoped |
| `vehicles` | `vehicles_captain_read`: `office_id = captain_office_id()` — read-only, own office |
| `trip_passengers` | `trip_passengers_captain_rw`: only trips where `driver_id = current_driver_id()` (before this, the table had **no RLS** and the manifest leaked names + phones) |
| `trip_events` | `trip_events_captain_rw`: same driver-scoped predicate (also previously unprotected) |
| `captain_requests` | Office-scoped; `anon` revoked |
| `trip_seats` | Legacy blanket policies dropped; marketplace reads go through sanitised views |

### Fixed during this audit — captain could cancel their own trip

`captain_update_trip_status` gated **only on ownership**, not on the target status, while
`update_trip_status`'s graph permits `open_for_booking|boarding|in_progress → cancelled`
— a transition its own comments mark "ops" / "admin emergency only". Cancelling a trip
cancels every open booking on it and releases every locked seat. The Captain App never
renders a cancel control, so this was unreachable through the UI, but the RPC is granted
to `authenticated`, so a crafted call could wipe out a trip's bookings.

Migration `20260723090000_captain_status_transition_allowlist.sql` restricts captains to
`boarding | in_progress | completed` (`status_not_allowed_for_captain` otherwise). Ops
retains the full graph via `office_update_trip_status`, which is untouched.
**✅ Applied to the linked database on 2026-07-23 and verified against the live function.**

### Fixed during the third audit — incident reports had no RLS

`driver_trip_reports`, where the app files incidents and SOS, had **row-level security
disabled** while `anon` held full DML. An unauthenticated visitor could read every incident
report on the platform, delete all of them, and forge an SOS attributed to a real captain —
all three confirmed empirically before the fix.

The cause was an omission, not a decision: the original schema created the table *with* RLS,
`all_app_scheme.sql` blanket-disabled it, and the multi-office sweep
(`20260721090200`) re-enabled ~22 tables but not this one. Its two original policies
survived and still read correctly — but **a policy on a table without RLS is documentation,
not enforcement.**

Migration `20260723120000_driver_trip_reports_rls.sql` enables RLS, revokes `anon`, and
replaces the legacy pair with the multi-office convention (`current_driver_id()` for the
captain, `current_office_id()` for operations). **Applied and verified.**

**Open risk:** `trip_live_locations` has no RLS (kept open for Realtime delivery);
write-path ownership is the compensating control (§6). Closing it requires verification
against a real subscribed client map — see recommendation R1.

---

## 10. RTL / Arabic UX guidelines

The app is genuinely RTL-native (`locale: const Locale('ar')`), not translated LTR.

- **Data vs prose direction:** `CaptainTextDirection.ofIdentifier` applies the Unicode
  first-strong rule to *identifiers* (plates, phones, licence/employee codes) so a latin
  plate `ABC 1234` and an Egyptian plate `ط ن ج 4821` each lay out correctly; prose
  inherits the ambient RTL direction. **Rule:** use it for identifiers only, never for
  sentences.
- **Directional icons — author for LTR, let the framework mirror.** Material's directional
  icons carry `matchTextDirection: true`, and `Icon` wraps those in a horizontal flip when
  the ambient `Directionality` is RTL (`widgets/icon.dart`). So a drill-in chevron that
  should appear **left-pointing** in this RTL app is written as
  `Icons.chevron_right_rounded`; the framework flips it.

  > **The trap.** Reaching for the left-named icon "because the app is Arabic" mirrors an
  > already-correct icon a second time and lands it backwards. The second pass did exactly
  > that on three surfaces and recorded it as a fix; the third pass corrected it
  > (BUG-304). Back and forward **arrows** were never touched and were always right,
  > precisely because they were left to the framework.

  Guarded by `captain_rtl_direction_test.dart`, which asserts the **rendered** direction
  and sweeps the source for left-named chevrons.
- **Directional spacing/padding** uses `EdgeInsetsDirectional` throughout.
- **Auth fields:** the phone field is forced LTR while name fields follow app RTL
  (test-covered).

---

## 11. Responsive UI

- Layout tests render key screens across **320 / 390 / 430 pt** widths **and** system font
  scales of **1.0 / 1.3 / 1.6**, asserting **no overflow**: auth, profile, trip execution
  across all six stages, trip-history list and detail, and the passenger manifest and
  notification tiles (`captain_overflow_sweep_test`).
- The trip-execution **docked action bar keeps a constant height across every stage**,
  so a status transition never reflows the page above it. The height is derived from
  `dockedActionHeight(context)`, which scales with the text scaler and is shared by all
  four variants — live button, waiting panel, terminal label, in-flight spinner. A flat
  56 held only at the default font; the waiting panel's two lines grew with the system
  font and the bar jumped 23 px on a transition at scale 1.6. Test-covered at every scale,
  spinner included.
- Scrollable bodies use slivers; the floating bottom nav is offset with reserved space
  so page controls stay reachable (`extendBody`).
- **Enlarged-font overflows fixed in the second pass:** the execution canopy's stage chip
  (up to 51 px) and the trip-history time strip (up to 32 px). Both were unconstrained
  children of a `Row`; both now shrink and truncate rather than pushing the row apart.

**Testing note.** `flutter_test` substitutes a font whose glyphs are far wider than
Cairo's, so Arabic measures longer in tests than on hardware. Passing proves the layout
holds with room to spare; a failure is not automatically user-visible.

---

## 12. Known limitations, bugs & improvements

### Fixed in this audit
- **Captain could cancel their own trip** via `captain_update_trip_status` (§9) —
  migration written, **not yet applied**. Highest-severity finding.
- **Live-tracking cadence corrected 60 s → 30 s** to match the documented platform
  cadence; test rewritten to assert against the constant. *(Trade-off: ~2× GPS/network
  cadence during a foreground trip. Revert `kAutoLocationInterval` to 60 s if battery
  telemetry warrants.)*
- **Sign-out could strand a stale identity.** `signOut()` cleared the cached
  `CaptainOfficeSession` only *after* a successful network sign-out, so a failed one left
  the device holding a captain identity the app still treated as current — the next
  screen would resolve trips for the captain who just left. The clear now runs in a
  `finally`, and the cubit settles to idle either way. Regression-tested.
- **RTL chevron** on the chats card corrected to left-pointing.

### Known limitations (by design)
- **Foreground-only location** (§6.1) — the single most impactful gap for tracking
  fidelity.
- **`trip_live_locations` RLS open** (§6.2) — compensated at the write path.

### Fixed in the second pass (2026-07-23)

Full write-ups in [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) §3.

- **Chat authorship was undecidable.** The bubble tested `senderName.contains('Captain')`
  while the datasource labels rows `أنت` / `العمليات` — neither branch ever matched, so
  every message including the captain's own rendered as incoming. Authorship is now
  carried as data (`CaptainMessage.isMine`).
- **`StatusUpdatePage` looked like it could end a trip.** Titled "تحديث حالة الرحلة" and
  offering "مكتمل", it only writes a `trip_events` row — a captain could tap it and leave
  believing the trip was finished while the backend still had it `in_progress`. Retitled
  "إبلاغ العمليات", it now states that it does not change the stage, and the three options
  shadowing real transitions (boarding / departed / completed) were removed.
- **Voice and image buttons sent nothing** — they posted the literal strings `Voice note`
  and `Image shared`. Removed until real media upload exists.
- **Stale ops broadcasts replayed on every launch** — the stream's initial snapshot was
  treated as new. It is now the "already seen" baseline.
- **Two enlarged-font overflows** and the **docked-bar height invariant** (§11).
- **Unhandled async failures**: `markAsRead` is fired from a non-awaiting tap handler, and
  `launchUrl` was unchecked. Both contained.

### Fixed in the third pass (2026-07-23)

Full write-ups with evidence in [`CAPTAIN_APP_BUGS.md`](CAPTAIN_APP_BUGS.md).

- **Live sharing stopped when the captain scrolled** — the timer's widget was disposed by
  the sliver list, silently (BUG-301). The most serious defect found in any pass: it broke
  the app's flagship feature under ordinary use, and the only surface that could have shown
  it instead asserted everything was fine.
- **Incident reports had no RLS and full `anon` DML** (BUG-302) — migration applied.
- **The status-allowlist migration was applied** and the hole verified closed (BUG-303).
- **Drill-in chevrons pointed backwards in RTL** (BUG-304) — an over-correction from the
  second pass, now guarded by a rendered-direction test.

### Test-coverage gaps (not defects)
- **Closed:** notifications, communication/chat and incidents now have cubit-level suites.
- **Remaining:** no widget-layout tests for the onboarding request form or the chat
  details page. Neither carries complex logic.

---

## 13. Business & service recommendations

> Superseded by [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) §6, which tiers these by
> business value and adds a recommended sequence. Kept here for continuity.

| # | Feature | Captain value | Business value | Priority | Complexity |
| --- | --- | --- | --- | --- | --- |
| 1 | **Background / foreground-service location** | Keeps sharing when phone is pocketed | Client trust: the map stops going dark mid-trip | **High** | High (platform perms, Android FGS, iOS background modes) |
| 2 | **Captain performance & punctuality analytics** | See own on-time %, ratings | Ops quality signal; incentive basis | High | Medium |
| 3 | **Emergency / SOS escalation** (beyond the current report button) | Fast help while driving | Safety compliance | High | Medium |
| 4 | **Document-expiry reminders** (licence, vehicle papers) | Avoid being pulled off duty | Fleet compliance | Medium | Low–Medium |
| 5 | **Trip proof / completion confirmation** (photo or signature) | Dispute protection | Settlement evidence | Medium | Medium |
| 6 | **Captain earnings / trip payout view** | Motivation, transparency | Retention | Medium | Medium (needs payout model) |
| 7 | **Offline queueing for status/location** | Survives dead zones on intercity routes | No lost fixes/transitions | Medium | Medium |
| 8 | **Incident media attachments** | Richer reports | Faster ops resolution | Low | Low |

Recommendations are **not** implemented — they are prioritized for product decision.

---

## 14. Testing

Captain suite: **247 tests, all passing** (`flutter test test/apps/captain`). Coverage
spans auth cubit + layout, onboarding + activation cubits, assigned-trips (cubit,
home, nav clearance, day summary, countdown), trip-execution (cubit, layout across
stages, `mark_station_arrived` usecase, GPS status card), live-location cubit (cadence,
duplicate-prevention, failure/retry, stop), passenger manifest, trip history (cubit,
detail, filters, labels, layout), profile, theme, and trip-stage logic.

Added in the first pass (3): sign-out lands at idle; a **failed** sign-out still lands at
idle (regression guard for the stale-identity bug); the remembered phone survives
sign-out.

Added in the second pass (**+73**, 174 → 247):

- **Communication** (new file): message authorship; empty/whitespace guard; trimming;
  load failure; ops-broadcast replay suppression; duplicate suppression.
- **Incidents** (new file): submit lifecycle; a failure never reports `submitted`;
  initial state.
- **Notifications** (new file): unread count; mark one; mark all; failure containment;
  stream error; emissions after close.
- **Overflow sweep** (new file): manifest and notification tiles across two widths × three
  font scales, with long Egyptian names and station names as the worst case.
- **Text-scale dimensions** added to the trip-execution, profile, auth and trip-history
  layout suites, and the docked-bar height invariant now runs at every scale with the
  in-flight spinner included.

**Analyzer:** `flutter analyze lib/apps/captain test/apps/captain` → **0 issues**.
(Repo-wide, 25 pre-existing analyzer errors live in unrelated **client** test files —
stale remember-me params — and are out of scope for the Captain App.)
