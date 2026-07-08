/// Canonical `trip_events.title` value the whole system uses to record that
/// the vehicle has arrived at a route station. Dashboard, Client, and
/// Captain all read/write this exact string so every app agrees on which
/// stations have actually been visited.
const String kStationArrivalEventTitle = 'وصول محطة';

/// Counts how many of [eventTitles] are the canonical per-station arrival
/// marker (see [kStationArrivalEventTitle]).
///
/// This is the single source of truth for "how many stations has the
/// captain reported arrived" — reused by the Dashboard live-trips
/// datasource, the Client tracking datasource, and the Captain trip
/// datasources so none of them can silently drift out of sync.
int countStationArrivalEvents(Iterable<String?> eventTitles) {
  var count = 0;
  for (final title in eventTitles) {
    if (title == kStationArrivalEventTitle) count++;
  }
  return count;
}

/// Clamps a raw arrival-event count to a valid "arrival floor": the number
/// of leading route stations authoritatively confirmed arrived by the
/// captain, never exceeding how many stations the route actually has.
///
/// Feed the result into [RouteProgressEngine.seedVisited] so GPS-inferred
/// progress can never regress below what the captain explicitly reported,
/// and so a route with fewer stations than arrival events can't overflow.
int stationArrivalFloor({
  required int arrivalEventCount,
  required int routePointCount,
}) {
  if (routePointCount <= 0) return 0;
  return arrivalEventCount.clamp(0, routePointCount);
}
