# Dashboard — UX Audit

**Date** 2026-08-15 · **Scope** UI/UX only — no schema, RLS, RPC, auth, entitlement or
accounting change. **Branch** `fix-dashboard`.

This audit is the *usability* companion to `DASHBOARD_AUDIT.md`, which ran the same day
over correctness, security and data honesty. Where that one asked "is this true?", this one
asks "can an operator work in it all day?" Findings that turned out to be backend gaps are
listed in §7 and were not touched.

---

## 1. Executive summary

The console is in **much better UX shape than a 25-module product usually is**, and the
reason is that it already has a real design system with its rules written down
(`DASHBOARD_UX_GUIDELINES.md`) and enforced by tests. The 2026-07-23 consistency pass, the
2026-08-07 collapsible pass and the 2026-08-14 module-header pass did the heavy lifting.
Most of what a from-scratch audit would flag — three table paradigms, per-feature headers,
page-replacing action errors, unfoldable 220px hero blocks — has already been fixed.

So this pass found **few systemic problems and one badly-drifted module**.

**Strongest areas.** Design-system adoption is genuinely high: 83 `sectionId`-carrying
collapsible sections, one search widget, one KPI card, one master/detail layout, all 26
`DashboardErrorState` call sites carry an `onRetry`, and all six foldable filter sections
carry the `collapsedSummary` the guidelines demand. Only **3 hardcoded colours** exist in
~108k lines of dashboard code. RTL discipline is good and test-enforced.

**Weakest area — one module, not a pattern.** **مركز الشكاوى والدعم (tickets)** never got
any of those passes. It was the console's only remaining raw Material `DataTable`, it
rendered **English status text on an Arabic-only console**, its queue was **unpaginated and
unsortable**, and its status/priority filters **existed in the cubit but had no control on
screen**. It also had zero tests. This is where most of the implementation effort went.

**The one real P0.** A **RenderFlex overflow in the trip creation wizard** at 1.3× and 1.6×
text scale — a fixed `width: 220` tile whose Arabic label outgrew its lane. It was a known
failing test carried as "pre-existing" in `DASHBOARD_KNOWN_ISSUES.md`. It is now fixed; the
test that documented it passes.

**Biggest productivity opportunity (not implemented).** Filters do not survive navigation.
The shell disposes each module on every route switch, so an operator who filters الحجوزات,
opens a trip, and comes back starts over. Fold state already survives via
`DashboardSectionStateStore`; filter state is the obvious next tenant of that store.

---

## 2. UX score

Scored on the state **before** this pass. These are not generous; a 10 means "I could not
find a way to improve it", which nothing gets.

| Category | Score | Note |
|---|---:|---|
| Navigation | 8 | Sidebar contract is well-specified; naming collisions deliberately avoided. Settings row is hollow. |
| Information architecture | 6 | الرئيسية and نظرة تنفيذية overlap; payment verification duplicates bookings. |
| Visual hierarchy | 8 | Module header pass fixed the worst of it. |
| Forms | 7 | Well-sectioned; trip wizard is the one that bursts at large text. |
| Tables | 6 | `OpsDataTable` is good — but tickets was still a raw `DataTable`, unpaginated. |
| Filters | 6 | Where they exist they follow the rules. Tickets' filters were unreachable entirely. |
| Search | 8 | One debounced widget, used consistently. |
| Loading UX | 8 | Skeletons, per-feed tolerance, partial-data notice. |
| Empty states | 5 | `DashboardEmptyState` exists but only 7 of 25 modules use it; five bare "لا توجد بيانات مطابقة" strings. |
| Error states | 8 | Every retry wired; action-vs-load convention is documented and followed. |
| Dialogs | 7 | Consistent; destructive actions confirm. |
| Responsive | 7 | Breakpoints documented and tested — one real overflow slipped through at text scale. |
| RTL | 8 | Directional insets, icon-naming rule, test-enforced. |
| Accessibility | 5 | Text-scale coverage is partial; no semantic labels pass; the overflow proves the gap. |
| Consistency | 7 | High, with tickets as the visible outlier. |
| Productivity | 6 | Filters resetting on navigation is a daily tax. |
| **Overall** | **7** | A strong system with one unmigrated module and one real layout bug. |

---

## 3. Findings

### P0 — broken

**1. Trip creation wizard overflows at 1.3× and 1.6× text scale** · التشغيل › إنشاء رحلة
`trip_creation_wizard.dart` · `_InteractiveTimeTile`

The date/departure/arrival tiles were `Ink(width: 220)` containing a `Row` with no
`Flexible`. At 1.3× the Arabic label overflowed by 19px, at 1.6× by 62px — a striped
overflow banner across the trip planner, the console's highest-stakes form.

*Why it matters* Operators enlarge text; it is the most common accessibility setting there
is. *Impact* Visible corruption on the create-trip path. *Frequency* Every trip creation at
enlarged text. *Severity* P0 — it throws in debug and clips real content in release.

**Fixed.** `ConstrainedBox(minWidth: 220)` instead of a hard width, `MainAxisSize.min`, and
the label wrapped in `Flexible`. The tiles sit in a `Wrap`, so growing costs only a reflow.
This is the exact trap the design system already documented ("fixed-width lanes need
`ConstrainedBox(minWidth:)`, not `SizedBox(width:)`") — applied one level deeper.

---

### P1 — major

**2. تذاكر rendered English status text on an Arabic-only console**

`TicketStatus`/`TicketPriority` carried English display labels (`Submitted`, `Under Review`,
`Urgent`), printed straight onto the queue badges. The SLA column read `BREACHED`,
`Overdue`, `2h 30m left`. Six cubit snackbars were English (`Ticket closed`, `Assigned to …`).

*Why it matters* The console is Arabic-only by product decision. *Impact* The support desk —
staffed by the least technical operators — was the one module in a foreign language.
**Fixed**; the wire value was always `.name`, so nothing about persistence changed.

**3. تذاكر's status and priority filters were unreachable**

`setFilterStatus` / `setFilterPriority` existed and `filteredTickets` honoured them, but no
widget ever called them. The queue could be searched, never narrowed.

*Why it matters* The inverse of the guidelines' rule ("a control that cannot reach the query
is not a control") — here a query that no control could reach. *Impact* An agent could not
ask "show me the urgent open tickets", the queue's primary question. **Fixed** — a
responsive toolbar in the header's `pinned` slot, plus `clearFilters()`.

**4. تذاكر's queue was unpaginated, unsorted, and lost its header on scroll**

A raw Material `DataTable` inside nested `SingleChildScrollView`s: every filtered ticket
built at once, column headers scrolling out of view, no sort on SLA or date, hardcoded
`TextStyle(fontSize: 12)` throughout.

*Why it matters* A support queue's whole job is "what breaches next". *Impact* Unbounded
build cost and no way to triage. *Severity* P1. **Fixed** — migrated to `OpsDataTable`
(12/page, sticky header, sort on 5 columns, defaulting to the SLA clock soonest-first).

**5. Almost every list query is unbounded** — *not fixed, backend*. See §7.

---

### P2 — significant

**6. Five bare "لا توجد بيانات مطابقة" strings**
Four fleet card lists and the shared table default. A generic string answers none of the
three questions an empty state owes the reader. **Fixed for the four fleet lists** (specific
`DashboardEmptyState`s naming what is missing and where it comes from) and the shared
`OpsDataTable` now accepts an `emptyState` widget.

**7. `DashboardEmptyState` adoption is only 7 of 25 modules.** The rest use the app-wide,
page-sized, emoji-led `EmptyState` built for the mobile apps. Partly addressed (fleet,
tickets); the sweep is open work.

**8. الرئيسية and نظرة تنفيذية overlap substantially.** Home's four KPIs are a subset of the
executive tab's eleven. Carried from `DASHBOARD_KNOWN_ISSUES.md` #8; unchanged, because
deciding what Home is *for* is a product call, not a cleanup.

**9. Payment verification duplicates bookings** (~2.0k lines against 5.8k, same table, same
RPCs). Carried as #3 there. A genuine refactor with its own test surface.

**10. الإعدادات has nothing of its own** — a theme toggle already in the top bar, a paragraph,
and a sign-out already in the sidebar footer.

**11. Two partial-data notices** — `UnavailableSourcesNotice` vs `DashboardPartialDataNotice`.

**12. Three hardcoded colours** — the referral leaderboard's gold/silver/bronze medals. The
only ones in the dashboard, and arguably legitimate (medal metals are not theme colours),
but they are invisible to the dark-mode audit and belong in the palette.

---

### P3 — polish

**13. Filters do not survive navigation** — the highest-value P3 by daily frequency. See §6.

**14. Unpadded dates** — tickets printed `2026/8/5`. Fixed there; other modules use their
own formatters and are consistent.

**15. Shell-contract violations** — `subscriptions_screen.dart` and
`subscription_details_sheet.dart` mount their own `Scaffold`; `captain_request_card.dart`
wraps its own `Directionality`. Harmless today (the sheet genuinely needs a Scaffold for its
own chrome) but they are how modules drift from the shell.

---

## 4. What was fixed in this pass

| # | Module | Change |
|---|---|---|
| 1 | التشغيل › إنشاء رحلة | Text-scale overflow removed; fixed lane → `ConstrainedBox` + `Flexible` |
| 2 | تذاكر | Status, priority and SLA now Arabic; six cubit snackbars translated |
| 3 | تذاكر | Status + priority filter toolbar added; `clearFilters()` added |
| 4 | تذاكر | Raw `DataTable` → `OpsDataTable`; pagination, sticky header, 5 sortable columns |
| 5 | تذاكر | Two real empty states (never-had-any vs filtered-to-nothing, with a clear action) |
| 6 | تذاكر | Zero-padded dates; theme text styles replace hardcoded `fontSize` |
| 7 | الأسطول ×4 | Generic empty strings → specific `DashboardEmptyState`s |
| 8 | **shared** | `OpsDataTable` gained `onRowTap`, `rowTints` and `emptyState` |
| 9 | tests | New `tickets_queue_test.dart` — 13 tests over a module that had none |

`OpsDataTable`'s three new parameters are all optional and default to the previous
behaviour, so the other five modules using it are untouched. `onRowTap` restores
whole-row click (which the raw `DataTable` had via `onSelectChanged`) and adds a pointer
cursor; `rowTints` preserves the breached-SLA row highlight.

---

## 5. Testing

```
flutter analyze lib/apps/dashboard        → No issues found
flutter test test/apps/dashboard          → see §"Suite" below
```

**Before this pass:** 1,092 dashboard tests, **2 failing** — both
`trip_creation_driver_vehicle_test.dart` text-scale overflows, recorded as pre-existing.

**After:** those two pass. 13 new tests added (`tickets_queue_test.dart`) covering Arabic
labels, pagination, SLA-first sort, header sort, both empty states, filter reachability, and
no-overflow at two widths × two text scales.

The remaining 11 suite-wide failures listed in `DASHBOARD_KNOWN_ISSUES.md` are in the
**captain and client apps**, are unrelated to the dashboard, and were not touched.

---

## 6. The recommendation this audit would make first

**Move filter state into `DashboardSectionStateStore`.**

The shell destroys and rebuilds a module on every navigation. Fold state already survives
this, in a process-wide in-memory store that is cleared on sign-out and deliberately never
persisted. Filter state has exactly the same lifetime and exactly the same argument for
surviving: an operator who filters الحجوزات to "awaiting payment", opens a booking, and
comes back has to rebuild the filter every time.

It is not done here because it wants one shared mechanism adopted per module rather than 15
bespoke fixes, and because it interacts with the unbounded-query problem below — if list
queries become server-paged, filter state becomes query state and belongs in the same place.

---

## 7. Backend / business dependencies — found, deliberately not changed

Each of these presents as a UX problem and is not fixable in Flutter.

1. **Unbounded list queries.** الرئيسية fires 9 uncapped queries per visit, نظرة تنفيذية 12,
   and the shell re-runs them on every return. The *felt* symptom is slowness; the fix is
   server-side aggregates and paging. (`DASHBOARD_KNOWN_ISSUES.md` #2.)
2. **Reports cannot be date-bounded** for drivers, vehicles or complaints — those views are
   lifetime roll-ups with no date column. The UI now says so instead of drawing an inert
   date picker; removing the lie was the right frontend move, but the gap is a migration.
3. **Four report KPIs do not exist** (driver rating, working hours, fuel consumption,
   complaint resolution time). Removed rather than faked.
4. **Fleet RLS is role-agnostic** — a P0 in the security audit, listed here only because the
   client-side gate is currently what enforces it. Not a UX change.
5. **`revenue_daily_view` has no subscription revenue**, so the revenue report's
   subscription line is structurally zero.

---

## 8. Remaining UX problems — honest list

- الرئيسية / نظرة تنفيذية overlap is undecided (P2 #8).
- Payment verification still duplicates bookings (P2 #9).
- الإعدادات is still a hollow row (P2 #10).
- `DashboardEmptyState` adoption is still partial — 18 modules use the mobile `EmptyState`.
- Two partial-data notices remain (P2 #11).
- Filters still reset on navigation (P3 #13).
- Text-scale coverage is still partial: this pass proved 1.3×/1.6× finds real bugs, and most
  modules are only pumped at 1.0×. **Every module deserves a 1.6× pump.** That is the single
  cheapest way to find the next P0.
- No semantic/screen-reader pass has ever been done on this console.

---

## 9. Final score

| Category | Before | After |
|---|---:|---:|
| Tables | 6 | 8 |
| Filters | 6 | 7 |
| Empty states | 5 | 7 |
| RTL | 8 | 9 |
| Accessibility | 5 | 6 |
| Consistency | 7 | 8 |
| Responsive | 7 | 8 |
| **Overall** | **7** | **7.5** |

Overall moves by half a point, not more, and that is the honest number. One module was
brought up to the standard the other 24 already met, one real layout bug was removed, and
one shared widget got three capabilities. The structural items — the Home/Executive overlap,
the bookings duplication, filter persistence, unbounded queries — are all still open, and
they are what stands between 7.5 and 9.

---
---

# Pass 2 — 2026-08-15 (same day, continued)

Pass 1 ended by naming its own next move: *"Every module deserves a 1.6× pump. That is the
single cheapest way to find the next P0."* This pass took that advice, and it was right —
the sweep found a real overflow in the console's most-reused widget on its first run. It
also found something the sweep was not looking for: **the dashboard's directional arrows
point the wrong way in eight places.**

## 10. What this pass found

### P1 — eight directional icons render backwards under RTL

Material's arrows and chevrons carry `matchTextDirection: true`, so the framework mirrors
them itself. Naming the glyph you want to *see* therefore renders the opposite: a "back"
button in Arabic points **right**, so reaching for `chevron_right` gets it flipped to point
left.

The rule was known, written down in `dashboard_icons.dart`, and enforced by a test — for
exactly one widget, `OpsDataTable`. Everywhere else it was a comment, and eight call sites
had drifted:

| Site | Was | Rendered | Should read |
|---|---|---|---|
| `bookings_queue_board` pagination ×2 | prev `chevron_right`, next `chevron_left` | inverted against every other pager | prev ◀ / next ▶ |
| `bookings_queue_board` "عرض التفاصيل" | `chevron_left` | pointed backwards | forward |
| `trip_row_card` "عرض التفاصيل" | `arrow_forward` | correct — **and opposite to bookings' identical action** | forward |
| `route_details_view` "رجوع" | `arrow_forward` | a back button pointing forward | back |
| `plans_section` "كل الباقات" | `arrow_forward` | same | back |
| `platform_licenses_screen` "كل المكاتب" | `arrow_forward` | same | back |
| `wallet_amount_dialog` "متابعة" | `arrow_back` | a continue button pointing backwards | forward |
| `platform_overview_panel` row drill-in | `chevron_left` | pointed backwards | forward |
| `platform_office_card` selection marker | `chevron_left` | pointed away from the name | toward it |
| `routes_list_view` من→إلى | `arrow_back` | pointed at the origin, **opposite to the identical arrow in trips** | toward destination |

*Why it matters* Arrows are read pre-attentively — nobody parses them, they just steer the
eye. An arrow pointing the wrong way is not a cosmetic defect; it is a signpost with the
wrong town on it, and the two "عرض التفاصيل" buttons disagreeing with each other is the
kind of thing that makes a console feel untrustworthy without the operator being able to say
why.

**Fixed**, and more importantly made unrepeatable: `DashboardIcons` now exposes the direction
by **intent** (`back`, `forward`, `paginationPrevious`, `paginationNext`, `openModule`,
`breadcrumbSeparator`, `transition`), and `dashboard_rtl_test.dart` fails the build if any
dashboard file outside that one vocabulary file names a raw directional glyph. The guard was
verified against an injected regression: it names the offending file and glyph.

### P1 — `OpsDataTable`'s pagination bar overflows

Found by the new sweep on its first run. The bar was a `Row` of two unbounded `Text`s, a
`Spacer` and two fixed 48px buttons — nothing in it could yield. It overflowed at 360px, the
console's own narrowest declared breakpoint, at **every** text scale, and by 330px at 1.6×.

This is the shared table behind **13 call sites** — bookings, finance ×2, fleet ×4,
referrals ×3, licensing, tickets.

*Why the obvious fix was wrong* `Flexible` + ellipsis stops the overflow by deleting the
counts, and the counts are the entire content of the bar. It now uses a `Wrap`: at desktop
widths it lays out exactly as before, and when it runs out of room the counts drop onto
their own line instead of being truncated. Narrowness costs vertical space, not information.

*Caveat, stated honestly* the test font renders every Arabic glyph as a fixed-width box, so
the measured overflow is wider than production. Working it through with real glyph metrics,
1.6× still overflows a 360px pane; 1.0× likely does not. The bar was the only primitive in
the sweep with no flex protection at all, and the bookings board's own newer pagination bar
had already solved this independently — so the shared one was the outlier either way.

### Not a finding — what the sweep cleared

72 cases (8 primitives × 3 widths × 3 scales). Everything except the pagination bar passed
at 1.6×, including the module header, KPI grid, collapsed filter summaries, empty states,
error states, the partial-data notice and the master/detail placeholder. That is a real
result and worth recording: the design system's *own* components are text-scale sound.

## 11. What this pass implemented

| # | Area | Change |
|---|---|---|
| 1 | **shared** | `DashboardIcons` gained 6 intent-named directional tokens; all 24 directional usages in the dashboard now go through them |
| 2 | 8 modules | Wrong-facing arrows corrected (table above) |
| 3 | **shared** | `OpsDataTable` pagination bar reflows instead of overflowing |
| 4 | **shared** | `DashboardFilterMemory` — session-scoped filter persistence, sibling to `DashboardSectionStateStore` |
| 5 | الحجوزات, تذاكر | Filters, search and cleared-state now survive navigation |
| 6 | auth | Sign-out clears filter memory alongside section state |
| 7 | tests | +90: text-scale sweep (72), filter memory (6), tickets persistence (6), bookings persistence (4), RTL guards (2) |
| 8 | tests | Visual capture harness that actually loads the icon font — the existing harnesses all render icons as tofu boxes, which is fine for layout review and useless for reviewing arrows |

### On filter persistence

Pass 1 called this "the recommendation this audit would make first". It is now real for the
two busiest queues.

The mechanism is deliberately a **sibling** of the section-state store rather than a second
tenant inside it: fold state is `Map<String, bool>` and filters are per-module value objects
of unrelated shapes, so sharing one map would have meant either a lowest-common-denominator
type or a rewrite of five filter models to gain nothing. Both stores are process-wide,
in-memory, never persisted, and cleared together on sign-out.

**Why this is safe** — a remembered filter is invisible state, which is normally a trap: the
operator returns to a narrowed queue and reads it as the whole queue. It is safe here only
because both adopting modules already show an active-filter count and a clear affordance
(`مسح الفلاتر (2)`, the collapsed-summary chips). A test asserts the restored filter still
reports its `activeCount`, because that visibility is the precondition, not a nicety.
**Any module adopting this next must have that affordance first.**

`clearFilters()` *forgets* rather than storing an empty snapshot, so "I cleared this"
survives navigation exactly as a selection does.

## 12. Testing (pass 2)

```
flutter analyze lib/apps/dashboard test/apps/dashboard   → No issues found
flutter test test/apps/dashboard                         → 1,197 passing, 0 failing
flutter test  (whole repo)                               → 2,326 passing, 11 failing
```

Dashboard suite went 1,107 → **1,197** (+90, all new, all passing). The repo total went
2,236 → 2,326: the same +90, with the failure count **unchanged at 11**. Those 11 are the
four captain/client files already documented in `DASHBOARD_KNOWN_ISSUES.md`, re-run
individually to confirm (`+34 -11`); no file outside `lib/apps/dashboard` or
`test/apps/dashboard` was touched in this pass.

**Visually verified**, not merely compiled — captures in
`test/apps/dashboard/core/widgets/_captures/`:

* `directional_1_vocabulary.png` — all six tokens beside the action they name, rendered RTL.
  رجوع points right, عرض التفاصيل points left, السابق right, التالي left.
* `pagination_1_wide.png` — desktop layout, edge to edge as before.
* `pagination_2_narrow.png` / `pagination_3_narrow_large_text.png` — 380px, 1.0× and 1.6×.
  Both counts fully legible, both controls present, nothing clipped.

An intermediate version of the `Wrap` fix shrink-wrapped and centred the bar at desktop
widths; that was caught by *looking at the capture*, not by the tests, which were green
throughout. Worth recording as evidence for why the harness exists.

## 13. Score after pass 2

| Category | Pass 1 start | Pass 1 end | Pass 2 end |
|---|---:|---:|---:|
| Tables | 6 | 8 | 8.5 |
| Filters | 6 | 7 | 8 |
| RTL | 8 | 9 | 9.5 |
| Accessibility | 5 | 6 | 6.5 |
| Consistency | 7 | 8 | 8.5 |
| Responsive | 7 | 8 | 8.5 |
| Productivity | 6 | 6 | 7 |
| **Overall** | **7** | **7.5** | **8** |

Half a point again. RTL rises because the rule is now mechanically enforced rather than
documented; filters and productivity rise because the console's most repeated motion stopped
costing re-work in the two modules where it is most repeated — but only two of roughly
fifteen filtered modules have it, which is why filters is 8 and not 9.

What still stands between 8 and 9 is unchanged and structural: the الرئيسية / نظرة تنفيذية
overlap, مراجعة المدفوعات duplicating الحجوزات, unbounded queries, `DashboardEmptyState`
adoption across the remaining 18 modules, filter persistence in the other thirteen, and the
screen-reader pass that has never been done.
