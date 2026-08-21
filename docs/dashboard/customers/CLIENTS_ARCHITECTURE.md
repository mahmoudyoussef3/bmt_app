# العملاء — Architecture

Feature-first Clean Architecture, one direction: **presentation → domain ← data**.
Nothing here departs from `DASHBOARD_ARCHITECTURE.md`; this file records the
decisions specific to the module.

---

## 1. Layout

```
features/customers/
├── customers_di.dart                    datasource → repository → 7 use cases → cubit
├── data/
│   ├── datasources/
│   │   ├── customers_datasource.dart            interface
│   │   └── supabase_customers_datasource.dart   7 RPC calls + error translation
│   ├── models/customer_models.dart              document → entity, one place
│   └── repositories/customers_repository_impl.dart
├── domain/
│   ├── entities/       customer · filters · profile · subscription · trip · payment · activity · insight
│   ├── repositories/customers_repository.dart   7 reads, 0 writes
│   └── usecases/customers_usecases.dart         one class per read
└── presentation/
    ├── cubit/          customers_(cubit|state) · customer_profile_(cubit|state)
    ├── screens/        customers_screen.dart    the composition root
    └── widgets/        13 files
```

---

## 2. Why the data layer is RPC-only

A customer is a join across seven tables, one of which (`clients`) has no
`office_id` at all. Doing that in Dart would mean fetching every booking,
payment and subscription the office has ever taken in order to render twelve
rows — precisely the cost `DashboardQueryCaps` exists to refuse — and it would
re-derive the ownership predicate `office_owns_client` already states once.

So aggregation, filtering, sorting and paging happen server-side, and the client
sends a page request.

`SupabaseCustomersDatasource` makes no `.from(...)` call at all. A
`.from('clients')` read would be scoped only by RLS — correct today, and one
policy edit away from not being. A boundary test asserts this stays true.

### No office id, anywhere

Every RPC resolves the office from `current_office_id()` and refuses to accept
one as a parameter. The datasource therefore holds no `DashboardSession` and has
no office id to get wrong. A boundary test greps the whole feature for
`officeId` / `office_id` (comments stripped) and fails on a match.

---

## 3. Errors

The console's one shape, end to end:

```
datasource   LicensingGuard.check(e) first, then translate the machine code
             'not_authorized' → 'هذا العميل لا يتبع مكتبك، أو لا تملك صلاحية عرض العملاء.'

repository   names the operation, keeps the reason
             throw Exception('تعذر تحميل ملف العميل: ${_reason(error)}');

cubit        strips 'Exception: ' and emits
```

`not_authorized` is the one that matters: it is what a client id from another
office comes back as, and telling the operator *"this customer does not belong to
your office"* says they are looking at the wrong record rather than that the
console is broken.

`LicensingGuard.check` runs first in every catch, as everywhere else — a
plan-limit refusal must leave as a `LicensingFailure` so the shell can raise the
upgrade card.

---

## 4. Two cubits, on purpose

| Cubit | Owns | Lifetime |
|---|---|---|
| `CustomersCubit` | overview, directory page, filters, paging | one per module mount, registered as a **factory** |
| `CustomerProfileCubit` | one customer's profile and its five tabs | one per opened customer, **constructed at the call site** |

The split is not decoration. It buys three things:

1. **The directory survives the round trip.** Opening a customer and coming back
   does not touch `CustomersCubit`, so the search, filters and page are exactly
   as they were.
2. **No stale tab.** A second customer gets a second cubit (keyed on the client
   id), so tab data from the previous one cannot leak into it.
3. **Rebuild boundaries that mean something.** A tab load rebuilds the profile
   only.

`CustomerProfileCubit` is **not registered in DI** because it takes the client id
it serves as a constructor argument. A factory could not receive it and a
singleton would be shared between two customers, so the screen builds it from
the use cases in the graph — the same shape `trips_screen.dart` uses.

---

## 5. Lazy tabs and contained failure

The header and نظرة عامة arrive in one round trip; the other four tabs are
fetched on first selection and then kept. A customer with three years of history
otherwise costs four queries on open, three of which nobody reads.

Only the **profile** fetch can produce `CustomerProfileErrorState` — without it
there is no identity and no header. Every tab below owns a `CustomerTabStatus`
(`loaded` / `loading` / `error`), so:

- a broken tab shows its own error and leaves the header and the other tabs up;
- the header names every failed tab in a `DashboardPartialDataNotice`;
- a tab that had data and then failed a *refresh* keeps its rows and shows a
  "may be out of date" notice above them, because stale is not the same as gone;
- a tab nobody opened is not reported as failed — it was never asked.

Refresh re-reads the header and only the tabs already loaded. Refreshing is not
the same request as opening.

---

## 6. Request sequencing

`CustomersCubit` holds a `_requestSeq` counter. Typing "أحمد" fires several
requests as the field debounces down, and without sequencing whichever the
server answers last wins — which can be the oldest. Every response checks its
sequence before emitting. A test holds the first call open until the second has
answered and asserts the newer result survives.

Search itself is **not** debounced in the cubit: `DebouncedSearchField` already
does it at the widget, and two debounces in series make the field feel broken.

---

## 7. State conventions

- `sealed class` + `switch`, like the console's other 25 state files.
- Derived values are getters on `Loaded` where they are cheap
  (`pageCount`, `isFilteredEmpty`, `failedSources`).
- **A failed action never emits an error state.** Only a failed first load does.
  A refused page turn sets `actionError` on the intact `Loaded` state and the
  screen shows a snackbar — losing a filtered directory because one request was
  refused is not a trade an operator would make.
- `copyWith` takes explicit `clearX` flags for nullable fields.

---

## 8. Paging is zero-based

`OpsDataTable.currentPage` is a **zero-based index**, and `onPageChanged` emits
one. Both cubits take zero-based page indices to match. Passing a one-based
number renders *"صفحة 2 من 1"* on a single-page result — which is exactly what
happened during implementation, and is why the widget tests assert the pager
text.

The card layout below the table breakpoint carries its own pager speaking the
same zero-based numbers, so the two layouts page identically.

---

## 9. Boundaries under test

`customers_boundaries_test.dart` reads the source and fails on:

- any `officeId` / `office_id` in the feature;
- `DashboardSession` in the datasource;
- any `.from(` in the datasource;
- `gateway_response` / `gateway_transaction_id` / `gateway_order_id` / `card_number` anywhere;
- presentation importing `data/` or naming `SupabaseClient`;
- domain importing Flutter or Supabase;
- data importing presentation;
- `Color(0x…)` in a widget;
- physical insets/alignments instead of directional ones;
- `TextDirection.ltr`;
- a write verb on the repository interface.

Comments are stripped before matching, so the module can document the very
things it excludes without failing its own check.
