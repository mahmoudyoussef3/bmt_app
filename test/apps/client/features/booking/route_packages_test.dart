import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/route_packages_state.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_package_pricing.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/route_packages_section.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';

import '../../client_test_app.dart';

/// Packages moved off the office profile — where a plan could only ever say
/// "priced later" — onto Route Details, where the corridor exists to quote
/// them against. These pin the two things that move made possible: a real
/// "from" figure taken from the route's own `trip_pricing` rows, and a tap
/// that carries the plan into the booking wizard.
class _StubRoutePackagesCubit extends Cubit<RoutePackagesState>
    implements RoutePackagesCubit {
  _StubRoutePackagesCubit(super.initialState);

  @override
  Future<void> loadFor(String officeId) async {}
}

TripStopPairPrice _pair({
  required String from,
  required String to,
  required double oneTime,
  required double monthly,
  bool active = true,
}) {
  return TripStopPairPrice(
    fromPointId: from,
    toPointId: to,
    oneTimePrice: oneTime,
    fiveDaysPrice: oneTime * 4,
    tenDaysPrice: oneTime * 8,
    monthlyPrice: monthly,
    threeMonthsPrice: monthly * 3,
    isActive: active,
  );
}

const _monthlyPlan = PackagePlan(
  id: 'p-month',
  nameAr: 'باقة الشهر',
  nameEn: 'Monthly Plan',
  packageType: 'work_month',
  durationDays: 30,
  rideCount: 30,
  price: 4000,
  officeId: 'o1',
  officeName: 'Nile Transport',
);

/// A shape no `trip_pricing` tier covers: a same-day multi-ride plan.
const _sameDayPlan = PackagePlan(
  id: 'p-roundtrip',
  nameAr: 'ذهاب وعودة',
  nameEn: 'Round Trip',
  packageType: 'just_go',
  durationDays: 1,
  rideCount: 2,
  price: 150,
  officeId: 'o1',
  officeName: 'Nile Transport',
);

RouteOptionData _route({List<TripStopPairPrice> pricing = const []}) {
  return RouteOptionData(
    id: 'r1',
    routeName: 'Banha → Smart Village',
    pickup: 'Banha',
    destination: 'Smart Village',
    distance: '60 km',
    duration: '1h 20m',
    availableSeats: 12,
    startingPrice: 'EGP 60',
    priceRange: 'EGP 60 - 90',
    availableTrips: [
      RouteTripOptionData(
        id: 't1',
        departureTime: '07:30',
        arrivalTime: '08:50',
        availableSeats: 12,
        vehicleType: 'Minibus',
        price: 'EGP 60',
        stopPricing: pricing,
      ),
    ],
  );
}

Widget _section(
  RouteOptionData route,
  RoutePackagesState state,
  void Function(PackagePlan) onTap,
) {
  return clientTestApp(
    BlocProvider<RoutePackagesCubit>(
      create: (_) => _StubRoutePackagesCubit(state),
      child: Scaffold(
        body: SingleChildScrollView(
          child: RoutePackagesSection(route: route, onSelectPackage: onTap),
        ),
      ),
    ),
  );
}

void main() {
  group('routePackageFromPrice', () {
    test('leads with the cheapest pair that prices the plan shape', () {
      final price = routePackageFromPrice(
        _route(
          pricing: [
            _pair(from: 'a', to: 'c', oneTime: 90, monthly: 2400),
            _pair(from: 'a', to: 'b', oneTime: 60, monthly: 1600),
          ],
        ),
        _monthlyPlan,
      );

      // The widest pair is the dearest, so "from" must be the short hop —
      // a figure a rider can actually pay on this corridor.
      expect(price, 1600);
    });

    test('ignores deactivated pricing rows', () {
      final price = routePackageFromPrice(
        _route(
          pricing: [
            _pair(from: 'a', to: 'b', oneTime: 60, monthly: 900, active: false),
            _pair(from: 'a', to: 'c', oneTime: 90, monthly: 2400),
          ],
        ),
        _monthlyPlan,
      );

      expect(price, 2400);
    });

    test('is null when no tier covers the plan, never the catalogue price', () {
      final price = routePackageFromPrice(
        _route(
          pricing: [_pair(from: 'a', to: 'b', oneTime: 60, monthly: 1600)],
        ),
        _sameDayPlan,
      );

      // 150 is the catalogue's flat figure — the wizard's last resort, not
      // something to quote a browsing rider as this route's price.
      expect(price, isNull);
    });

    test('is null when the route publishes no pricing at all', () {
      expect(routePackageFromPrice(_route(), _monthlyPlan), isNull);
    });
  });

  group('RoutePackagesSection', () {
    testWidgets('quotes each plan against this route and hands it on', (
      tester,
    ) async {
      PackagePlan? chosen;
      final route = _route(
        pricing: [_pair(from: 'a', to: 'b', oneTime: 60, monthly: 1600)],
      );

      await tester.pumpWidget(
        _section(
          route,
          const RoutePackagesLoaded([_monthlyPlan]),
          (plan) => chosen = plan,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monthly Plan'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('EGP 1600'), findsOneWidget);

      await tester.tap(find.text('Monthly Plan'));
      await tester.pumpAndSettle();
      expect(chosen?.id, 'p-month');
    });

    testWidgets('an unpriceable plan still lists, saying so', (tester) async {
      await tester.pumpWidget(
        _section(
          _route(
            pricing: [_pair(from: 'a', to: 'b', oneTime: 60, monthly: 1600)],
          ),
          const RoutePackagesLoaded([_sameDayPlan]),
          (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Round Trip'), findsOneWidget);
      expect(find.text('Price shown when you pick a trip'), findsOneWidget);
      expect(find.text('From'), findsNothing);
    });

    testWidgets('an operator with no plans leaves no empty shelf', (
      tester,
    ) async {
      await tester.pumpWidget(
        _section(_route(), const RoutePackagesLoaded([]), (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Commute packages'), findsNothing);
    });

    testWidgets('a catalogue that fails to load is silent', (tester) async {
      await tester.pumpWidget(
        _section(_route(), const RoutePackagesUnavailable(), (_) {}),
      );
      await tester.pumpAndSettle();

      // Packages are optional context beside a route the rider can already
      // book, so a failure must not put an error in front of them.
      expect(find.text('Commute packages'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
