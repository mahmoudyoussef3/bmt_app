# Finance — UX

The rules the module is designed against, and the reasoning behind the ones that
are not obvious.

---

## 1. The test

> If I am an EWT office owner and I open Finance for thirty seconds, do I
> understand what happened to my money and what I need to do?

Everything below is downstream of that sentence. A panel that does not help
answer it does not earn its vertical space.

---

## 2. Hierarchy, not a grid

The overview is ordered as an argument:

```
1  money status      ← the headline, and the arithmetic behind it
2  problems          ← what needs a decision, and where to make it
3  trend             ← which way it is moving
4  composition       ← where it comes from
5  reconciliation    ← collapsed; for when a figure is challenged
```

Fifteen equal cards is not a dashboard, it is a database viewer with rounded
corners. Each block above is visually distinct in weight: the hero is a
gradient-backed card with a display-size figure, the KPIs are a single tinted
band, the attention rows are bordered and tappable, the panels are collapsible
sections with icons and subtitles.

---

## 3. Every figure explains itself

No label may be ambiguous. «إجمالي» / «الدخل» / «المدفوعات» on their own are
banned; the module says «إجمالي المتحصلات», «صافي الإيراد», «مستحقات لم تُحصّل».

Where a definition cannot fit in a label it goes in the subtitle:

- The hero spells out `إجمالي المتحصلات − المرتجعات المنفذة = صافي الإيراد` and
  then says in words that this is **not profit**.
- «مستحقات لم تُحصّل» says «عملية قائمة» so the reader knows cancelled seats are
  excluded.
- «معدل التحصيل» names its denominator.
- «طرق التحصيل» says it covers bookings only, because packages record no rail.
- Every panel subtitle names the period it was computed over.
- The attention panel says it counts the whole book, not the window.

The transaction detail carries an **effect line** stating what that single row
did to the headline number. An aggregate is only trustworthy if any row can be
traced into it.

---

## 4. The period must be unmissable

It is pinned to the module header, above the tabs, because every tab answers the
same question for the same window. A per-tab date picker is how two figures on
one screen end up meaning two different periods.

A chip is a **name**, not a boundary. Under the chips the bar states the
resolved window in dates, what the comparison is measured against, and whether
the period is still filling up (`الفترة ما زالت جارية` / `فترة مكتملة`).

Selecting «فترة مخصصة» with no range yet is refused rather than silently
resolving to the default window while the chip claims otherwise.

---

## 5. Colour is never the only signal

| Meaning | Colour | Second signal |
|---|---|---|
| Collected | green | «محصّلة» pill |
| Pending / needs attention | amber | «قيد التحصيل» pill, clock glyph, worded action |
| Problem | red | «!» glyph, «مقعد ملغي» pill, worded action |
| Reversed | accent | strikethrough on the amount |

Attention rows rank themselves in three ways at once — position in the list, a
severity glyph, and a tint — so the ordering survives for a reader who cannot
separate two of them.

---

## 6. Arabic and RTL

- Arabic-first throughout; no English strings in the UI.
- **Western digits with thousands separators** for money, on purpose: these
  figures sit in dense right-aligned columns, and mixing Arabic-Indic numerals
  in is where `١٢٬٣٤٥` starts reading as a different magnitude than `12,345` one
  row above it.
- Route labels are composed through `routeDirectionLabel`, never printed from a
  stored `'A → B'` string — see `FINANCE_FEATURES.md`.
- Directional icons come from `DashboardIcons` so they self-mirror; no finance
  file names a raw `Icons.chevron_left` / `arrow_back`.
- Layout uses `AlignmentDirectional` and `EdgeInsetsDirectional`; nothing forces
  a text direction.

---

## 7. Desktop-first, responsive

Verified at 1100 / 1366 / 1440 / 1920, in light and dark, with quadruple Arabic
names, geocoder-length routes and seven-figure amounts. Breakpoints:

| Width | Behaviour |
|---|---|
| ≥ 1040 | KPIs four across; paired panels side by side above 980 |
| < 1100 | ledger filters wrap to two rows |
| < 980 | paired panels stack |
| < 820 | the hero stacks headline / sparkline / breakdown |

The four-across KPI band gives a detail line roughly fifteen characters at 1366.
Details are written to that budget: a sentence that ellipsises mid-word is worse
than a shorter true one.

Four widget tests pump the whole module at each width over a deliberately
oversized fixture and assert no overflow, so a future copy change cannot
reintroduce one silently.

---

## 8. Reading is not deciding

The module's charter is that it has no approve button. That is about
**authority**, and it was never about silence.

- Naming a queue and its size is reading.
- Opening the module that owns the decision is navigation.
- Approving, refunding, cancelling — none of those exist here, and a screen test
  asserts that none of those words appears anywhere in the module, on any tab,
  or in the transaction detail.

---

## 9. Trust

- **Never invent a number.** A delta with no comparable window renders `—`, not
  0%. A trend with no baseline shows no arrow.
- **Never hide an exclusion.** Pending, cancelled and wallet liability are memo
  lines on the statement, not omissions.
- **Say when the view is a window.** The row cap is announced, not swallowed.
- **Say when the books do not balance.** The control identity is asserted on
  every load; a failure is stated with the exact gap and promoted to the top of
  the attention panel.
