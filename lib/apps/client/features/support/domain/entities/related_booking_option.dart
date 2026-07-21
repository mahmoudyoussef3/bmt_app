/// A booking the client may attach to a support ticket.
///
/// Linking matters beyond context for the agent: the backend derives the
/// ticket's owning office from the linked booking/trip, and only a linked
/// ticket reaches that office's dashboard — an unlinked one stays with EWT
/// platform support. The client never chooses an office directly; they choose
/// the booking, and the server resolves the rest.
class RelatedBookingOption {
  const RelatedBookingOption({
    required this.bookingId,
    this.tripId,
    required this.route,
    this.tripDate,
    this.seat = '',
  });

  final String bookingId;
  final String? tripId;
  final String route;
  final DateTime? tripDate;
  final String seat;
}
