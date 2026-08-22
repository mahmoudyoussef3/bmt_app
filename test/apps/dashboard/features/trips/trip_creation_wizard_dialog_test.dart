import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/entities/operation_route.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_creation_wizard.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_package_offer.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/trip_pricing.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/domain/entities/trip_driver_option.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_creation/presentation/cubit/trip_creation_cubit.dart';

/// Regression coverage for the wizard's most damaging bug: a rejected submit
/// (a duplicate trip code, a conflict the availability check missed) used to
/// tear the whole form down and silently wipe everything the operator had
/// picked, because the dialog swapped [TripCreationWizard] out for an
/// unrelated loading/error widget on every [TripCreationLoading] /
/// [TripCreationError] emission — including the ones `submitTrip` raises
/// after the wizard's own data has already loaded.

const _vehicle = AssignedVehicle(
  id: 'v-1',
  plateNumber: 'ABC 123',
  vehicleCode: 'VH-01',
  vehicleType: 'Hiace',
  brand: 'Toyota',
  model: 'Hiace',
  capacity: 14,
  status: 'active',
);

const _driver = TripDriverOption(
  id: 'd-1',
  name: 'أحمد محمد',
  phone: '01000000001',
  assignedVehicle: _vehicle,
);

final _route = OperationRoute(
  id: 'r-1',
  name: 'بنها - القاهرة',
  startCity: 'بنها',
  endCity: 'القاهرة',
  duration: 'ساعة',
  distance: '60 كم',
  status: OperationRouteStatus.active,
  stations: const [
    RouteStation(
      id: 'st-1',
      name: 'بنها',
      area: 'القليوبية',
      arrivalOffset: '0',
      departureOffset: '0',
      locationDescription: '',
      notes: '',
      order: 1,
    ),
    RouteStation(
      id: 'st-2',
      name: 'القاهرة',
      area: 'القاهرة',
      arrivalOffset: '60',
      departureOffset: '60',
      locationDescription: '',
      notes: '',
      order: 2,
    ),
  ],
  notes: const [],
);

/// Mirrors the real cubit's `submitTrip` failure path exactly: emits
/// Loading, then Error, then re-emits the last loaded state — the same
/// sequence a duplicate-trip-code or a stale-conflict refusal produces.
class _FakeTripCreationCubit extends Cubit<TripCreationState>
    implements TripCreationCubit {
  _FakeTripCreationCubit()
    : super(
        TripCreationWizardDataLoaded(
          routes: [
            {
              'id': _route.id,
              'name': _route.name,
              'start_city': _route.startCity,
              'end_city': _route.endCity,
              'duration': _route.duration,
              'distance': _route.distance,
              'route_stations': [
                for (final s in _route.stations)
                  {
                    'id': s.id,
                    'name': s.name,
                    'area': s.area,
                    'arrival_offset': s.arrivalOffset,
                    'departure_offset': s.departureOffset,
                    'sort_order': s.order,
                  },
              ],
            },
          ],
          drivers: const [_driver],
          packages: const [],
        ),
      );

  int submitAttempts = 0;

  @override
  Future<OperationTrip?> submitTrip(
    CreateTripInput input,
    List<TripPricing> pricing,
    List<TripPackageOffer> offers,
  ) async {
    submitAttempts += 1;
    final prev = state;
    emit(const TripCreationLoading());
    await Future<void>.delayed(Duration.zero);
    emit(const TripCreationError('حدث تعارض مؤقت أثناء ترقيم الرحلة.'));
    if (prev is TripCreationWizardDataLoaded) emit(prev);
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getResourceConflicts({
    required String date,
    required String departureTime,
    required String arrivalTime,
  }) async => const [];

  @override
  Future<void> loadWizardData() async {}

  @override
  void reset() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _harness(TripCreationCubit cubit) {
  return MaterialApp(
    theme: DashboardAppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider<TripCreationCubit>.value(
        value: cubit,
        child: const Scaffold(body: TripCreationWizardDialog()),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a rejected submit keeps the selected route, driver and price on screen',
    (tester) async {
      final cubit = _FakeTripCreationCubit();
      addTearDown(cubit.close);

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_harness(cubit));
      await tester.pump();

      // Pick the route.
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_route.name).last);
      await tester.pumpAndSettle();

      // Pick the driver.
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(_driver.name).last);
      await tester.pumpAndSettle();

      // Set a ticket price.
      final priceField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'سعر التذكرة (رحلة واحدة)',
      );
      expect(priceField, findsOneWidget);
      await tester.enterText(priceField, '100');
      await tester.pump();

      expect(find.text(_route.name), findsWidgets);
      expect(find.text(_driver.name), findsWidgets);

      final submitButton = find.widgetWithText(FilledButton, 'إنشاء الرحلة');
      expect(submitButton, findsOneWidget);
      expect(
        tester.widget<FilledButton>(submitButton).onPressed,
        isNotNull,
        reason: 'the plan is complete, so submit must be enabled',
      );

      await tester.tap(submitButton);
      // Loading, then the rejection, then the re-emitted loaded state.
      await tester.pumpAndSettle();

      expect(cubit.submitAttempts, 1);

      // The whole point: none of the operator's picks were wiped by the
      // failed submit's Loading -> Error -> Loaded round trip.
      expect(
        find.text(_route.name),
        findsWidgets,
        reason: 'the selected route must survive a rejected submit',
      );
      expect(
        find.text(_driver.name),
        findsWidgets,
        reason: 'the selected driver must survive a rejected submit',
      );
      final priceAfter = tester.widget<TextField>(priceField);
      expect(
        priceAfter.controller?.text,
        '100',
        reason: 'the typed price must survive a rejected submit',
      );
      expect(
        find.text('حدث تعارض مؤقت أثناء ترقيم الرحلة.'),
        findsOneWidget,
        reason: 'the server refusal is shown as a snackbar, not a blank form',
      );
    },
  );
}
