import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/search_options.dart';
import 'package:bmt_app/apps/client/features/booking/domain/repositories/booking_repository.dart';
import 'package:bmt_app/apps/client/features/booking/domain/usecases/get_search_options_usecase.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_search_cubit.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_hero_search_form.dart';

import '../../client_test_app.dart';

/// Serves the station lists the picker offers; every other repository call is
/// out of this widget's reach.
class _StubRepository implements BookingRepository {
  @override
  Future<TripSearchOptions> getSearchOptions() async {
    return const TripSearchOptions(
      pickupPoints: ['Cairo', 'Giza'],
      destinations: ['Alexandria', 'Luxor'],
      departureTimes: ['08:00'],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<BookingSearchCubit> _pump(
  WidgetTester tester, {
  void Function(BookingSearchQuery query)? onSearch,
}) async {
  final cubit = BookingSearchCubit(
    GetSearchOptionsUseCase(_StubRepository()),
  )..init(const BookingSearchQuery(), todayDate: 'Today, Jan 1');
  addTearDown(cubit.close);

  await tester.pumpWidget(
    clientTestApp(
      BlocProvider<BookingSearchCubit>.value(
        value: cubit,
        child: Scaffold(
          body: HomeHeroSearchForm(onSearch: onSearch ?? (_) {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

Future<void> _pickStation(
  WidgetTester tester,
  String rowLabel,
  String station,
) async {
  await tester.tap(find.text(rowLabel));
  await tester.pumpAndSettle();
  await tester.tap(find.text(station).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the card starts on its placeholders, not on a selection', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Departure station'), findsOneWidget);
    expect(find.text('Arrival station'), findsOneWidget);
  });

  testWidgets('picking a station fills the row in place, without leaving Home', (
    tester,
  ) async {
    final cubit = await _pump(tester);

    await _pickStation(tester, 'From', 'Cairo');
    await _pickStation(tester, 'To', 'Alexandria');

    expect(cubit.state.query.pickup, 'Cairo');
    expect(cubit.state.query.destination, 'Alexandria');
    expect(find.text('Departure station'), findsNothing);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Alexandria'), findsOneWidget);
  });

  testWidgets('the swap disc flips the two stations', (tester) async {
    final cubit = await _pump(tester);
    await _pickStation(tester, 'From', 'Cairo');
    await _pickStation(tester, 'To', 'Alexandria');

    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pumpAndSettle();

    expect(cubit.state.query.pickup, 'Alexandria');
    expect(cubit.state.query.destination, 'Cairo');
  });

  testWidgets('only the CTA reports out, and it carries the chosen query', (
    tester,
  ) async {
    final searched = <BookingSearchQuery>[];
    await _pump(tester, onSearch: searched.add);

    await _pickStation(tester, 'From', 'Cairo');
    expect(searched, isEmpty);

    await _pickStation(tester, 'To', 'Alexandria');
    await tester.tap(find.text('Search Trip'));
    await tester.pumpAndSettle();

    expect(searched, hasLength(1));
    expect(searched.single.pickup, 'Cairo');
    expect(searched.single.destination, 'Alexandria');
    expect(searched.single.isComplete, isTrue);
  });
}
