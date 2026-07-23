import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/summary/summary_edit_strip.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/wizard_summary_step.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

const _route = RouteOptionData(
  id: 'r1',
  routeName: 'test new route',
  pickup: 'Cairo Military Academy Stadium',
  destination: 'Gate 3, Concord Plaza Mall',
  distance: '32 km',
  duration: '1h 19m',
  availableSeats: 12,
  startingPrice: 'EGP 40',
  priceRange: 'EGP 40',
  availableTrips: [],
);

/// Mirrors the data the Dashboard actually hands this screen: raw `HH:mm:ss`
/// clocks, long geocoded stop names, and a plan with no English name.
BookingWizardCubit _sessionCubit() {
  final cubit = BookingWizardCubit(_route)
    ..selectPickup(
      const RoutePointData(
        id: 'p1',
        name: 'Cairo Military Academy Stadium, Cairo, Egypt',
        order: 1,
      ),
    )
    ..selectDropoff(
      const RoutePointData(
        id: 'p2',
        name: 'Gate 3, Concord Plaza Mall 90th Street, South Teseen, QH, Egypt',
        order: 4,
      ),
    )
    ..selectTrip(
      const RouteTripOptionData(
        id: 't1',
        tripDate: '2030-01-08',
        departureTime: '00:00:00',
        arrivalTime: '01:19:00',
        availableSeats: 9,
        vehicleType: 'H1',
        price: 'EGP 40',
      ),
    )
    ..selectSeat('s1', 'D2')
    ..selectPackage(
      const PackagePlan(
        id: 'pk1',
        nameAr: 'رحلة ذهاب وعودة',
        nameEn: '',
        packageType: 'round_trip',
        durationDays: 1,
        rideCount: 2,
        price: 70,
      ),
    );
  return cubit;
}

Future<void> _pumpStep(
  WidgetTester tester, {
  ValueChanged<int>? onEditStep,
}) async {
  final cubit = _sessionCubit();
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<BookingWizardCubit>.value(
          value: cubit,
          child: WizardSummaryStep(
            onNext: () {},
            onEditStep: onEditStep ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders raw trip clocks as readable times and a ride length', (
    tester,
  ) async {
    await _pumpStep(tester);

    expect(find.text('12:00 AM'), findsOneWidget);
    expect(find.text('1:19 AM'), findsOneWidget);
    expect(find.text('1h 19m'), findsOneWidget);
    expect(find.text('00:00:00'), findsNothing);
  });

  testWidgets('keeps the total visible with the action, not below the fold', (
    tester,
  ) async {
    await _pumpStep(tester);

    final total = find.text('EGP 70');
    expect(total, findsWidgets);
    expect(find.text('Total due'), findsWidgets);

    // The pinned total sits inside the viewport above the CTA.
    final button = tester.getRect(find.text('Proceed to payment'));
    final pinned = tester.getRect(total.last);
    expect(pinned.bottom, lessThan(button.top + 1));
    expect(pinned.bottom, lessThan(tester.view.physicalSize.height));
  });

  testWidgets('falls back to the Arabic plan name when no English one is set', (
    tester,
  ) async {
    await _pumpStep(tester);

    expect(find.textContaining('رحلة ذهاب وعودة'), findsWidgets);
    expect(find.textContaining('2 Rides'), findsWidgets);
  });

  testWidgets('edit chips jump back to the step that owns the choice', (
    tester,
  ) async {
    final edited = <int>[];
    await _pumpStep(tester, onEditStep: edited.add);

    Finder chip(String label) => find.descendant(
      of: find.byType(SummaryEditStrip),
      matching: find.text(label),
    );

    await tester.tap(chip('Seat'));
    await tester.tap(chip('Stops'));
    await tester.pump();

    expect(edited, [2, 0]);
  });

  testWidgets('lays out on a small phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpStep(tester);

    expect(tester.takeException(), isNull);
  });
}
