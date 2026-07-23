import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_trip_step.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The trip's date is the date the rider travels *and* the date any package
/// they buy starts running — they are never asked to pick one. That only works
/// if the departure step actually shows the date it is committing them to.
void main() {
  RouteOptionData routeWithTripOn(String isoDate) => RouteOptionData(
    id: 'r1',
    routeName: 'test new route',
    pickup: 'Cairo',
    destination: 'Alexandria',
    distance: '32 km',
    duration: '1h 19m',
    availableSeats: 12,
    startingPrice: 'EGP 40',
    priceRange: 'EGP 40',
    availableTrips: [
      RouteTripOptionData(
        id: 't1',
        tripDate: isoDate,
        departureTime: '08:00:00',
        arrivalTime: '09:19:00',
        availableSeats: 9,
        vehicleType: 'H1',
        price: '40',
      ),
    ],
  );

  Future<BookingWizardCubit> pumpStep(
    WidgetTester tester,
    RouteOptionData route,
  ) async {
    final cubit = BookingWizardCubit(route);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<BookingWizardCubit>.value(
            value: cubit,
            child: WizardTripStep(onNext: () {}),
          ),
        ),
      ),
    );
    return cubit;
  }

  String iso(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

  testWidgets('every departure shows the day it runs, not just its clock', (
    tester,
  ) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await pumpStep(tester, routeWithTripOn(iso(tomorrow)));

    expect(find.text('Tomorrow'), findsOneWidget);
  });

  testWidgets('raw Supabase clocks are rendered as readable times', (
    tester,
  ) async {
    await pumpStep(tester, routeWithTripOn(iso(DateTime.now())));

    expect(find.text('08:00:00'), findsNothing);
    expect(find.text('8:00 AM'), findsOneWidget);
  });

  testWidgets('the pinned summary carries the day into the confirmation', (
    tester,
  ) async {
    final route = routeWithTripOn(iso(DateTime.now()));
    final cubit = await pumpStep(tester, route);

    cubit.selectTrip(route.availableTrips.first);
    await tester.pump();

    expect(find.text('Departs Today · 8:00 AM'), findsOneWidget);
  });

  testWidgets('a trip with no date still renders rather than crashing', (
    tester,
  ) async {
    final route = routeWithTripOn('');
    final cubit = await pumpStep(tester, route);

    cubit.selectTrip(route.availableTrips.first);
    await tester.pump();

    expect(find.text('Departs 8:00 AM'), findsOneWidget);
  });
}
