# Dashboard — Performance

The console is a Flutter Web app an operator keeps open all day. Its performance problems
have never been rendering; they are **query volume** and **emission rate**. Measured
2026-08-16.

---

## 1. What was actually costing something

Four defects, in the order they mattered.

### 1.1 A realtime storm on الحجوزات · **fixed**

```dart
// before
_client.from('operation_bookings')
    .stream(primaryKey: ['id'])
    .asyncMap((_) => fetchBookings());     // full joined re-read, per event
```

Realtime carries bare rows; the board needs the trip, route, driver, vehicle and package
joined onto them, which a stream cannot do — so every change had to be answered by
re-running the enriched select. Answering each change *on its own* meant:

- one bulk approval of 20 bookings → **20 full-table reads**
- a busy sales day → a permanent one, since `asyncMap` queues rather than drops

Now the stream is a signal, and two guards make the re-read proportional to activity
rather than to row count: a burst is coalesced into one read (`realtimeSettle`, 400ms),
and while a read is in flight the next is not started — it is remembered and run once the
first returns.

### 1.2 An unbounded subscription behind the notifications bell · **fixed**

```dart
// before — no filter, no limit, open for the whole session
.stream(primaryKey: ['id'])
.map((rows) => rows.where((r) => !(r['is_read'] as bool? ?? false)).length);
```

`.stream()` fetches an initial snapshot over REST and then applies deltas locally, so
this pulled the office's **entire alert history** into memory on every sign-in and grew
with every alert ever raised — to count unread.

Now the count is a server-side `count(exact)` over `is_read = false`, re-run whenever the
already-bounded (100-row) feed stream ticks. The badge stays exact — it still counts *all*
unread, not a page of them — and the client holds nothing.
`operational_alerts (office_id, created_at desc) where is_read = false` is indexed for
precisely this query.

*Rejected alternative:* filtering the stream with `.eq('is_read', false)`. A row updated
to `is_read = true` no longer matches the filter, so no event is delivered and the SDK
never evicts it — the badge would go stale in the one direction that matters.

### 1.3 Every list query was unbounded · **fixed, with a visible ceiling**

112 selects, 12 `.limit()` calls, **0** `.range()`. الحجوزات, الرحلات, الشكاوى,
الاشتراكات and التقييمات each pulled the office's entire history on every visit and then
paginated in Dart — and the shell rebuilds a module on every navigation, so returning to
a screen re-ran it.

An office with 50,000 bookings paid for 50,000 joined rows to look at the twelve on
screen, several times per session.

### 1.4 Two composition screens fetched a feed they already had · **fixed**

الرئيسية fired 9 feeds and نظرة تنفيذية 12. One of them was the payment-verification
queue, used only to count bookings awaiting a decision — a number contained in the
bookings feed both screens *also* fetched. Folding مراجعة المدفوعات into الحجوزات removed
the duplicate query from both: **9 → 8** and **12 → 11**.

---

## 2. The cap contract

`core/query/dashboard_query_caps.dart` holds every ceiling in one file so the numbers can
be reviewed against each other rather than discovered one datasource at a time.

| List | Cap | Why this number |
|---|---:|---|
| bookings | 2,000 | heaviest row in the console (five joins); ~a trading week with room over it |
| trips | 1,500 | created by the office, a couple of dozen a day; several months |
| subscriptions | 1,500 | read as a live book, not an archive |
| reviews | 1,500 | light rows, and the averages are the point |
| tickets | 1,000 | arrive at a fraction of the booking rate, worked as a queue |
| finance ledger | 3,000 | pre-existing; unchanged |

**A cap is always three things, never one:**

1. `.limit(...)` **and** `.order(...)` on a time column, descending — so *which rows
   survive* is a decision, not whatever the planner returned first.
2. a `capReached` getter on the `Loaded` state (`rows.length >= cap`).
3. a `DashboardCapNotice` on the screen, beside the count it qualifies.

The third is not optional. Every tally on a capped state — tab counts,
`approvedRevenue`, `availableRoutes` — is computed over the loaded list, so when the cap
is hit they describe the window and not the business. Presenting a truncated total as a
total is the failure this console refuses everywhere else.

Where narrowing the filters genuinely cannot reach older rows (التقييمات has no filter
that reaches the query), the notice says nothing rather than offering advice that does
not work: `hint: ''`.

### What a cap is not

It is not paging. Reaching further back than the ceiling is still a query the console
cannot make. Server-side paging with server-side tallies is the end state — see §5.

---

## 3. Emission rate

Rebuild cost in this console is governed by how often cubits emit, not by how wide the
builders are. There is one builder per module by design — see
`DASHBOARD_UI_ARCHITECTURE.md` §4.

| Emitter | Rate | Control |
|---|---|---|
| `BookingsCubit` | realtime | 400ms coalesce + in-flight guard |
| `TripsListCubit` / `TripDetailsCubit` | realtime + 30s poll | 250ms debounce + in-flight guard |
| `LiveOpsCubit` | 15s poll | by design; it is the live view |
| `OperationalAlertsBadgeCubit` | realtime | builder scoped to the bell alone |

**Add a debounce before you add a `BlocSelector`.** An undebounced realtime feed rebuilds
the screen dozens of times a second regardless of how narrowly the builders are scoped.

---

## 4. Rendering notes

Measured, and deliberately left alone:

- **48 `ListView(` vs 7 `ListView.builder`.** The plain constructor is correct here: these
  are pages of 5–10 fixed sections, not long lists. The children are still built lazily.
- **94 `LayoutBuilder`s.** High, but this is a responsive desktop console where most
  screens genuinely swap layout on width. Not worth removing blind.
- **10 `IntrinsicHeight`.** Small enough not to matter; each one is inside a bounded row.
- **`AnimatedContainer` on every table row** (`_HoverableOpsBodyRow`, 150ms). One per
  visible row, and rows are capped by pagination.

---

## 5. What is still open

**Server-side paging.** The real end state, and it is a migration, not a Dart change.
الحجوزات computes `countByStatus`, `countForTab`, `approvedRevenue`, `availableRoutes`
and `bookingsForClient` over the *full* loaded set. Paging the query without moving those
tallies server-side would replace a truthful window with a lying one. It needs, per
module, roughly:

```
office_bookings_page(p_filters jsonb, p_limit int, p_offset int)
office_bookings_tallies(p_filters jsonb)
```

**The fleet workspace feed.** `GetFleetWorkspaceUseCase` runs **23 selects** and الرئيسية
calls it on every load. It is the single most expensive feed in the console and it wants
one `office_fleet_workspace` RPC returning one document.

**Module teardown on navigation.** The shell disposes and rebuilds each module on every
route change, so returning to الحجوزات refetches it. With the caps in place this is now
a bounded cost and arguably correct for an ops console (fresh data on every visit) — but
it is why `DashboardFilterMemory` had to exist.

**`bulkApprove` / `bulkReject` are N sequential round trips**, each an RPC followed by a
single-row refetch — 2N for a batch of N. A `office_bulk_approve_payments` RPC would make
it one.
