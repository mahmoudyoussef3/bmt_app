import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/live_trips/domain/entities/live_trip.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/repositories/live_trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/get_live_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/presentation/cubit/live_trips_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/presentation/screens/live_trips_screen.dart';

void main() {
  testWidgets('LiveTripsScreen renders empty live feed safely', (tester) async {
    final cubit = LiveTripsCubit(
      GetLiveTripsUseCase(const _EmptyLiveTripsRepository()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..load(),
              child: const LiveTripsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد رحلات مباشرة الآن'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await cubit.close();
  });
}

class _EmptyLiveTripsRepository implements LiveTripsRepository {
  const _EmptyLiveTripsRepository();

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    return [];
  }
}
