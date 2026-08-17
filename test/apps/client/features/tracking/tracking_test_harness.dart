import 'dart:async';

import 'package:bmt_app/apps/client/features/tracking/data/datasources/tracking_datasource.dart';
import 'package:bmt_app/apps/client/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/confirm_boarding_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/get_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_tracking_trip_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/domain/usecases/watch_vehicle_feed_usecase.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/bloc/live_tracking_bloc.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/core/tracking/live_tracking_config.dart';

/// A tracking datasource whose feed the test drives by hand.
///
/// Both halves of the split are built from one of these, so a test can assert
/// that the *cubit* holds the trip document and the *bloc* holds the feed without
/// two sets of fakes disagreeing about what the server said.
class FakeTrackingDatasource implements TrackingDatasource {
  FakeTrackingDatasource({required this.trip});

  TrackingTripData trip;

  final StreamController<VehicleFeedEvent> feed =
      StreamController<VehicleFeedEvent>.broadcast();

  /// How many times the feed has been subscribed to. One per tracked trip is the
  /// contract; two would mean two channels for one bus.
  int feedSubscriptions = 0;

  String? confirmedBookingId;
  int confirmCalls = 0;
  Object? boardingFailure;
  bool failNextFetch = false;

  /// Blocks `confirmBoarding` so a second tap can be attempted mid-flight.
  Future<void>? hold;

  @override
  Future<TrackingTripData> getTrackingTrip({
    String? bookingId,
    String? tripId,
  }) async {
    if (failNextFetch) {
      failNextFetch = false;
      throw Exception('network down');
    }
    return trip;
  }

  @override
  Stream<VehicleFeedEvent> watchVehicleFeed(String tripId) {
    feedSubscriptions++;
    return feed.stream;
  }

  @override
  Stream<void> watchTripChanges(String tripId) => const Stream<void>.empty();

  @override
  Future<void> confirmBoarding(String bookingId) async {
    confirmCalls++;
    confirmedBookingId = bookingId;
    if (hold != null) await hold;
    final failure = boardingFailure;
    if (failure != null) throw failure;
  }

  /// Publish a position on the feed.
  void emitFix({
    required double latitude,
    required double longitude,
    DateTime? recordedAt,
    double? speed,
    double? accuracy,
  }) {
    feed.add(
      VehicleFixReported(
        TrackingPoint(
          latitude: latitude,
          longitude: longitude,
          recordedAt: recordedAt ?? DateTime.now(),
          speed: speed,
          accuracy: accuracy,
        ),
      ),
    );
  }

  void emitLink(TrackingLink link) => feed.add(VehicleLinkChanged(link));

  Future<void> dispose() => feed.close();
}

TrackingCubit buildTrackingCubit(TrackingDatasource datasource) {
  final repository = TrackingRepositoryImpl(datasource);
  return TrackingCubit(
    getTrackingTrip: GetTrackingTripUseCase(repository),
    watchTrackingTrip: WatchTrackingTripUseCase(repository),
    confirmBoarding: ConfirmBoardingUseCase(repository),
  );
}

LiveTrackingBloc buildLiveTrackingBloc(
  TrackingDatasource datasource, {
  LiveTrackingConfig config = kLiveTrackingConfig,
  DateTime Function()? now,
}) {
  return LiveTrackingBloc(
    watchVehicleFeed: WatchVehicleFeedUseCase(
      TrackingRepositoryImpl(datasource),
    ),
    config: config,
    now: now ?? DateTime.now,
  );
}
