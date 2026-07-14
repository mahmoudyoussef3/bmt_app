import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/tracking/domain/entities/tracking_trip.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_contact_dialog.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_live_map.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_mobile_layout.dart';
import 'package:bmt_app/apps/client/features/tracking/presentation/widgets/tracking_tablet_layout.dart';

/// Builds the map plus the tablet/mobile layout for a loaded tracking
/// session, wiring the small set of navigation/cubit callbacks every layout
/// needs.
class TrackingScreenBody extends StatelessWidget {
  const TrackingScreenBody({
    super.key,
    required this.loaded,
    required this.shellMode,
    required this.isTablet,
    required this.sheetController,
  });

  final TrackingLoaded loaded;
  final bool shellMode;
  final bool isTablet;

  /// The mobile layout's draggable details sheet; forwarded to the map for
  /// sheet-aware camera padding and to the mobile layout to attach the sheet
  /// itself. Unused on tablet, which has no draggable sheet.
  final DraggableScrollableController sheetController;

  TrackingTripState get _currentState => loaded.currentState;
  TrackingTripData? get _trip => loaded.data;

  int get _currentTimelineStep => switch (_currentState) {
    TrackingTripState.notStarted => 1,
    TrackingTripState.driverOnWay => 2,
    TrackingTripState.boarding => 3,
    TrackingTripState.inProgress => 4,
    TrackingTripState.completed => 5,
  };

  @override
  Widget build(BuildContext context) {
    // On phones the map sits full-bleed behind a transparent, floating app
    // bar (see TrackingScreen), so the captain card needs enough top inset
    // to clear the back button instead of the small fixed margin used when
    // the map has its own bounded panel (tablet).
    final captainCardTopInset = isTablet
        ? 12.0
        : MediaQuery.paddingOf(context).top + kToolbarHeight + 12;
    final map = TrackingLiveMap(
      routePoints: _trip?.routePoints ?? const <TrackingPoint>[],
      vehicleFix: _trip?.vehicleFix,
      currentState: _currentState,
      progress: loaded.progress,
      trip: _trip,
      sheetController: sheetController,
      onRefresh: () => context.read<TrackingCubit>().refresh(),
      captainCardTopInset: captainCardTopInset,
      borderRadius: isTablet ? 18 : 0,
    );
    final cubit = context.read<TrackingCubit>();
    void onContactDriver() => showTrackingContactDialog(context, 'Driver', _trip?.driverPhone);
    void onSupport() => Navigator.of(context).pushNamed('/support');
    void onViewRoute() => cubit.refresh();
    void onBookAnotherTrip() => Navigator.of(context).pushReplacementNamed('/home');

    if (isTablet) {
      return TrackingTabletLayout(
        currentState: _currentState,
        trip: _trip,
        progress: loaded.progress,
        currentTimelineStep: _currentTimelineStep,
        map: map,
        driverRating: loaded.ratings.driver,
        vehicleRating: loaded.ratings.vehicle,
        routeRating: loaded.ratings.route,
        onViewRoute: onViewRoute,
        onContactDriver: onContactDriver,
        onSupport: onSupport,
        onRateDriver: cubit.rateDriver,
        onRateVehicle: cubit.rateVehicle,
        onRateRoute: cubit.rateRoute,
        onBookAnotherTrip: onBookAnotherTrip,
      );
    }
    return TrackingMobileLayout(
      shellMode: shellMode,
      currentState: _currentState,
      trip: _trip,
      progress: loaded.progress,
      currentTimelineStep: _currentTimelineStep,
      map: map,
      sheetController: sheetController,
      driverRating: loaded.ratings.driver,
      vehicleRating: loaded.ratings.vehicle,
      routeRating: loaded.ratings.route,
      onViewRoute: onViewRoute,
      onContactDriver: onContactDriver,
      onSupport: onSupport,
      onRateDriver: cubit.rateDriver,
      onRateVehicle: cubit.rateVehicle,
      onRateRoute: cubit.rateRoute,
      onBookAnotherTrip: onBookAnotherTrip,
    );
  }
}
