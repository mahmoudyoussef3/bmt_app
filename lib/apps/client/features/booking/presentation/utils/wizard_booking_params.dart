import '../../domain/entities/booking_option.dart';
import '../../domain/entities/booking_wizard_session.dart';

/// The wizard session is the rider's answers; the booking RPCs speak `p_*`
/// parameters. Translating between the two lives here alone, so the create and
/// the settle-payment calls can never describe the same booking differently.
///
/// The passenger's own name and phone are deliberately absent: the datasource
/// already stamps the caller's identity onto every booking RPC.
Map<String, dynamic> wizardConfirmBookingParams(BookingWizardSession session) {
  final pickup = session.pickupStop;
  final dropoff = session.dropoffStop;
  final trip = session.selectedTrip;

  return {
    'p_trip_id': trip?.id ?? '',
    'p_seat_id': session.selectedSeatId ?? '',
    'p_seat_label': session.selectedSeatLabel ?? '',
    'p_pricing_id': null,
    'p_pickup_point_id': _pointId(pickup),
    'p_dropoff_point_id': _pointId(dropoff),
    'p_route': '${pickup?.name ?? ''} → ${dropoff?.name ?? ''}',
    'p_trip_time': trip?.departureTime ?? '',
    'p_trip_date': trip?.tripDate,
    'p_payment_amount': session.totalPrice.round(),
    'p_pickup_point_name': pickup?.name ?? '',
    'p_dropoff_point_name': dropoff?.name ?? '',
    'p_package_id': session.selectedPackage?.id,
    'p_plan_start_date': session.packageStartDate?.toIso8601String().split(
      'T',
    )[0],
    ..._paymentParams(session),
  };
}

/// Settles payment on a booking the wizard already created — the path a rider
/// takes when a first attempt failed at the gateway.
Map<String, dynamic> wizardUpdatePaymentParams(BookingWizardSession session) =>
    {'p_booking_id': session.bookingId, ..._paymentParams(session)};

Map<String, dynamic> _paymentParams(BookingWizardSession session) => {
  'p_payment_method': session.paymentMethod ?? 'instapay',
  'p_receipt_url': session.receiptUrl,
  'p_payment_reference': session.paymentReference,
  'p_payer_phone': session.payerPhone,
};

/// A stop the rider picked off a map carries no persisted id.
String? _pointId(RoutePointData? point) =>
    point?.id.isEmpty == true ? null : point?.id;
