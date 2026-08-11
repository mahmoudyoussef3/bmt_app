import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/usecases/captain_requests_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_revenue_metrics_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/domain/usecases/office_profile_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/usecases/reviews_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_tickets_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';

import '../../domain/entities/dashboard_home_summary.dart';
import 'dashboard_home_state.dart';

/// The Home screen owns no data source of its own. It is a pure composition
/// root: every list below already exists in full on its own feature's screen
/// (Trips, Bookings, Fleet, …), so this cubit only re-fetches the same
/// already-registered use cases in parallel and lets [DashboardHomeSummary]
/// derive the counts the UI needs. That guarantees every number shown on Home
/// matches its corresponding module screen for the same office — there is no
/// second, capped, hand-rolled query path to drift out of sync.
class DashboardHomeCubit extends Cubit<DashboardHomeState> {
  DashboardHomeCubit({
    required GetOperationTripsUseCase getTrips,
    required GetOperationBookingsUseCase getBookings,
    required GetBookingPaymentVerificationsUseCase getPaymentVerifications,
    required GetRevenueMetricsUseCase getRevenueMetrics,
    required GetFleetWorkspaceUseCase getFleetWorkspace,
    required GetCaptainRequestsUseCase getCaptainRequests,
    required GetReviewsUseCase getReviews,
    required GetOfficeProfileUseCase getOfficeProfile,
    required GetTicketsUseCase getTickets,
    required GetSubscriptionsUseCase getSubscriptions,
  }) : _getTrips = getTrips,
       _getBookings = getBookings,
       _getPaymentVerifications = getPaymentVerifications,
       _getRevenueMetrics = getRevenueMetrics,
       _getFleetWorkspace = getFleetWorkspace,
       _getCaptainRequests = getCaptainRequests,
       _getReviews = getReviews,
       _getOfficeProfile = getOfficeProfile,
       _getTickets = getTickets,
       _getSubscriptions = getSubscriptions,
       super(const DashboardHomeLoading());

  final GetOperationTripsUseCase _getTrips;
  final GetOperationBookingsUseCase _getBookings;
  final GetBookingPaymentVerificationsUseCase _getPaymentVerifications;
  final GetRevenueMetricsUseCase _getRevenueMetrics;
  final GetFleetWorkspaceUseCase _getFleetWorkspace;
  final GetCaptainRequestsUseCase _getCaptainRequests;
  final GetReviewsUseCase _getReviews;
  final GetOfficeProfileUseCase _getOfficeProfile;
  final GetTicketsUseCase _getTickets;
  final GetSubscriptionsUseCase _getSubscriptions;

  Future<void> load() async {
    emit(const DashboardHomeLoading());
    try {
      
      final tripsFuture = _getTrips();
      final bookingsFuture = _getBookings();
      final paymentVerificationsFuture = _getPaymentVerifications();
      final revenueFuture = _getRevenueMetrics();
      final fleetFuture = _getFleetWorkspace();
      final captainRequestsFuture = _getCaptainRequests();
      final reviewsFuture = _getReviews();
      final officeProfileFuture = _getOfficeProfile();
      final ticketsFuture = _getTickets();
      final subscriptionsFuture = _getSubscriptions();

      await Future.wait([
        tripsFuture,
        bookingsFuture,
        paymentVerificationsFuture,
        revenueFuture,
        fleetFuture,
        captainRequestsFuture,
        reviewsFuture,
        officeProfileFuture,
        ticketsFuture,
        subscriptionsFuture,
      ]);

      final summary = DashboardHomeSummary(
        trips: await tripsFuture,
        bookings: await bookingsFuture,
        paymentVerifications: await paymentVerificationsFuture,
        revenue: await revenueFuture,
        fleet: await fleetFuture,
        captainRequests: await captainRequestsFuture,
        reviews: await reviewsFuture,
        officeProfile: await officeProfileFuture,
        tickets: await ticketsFuture,
        subscriptions: await subscriptionsFuture,
      );

      emit(DashboardHomeLoaded(summary));
    } catch (error) {
      emit(DashboardHomeError(error.toString()));
    }
  }
}
