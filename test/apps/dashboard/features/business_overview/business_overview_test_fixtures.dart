import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/business_overview/domain/entities/business_overview.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    as finance;
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_money_model.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

/// Fixtures for the Business Overview tests.
///
/// Self-contained rather than sharing `dashboard_home_test_fixtures.dart`: this
/// suite needs to vary fields that one hard-codes — the driver id on a trip and
/// the client id on a booking, which are what the roster and the customer-base
/// derivations count on. Coupling the two suites so one could be edited only by
/// checking the other is a worse trade than a builder each.

/// A fixed clock, so "today" is the same day in every assertion. Midday, so a
/// test can put a trip an hour either side of "now" without crossing midnight.
final fixedNow = DateTime(2026, 8, 7, 12);

DateTime daysAgo(int days) => fixedNow.subtract(Duration(days: days));

String _two(int n) => n.toString().padLeft(2, '0');

OperationTrip buildTrip({
  required String id,
  String route = 'القاهرة - الإسكندرية',
  String driver = 'أحمد علي',
  String? driverId,
  String? vehicleId,
  OperationTripStatus status = OperationTripStatus.scheduled,
  DateTime? at,
  int capacity = 10,
  int bookedSeats = 0,
}) {
  final scheduled = at ?? fixedNow;
  return OperationTrip(
    id: id,
    routeId: '$id-route',
    route: route,
    routePoints: const [],
    driverId: driverId ?? '$id-driver',
    driver: driver,
    vehicleId: vehicleId ?? '$id-vehicle',
    vehicle: 'تويوتا هايس',
    date: '${scheduled.year}-${_two(scheduled.month)}-${_two(scheduled.day)}',
    departure: '${_two(scheduled.hour)}:${_two(scheduled.minute)}',
    arrival: '',
    status: status,
    capacity: capacity,
    seats: [
      for (var i = 0; i < capacity; i++)
        TripSeat(
          id: '$id-seat-$i',
          label: '$i',
          row: i,
          column: 0,
          state: i < bookedSeats
              ? TripSeatState.reserved
              : TripSeatState.available,
        ),
    ],
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

OperationBooking buildBooking({
  required String id,
  String? clientId,
  String? tripId,
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.approved,
  DateTime? createdAt,
  double amount = 100,
}) {
  final created = createdAt ?? fixedNow;
  return OperationBooking(
    id: id,
    bookingNumber: id,
    clientId: clientId ?? '$id-client',
    passengerName: 'راكب $id',
    phone: '0100000000',
    route: 'القاهرة - الإسكندرية',
    tripTime: '10:00',
    date: '${created.year}-${_two(created.month)}-${_two(created.day)}',
    seat: 'A1',
    paymentMethod: BookingPaymentMethod.cash,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: amount,
    packageName: '',
    createdAt: created,
    tripDetails: tripId == null
        ? BookingTripDetails.empty
        : BookingTripDetails(
            tripId: tripId,
            route: 'القاهرة - الإسكندرية',
            date: '2026-08-07',
            time: '10:00',
            vehicle: 'تويوتا هايس',
            driver: 'أحمد علي',
          ),
    notes: const [],
    timeline: const [],
  );
}

BookingPaymentVerification buildVerification({
  required String id,
  BookingVerificationStatus status = BookingVerificationStatus.pending,
}) {
  return BookingPaymentVerification(
    id: id,
    bookingId: '$id-booking',
    customer: const VerificationCustomer(
      name: 'عميل',
      phone: '0100000000',
      email: '',
      profileStatus: 'موثق',
    ),
    trip: const VerificationTrip(
      tripId: 'trip-1',
      route: 'القاهرة - الإسكندرية',
      date: '2026-08-07',
      time: '10:00',
      vehicle: 'تويوتا هايس',
      driver: 'أحمد علي',
    ),
    selectedSeat: 'A1',
    seatState: VerificationSeatState.temporaryReserved,
    amount: '100 ج.م',
    method: VerificationPaymentMethod.card,
    referenceNumber: 'REF$id',
    receiptTitle: 'إيصال',
    receiptMeta: '',
    status: status,
    notes: const [],
    history: const [],
  );
}

finance.RefundRequest buildRefund({
  required String id,
  finance.RefundStatus status = finance.RefundStatus.pending,
  double amount = 50,
  DateTime? date,
}) {
  return finance.RefundRequest(
    id: id,
    transactionId: '$id-txn',
    clientName: 'عميل $id',
    amount: amount,
    date: date ?? fixedNow,
    status: status,
    reason: 'إلغاء رحلة',
  );
}

SupportTicket buildTicket({
  required String id,
  TicketStatus status = TicketStatus.submitted,
  TicketPriority priority = TicketPriority.medium,
}) {
  return SupportTicket(
    id: id,
    ticketNumber: id,
    clientId: '$id-client',
    clientName: 'عميل $id',
    clientPhone: '0100000000',
    category: 'شكوى عامة',
    title: 'مشكلة $id',
    description: '',
    priority: priority,
    status: status,
    createdAt: fixedNow,
    updatedAt: fixedNow,
  );
}

UserSubscription buildSubscription({
  required String id,
  SubscriptionStatus status = SubscriptionStatus.active,
}) {
  return UserSubscription(
    id: id,
    userId: '$id-user',
    userName: 'مشترك $id',
    userPhone: '0100000000',
    packageId: 'pkg-1',
    packageName: 'باقة شهرية',
    routeId: 'route-1',
    routeLabel: 'القاهرة - الإسكندرية',
    originTripId: 'trip-1',
    type: SubscriptionType.monthly,
    price: 500,
    currency: 'ج.م',
    totalRides: 20,
    usedRides: 15,
    remainingRides: 5,
    startDate: fixedNow,
    endDate: fixedNow.add(const Duration(days: 10)),
    status: status,
    createdAt: fixedNow,
    updatedAt: fixedNow,
  );
}

CaptainRequest buildCaptainRequest({
  required String id,
  CaptainRequestStatus status = CaptainRequestStatus.pending,
}) {
  return CaptainRequest(
    id: id,
    fullName: 'كابتن $id',
    phone: '0100000000',
    status: status,
    createdAt: fixedNow,
  );
}

TripReviewEntry buildReview({
  required String id,
  int rating = 5,
  DateTime? createdAt,
}) {
  return TripReviewEntry(
    id: id,
    bookingId: '$id-booking',
    bookingNumber: id,
    clientName: 'عميل $id',
    driverName: 'أحمد علي',
    vehicleName: 'تويوتا هايس',
    routeLabel: 'القاهرة - الإسكندرية',
    driverRating: rating,
    vehicleRating: rating,
    routeRating: rating,
    comment: '',
    createdAt: createdAt ?? fixedNow,
  );
}

FleetWorkspace buildFleet({
  int activeDrivers = 0,
  int activeVehicles = 0,
  int vehiclesInMaintenance = 0,
}) {
  FleetVehicle vehicle(String id, FleetVehicleStatus status) => FleetVehicle(
    id: id,
    vehicleCode: id,
    plateNumber: id.toUpperCase(),
    vehicleType: 'ميكروباص',
    brand: 'تويوتا',
    model: 'هايس',
    manufactureYear: 2020,
    color: 'أبيض',
    capacity: 10,
    seatLayoutType: 'standard',
    imageUrl: '',
    notes: '',
    status: status,
    seatConfiguration: const SeatConfiguration(rows: 5, columns: 2, seats: []),
    licenseExpiry: '',
    insuranceExpiry: '',
    inspectionExpiry: '',
  );

  return FleetWorkspace(
    drivers: [
      for (var i = 0; i < activeDrivers; i++)
        FleetDriver(
          id: 'driver-$i',
          employeeCode: 'D$i',
          fullName: 'سائق $i',
          phone: '0100000000',
          emergencyPhone: '',
          address: '',
          nationalId: '',
          profileImageUrl: '',
          licenseNumber: '',
          licenseExpiryDate: '',
          hireDate: '',
          notes: '',
          status: FleetDriverStatus.active,
        ),
    ],
    vehicles: [
      for (var i = 0; i < activeVehicles; i++)
        vehicle('vehicle-$i', FleetVehicleStatus.active),
      for (var i = 0; i < vehiclesInMaintenance; i++)
        vehicle('maint-$i', FleetVehicleStatus.maintenance),
    ],
    assignments: const [],
    documents: const [],
  );
}

const emptyRevenue = finance.RevenueMetrics(
  todayRevenue: 0,
  weeklyRevenue: 0,
  monthlyRevenue: 0,
  activeSubscriptions: 0,
  totalBookingsRevenue: 0,
);

WalletFinancePosition buildWallet({
  double liability = 0,
  List<WalletMovement> movements = const [],
  List<SettledRefund> refunds = const [],
}) {
  return WalletFinancePosition(
    currentLiability: liability,
    movements: movements,
    refunds: refunds,
  );
}

BusinessOverview buildOverview({
  List<OperationTrip>? trips,
  List<OperationBooking>? bookings,
  List<BookingPaymentVerification>? paymentVerifications,
  List<SupportTicket>? tickets,
  List<TripReviewEntry>? reviews,
  List<UserSubscription>? subscriptions,
  List<CaptainRequest>? captainRequests,
  List<finance.RefundRequest>? refundRequests,
  FleetWorkspace? fleet,
  finance.RevenueMetrics? revenue,
  WalletFinancePosition? wallet,
  Set<BusinessDataSource>? unavailable,
  DateTime? generatedAt,
}) {
  return BusinessOverview(
    trips: trips ?? const [],
    bookings: bookings ?? const [],
    paymentVerifications: paymentVerifications ?? const [],
    tickets: tickets ?? const [],
    reviews: reviews ?? const [],
    subscriptions: subscriptions ?? const [],
    captainRequests: captainRequests ?? const [],
    refundRequests: refundRequests ?? const [],
    fleet: fleet ?? buildFleet(),
    revenue: revenue ?? emptyRevenue,
    wallet: wallet ?? buildWallet(),
    unavailable: unavailable ?? const {},
    generatedAt: generatedAt ?? fixedNow,
  );
}
