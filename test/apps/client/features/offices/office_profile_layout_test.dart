import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_offices_rail.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_route.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_trip.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_cubit.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/cubit/office_profile_state.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/screens/office_profile_screen.dart';

import '../../client_test_app.dart';

/// The office profile packs a masthead, a day-grouped departure board and a
/// route list into one scroll, and every row of it is built from
/// operator-supplied Arabic text. This pins the layout against the two ways it
/// broke while being built: a fare column starving the middle of a departure
/// tile, and a chip row overflowing its own pill.
class _StubOfficeProfileCubit extends Cubit<OfficeProfileState>
    implements OfficeProfileCubit {
  _StubOfficeProfileCubit(super.initialState);

  @override
  Future<void> load(String officeId) async {}
}

String _isoDaysFromNow(int days) =>
    DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);

const _office = OfficeSummary(
  id: 'o1',
  name: 'شركة النيل السريع للنقل السياحي والرحلات بين المحافظات',
  description:
      'نقل يومي مكيّف بين القاهرة الكبرى ومدن الدلتا، بمواعيد ثابتة وأسطول حديث.',
  rating: 4.6,
  ratingsCount: 128,
  serviceAreas: ['القاهرة', 'بنها', 'طنطا', 'المنصورة'],
);

/// Two departures today and one sold-out, fare-less departure tomorrow — the
/// grouping and the two degraded states in one board.
List<OfficeTrip> _trips() => [
  OfficeTrip(
    id: 't1',
    routeId: 'r1',
    routeName: 'بنها → القرية الذكية',
    pickup: 'بنها',
    destination: 'القرية الذكية',
    tripDate: _isoDaysFromNow(0),
    departureTime: '07:30:00',
    duration: '1h 20m',
    price: 'EGP 60',
    seatsLeft: 12,
  ),
  OfficeTrip(
    id: 't2',
    routeId: 'r1',
    routeName: 'بنها → القرية الذكية',
    pickup: 'بنها',
    destination: 'القرية الذكية',
    tripDate: _isoDaysFromNow(0),
    departureTime: '17:45:00',
    duration: '1h 30m',
    price: 'EGP 60',
    seatsLeft: 3,
  ),
  OfficeTrip(
    id: 't3',
    routeId: 'r2',
    routeName: 'المنصورة → مدينة نصر',
    pickup: 'المنصورة',
    destination: 'مدينة نصر',
    tripDate: _isoDaysFromNow(1),
    departureTime: '06:00:00',
    duration: '2h 40m',
    price: '',
    seatsLeft: 0,
  ),
];

/// A named corridor with endpoints, plus one that has neither — the tile's
/// spine layout and its bare-name fallback.
const _routes = [
  OfficeRoute(
    id: 'r1',
    name: 'خط بنها - القرية الذكية السريع',
    startCity: 'بنها',
    endCity: 'القرية الذكية',
  ),
  OfficeRoute(id: 'r2', name: 'خط داخلي', startCity: '', endCity: ''),
];

Future<void> _atEachSize(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  for (final size in const [Size(320, 640), Size(430, 932)]) {
    await tester.binding.setSurfaceSize(size);
    await body();
  }
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    final tag = locale.languageCode;

    testWidgets('the office profile lays out cleanly ($tag)', (tester) async {
      await _atEachSize(tester, () async {
        await tester.pumpWidget(
          clientTestApp(
            locale: locale,
            BlocProvider<OfficeProfileCubit>(
              create: (_) => _StubOfficeProfileCubit(
                OfficeProfileLoaded(routes: _routes, trips: _trips()),
              ),
              child: OfficeProfileScreen(office: _office),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Walk the whole scroll so every tile is built and laid out, not just
        // the two that happen to fit the first viewport.
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('the home offices rail lays out cleanly ($tag)', (
      tester,
    ) async {
      await _atEachSize(tester, () async {
        await tester.pumpWidget(
          clientTestApp(
            locale: locale,
            Scaffold(
              body: Center(
                child: HomeOfficesRail(
                  offices: const [
                    _office,
                    // An unrated newcomer with no service areas: the tile's
                    // other footing.
                    OfficeSummary(id: 'o2', name: 'Delta Lines'),
                  ],
                  isLoading: false,
                  onOpenOffice: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('departures are grouped under a day heading', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      clientTestApp(
        BlocProvider<OfficeProfileCubit>(
          create: (_) => _StubOfficeProfileCubit(
            OfficeProfileLoaded(routes: const [], trips: _trips()),
          ),
          child: OfficeProfileScreen(office: _office),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Three departures across two dates read as two dated groups, not as one
    // undifferentiated column of times.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
  });
}
