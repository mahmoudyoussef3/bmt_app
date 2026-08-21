# العملاء — UX

The interface decisions and why each was made. The console-wide rules live in
`DASHBOARD_UX_GUIDELINES.md` and `DASHBOARD_UI_ARCHITECTURE.md`.

---

## 1. Browse in a grid, work full width

Opening a customer **replaces** the directory rather than opening a pane beside
it. That is the console's standing rule since التراخيص moved off master/detail,
and it applies here for the same reason: a Customer 360 with five tabs is work,
not reading. In three fifths of a window, every tab inside it would need its own
horizontal scroll.

"Which customer is open" is widget state on `CustomersScreen`, not cubit state.
The shell has no navigator, so it is not a route — and keeping it out of
`CustomersCubit` is exactly why the directory survives the round trip intact.

The way back is on screen in **every** state of the workspace, including loading
and error. Without that, a failed profile strands the operator with only the
sidebar to escape it.

---

## 2. Hierarchy

```
back bar          ← العودة إلى العملاء · customer name · تحديث
   ↓
header card       identity · quick actions · ملخص العميل chips
   └ tab strip    pinned at the card's bottom edge, against the panel it switches
   ↓
partial notice    only when a tab failed
   ↓
tab body
```

The tab strip does not fold. A tab bar that can be collapsed is navigation that
can be hidden. It sits at the bottom edge of the header card so it is against
the content it drives and does not move when anything above it changes.

---

## 3. State treatments

| Situation | Treatment |
|---|---|
| First load | `DashboardLoading` skeleton — no full-screen spinner |
| Failed first load | `DashboardErrorState` with retry, plus the back bar |
| Loaded, nothing there | `DashboardEmptyState` saying what would put data here |
| Loaded, nothing **matched** | A different message, plus a "مسح التصفية" button |
| Refetching over a loaded page | Rows dim to 55%, page stays put |
| A refused request | Snackbar over the page — never replaces it |
| Some tabs failed | `DashboardPartialDataNotice` naming them, plus what arrived |
| A tab failed a *refresh* | Its rows stay, with a "may be out of date" strip above |
| Feed came back full | `DashboardCapNotice` saying the window is a window |

The two empty states are genuinely different claims:

> **لا يوجد عملاء حتى الآن** — يظهر العميل هنا بعد أول حجز أو اشتراك مع المكتب —
> لا يُنشأ العملاء من هذه الشاشة.

> **لم نجد عملاء مطابقين للبحث** — جرّب تعديل الكلمات أو إزالة بعض عوامل التصفية.

The first is a fact about the business and says why the office cannot fix it
here (customers arrive by signing up in the Client app). The second is a fact
about the filters and offers the way out.

---

## 4. Three status axes, never merged

A trip row draws booking status, payment status and boarding status as three
separate marks. Collapsing them into one badge would destroy the most common
thing an operator needs to see:

> confirmed booking · approved payment · `no_show` manifest
> — they paid and did not turn up.

Each axis uses its own vocabulary, taken from the database's own values via the
existing `BookingStatus` / `PaymentStatus` enums.

Tones carry meaning rather than decoration: a **refunded** payment reads neutral,
not red. It is a corrected record, not a failure, and colouring it as an error
would tell the operator something untrue about a row working as designed. A
subscription still marked `active` past its end date reads neutral and is
labelled منتهي.

---

## 5. Null is not zero

Three places where this is load-bearing:

- **No wallet row** renders as `—` with *"لم تُفتح محفظة لهذا العميل"*, not as
  `0.00 ج.م`.
- **`trips_count = 0`** omits the usage bar and says why. A 0% bar reads as
  "used nothing"; the truth is "not measurable".
- **No manifest verdict yet** omits the attendance rate. A trip still marked
  `reserved` has said nothing about whether the passenger turned up.

---

## 6. Responsive

| Breakpoint | Behaviour |
|---|---|
| < 1100 | directory table → card list (with its own pager) |
| < 1000 | trips table → cards |
| < 900 | payments table → cards; overview panels stack |
| < 760 | profile header stacks identity above quick actions |
| < 720 | directory toolbar stacks search above sort |

Layout tests pump every tab at 1600 / 1200 / 900 and at 1.0× and 1.6× text
scale. Arabic at 1.6× overflows layouts that look fine at 1.0× — it found two
real overflows during implementation, both in the profile header.

---

## 7. RTL

- `EdgeInsetsDirectional` / `AlignmentDirectional` throughout; a boundary test
  fails on any physical form.
- Directional glyphs come from `DashboardIcons` (`back`, `paginationPrevious`,
  `paginationNext`), never from a raw `Icons.chevron_*`. `dashboard_rtl_test`
  enforces this and caught three during implementation — including one where the
  hand-picked chevron was the wrong way round.
- Nothing forces `TextDirection.ltr`.
- Money uses Finance's western-digit format. A total rendered `١٢٬٣٤٥` beside a
  Finance figure rendered `12,345` is how one office ends up believing it has two
  different numbers.

---

## 8. Time is read once per build

Every relative label on a page — "منذ ٣ ساعات", "غداً" — comes from a single
`DateTime.now()` taken at the top of the build and passed down. Two labels
computed from two clock reads can disagree, and the tests inject a fixed clock
so they are deterministic.
