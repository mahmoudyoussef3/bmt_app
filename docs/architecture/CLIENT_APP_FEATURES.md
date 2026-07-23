# Client App — Feature Catalogue & User Stories

> **Scope.** The passenger flavor of the EWT platform — `lib/apps/client`, entry
> `lib/main_client.dart`. Bilingual Arabic/English with full RTL support; Arabic is the
> primary locale.
>
> **Audience.** Product, operations and engineering. This document describes *what the app
> does and why*, in the language of the person using it. For the engineering conventions
> that govern this code see [`.claude/docs/CLIENT_APP.md`](../../.claude/docs/CLIENT_APP.md);
> for the journeys drawn as flows see
> [`CLIENT_APP_USER_FLOWS.md`](CLIENT_APP_USER_FLOWS.md).
>
> **Last revised.** 2026-07-23 (design-unification and bug-fix pass — see §7).

---

## 1. Who the passenger is

The passenger is someone who needs a seat on an intercity bus, usually today or tomorrow.
They are:

- **Buying, not operating.** They cannot see revenue, driver identities, vehicle plates or
  any other office-internal data. Server-side, they read the platform through the
  `public_trips` view and `public_offices` — the operational tables are closed to them.
- **Choosing between competing offices.** EWT is a marketplace: several transport offices
  sell seats on overlapping corridors, and the passenger picks by price, departure time,
  rating and reputation.
- **On a phone, frequently on mobile data, frequently in Arabic.** Every screen must
  survive RTL, a slow connection and a fare that the office has not priced yet.
- **Anonymous until they need to be.** Browsing routes, offices and departures works
  without an account; only booking requires signing in.

---

## 2. Feature map

| # | Feature | Entry point | Backed by |
|---|---|---|---|
| 1 | Onboarding | first launch | local flag |
| 2 | Authentication | Welcome screen | Supabase email/password |
| 3 | Home / departure board | tab **Home** | `public_trips`, bookings, packages |
| 4 | Route discovery | tab **Routes** | routes + stations |
| 5 | Trip search & booking wizard | Home search, route cards | `public_trips`, `trip_seats` |
| 6 | Seat selection & release | wizard step 3 | `trip_seats` |
| 7 | Packages / subscriptions | Home quick action | `transport_packages` |
| 8 | Payments & checkout | wizard step 6 | payment methods, Paymob, receipts |
| 9 | My Trips | tab **Trips** | bookings + `public_trips` |
| 10 | Live tracking | trip card / details | `trip_live_locations`, `trip_events` |
| 11 | Offices marketplace | Home rail, Routes tab | `public_offices` |
| 12 | Support tickets | Home quick action | support tickets |
| 13 | Communication / chat | Profile, trip details | conversations |
| 14 | Notifications | Home bell | `notifications` (realtime) |
| 15 | Loyalty | Profile | points, tiers, rewards |
| 16 | Referrals | Profile | referral codes |
| 17 | Profile & settings | tab **Profile** | profile, theme, locale |

The shell hosts **four** tabs — Home, Routes, Trips, Profile. Everything else is pushed
onto the root navigator.

---

## 3. Feature detail

### 3.1 Onboarding

**Story.** *As a first-time user, I want to understand what the app is for before it asks
me for anything.*

A short illustrated sequence shown once, gated on a locally stored flag. It never blocks a
returning user, and it is skippable. Failure to read the flag is treated as "already seen"
rather than trapping the user in onboarding.

### 3.2 Authentication

**Story.** *As a passenger, I want to browse without an account and only sign in when I
actually book.*

- **Email + password only.** This is the entire authentication surface.
- **Guest entry** from the welcome screen goes straight to the shell. Booking is what
  forces a sign-in, not opening the app.
- **Remember Me** caches the email/password pair locally, deliberately decoupled from
  sign-in itself so a background poll cannot clobber it. Signing out never clears it.
- **Persistent sessions** come from Supabase's own session cache — a returning user lands
  on the shell, not the welcome screen.
- **Password reset** by email.

> A Google / Apple / Phone provider row used to sit under the email buttons. Every one of
> them opened a "coming soon" sheet — a dead end on the first tap a new user makes. It was
> removed in the 2026-07-23 pass and comes back only when those providers are really wired
> up. Phone/OTP was deleted earlier: the platform has no SMS provider.

### 3.3 Home — the departure board

**Story.** *As a passenger, I want to see what I have booked and what I could book, on one
screen.*

A hero search canvas over a scrolling board:

- **Search pill** — where to, opening the search flow.
- **Quick actions** — Routes, My Trips, Packages, Support.
- **Active bookings** with their real status: under review, confirmed, trackable.
- **Upcoming trips** and **destination suggestions**.
- **Active package** card when the rider holds a subscription.
- **Offices rail** — a shortcut into the marketplace. If the directory fails to load it is
  silently absent; Home is a departure board, not an office browser.
- **Notification bell** with unread state.

Home re-loads on app resume, so a missed realtime event or a reconnect after being offline
self-corrects. Pull-to-refresh reloads Home and the offices directory together.

### 3.4 Route discovery (tab **Routes**)

**Story.** *As a passenger, I want to see which corridors are served before I commit to a
date.*

A hub of the corridors the platform runs, with search, a popular-routes list, and a
map-based pickup/destination picker. Selecting a corridor leads to the departures on it.

### 3.5 Trip search and the booking wizard

**Story.** *As a passenger, I want to go from "I need to get to Alexandria" to a paid seat
without losing my place.*

Search resolves to a route, then a list of departures with vehicle, time, seats left and
fare. Choosing one opens the **six-step wizard**:

| Step | Question |
|---|---|
| 1 · Stops | Where do you board and get off? |
| 2 · Trip | Which departure? |
| 3 · Seat | Which seat? |
| 4 · Package | Single ticket or a commute package? |
| 5 · Summary | Is this right? |
| 6 · Payment | How are you paying? |

Wizard rules that matter:

- The system back gesture **walks the wizard backwards** one step before leaving it, so
  correcting a stop never discards the session.
- While a booking is being confirmed the screen is **blocked and the back arrow is
  disabled but still drawn** — a second confirm would race the first, and removing the
  arrow would reflow the header at the worst moment.
- The block stays up through the card-gateway webview *and* the "did that actually clear?"
  verification, not just while the RPC runs.
- A fare the office has not published renders as "not priced yet", never as `EGP 0`.

### 3.6 Seat selection & release

**Story.** *As a passenger, I want to pick where I sit, and give the seat back if my plans
change.*

A real cabin map from `trip_seats`, with the driver position drawn as non-bookable.
Availability truth is the seat state (`available → reserved → paid`), never a cached count.
A failed confirm **releases the lock it took**, so no seat is ever stranded; a seat that
already carries a booking is never released.

### 3.7 Packages / subscriptions

**Story.** *As a commuter, I want a multi-ride package instead of buying the same ticket
every morning.*

- **The catalogue** (`/subscription`) lists plans for a corridor as flat multiples of the
  single fare — packages are never priced as `rides × fare`.
- **My Subscription** (`/my-subscription`) shows what the rider holds: validity window,
  rides used, rides left.
- A package is always scheduled against the trip picked in the wizard, never independently.

### 3.8 Payments & checkout

**Story.** *As a passenger, I want to pay the way I normally pay, and know where I stand
if it needs a human to check.*

Methods: **card** (Paymob-hosted checkout), **InstaPay**, **bank transfer**, **Vodafone
Cash**, and **wallet balance**.

- A transfer-type method routes to **receipt upload** instead of "pay now" — the rider
  attaches proof and the booking waits on office approval.
- An **underfunded wallet stays visible and selectable** and says how short it is; hiding
  it would leave the rider wondering where their balance went. The pay button carries the
  same reason.
- **Promo codes** are optional and folded away until asked for. A rejected code is a
  rejected code, not a broken checkout — the rider can still pay full fare.
- A booking with something missing is **named**, not silently accepted.

### 3.9 My Trips (tab **Trips**)

**Story.** *As a passenger, I want one place that shows every trip I have, in whatever
state it is in.*

Filter tabs for **upcoming / active / completed / cancelled**, each with a live count.
Trip details carry the boarding pass, the crew, the vehicle, the seats, the payment state,
the cabin map, and the actions that are legal right now:

- **Track Vehicle** appears only once the trip is under way **and this booking's own
  payment is approved** — a trip can be in progress for other passengers while this rider
  is still awaiting review.
- **Cancel** lives in the docked bottom bar only, never mirrored into the header where it
  would sit one stray tap from the back arrow.
- **Rate this trip** appears once, on a completed and unrated trip.

### 3.10 Live tracking

**Story.** *As a passenger waiting at a stop, I want to see where the bus actually is.*

A live map with the vehicle position, the route line, stop markers and route-completion
progress. Position comes from a realtime subscription with an 8-second poll as a fallback,
because realtime delivery alone was not reliable enough to stake the screen on.

Every state degrades to a sentence rather than a crash: loading, no fix yet, no trackable
booking, and error each render their own hint. **No percentage is ever invented.**

### 3.11 Offices marketplace

**Story.** *As a passenger, I want to choose who I travel with, not just when.*

- **Directory** — every active office, best-rated first, **searchable by company name or
  by a city it serves** (a rider going to Alexandria searches the city, not a company they
  have never heard of). A search that matches nothing says so and offers a way back to the
  full list — distinct from "no offices are operating yet".
- **Office profile** — identity, passenger rating, then **departures on sale** first
  (what the rider can act on today) and the **corridors it runs** second (the fallback for
  a date the board does not reach). Tapping a departure carries route, date and time
  straight into the booking flow.
- Office ratings are rated explicitly by passengers on completed trips — never inferred
  from driver or vehicle scores.
- A sold-out departure **stays listed but stops being tappable**: the rider learns the bus
  exists and fills up, which is what brings them back earlier next time.

### 3.12 Support

**Story.** *As a passenger with a problem, I want to raise it and then see what happened.*

Ticket creation with a topic, a description, an optional related booking and attachments.
The ticket list shows status; ticket details show the thread and the agent's note. On
success the rider lands on the ticket they just created, not back on an empty form.

### 3.13 Communication

Threaded conversations with the office and support, with a search box and category filters
over the thread list.

### 3.14 Notifications

**Story.** *As a passenger, I want to know when my booking is approved, my trip changes, or
my package is about to run out.*

A live subscription (not a fetch) over the `notifications` table, with:

- **Category filtering** — All, Booking, Payment, Trip, News, Offers, Alerts. The strip
  only appears once there is something to filter; a category with nothing in it says so
  without claiming the whole inbox is empty.
- **Mark one / mark all as read.**
- **Deep links.** A notification carries a server-supplied `action_url`. Unrecognised
  values land harmlessly on the shell rather than throwing (see §7).

### 3.15 Loyalty

Points, tiers and a reward catalogue. Tier branding (colours, icons) is operator-configured
on the backend and resolved to Flutter values in the presentation layer. A failed redeem
snackbars the reason and keeps the panel loaded — only an initial load failure is fatal.

### 3.16 Referrals

A shareable referral code with a rewards ledger and a share sheet.

### 3.17 Profile & settings

The rider's identity and real booking counts (never decorative placeholders), plus
language, theme (light/dark/system), legal documents, and sign-out behind a confirmation.

---

## 4. Cross-cutting behaviour

### 4.1 Navigation

- Route constants live **with their feature** (`BookingRoutes`, `TripsRoutes`, …);
  app-shell-only paths live in `ClientRoutes`. Every path is declared exactly once, and a
  test enforces that the router registers exactly the declared surface — no raw strings.
- The four shell tabs stay mounted in an `IndexedStack`, so an in-flight load is never
  orphaned by a tab switch.
- An unknown route can never crash the app: `onUnknownRoute` lands on the shell.

### 4.2 The header

Every screen uses **`ClientAppBar`** (or `ClientSliverAppBar` for collapsing headers).
It owns one title style, one flat surface, start-aligned titles, and a back arrow that
appears only when there is something to pop. Variants it supports: a subtitle, a leading
brand mark or avatar, a disabled-but-visible back arrow, an explicit navigation glyph
(a close icon for a modal checkout), and a progress bar below the toolbar.

### 4.3 Money

All fares render as `EGP 100` / `ج.م ١٠٠` — symbol, space, amount, and no trailing `.00`
on a whole number. A missing or zero amount is said out loud ("not priced yet"), never
rendered as a fake `EGP 0`.

### 4.4 Loading and failure

Every list has a **skeleton in the shape of its loaded layout**, not a bare spinner.
Errors are a retryable `ClientErrorCard`. A refresh that fails keeps the last usable data
on screen rather than replacing it with an error.

### 4.5 Localization and RTL

All user-facing copy comes from generated `context.l10n` keys; there are no hardcoded
user-facing strings in the client. Directional glyphs are mirrored by Flutter's own
`matchTextDirection` handling — see §7 for the bug this fixed.

---

## 5. What the passenger cannot do

Deliberate boundaries, enforced server-side and mirrored in the UI:

- Read `operation_trips` directly, or any revenue, driver id, vehicle id, plate number,
  occupancy or internal note.
- Approve their own payment. Approval is the office's, through `office_approve_payment`.
- See another office's data — cross-office isolation is enforced by RLS, not by the client.
- Buy a seat on a past-dated trip: the client only sells `trip_date >= today`.

---

## 6. Known gaps

- **Wallet top-up** has no flow. The wallet can be spent but not funded in-app.
- **Social sign-in** is not implemented; it needs provider credentials and native config.
- `TripLiveTrackingCard` resolves its cubit from the DI container inside `build()` rather
  than receiving it from a route scope. It works, but it makes the screen awkward to test
  and is the one place that reaches into `clientGetIt` from a widget.

---

## 7. Fixed in the 2026-07-23 pass

| Defect | Effect | Fix |
|---|---|---|
| `DirectionalIcon` double-mirrored arrows | Every back/forward arrow and chevron pointed **the wrong way in Arabic** across 39 files — Flutter already mirrors `matchTextDirection` glyphs, and the widget flipped them again | Mirror only glyphs Flutter will not mirror itself |
| `action_url` pushed unchecked | Tapping a package-expiry notification threw "Could not find a generator for route" — `/subscriptions` was never a registered route. Also reachable from an FCM tap while backgrounded | Registered the legacy path as an alias of My Subscription, plus an `onUnknownRoute` safety net |
| `TripProgressSummary` blind cast | `state as TrackingLoaded` threw on `TrackingEmpty` — an ordinary "nothing to track yet" answer — taking the **entire trip-details list** down with it and leaving a bare app bar | Exhaustive switch over the sealed state |
| Two money formatters | The same fare read `EGP 100` while browsing and `EGP100.00` at checkout | One format everywhere |
| Raw route strings | `'/tracking'` and `'/booking/search'` hardcoded in five call sites | Route constants |
| Eight bespoke app bars + ~15 hand-rolled `AppBar`s | Four different title styles, `centerTitle` flipping between screens, three background sources, elevation 0/1/default | One `ClientAppBar` / `ClientSliverAppBar` |
| Unwired features | Notification category filtering and offices search were fully built in the cubits but never rendered | Wired both, with tests |
| Test suite | 59 failing / 247 passing; most suites never provided localizations, so widgets crashed on `context.l10n` before asserting anything | Shared harness; **475 passing, 0 failing** |
