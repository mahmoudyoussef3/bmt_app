# Captain App — Defect Register

> Every defect found by the production-readiness audits, with the evidence that proved it
> and the test or query that proves it stays fixed.
>
> **Companions.** [`CAPTAIN_APP.md`](CAPTAIN_APP.md) (architecture) ·
> [`CAPTAIN_APP_FEATURES.md`](CAPTAIN_APP_FEATURES.md) (what each feature does) ·
> [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) (delivery status) ·
> [`CAPTAIN_APP_USER_FLOWS.md`](CAPTAIN_APP_USER_FLOWS.md) (journeys).
>
> **Third pass: 2026-07-23.** Four defects, two of them live security holes on the
> production-bound database and one a silent failure of the app's flagship feature.
>
> **A note on severity.** "Critical" here means *it costs money, safety or trust in
> production* — not *it looks bad in review*.

---

## Legend

| Field | Meaning |
| --- | --- |
| **Severity** | Critical / High / Medium / Low |
| **Class** | Security · Functional · Layout · Robustness · UX |
| **Proof** | What was actually run to demonstrate the defect, before the fix |
| **Guard** | The test or query that fails if it regresses |

---

# Pass 3 — 2026-07-23

## BUG-301 · Live location sharing stopped when the captain scrolled

| | |
| --- | --- |
| **Severity** | 🔴 Critical |
| **Class** | Functional — silent failure |
| **Status** | ✅ Fixed |
| **Files** | [`trip_location_auto_share.dart`](../../lib/apps/captain/features/live_location/presentation/widgets/trip_location_auto_share.dart) |

### Impact

The 30-second location cadence is the Captain App's reason for existing on the platform:
it is what makes the client's tracking map move. It stopped whenever the captain scrolled
down the trip-execution page — to check the route, the next stop, or the passenger
manifest — and it did so **silently**. No error, no state change, nothing on screen.

Worse than stopping: when the captain scrolled back up, the card rebuilt from scratch,
restarted the timer, and displayed **"مشاركة الموقع تلقائياً كل 30 ثانية"** again. The one
surface that could have revealed the outage was the surface asserting everything was fine.
The client's map simply went stale mid-trip, which reads to a paying passenger as "the bus
is not moving."

### Root cause

`TripLocationAutoShare` owns the timer through a `BlocProvider` it creates itself, and it
is mounted as one child of the trip-execution page's `SliverList.list`. A sliver list
builds children **lazily**: an element scrolled beyond the viewport *and* the cache extent
is deactivated and disposed. Disposal closed the provider's `LiveLocationCubit`, and
`close()` cancels the timer — correctly, which is why nothing looked wrong.

The cubit's own unit tests could never catch this. They drive the cubit directly and
never scroll; the cadence they assert was real, but the *widget carrying it* was not
guaranteed to be alive. **A verified interval is worth nothing without a verified
lifetime.**

The page even carried a comment claiming the widget was "kept mounted across the whole
trip". It was an intention, not a mechanism.

### Proof (before the fix)

`auto_share_scroll_survival_test.dart`, reproducing the page's real sliver structure:

```
scrolled away, then 3 × 30s elapsed
  expected: 3 fixes
  actual:   0 fixes
```

### Fix

`_AutoShareControllerState` now uses `AutomaticKeepAliveClientMixin` with
`wantKeepAlive => widget.enabled` — the element is held across scrolling **only while a
trip is actually under way**, so a finished trip still releases it. `updateKeepAlive()` is
called when `enabled` changes.

### Guard

`test/apps/captain/features/live_location/auto_share_scroll_survival_test.dart` — two
tests: sharing survives a 2500 px scroll, and three scrolled-away intervals still produce
exactly three fixes.

### Related

`TripLocationAutoShare` was the **only** widget in the captain source that provides a
cubit from inside a scrollable list — verified by sweeping every
`features/*/presentation/widgets/` file for `BlocProvider`. No sibling instance of this
bug exists today.

---

## BUG-302 · Incident and SOS reports were world-readable and world-deletable

| | |
| --- | --- |
| **Severity** | 🔴 Critical |
| **Class** | Security |
| **Status** | ✅ Fixed — migration applied to the live database |
| **Migration** | [`20260723120000_driver_trip_reports_rls.sql`](../../supabase/migrations/20260723120000_driver_trip_reports_rls.sql) |

### Impact

`driver_trip_reports` is where the Captain App files incident and SOS reports. On the live
database it had **row-level security disabled**, while `anon` — the unauthenticated role
the public client uses — held `SELECT`, `INSERT`, `UPDATE`, `DELETE` and `TRUNCATE`.

An unauthenticated visitor could therefore:

- **read every incident report on the platform** — every breakdown, every emergency, every
  passenger dispute, across every office;
- **delete all of them**, destroying the safety record;
- **forge an SOS attributed to a real captain** who never sent it.

Two of those are integrity failures on a safety feature. The third fabricates a distress
signal in a driver's name.

### Root cause

Not a design decision — an **omission**. The original schema
(`migration_02_three_app_architecture.sql`) created the table *with* RLS and two correct
policies. `all_app_scheme.sql`, the anon-era dashboard schema, then blanket-disabled RLS
across a long list of tables. The multi-office hardening sweep
(`20260721090200_multi_office_rls.sql`) re-enabled it on ~22 of them — but
`driver_trip_reports` was **not in that list**.

The two original policies survived and still read correctly on inspection, which is what
made this easy to miss: `pg_policies` showed sane, driver-scoped rules. They were inert.
**A policy on a table without RLS is documentation, not enforcement.**

Unlike `trip_live_locations` — deliberately left open so realtime delivery to client maps
works — there is no delivery reason to keep this table readable. Nothing outside the
Captain App's insert touches it.

### Proof (before the fix)

Run as `anon` against the live database, inside `BEGIN … ROLLBACK`:

| Attempt | Result |
| --- | --- |
| `SELECT` every report | **SUCCEEDED** |
| `DELETE` every report | **SUCCEEDED** |
| `INSERT` an SOS naming a real captain | **SUCCEEDED** |

### Fix

RLS enabled; `anon` revoked entirely; the two legacy policies replaced with the
multi-office convention:

- `driver_trip_reports_captain_rw` — `driver_id = current_driver_id()`
- `driver_trip_reports_office_manage` — the trip's `office_id = current_office_id()`

The office policy is written now so the Dashboard's future incident view is already
scoped.

### Guard

Dry-run assertions, re-runnable against the live database:

| Actor | Attempt | After fix |
| --- | --- | --- |
| anon | SELECT / INSERT / DELETE | permission denied (all three) |
| captain | file own report | allowed |
| captain | read own reports | allowed |
| captain | file as another driver | RLS violation |
| ordinary client | SELECT reports | 0 rows |

---

## BUG-303 · A captain could cancel their own trip through a crafted RPC

| | |
| --- | --- |
| **Severity** | 🟠 High |
| **Class** | Security |
| **Status** | ✅ Fixed — migration applied to the live database |
| **Migration** | [`20260723090000_captain_status_transition_allowlist.sql`](../../supabase/migrations/20260723090000_captain_status_transition_allowlist.sql) |

### Impact

`captain_update_trip_status` gated on **ownership only** — it checked *whose* trip it was,
never *what status* was being set — then delegated to `update_trip_status`, whose
transition graph permits `open_for_booking | boarding | in_progress → cancelled`, marked
in its own comments as "ops cancels" / "admin emergency only".

Cancelling runs two further statements: it releases **every held seat** and cancels
**every open booking** on the trip. The RPC is granted to `authenticated`, so any captain
could wipe out their own trip's revenue with one crafted call. The Captain App renders no
cancel control, so this was unreachable through the UI — but the UI was the only thing
stopping it.

This was identified and written up in pass 2; it had **not been applied to the database**.
This pass confirmed the hole was still live, then closed it.

### Proof (before the fix)

Impersonating a real captain against a real `open_for_booking` trip, inside
`BEGIN … ROLLBACK`:

```
crafted call: captain_update_trip_status(<trip>, 'cancelled')
  → succeeded
  → bookings cancelled: 1 of 1
  → (true state before and after rollback: open_for_booking, 0 cancelled, 1 held seat)
```

### Fix

The wrapper now allowlists the three transitions a captain actually performs —
`boarding`, `in_progress`, `completed` — and raises `status_not_allowed_for_captain`
otherwise. Operations keeps the full graph through `office_update_trip_status`, untouched.

The app already sent only those three statuses and its error handler already recognised
the new rejection, so applying this was a no-op for the client.

### Guard

Verified against the live function after applying:

| Attempt | Result |
| --- | --- |
| crafted `cancelled` | `status_not_allowed_for_captain` |
| crafted `open_for_booking` | `status_not_allowed_for_captain` |
| bogus status | `status_not_allowed_for_captain` |
| legitimate boarding → in_progress → completed | all allowed |
| another captain's trip | `not_your_trip` |
| non-captain caller | `not_a_captain` |

---

## BUG-304 · Drill-in chevrons pointed backwards in RTL

| | |
| --- | --- |
| **Severity** | 🟡 Medium |
| **Class** | UX — RTL correctness |
| **Status** | ✅ Fixed |
| **Files** | `captain_list_group.dart` · `trip_history_card.dart` · `chats_page.dart` |

### Impact

Every drill-in row in the app — the shared list row used across profile and settings, the
trip-history card, and the trip-chats entry — displayed a chevron pointing **right**. In
an RTL app the next screen arrives from the left, so a right-pointing chevron reads as
"go back". Three of the app's most-used affordances pointed away from where they led.

### Root cause

An over-correction. Material's directional icons carry `matchTextDirection: true`, and
`Icon` wraps those in a horizontal flip when the ambient `Directionality` is RTL
(`widgets/icon.dart`). The glyph name is authored **for LTR** and the framework mirrors
it.

Pass 2 changed these call sites from `chevron_right` to `chevron_left` "to match RTL" and
recorded it as a fix. That mirrored an already-correct icon a second time. The
back-arrows elsewhere in the app were never touched and were correct all along, precisely
because they were left to the framework.

**The rule:** author directional icons for LTR and let `Directionality` do the mirroring.
Reaching for the left-named icon "because the app is Arabic" is the bug.

### Proof (before the fix)

`captain_rtl_direction_test.dart` computes the *effective on-screen* direction —
glyph direction XOR the framework's RTL mirror — rather than asserting on the icon's name:

```
drill-in row rendered in RTL
  expected: points left
  actual:   points right
```

### Fix

All three sites use `Icons.chevron_right_rounded`, which the framework mirrors to point
left under the app's RTL. Each carries a comment explaining why the LTR-named icon is the
correct one.

### Guard

`test/apps/captain/captain_rtl_direction_test.dart` — four tests: the mirroring rule
itself (re-derived from `matchTextDirection` so it tracks upstream), back/forward arrow
semantics, the rendered direction of a real drill-in row, and a source sweep asserting
**no captain file names a left chevron**.

---

# Open — not fixed

## RISK-305 · `trip_live_locations` has no row-level security

| | |
| --- | --- |
| **Severity** | 🟠 High |
| **Status** | ⚠️ Open — accepted limitation, deliberately not changed in this pass |

The table is kept open so Supabase Realtime delivery to client tracking maps works;
delivery was verified in that configuration. `anon` holds full DML on it, and any
authenticated user could in principle insert arbitrary positions.

**Compensating control (verified this pass).** Ownership is enforced at the *write path*:
`SupabaseLocationDatasource` stamps the **server-resolved** driver from
`CaptainIdentityProvider` — never a client-supplied id — and scopes the trip lookup by
`driver_id`, so a captain cannot push positions onto a trip that is not theirs.

**Why it was not fixed here.** Enabling RLS risks breaking live delivery to the client
map, which cannot be verified from a SQL session. Closing it properly needs a policy
proven against a real subscribed client. Doing it blind on the production-bound database
during an audit would trade a known, contained risk for an unknown outage on the
customer-facing feature.

**Recommended fix:** add a SELECT policy for clients holding a booking on the trip plus an
INSERT policy mirroring the write path, enable RLS, then verify a real client map still
moves before committing.

## RISK-306 · Other tables with RLS off and full `anon` DML — outside captain scope

The sweep that found BUG-302 checked **every** table. Eight more are in the same state.
They belong to the Client and Dashboard surfaces, which this audit was scoped not to
change, so they are **reported, not touched**:

| Table | Rows | Note |
| --- | --- | --- |
| `support_messages` | 3 | Customer-support conversation content |
| `support_attachments` | — | Has policies defined but inert |
| `support_timeline_events` | — | Has policies defined but inert |
| `operation_complaints` | 0 | No policies at all |
| `trip_progress_events` | 0 | Has a policy but inert |
| `routes` | — | No policies at all |
| `user_roles` | 1 | Still read by the Dashboard tickets datasource |
| `admins` | 1 | Legacy; **not** an auth source |

**On `admins` / `user_roles`:** these are *not* privilege-escalation vectors today.
Authorisation resolves through `is_admin()` → `office_users` and `is_platform_admin()` →
`platform_admins`, and both of those tables have RLS enabled. They are stale tables that
should be retired.

`support_messages` is the one carrying real data and deserves the same treatment
`driver_trip_reports` just received.

---

# Passes 1–2 — 2026-07-23 (earlier)

Full write-ups in [`CAPTAIN_APP_STATUS.md`](CAPTAIN_APP_STATUS.md) §3. Summarised here so
the register is complete.

| ID | Defect | Severity | Class | Status |
| --- | --- | --- | --- | --- |
| BUG-201 | Chat authorship undecidable — bubble tested `senderName.contains('Captain')` while rows are labelled `أنت`/`العمليات`, so every message rendered as incoming | High | Functional | ✅ Fixed — authorship carried as data (`isMine`, verified this pass to derive from `sender_type`) |
| BUG-202 | `StatusUpdatePage` looked like it could end a trip — offered "مكتمل" but only wrote a `trip_events` row | High | Functional | ✅ Fixed — retitled "إبلاغ العمليات", lifecycle-shadowing options removed |
| BUG-203 | Voice and image buttons posted the literal strings `Voice note` / `Image shared` | Medium | Functional | ✅ Fixed — removed until real upload exists |
| BUG-204 | Stale ops broadcasts re-announced on every launch — the stream's initial snapshot was treated as new | Medium | UX | ✅ Fixed — first emission is the "already seen" baseline |
| BUG-205 | Execution canopy stage chip overflowed by up to 51 px at font scale 1.6 | Medium | Layout | ✅ Fixed |
| BUG-206 | Docked action bar changed height at enlarged fonts (112 px vs 89 px at scale 1.6), reflowing the page mid-transition | Medium | Layout | ✅ Fixed — shared scaled height across all four variants |
| BUG-207 | Trip-history time strip overflowed by up to 32 px at enlarged fonts | Medium | Layout | ✅ Fixed |
| BUG-208 | `markAsRead` and `launchUrl` failures escaped as unhandled async errors | Medium | Robustness | ✅ Fixed |
| BUG-209 | Sign-out could strand a stale identity — the cached session was cleared only after a *successful* network sign-out | High | Security | ✅ Fixed — clear moved to `finally` |
| BUG-210 | Live-tracking cadence had drifted to 60 s against a documented 30 s | Medium | Functional | ✅ Fixed — see BUG-301 for why the interval alone was not enough |

---

## Where the bugs came from

Three of this pass's four defects share a shape worth naming, because it predicts where
the next one will be:

1. **BUG-301** — a correct unit test on a component whose *lifetime* nothing tested.
2. **BUG-302** — a correct-looking policy on a table where enforcement was switched off.
3. **BUG-304** — a correct-looking fix applied on top of a framework that had already
   handled it.

In all three the artefact you would inspect — the test, the policy, the icon name — read
correctly. The defect lived in the layer underneath, and only running the thing exposed
it. Reading the code was not enough for any of them.
