# Client · Packages & My Subscription

Ride packages (single ride, weekly, monthly, …) sold by offices, the **fare menu of one trip**
shown in the booking wizard, and the rider's active subscription card.

## Overview

| Layer | Files (relative to `lib/apps/client/features/packages/`) |
|---|---|
| Screens | `presentation/screens/my_subscription_screen.dart` (route `PackagesRoutes.mySubscription` = `/my-subscription`); package pickers are rendered inside the booking feature: `features/booking/presentation/widgets/wizard_package_step.dart` (`PackagesCubit.loadForTrip`) and `features/booking/presentation/widgets/route_details/route_packages_section.dart` (`RoutePackagesCubit.loadFor(officeId)`) |
| Cubits | `PackagesCubit` (`presentation/cubit/packages_cubit.dart`), `MySubscriptionCubit`, `features/booking/presentation/cubit/route_packages_cubit.dart` |
| Use cases | `GetTripPackagesUseCase`, `GetOfficePackagesUseCase`, `GetMySubscriptionUseCase` |
| Repo | `data/repositories/packages_repository_impl.dart` (drops packages with no resolved office) |
| **Datasource** | `data/datasources/supabase_packages_datasource.dart` |
| Models / mappers | `data/models/package_plan_model.dart`, `data/mappers/package_plan_mapper.dart`, `my_subscription_mapper.dart` |
| Entities | `domain/entities/package_plan.dart`, `my_subscription.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| K1 | Office catalogue packages | `GET transport_packages?office_id=eq.&trip_id=is.null` | anon | `GET /api/v1/packages?officeId=` |
| K2 | A trip's fare menu | `GET transport_packages?or=(id.in.(…),walk-up)` | anon | `GET /api/v1/trips/{tripId}/packages` |
| K3 | My active subscription | `GET subscriptions?client_id=eq.&status=eq.active` | session | `GET /api/v1/me/subscription` |

---

## K1 — Catalogue packages: `getPackages({officeId})` (`supabase_packages_datasource.dart:16-36`)

```
GET /rest/v1/transport_packages
  ?select=*,office:public_offices(id,name,logo_url,rating,ratings_count,description,service_areas)
  &active=eq.true
  &trip_id=is.null                      // catalogue only — trip-scoped packages never browse
  [&office_id=eq.<officeId>]
  &order=display_order.asc
```

`RLS` (`20260807140000_licensing_marketplace.sql:217`): `active = true AND office_is_listed(office_id)
AND office_sells_packages(office_id)` — an office whose licence does not include passenger packages
sells none, regardless of what it published.

Row mapping (`PackagePlanModel.fromJson`):

| Field | Column |
|---|---|
| `id`, `nameAr`, `nameEn`, `packageType`, `durationDays` (default 1), `rideCount` (default 1), `price` (num), `descriptionAr`, `descriptionEn` | `id, name_ar, name_en, package_type, duration_days, ride_count, price, description_ar, description_en` |
| `officeId`, `officeName`, `officeLogoUrl`, `officeRating`, `officeRatingsCount`, `officeDescription`, `officeServiceAreas[]` | embedded `office` |

`PackagesRepositoryImpl._marketplaceReady` drops any row whose `office` embed did not resolve
(`hasOffice == false`) — the guarantee that a rider never sees a package they cannot attribute to a listed office.

---

## K2 — A trip's fare menu: `getTripPackages({officeId, packageIds})` (line 38)

Inputs come from the wizard session: `officeId = route.office.id`; `packageIds` = the package ids
present in the selected trip's `trip_package_prices` rows for the rider's stop pair (or all active
pricing rows before the stops are chosen) — see `BookingWizardSession.tripPackageIds`.

```
GET /rest/v1/transport_packages
  ?select=<same columns as K1>
  &active=eq.true
  &office_id=eq.<officeId>
  &or=(id.in.(<id1>,<id2>,…),and(trip_id.is.null,duration_days.lte.1,ride_count.eq.1))
  &order=display_order.asc
```

**`BUSINESS RULE` (client-side today):** the menu = the packages the office priced on this trip
**plus the office's walk-up single-ride package** (`trip_id IS NULL AND duration_days <= 1 AND
ride_count = 1`), which is deliberately *not* in `trip_package_prices` because its fare is the trip's
`one_time_price`. Without the walk-up clause a rider could not buy a single ride. Empty `officeId` ⇒ empty list.

Price display per package is resolved client-side from the trip's `trip_pricing` row for the exact
stop pair (`lib/core/pricing/trip_pricing_resolver.dart`), mirroring `confirm_seat_booking_v2`:
single ride ⇒ `one_time_price`; other packages ⇒ `trip_package_prices.price`; fallback ⇒ catalogue `price`.
Per-package office notes come from `trip_package_prices.note` (exact pair only).

**Proposed .NET:** `GET /api/v1/trips/{tripId}/packages?from=<stationId>&to=<stationId>` → the
resolved menu with `resolvedPrice` and `note` already computed server-side, so the app and the
booking endpoint can never disagree on the fare.

---

## K3 — My subscription: `getMySubscription()` (line 66)

```
GET /rest/v1/subscriptions
  ?select=id,package_name,route_name,status,start_date,end_date,trips_count,trips_used
  &client_id=eq.<uid>&status=eq.active
  &order=created_at.desc&limit=1            (maybeSingle)
```

→ `MySubscription { id, packageName, routeName, status, startDate, endDate, tripsTotal=trips_count, tripsUsed=trips_used }` or `null`.
`RLS`: `subscriptions_client_read` (`client_id = auth.uid()`).

**Two subscription tables exist** (`subscriptions` — what this screen, Home and Profile read;
`transport_subscriptions` — what `confirm_seat_booking_v2` decrements via `p_subscription_id`). The
dashboard's payment approval mirrors into `subscriptions`. `NEEDS BACKEND DECISION`: collapse into
one subscription model; the client only needs the K3 shape.

**Proposed .NET:** `GET /api/v1/me/subscription` → the K3 shape or `204`.

---

## Notes for the .NET team

1. A package is either **catalogue** (`trip_id IS NULL`, sellable on any of the office's trips) or
   **trip-scoped** (`trip_id = <trip>`, sellable only there). Keep the distinction.
2. The walk-up single-ride rule is identified *by shape* (`duration_days <= 1 && ride_count == 1`), not by a flag.
3. `office_sells_packages` is a licensing switch separate from marketplace listing — an office can be
   listed and still sell no packages.
