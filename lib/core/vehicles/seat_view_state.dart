/// The **state** half of the seat system — what is true about a seat right
/// now, as opposed to where it sits in the cabin.
///
/// `seat_layout_blueprint.dart` says where a seat is; this says how it reads.
/// The two are deliberately independent: the same Hiace cabin is drawn with
/// booking states in the Client App and with operational states in the Owner
/// Dashboard, and neither changes the layout.
///
/// These are **presentation** states, not domain states. Each app keeps its own
/// domain enum (`TripSeatState`, `SeatAvailability`, …) and maps onto this at
/// the edge, which is what lets one renderer serve all of them without ever
/// learning a booking rule.
///
/// Pure Dart on purpose, so a mapper can live in a cubit or an entity without
/// dragging Flutter in.
library;

enum SeatViewState {
  /// Free and offerable. Reads as an invitation.
  available,

  /// Chosen in the current interaction. The one loud state on the map.
  selected,

  /// Taken by someone — sold, paid, boarded. Not offerable, but real.
  occupied,

  /// Held but not settled: a lock, a pending payment, an unconfirmed booking.
  /// Distinct from [occupied] because the hold can still lapse.
  reserved,

  /// Withdrawn from sale — blocked by the operator, out of service, or simply
  /// not offerable in this context. Clearly unavailable without reading as an
  /// error.
  disabled,
}
