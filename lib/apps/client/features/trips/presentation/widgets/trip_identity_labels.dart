import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Display-safe driver/vehicle/route text derived from [TripData].
///
/// The data layer cannot localize, so a driver, vehicle, or route point that
/// hasn't resolved yet (still assigning a captain, a vehicle, or an
/// unparsable route string) is carried on the entity as an empty string.
/// These are the single place that turns that blank into localized copy —
/// kept in the presentation layer, same as [driverBadgeLabelFor] and
/// [statusLabelFor] in `trip_status_mapping.dart`.
String driverNameFor(BuildContext context, TripData trip) {
  return trip.driverName.isEmpty
      ? context.l10n.trips_driverPending
      : trip.driverName;
}

String vehicleNameFor(BuildContext context, TripData trip) {
  return trip.vehicleName.isEmpty
      ? context.l10n.trips_vehiclePending
      : trip.vehicleName;
}

String pickupLabelFor(BuildContext context, TripData trip) {
  return trip.pickup.isEmpty
      ? context.l10n.trips_routePointUnknown
      : trip.pickup;
}

String destinationLabelFor(BuildContext context, TripData trip) {
  return trip.destination.isEmpty
      ? context.l10n.trips_routePointUnknown
      : trip.destination;
}
