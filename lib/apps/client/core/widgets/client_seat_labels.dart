import 'package:flutter/widgets.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// The Client App's words for the shared seat map.
///
/// [VehicleSeatLayout] lives in `core/` and defaults to Arabic so the two
/// Arabic-only apps can use it without a localization delegate in the tree.
/// The Client App is bilingual, so it passes its own strings here instead.
///
/// Riders only ever see three of the five states — a seat is free, theirs, or
/// somebody's — so the three they cannot reach reuse the "unavailable" wording
/// rather than inventing copy for states the booking flow never emits.
VehicleSeatLabels clientSeatLabels(BuildContext context) {
  final l10n = context.l10n;
  return VehicleSeatLabels(
    front: l10n.seatSelection_frontOfVehicle,
    rear: l10n.seatSelection_cabinRear,
    driver: l10n.booking_driver,
    door: l10n.seatSelection_cabinDoor,
    available: l10n.booking_available,
    selected: l10n.seatSelection_seatStatusSelected,
    occupied: l10n.booking_unavailable,
    reserved: l10n.booking_unavailable,
    disabled: l10n.booking_unavailable,
    overflow: l10n.booking_additionalVehicleSeats,
  );
}
