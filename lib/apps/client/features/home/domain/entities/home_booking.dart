import 'package:bmt_app/apps/client/features/home/domain/entities/home_booking_status.dart';

/// A seat the rider has already committed to, as Home shows it back to them:
/// which departure it is on, where it stands, and what they paid.
///
/// Home surfaces these so a booking is never invisible — a rider who has just
/// paid must be able to see the trip and its status, not wonder whether the
/// booking went through.
class HomeBookingData {
  const HomeBookingData({
    required this.id,
    required this.tripId,
    required this.bookingNumber,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.tripDate,
    required this.departureTime,
    required this.seatLabel,
    required this.fare,
  });

  final String id;

  /// The departure this booking sits on; links the booking to the trip in the
  /// departures feed so that trip can be marked as already booked.
  final String tripId;

  /// Operator-facing reference (e.g. `BK-1A2B3C4D`); empty when unset.
  final String bookingNumber;

  final HomeBookingStatus status;
  final String pickup;
  final String destination;

  /// ISO `yyyy-MM-dd`; empty when the booking carries no date.
  final String tripDate;

  /// Raw `HH:mm:ss`; empty when the trip has no time set.
  final String departureTime;

  /// Seat label as printed on the manifest (e.g. `A3`); empty when unassigned.
  /// A booking holds exactly one seat — a rider taking two seats holds two
  /// bookings.
  final String seatLabel;

  /// Preformatted amount paid (e.g. `EGP 100`); empty when not recorded.
  final String fare;

  String get routeLabel => '$pickup → $destination';
}
