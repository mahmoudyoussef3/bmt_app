# Client App — Architecture

> Scope: `lib/apps/client` (901 Dart files, ~70k lines). Backend: Supabase.
> The authoritative coding conventions are `.claude/docs/CLIENT_APP.md`; this
> document describes the system those conventions produced and the places where
> the two have drifted.

---

## 1. What the Client App is

A customer-facing marketplace for intercity / commuter shuttle seats. Several
**transport offices** publish routes, trips, vehicles and packages from the
Dashboard; the Client App lets a passenger discover them, book a seat, pay, and
follow the vehicle.

The Client owns **no operational entity**. It creates only passenger-scoped
records — bookings, payments, support tickets, reviews, seat locks — and reads
everything else through marketplace-safe views.

```
Dashboard (offices)     ── writes ─▶  routes · trips · vehicles · packages · fares
Captain app (drivers)   ── writes ─▶  trip status · live positions · incident reports
Client app (passengers) ── writes ─▶  bookings · payments · tickets · reviews
                        ── reads  ─▶  public_trips · public_offices · trip_seats ·
                                      trip_route_points · trip_live_locations
```

## 2. Layering

Feature-first Clean Architecture, one directory per feature under
`lib/apps/client/features/<x>/`:

```
data/         datasources (abstract + Supabase impl) · models · mappers · repositories
domain/       entities · repository contracts · use cases
presentation/ cubit (Cubit + sealed State) · screens · widgets · routes
```

Dependency direction is strictly `presentation → domain → data`. Domain holds no
Flutter, Supabase or JSON import. Presentation never imports `data/`.

The stack differs from the repo-root `CLAUDE.md` playbook and that is deliberate:
no Retrofit, no Dio, no freezed, no `ApiResult<T>`. State is plain `sealed class`
unions; datasources throw and cubits catch.

## 3. Composition root

```
lib/main_client.dart
  → bootstrapFlavorApp(AppFlavor.client)
    → ClientApp (lib/apps/client/client_app.dart)
       ├─ registerClientDependencies()      core/di/client_di.dart  (clientGetIt)
       ├─ ClientThemeStore restore          light / dark / system
       ├─ Supabase onAuthStateChange        → FcmService.initialize(...)
       ├─ MaterialApp
       │    routes:          ClientRouter.routes
       │    onUnknownRoute:  → the shell (a server-supplied action_url must
       │                       never throw "no generator for route")
       └─ home: ClientSplashGate → onboarding | shell | welcome
```

- **DI**: `clientGetIt` (`GetIt.asNewInstance()`), one private
  `_registerXDependencies()` per feature. Datasources and repositories are
  `registerLazySingleton`; cubits are `registerFactory`.
- **Routing**: `ClientRouter.routes` is a flat `Map<String, WidgetBuilder>`.
  Route-name constants live with their feature (`BookingRoutes`, `TripsRoutes`,
  …); only shell paths live in `ClientRoutes`. `ClientCubitScopes` wraps each
  screen in the `BlocProvider`s it needs.
- **Arguments** are resolved by the owning entity's `fromArguments` factory, so
  argument shapes stay testable next to the type they produce.

`test/apps/client/core/client_router_test.dart` asserts the route table against
a hand-declared surface, so a constant nobody registers — or a route registered
under no constant — fails the build.

## 4. The two booking funnels (one retired)

The app carried **two** booking implementations. Only one works.

| | Booking wizard (live) | Seat-selection funnel (retired) |
|---|---|---|
| Entry | `BookingRoutes.wizard` | `SeatSelectionRoutes.seatSelection` |
| Commits via | `PlaceSeatBookingUseCase` — lock **then** confirm, releasing the lock if confirm throws | `ConfirmSeatBookingUseCase` alone, no lock |
| RPC arguments | full 22-arg set incl. `p_package_id`, `p_plan_start_date` | 17 args — cannot resolve against the live function |
| Card outcome | read back from our own DB (`card_payment_state`) | the WebView's return value, discarded |

The retired funnel is **no longer registered in `ClientRouter`** (see
`CLIENT_STATUS.md` for the orphaned files awaiting deletion). Seats are booked
only through the wizard.

## 5. State-management shape

One cubit per screen concern, not one per feature. States are sealed unions:

```dart
sealed class TripsState {}
class TripsLoading extends TripsState {}
class TripsLoaded  extends TripsState { … }
class TripsError   extends TripsState { final String message; }
```

Notable cubits:

| Cubit | Owns |
|---|---|
| `BookingWizardCubit` | the answers (route, date, trip, stops, seat, package, method) |
| `BookingWizardStepCubit` | which step is showing |
| `BookingWizardConfirmCubit` | the booking attempt and the card settlement wait |
| `TripsCubit` | My Trips list + selected trip + realtime refresh + cancel |
| `TrackingCubit` | live trip, position stream, progress engine, ETA ticker |
| `NotificationsCubit` | realtime inbox + unread count |

## 6. Realtime

Clients hold **no read policy on `operation_trips`**, so its postgres_changes
never reach them. Two channels carry the signal instead:

- `operation_bookings` filtered on `client_id` — the rider's own bookings.
- `trip_events` — RLS delivers only events for trips the rider actually booked;
  `update_trip_status` writes one row per lifecycle transition.
- `trip_seats` — the marketplace-readable table Home uses as a "something
  changed" ping (payload ignored).
- `trip_live_locations` — vehicle position, plus an 8s `latestLocation` poll as
  a delivery fallback.

## 7. Domain model — three independent state axes

A booking is described by three statuses that can and do disagree. They are kept
separate on purpose; see `CLIENT_BOOKING_LIFECYCLE.md`.

| Axis | Source | Enum |
|---|---|---|
| Journey | `operation_trips.status` | `TripStatus` |
| Booking | `operation_bookings.status` | `BookingState` |
| Payment | `operation_bookings.payment_status` | `PaymentStatus` |

`TripAttention` (`domain/entities/trip_attention.dart`) is derived from all
three and answers the one question no single badge can: *is it my move?*

## 8. Known architectural debt

- **Orphaned files.** The retired funnel's screens/cubit still exist in `lib/`
  but are unreachable. Listed in `CLIENT_STATUS.md` for deletion.
- **`trips` route argument naming.** `TripsRoutes.tripDetails` takes
  `{'tripId': <booking id>}`. The key is wrong; the value is right. Renaming it
  touches every call site and the notification resolver together.
- **File-size guideline.** `.claude/docs/CLIENT_APP.md` sets a 120-line ceiling
  for presentation files; `seat_release_screen.dart`, `subscription_screen.dart`
  and `communication_screen.dart` are well over it.
- **`promo_codes` does not exist** in the database. The promo path was part of
  the retired funnel and went with it, but `PaymentRepository.validatePromoCode`
  and its datasource method remain.
