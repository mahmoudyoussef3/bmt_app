# Dashboard — Routes and Stations

`/routes` — «المسارات». Owner only. Licensed on `routes`. Quota-gated on `max_routes`.

---

## 1. The model

```
operation_routes
   name, code, direction, active
      │
      └── route_stations (ordered)
             name            ← required. A stop IS a name.
             sequence        ← the order the bus calls at them
             latitude/longitude  ← OPTIONAL
             dwell time      ← how long the bus waits
             boarding rule   ← may passengers board / alight here
```

**Name-first is the design decision**, and it was arrived at by rebuilding the module
twice. A stop is a name that a passenger and a driver both recognise; GPS is an
enhancement. The armed map-picking mode — where the operator had to enter a mode, click
the map, then exit — is gone for good, and should not come back. The map is a dialog you
open when you want coordinates, not a mode you live in.

---

## 2. The builder

`RouteBuilderCubit` holds a draft, separate from `RoutesCubit` which holds the list. The
draft is editable without touching the saved route, and only `save` commits.

- **Reordering** stations renumbers `sequence`; the schedule recalculates through the new
  order.
- **Dwell time** on a stop pushes every stop after it later — the schedule is cumulative.
- **Reversing direction** re-runs the calculation the other way rather than mirroring the
  numbers.
- **Distance and duration are optional.** With no geo provider configured the route still
  saves; totals are simply absent. A route that cannot be saved because a third-party
  routing API is down is a worse product than a route without an ETA.
- **A failed calculation surfaces a message and keeps the draft.** It never discards the
  operator's work.
- **Existing stops are offered, not retyped.** The stop library suggests names the office
  already uses, so "محطة رمسيس" does not become four spellings.

---

## 3. Terminal stops and search

The client's route catalogue searches **every** station, not just endpoints, through one
shared normaliser in `core/search`. That is why a passenger looking for a mid-route town
finds the corridor that passes through it. The dashboard's job is to make sure those
station names are the ones passengers would actually type.

The terminal-stop rule: the first and last stations define the corridor's headline; the
ones between define what it can sell.

---

## 4. Pricing lives on the trip, not the route

A route has no price. A **trip** carries one fare, expanded to every stop pair, and
packages are flat multiples of it. This trips people up because a corridor feels like the
thing that should be priced — but the same corridor at 6am and at 6pm may not be worth the
same, and the trip is where that is expressed.

---

## 5. Reach

Routes are read by more surfaces than any other office-owned object:

| Reader | Via |
|---|---|
| Client app catalogue | `routes_marketplace_read` policy |
| Captain app | `routes_captain_read` policy |
| Trip planner | The office's own list |
| Live ops, reports, home top-routes | Joined through trips |

Which is why route RLS carries three policies rather than one, and why deleting a route
that has trips is refused.

---

## 6. Known gaps

- **No route performance over time.** Occupancy is computed per trip and aggregated per
  period; there is no "this corridor month over month" view. Home shows top routes for a
  window; nothing trends them.
- **No schedule templates.** Every trip is created individually. An office running the
  same six departures daily creates them one at a time, forever. This is the single
  highest-value missing operational feature in the console.
- **No station-level demand.** The schema knows which stop each passenger boards at; no
  screen reports it, so an operator cannot see which stops justify their dwell time.
- **No route versioning.** Editing a route's stations changes it for historical trips too,
  because trips reference the route rather than a snapshot of it.
