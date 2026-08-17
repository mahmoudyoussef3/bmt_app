import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/confirm_boarding_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_feed_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';

/// A [TrackingDatasource] that reports "nothing to track".
///
/// `TripLiveTrackingCard` builds its own `TrackingCubit` and `LiveTrackingBloc`
/// out of `clientGetIt`, so any test that renders an in-progress trip pulls the
/// whole tracking stack in with it. Without a registration the card throws and
/// takes the entire detail list down with it — the screen renders as just an app
/// bar, which is far more confusing than the assertion that follows.
class _NoTrackingDatasource implements TrackingDatasource {
  const _NoTrackingDatasource();

  @override
  Future<TrackingTripData> getTrackingTrip({String? bookingId, String? tripId}) async =>
      const TrackingTripData.none();

  @override
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId) =>
      const Stream<VehicleFeedEvent>.empty();

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream<void>.empty();

  @override
  Future<void> confirmBoarding(String bookingId) async {}
}

/// Registers the tracking pair backed by [_NoTrackingDatasource] and unregisters
/// them again when the test ends. Call from `setUp` in any suite that renders a
/// live trip.
void registerStubTrackingCubit() {
  if (clientGetIt.isRegistered<TrackingCubit>()) return;
  clientGetIt.registerFactory<TrackingCubit>(() {
    final repository = TrackingRepositoryImpl(const _NoTrackingDatasource());
    return TrackingCubit(
      getTrackingTrip: GetTrackingTripUseCase(repository),
      watchTrackingTrip: WatchTrackingTripUseCase(repository),
      confirmBoarding: ConfirmBoardingUseCase(repository),
    );
  });
  clientGetIt.registerFactory<LiveTrackingBloc>(() {
    final repository = TrackingRepositoryImpl(const _NoTrackingDatasource());
    return LiveTrackingBloc(
      watchVehicleFeed: WatchVehicleFeedUseCase(repository),
    );
  });
}

void unregisterStubTrackingCubit() {
  if (clientGetIt.isRegistered<TrackingCubit>()) {
    clientGetIt.unregister<TrackingCubit>();
  }
  if (clientGetIt.isRegistered<LiveTrackingBloc>()) {
    clientGetIt.unregister<LiveTrackingBloc>();
  }
}
