/// A booking the client may attach to a support ticket.
///
/// Linking matters beyond context for the agent: the backend derives the
/// ticket's owning office from the linked booking/trip, which overrides the
/// office the client picked on the form. When no booking is linked the ticket
/// goes to the office the client chose directly; either way it always reaches
/// an office's dashboard.
class RelatedBookingOption {
  const RelatedBookingOption({
    required this.bookingId,
    this.tripId,
    required this.route,
    this.tripDate,
    this.seat = '',
    this.officeId,
  });

  final String bookingId;
  final String? tripId;
  final String route;
  final DateTime? tripDate;
  final String seat;

  /// The office that operated this booking's trip — the office the backend
  /// will route the ticket to once this booking is linked. Carried so the
  /// form can show that destination instead of letting the client pick one
  /// the server is going to override.
  final String? officeId;
}
