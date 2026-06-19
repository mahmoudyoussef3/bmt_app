import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/live_trips/domain/entities/live_trip.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/repositories/live_trips_repository.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/get_live_trips_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/start_live_trip_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/pause_live_trip_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/resume_live_trip_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/complete_live_trip_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/mark_route_point_arrived_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/mark_route_point_completed_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/skip_route_point_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/resolve_live_trip_alert_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/report_live_trip_alert_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/call_driver_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/send_driver_message_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/toggle_passenger_checkin_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/usecases/watch_vehicle_position_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/presentation/cubit/live_trips_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/presentation/screens/live_trips_screen.dart';

void main() {
  testWidgets('LiveTripsScreen renders empty live feed safely', (tester) async {
    final repository = const _EmptyLiveTripsRepository();
    final cubit = LiveTripsCubit(
      getLiveTrips: GetLiveTripsUseCase(repository),
      startTrip: StartLiveTripUseCase(repository),
      pauseTrip: PauseLiveTripUseCase(repository),
      resumeTrip: ResumeLiveTripUseCase(repository),
      completeTrip: CompleteLiveTripUseCase(repository),
      markPointArrived: MarkRoutePointArrivedUseCase(repository),
      markPointCompleted: MarkRoutePointCompletedUseCase(repository),
      skipPoint: SkipRoutePointUseCase(repository),
      resolveAlert: ResolveLiveTripAlertUseCase(repository),
      reportAlert: ReportLiveTripAlertUseCase(repository),
      callDriver: CallDriverUseCase(repository),
      messageDriver: SendDriverMessageUseCase(repository),
      togglePassengerCheckin: TogglePassengerCheckinUseCase(repository),
      watchVehiclePosition: WatchVehiclePositionUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider.value(
              value: cubit..loadLiveTrips(),
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

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> startTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> pauseTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> resumeTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> completeTrip(String tripId) => throw UnimplementedError();

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) => throw UnimplementedError();

  @override
  Future<String> callDriver(String driverPhone) => throw UnimplementedError();

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) =>
      throw UnimplementedError();

  @override
  Future<LiveTrip> togglePassengerCheckin(String tripId, String passengerId) =>
      throw UnimplementedError();

  @override
  Stream<VehiclePosition> watchVehiclePosition(String tripId) =>
      const Stream.empty();
}
