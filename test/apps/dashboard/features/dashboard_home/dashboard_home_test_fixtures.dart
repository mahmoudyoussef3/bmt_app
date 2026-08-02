import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/entities/captain_request.dart';
import 'package:bmt_app/apps/dashboard/features/dashboard_home/domain/entities/dashboard_home_summary.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RevenueMetrics;
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/entities/office_profile.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/entities/booking_payment_verification.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';

/// Hand-built fixtures shared by the dashboard_home tests. Every field maps
/// to a real entity from the feature that owns it — nothing here invents a
/// shape [DashboardHomeSummary] doesn't actually consume.
OperationTrip buildTrip({
  required String id,
  String route = 'القاهرة - الإسكندرية',
  String driver = 'أحمد علي',
  String vehicle = 'تويوتا هايس',
  OperationTripStatus status = OperationTripStatus.scheduled,
  DateTime? at,
  int capacity = 14,
  int bookedSeats = 0,
}) {
  final scheduled = at ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final seats = [
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
  ];
  return OperationTrip(
    id: id,
    routeId: '$id-route',
    route: route,
    routePoints: const [],
    driverId: '$id-driver',
    driver: driver,
    vehicleId: '$id-vehicle',
    vehicle: vehicle,
    date: '${scheduled.year}-${two(scheduled.month)}-${two(scheduled.day)}',
    departure: '${two(scheduled.hour)}:${two(scheduled.minute)}',
    arrival: '',
    status: status,
    capacity: capacity,
    seats: seats,
    passengers: const [],
    events: const [],
    notes: const [],
  );
}

OperationBooking buildBooking({
  required String id,
  BookingStatus status = BookingStatus.reserved,
  PaymentStatus paymentStatus = PaymentStatus.pending,
  DateTime? date,
  double amount = 100,
  String? passengerName,
}) {
  final d = date ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return OperationBooking(
    id: id,
    bookingNumber: id,
    clientId: '$id-client',
    passengerName: passengerName ?? 'راكب $id',
    phone: '0100000000',
    route: 'القاهرة - الإسكندرية',
    tripTime: '10:00',
    date: '${d.year}-${two(d.month)}-${two(d.day)}',
    seat: 'A1',
    paymentMethod: BookingPaymentMethod.cash,
    status: status,
    paymentStatus: paymentStatus,
    paymentAmount: amount,
    packageName: '',
    createdAt: d,
    tripDetails: BookingTripDetails.empty,
    notes: const [],
    timeline: const [],
  );
}

BookingPaymentVerification buildPaymentVerification({
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
      date: '2026-01-01',
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

const emptyRevenueMetrics = RevenueMetrics(
  todayRevenue: 0,
  weeklyRevenue: 0,
  monthlyRevenue: 0,
  activeSubscriptions: 0,
  totalBookingsRevenue: 0,
);

const emptyFleetWorkspace = FleetWorkspace(
  drivers: [],
  vehicles: [],
  assignments: [],
  documents: [],
);

CaptainRequest buildCaptainRequest({
  required String id,
  CaptainRequestStatus status = CaptainRequestStatus.pending,
}) {
  return CaptainRequest(
    id: id,
    fullName: 'كابتن $id',
    phone: '0100000000',
    status: status,
    createdAt: DateTime.now(),
  );
}

final officeProfileListed = OfficeProfile(
  id: 'office-1',
  name: 'مكتب تجريبي',
  slug: 'demo-office',
  description: 'مكتب تجريبي للاختبار',
  serviceAreas: const ['القاهرة'],
  status: 'active',
  listingStatus: 'listed',
  rating: 4.5,
  ratingsCount: 12,
  joinCode: 'JOIN123',
);

final officeProfileDraft = OfficeProfile(
  id: 'office-2',
  name: 'مكتب قيد التجهيز',
  slug: 'draft-office',
  description: '',
  serviceAreas: const [],
  status: 'active',
  listingStatus: 'draft',
  rating: 0,
  ratingsCount: 0,
  joinCode: 'JOIN456',
);

SupportTicket buildTicket({
  required String id,
  TicketStatus status = TicketStatus.submitted,
  TicketPriority priority = TicketPriority.medium,
}) {
  final now = DateTime.now();
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
    createdAt: now,
    updatedAt: now,
  );
}

UserSubscription buildSubscription({
  required String id,
  SubscriptionStatus status = SubscriptionStatus.active,
  int remainingRides = 5,
  DateTime? endDate,
}) {
  final now = DateTime.now();
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
    usedRides: 20 - remainingRides,
    remainingRides: remainingRides,
    startDate: now,
    endDate: endDate ?? now.add(const Duration(days: 10)),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

DashboardHomeSummary buildSummary({
  List<OperationTrip>? trips,
  List<OperationBooking>? bookings,
  List<BookingPaymentVerification>? paymentVerifications,
  RevenueMetrics? revenue,
  FleetWorkspace? fleet,
  List<CaptainRequest>? captainRequests,
  List<TripReviewEntry>? reviews,
  OfficeProfile? officeProfile,
  List<SupportTicket>? tickets,
  List<UserSubscription>? subscriptions,
}) {
  return DashboardHomeSummary(
    trips: trips ?? const [],
    bookings: bookings ?? const [],
    paymentVerifications: paymentVerifications ?? const [],
    revenue: revenue ?? emptyRevenueMetrics,
    fleet: fleet ?? emptyFleetWorkspace,
    captainRequests: captainRequests ?? const [],
    reviews: reviews ?? const [],
    officeProfile: officeProfile ?? officeProfileListed,
    tickets: tickets ?? const [],
    subscriptions: subscriptions ?? const [],
  );
}
