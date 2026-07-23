# Client App — User Journeys

> **Scope.** The passenger journeys through `lib/apps/client`, drawn end to end.
> For what each feature *is*, see [`CLIENT_APP_FEATURES.md`](CLIENT_APP_FEATURES.md).
> For the engineering conventions, see
> [`.claude/docs/CLIENT_APP.md`](../../.claude/docs/CLIENT_APP.md).
>
> **Last revised.** 2026-07-23.

---

## 1. The shape of a passenger's trip

```mermaid
flowchart LR
    A[Discover] --> B[Choose]
    B --> C[Book]
    C --> D[Pay]
    D --> E[Wait for approval]
    E --> F[Travel]
    F --> G[Rate]

    A -.- A1["Home board<br/>Routes tab<br/>Offices directory"]
    B -.- B1["Departures<br/>Vehicle · fare · seats left"]
    C -.- C1["6-step wizard<br/>Seat locked"]
    D -.- D1["Card / InstaPay<br/>Transfer / Wallet"]
    E -.- E1["Office approves<br/>Seat: reserved → paid"]
    F -.- F1["Boarding pass<br/>Live tracking"]
    G -.- G1["Driver · vehicle<br/>· office rating"]
```

The one thing that shapes every screen: **a booking is not confirmed when it is paid.**
An office still has to approve it. Every surface that shows a booking distinguishes
"under review" from "confirmed", and tracking stays locked until this rider's own payment
clears.

---

## 2. First launch and landing

```mermaid
flowchart TD
    S[Launch] --> SG[Splash gate]
    SG --> OB{Seen onboarding?}
    OB -- no --> ON[Onboarding]
    ON --> W
    OB -- yes --> AU{Supabase session?}
    AU -- yes --> SH[Shell · Home tab]
    AU -- no --> W[Welcome]
    W --> SI[Sign in]
    W --> SU[Create account]
    W --> G[Continue as guest]
    SI --> SH
    SU --> AS[Account created] --> SH
    G --> SH
```

The splash holds until onboarding status resolves. The session check reads
`currentSession` as well as the auth stream, so a restored session lands on the shell
without a flash of the welcome screen.

**Guest mode is real.** A guest browses Home, Routes, offices and departures. The wall is
at booking, not at launch.

---

## 3. Discovery — three ways in

```mermaid
flowchart TD
    H[Home] --> S1[Search pill] --> SR[Search]
    H --> QA[Quick action: Routes] --> PR[Popular routes]
    H --> OR[Offices rail] --> OD[Offices directory]
    RT[Routes tab] --> RH[Routes hub]
    RH --> MAP[Map pickup/destination]
    RH --> PR
    OD --> OP[Office profile]
    OP --> DEP[Departures on sale]
    OP --> COR[Corridors it runs]
    SR --> RS[Route selection]
    PR --> RS
    MAP --> RS
    DEP --> RS
    COR --> RS
    RS --> RO[Route overview]
    RS --> VL[Vehicle listing]
    RO --> WZ[Booking wizard]
    VL --> VD[Vehicle details] --> WZ
```

All roads converge on the same route-selection surface, so there is one booking entry
point rather than four. An office departure carries route + date + time with it, so the
rider lands with those already chosen.

### 3.1 Offices directory search

```mermaid
flowchart TD
    OD[Directory loads] --> Q{Query typed?}
    Q -- no --> ALL[Every active office<br/>best-rated first]
    Q -- yes --> M{Matches name<br/>or a service area?}
    M -- yes --> HIT[Matching offices]
    M -- no --> NONE["No office matches “…”<br/>+ Clear search"]
    NONE --> CLR[Clear] --> ALL
    EMPTY[No offices at all] --> E2["No offices are open<br/>for booking right now"]
```

"Nothing matched your search" and "no offices exist" are deliberately different messages —
only one of them is the rider's to fix. A refresh keeps the query applied.

---

## 4. The booking wizard

```mermaid
flowchart TD
    W1[1 · Stops<br/>board & alight] --> W2[2 · Trip<br/>which departure]
    W2 --> W3[3 · Seat<br/>cabin map]
    W3 --> W4[4 · Package<br/>single or commute]
    W4 --> W5[5 · Summary<br/>review]
    W5 --> W6[6 · Payment]
    W6 --> CF{Confirm}
    CF -- writing --> BLK[Screen blocked<br/>back arrow drawn but inert]
    BLK --> OK[Booking created<br/>seat reserved]
    BLK --> FAIL[Failed] --> REL[Seat lock released]
    OK --> PAY[Payment route]
    W2 -. edit chip .-> W1
    W5 -. edit chip .-> W2
    W5 -. edit chip .-> W3
```

- The **system back gesture walks the wizard backwards** before leaving it.
- Edit chips on the summary jump straight back to the step that owns the choice.
- A failed confirm **hands the seat lock back**; a seat that already carries a booking is
  never released.

---

## 5. Payment and approval

```mermaid
flowchart TD
    CO[Checkout] --> M{Method}
    M -- Card --> PM[Paymob hosted page]
    PM --> V[Verifying payment]
    V --> OKC[Cleared]
    V --> NOC[Declined]
    M -- InstaPay / Bank transfer --> RU[Receipt upload]
    RU --> PEND[Pending office review]
    M -- Wallet --> WB{Balance ≥ total?}
    WB -- no --> SHORT["Shown as “short by EGP N”<br/>pay button disabled"]
    WB -- yes --> OKC
    OKC --> REV[Booking under review]
    PEND --> REV
    REV --> APP{Office decision}
    APP -- approve --> CONF[Confirmed · seat paid]
    APP -- reject --> REJ[Rejected · seat released]
    CONF --> TRK[Tracking unlocked]
```

The rider is never dropped into an unexplained state: an underfunded wallet says how short
it is *before* the tap, a transfer says it is waiting on review, and a card that has not
been verified yet keeps the screen blocked rather than claiming success.

---

## 6. My Trips and trip details

```mermaid
flowchart TD
    T[Trips tab] --> F{Filter}
    F --> UP[Upcoming]
    F --> AC[Active]
    F --> CM[Completed]
    F --> CN[Cancelled]
    UP --> TD[Trip details]
    AC --> TD
    CM --> TD
    CN --> TD
    TD --> BP[Boarding pass]
    TD --> CREW[Captain · call / chat]
    TD --> SEAT[Cabin map]
    TD --> PAYC[Payment state]
    TD --> ACT{Actions}
    ACT --> TRKB["Track Vehicle<br/>(in progress AND payment approved)"]
    ACT --> CAN["Cancel<br/>(docked bar only)"]
    ACT --> RATE["Rate this trip<br/>(completed, unrated)"]
    ACT --> AGAIN["Book another trip<br/>(completed)"]
```

The gate on **Track Vehicle** is the subtle one: the trip being in progress is not enough,
because a trip runs for other passengers while this rider's payment may still be under
review.

---

## 7. Live tracking

```mermaid
flowchart TD
    TR[Open tracking] --> L[Loading]
    L --> ST{Tracking state}
    ST -- Loaded + GPS fix --> MAP["Map · vehicle · route<br/>+ % of route covered"]
    ST -- Loaded, no fix --> WAIT["“Waiting for the vehicle”"]
    ST -- Empty --> NONE["“Nothing to track”"]
    ST -- Error --> ERR["“Position unavailable”"]
    MAP --> RTS[Realtime subscription]
    MAP --> POLL[8s poll fallback]
```

Every branch renders a sentence. Nothing here fabricates a percentage, and no state
crashes the card — the `TrackingEmpty` branch used to, taking the whole trip-details list
with it.

---

## 8. Notifications

```mermaid
flowchart TD
    N[Bell] --> INBOX[Live subscription]
    INBOX --> E{Any notifications?}
    E -- no --> EMPTY["“You're all caught up”<br/>no filter strip"]
    E -- yes --> BAR[Category strip]
    BAR --> C{Category}
    C -- All / Booking / Payment /<br/>Trip / News / Offers / Alerts --> LIST[Filtered feed]
    LIST --> CE{Any in this category?}
    CE -- no --> NC["“Nothing in this category”<br/>strip stays, so there is a way back"]
    LIST --> TAP[Tap]
    TAP --> MR[Mark read]
    TAP --> AU{action_url}
    AU -- known route --> NAV[Navigate]
    AU -- unknown / empty --> SHELL[Land on shell · never throw]
```

---

## 9. Packages

```mermaid
flowchart TD
    HQ[Home quick action] --> HAS{Holds a package?}
    HAS -- yes --> MS[My Subscription<br/>validity · rides used · rides left]
    HAS -- no --> CAT[Package catalogue]
    CAT --> PD[Plan details]
    PD --> WZ[Booking wizard step 4]
    EXP[Package expired notification] --> MS
```

The expiry notification is the one that used to crash: it carries `/subscriptions`, which
was never a registered route.

---

## 10. Support

```mermaid
flowchart TD
    SC[Support centre] --> NEW[New ticket]
    NEW --> FORM[Topic · description<br/>· related booking · attachments]
    FORM --> SUB{Submit}
    SUB -- ok --> TD[Ticket details<br/>lands on what was just created]
    SUB -- fail --> ERRS[Reason snackbarred<br/>form kept]
    SC --> LIST[My tickets] --> TD
    TD --> THREAD[Status · agent note · attachments]
```

---

## 11. Sign-out

```mermaid
flowchart TD
    P[Profile] --> SO[Sign out] --> CONF{Confirm?}
    CONF -- no --> P
    CONF -- yes --> CLR[Supabase session ends]
    CLR --> WEL[Welcome]
    CLR -. Remember Me survives .-> RM[Email prefilled next visit]
```

Signing out ends the session but never clears Remember Me — the rider asked the app to
remember them, not to stay logged in forever.

---

## 12. Journeys verified in this pass

| Journey | How |
|---|---|
| Route table completeness | `client_router_test` — every declared constant registered, every registered path declared, no duplicates |
| Header behaviour across all screens | `client_app_bar_test` — back visibility, custom back, disabled back, long titles, RTL |
| Offices search incl. empty vs no-match | `offices_directory_search_test` (9 tests) |
| Notification filtering incl. empty category | `notifications_screen_test` (4 tests) |
| Tracking states never crash the trip screen | `trip_progress_summary_test` |
| RTL arrow mirroring | `directional_icon_test` |
| Trip actions per status & payment state | `trip_details_view_test`, `trip_details_presentation_test` |
| Checkout: totals, transfer, underfunded wallet, promo | `payment_checkout_screen_test`, `payment_widgets_test` |
| Wizard steps, summary, payment | `wizard_*_step_test` |

**Suite status: 475 passing, 0 failing** (baseline before this pass: 247 passing,
59 failing).
