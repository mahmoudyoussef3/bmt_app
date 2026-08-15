# Dashboard — UX Roadmap

Prioritised from `DASHBOARD_UX_AUDIT.md` (2026-08-15). Items already done are in that
document's §4 (pass 1) and §11 (pass 2) and are not repeated.

Ordering is by **operator cost per day**, not by implementation size.

> **Updated after pass 2.** N1 is half done and stays at the top for its second half; X1 is
> half done and moves up. Two items are closed. The sequencing note at the bottom still
> holds, and pass 2 is evidence for it: N1's first half found a real P1 within minutes.

---

## NOW

### N1 · Pump every *module* at 1.6× text scale — **half done**

**Done in pass 2** `dashboard_text_scale_sweep_test.dart` covers the eight shared primitives
at 3 widths × 3 scales (72 cases). It found the `OpsDataTable` pagination overflow on its
first run, and cleared everything else.

**Still open** the sweep tests the *primitives*, not the *screens*. A module can compose
sound primitives into an unsound layout — which is exactly what the trip wizard did in pass
1. Roughly 20 module screens still have no 1.6× case.

**User impact** Enlarged text is the most-used accessibility setting there is, and Arabic at
1.6× overflows layouts that look perfect at 1.0×. Every module without that test is
unproven, not proven-good.

**Solution** Per-module `testWidgets` reusing the fixtures that already exist in each
module's own test file (`*_test_fixtures.dart`, the `_Fake*Cubit` pattern), asserting
`expect(tester.takeException(), isNull)` at 1.0/1.3/1.6×. Start with the forms — trip
creation, staff accounts, office identity, the wallet dialogs — because a burst form is
worse than a burst table.

**Priority** P1 · **Complexity** M (mechanical, ~20 fixture wire-ups) · **Depends on** nothing

---

### N2 · Finish the `DashboardEmptyState` sweep

**Problem** 7 of 25 modules use the dashboard empty state; the rest use the app-wide,
emoji-led, page-sized `EmptyState` built for the mobile apps.

**User impact** An empty panel that says "لا توجد بيانات" tells the operator nothing about
whether the screen is broken, filtered, or genuinely new.

**Solution** Module by module, replacing with `DashboardEmptyState` and writing copy that
answers *what is empty, why, and what to do*. Fleet and tickets are done and are the model.

**Priority** P2 · **Complexity** M · **Depends on** nothing

---

### N3 · Decide what الرئيسية is for

**Problem** Home's four KPIs are a strict subset of نظرة تنفيذية's eleven; Home's lower half
(revenue trend, top routes, activity feed) is executive material on the operator's console.

**User impact** Two screens answering one question, neither answering it fully. The operator
who opens the console to find out *what needs doing* scrolls past a revenue chart.

**Solution** Sharpen to: **الرئيسية = what must I do now** (queues, alerts, exceptions,
today's trips), **نظرة تنفيذية = how are we doing** (trends, comparisons, roll-ups). Move,
don't duplicate.

**Priority** P2 · **Complexity** M · **Depends on** a product decision, not code

---

### N2 · Roll filter memory out to the remaining modules — **mechanism done**

**Done in pass 2** `DashboardFilterMemory` exists, is tested, is cleared on sign-out, and is
adopted by الحجوزات and تذاكر. The pattern is three lines per module: read on `load()`,
`write` in the filter setters, `forget` in `clearFilters()`.

**Still open** ~13 filtered modules: الاشتراكات, المالية, التقارير, المستخدمون, التقييمات,
مراجعة المدفوعات, المحفظة, الإحالات, مكاتب المنصة, and the fleet lists.

**The precondition, not optional** a module may only adopt this **if it already shows an
active-filter count or a collapsed-summary chip**. Persistence turns a filter into invisible
state, and invisible state over a narrowed queue is how an operator reads a partial list as
a complete one. Where the affordance is missing, add it first — that is the actual work item
for several of these modules, and it is worth doing on its own merits.

**Priority** P1 by impact · **Complexity** S per module, once the affordance exists

---

## NEXT

### X1 · ~~Filter state survives navigation~~ — **superseded by N2**

The mechanism landed in pass 2; what remains is rollout, which is now N2. The original note
that this should be sequenced with X2 still applies to the *paged* modules: once a list is
server-paged, its filters become query parameters and want to live with the page cursor
rather than beside it.

---

### X2 · Bound the list queries

**Problem** ~110 selects, 14 `.limit()` calls. الرئيسية fires 9 uncapped queries per visit,
نظرة تنفيذية 12, re-run on every return to the screen.

**User impact** Presents as "the dashboard is slow", worsening linearly with office age.

**Solution** A `dashboard_home_summary` RPC for the two composition screens; paging + caps on
module lists. Finance's `ledgerCapReached` is the pattern to copy.

**Priority** P1 · **Complexity** L · **Backend** — needs migrations, out of UI scope

---

### X3 · Fold مراجعة المدفوعات into الحجوزات

**Problem** Two modules (2.0k + 5.8k lines), one table, the same three RPCs.

**User impact** Two places to learn, two to keep consistent, and a narrower one that hides
the filters and bulk actions the richer one has.

**Solution** A saved queue preset on الحجوزات; keep `/payment-verification` as a deep link
that opens it.

**Priority** P2 · **Complexity** L (a real refactor with its own test surface)

---

### X4 · Retire الإعدادات

**Problem** A theme toggle already in the top bar, a paragraph saying permissions live
elsewhere, and a sign-out already in the sidebar footer.

**Solution** Fold anything real into ملف المكتب; drop the nav row.

**Priority** P2 · **Complexity** S

---

## LATER

### L1 · One partial-data notice
`UnavailableSourcesNotice` → `DashboardPartialDataNotice`. Needs a feature-local enum mapped
to labels. **P2 · S**

### L2 · Medal colours into the palette
The referral leaderboard's three `Color(0xFF…)` gold/silver/bronze — the only hardcoded
colours left in the dashboard, and invisible to the dark-mode audit. **P3 · S**

### L3 · Shell-contract cleanups
`subscriptions_screen.dart` / `subscription_details_sheet.dart` own `Scaffold`s,
`captain_request_card.dart` its own `Directionality`. Harmless now; this is how drift
starts. **P3 · S**

### L4 · Semantic / screen-reader pass
Never done on this console. Sort headers, icon-only buttons and status badges convey meaning
by colour and glyph alone. **P2 by principle · L**

### L5 · Test the untested modules
No tests exist for referrals, office billing, notifications dispatch, or settings. The
reports *screen* is untested (its cubit is covered). Tickets was on this list and now has
13. **P2 · M**

---

### L6 · Extend the icon-font capture harness to the other visual harnesses

`directional_and_pagination_visual_capture.dart` loads `MaterialIcons-Regular.otf` from the
SDK so icons render as icons. The four older capture harnesses (module header, bookings,
tickets, live ops, subscriptions) don't, so every icon in their PNGs is a tofu box. Harmless
for judging layout, useless for judging a glyph. Lift the loader into a shared helper.
**P3 · S**

---

## Sequencing note

N1 first, because it is the only item that *finds* new P0s rather than fixing known ones,
and it is mechanical — pass 2 demonstrated this, turning up a P1 in the most-reused widget
in the console within minutes of the first sweep running. N2 is the cheapest large win per
line of code, but its precondition (a visible active-filter affordance) is real and must not
be skipped. N2 and X2 want to be planned together for any module that becomes server-paged.
N3 and X3 are both product decisions wearing engineering clothes — neither should be started
by an engineer alone.
