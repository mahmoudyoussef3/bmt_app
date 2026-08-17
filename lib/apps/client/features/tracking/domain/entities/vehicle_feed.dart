import 'package:bmt_app/core/tracking/link_health.dart';

import 'tracking_point.dart';

/// [TrackingLink] and [TrackingFreshness] live in `core/tracking` because the
/// dashboard's fleet board asks the same two questions about the same feed. They
/// are re-exported here so this file stays the one import a reader of the client
/// tracking feature needs.
export 'package:bmt_app/core/tracking/link_health.dart';

/// One thing happening on the vehicle feed.
///
/// Positions and link health travel on a **single** stream, deliberately. They
/// come from one channel, and modelling them as two streams would mean either two
/// channels for one trip or a datasource quietly fanning one subscription into
/// two — both of which cost a socket to express something the transport already
/// knows in one place.
sealed class VehicleFeedEvent {
  const VehicleFeedEvent();
}

class VehicleFixReported extends VehicleFeedEvent {
  const VehicleFixReported(this.fix);

  final TrackingPoint fix;
}

class VehicleLinkChanged extends VehicleFeedEvent {
  const VehicleLinkChanged(this.link);

  final TrackingLink link;
}
