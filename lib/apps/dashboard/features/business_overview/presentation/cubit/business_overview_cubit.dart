import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/usecases/captain_requests_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_refund_requests_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_revenue_metrics_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_wallet_position_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/live_ops/domain/usecases/live_ops_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/usecases/reviews_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/tickets/domain/usecases/get_tickets_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_management/domain/usecases/trip_management_usecases.dart';

import '../../domain/entities/business_overview.dart';
import 'business_overview_state.dart';

/// Composition root for the Business Overview tab.
///
/// Owns no data source, exactly like `DashboardHomeCubit`: every figure on the
/// executive page is re-derived from use cases the operational modules already
/// register, so a number here can never drift from the module it came from.
///
/// **The one thing it does differently from Home: it tolerates failure.**
/// Twelve feeds, several of them behind separate licensing features, means an
/// office on a smaller plan would meet an error screen on the page it is meant
/// to open first. So each feed is guarded individually and its absence is
/// recorded in [BusinessOverview.unavailable], which the page renders as a
/// note. The error state is reserved for the case where nothing at all
/// answered — a dead session or a dead network, where there is genuinely
/// nothing to show.
class BusinessOverviewCubit extends Cubit<BusinessOverviewState> {
  BusinessOverviewCubit({
    required GetOperationTripsUseCase getTrips,
    required GetOperationBookingsUseCase getBookings,
    required GetBookingPaymentVerificationsUseCase getPaymentVerifications,
    required GetRevenueMetricsUseCase getRevenueMetrics,
    required GetFleetWorkspaceUseCase getFleetWorkspace,
    required GetCaptainRequestsUseCase getCaptainRequests,
    required GetReviewsUseCase getReviews,
    required GetTicketsUseCase getTickets,
    required GetSubscriptionsUseCase getSubscriptions,
    required GetRefundRequestsUseCase getRefundRequests,
    required GetWalletPositionUseCase getWalletPosition,
    required GetLiveOpsSnapshotUseCase getLiveOps,
  }) : _getTrips = getTrips,
       _getBookings = getBookings,
       _getPaymentVerifications = getPaymentVerifications,
       _getRevenueMetrics = getRevenueMetrics,
       _getFleetWorkspace = getFleetWorkspace,
       _getCaptainRequests = getCaptainRequests,
       _getReviews = getReviews,
       _getTickets = getTickets,
       _getSubscriptions = getSubscriptions,
       _getRefundRequests = getRefundRequests,
       _getWalletPosition = getWalletPosition,
       _getLiveOps = getLiveOps,
       super(const BusinessOverviewLoading());

  final GetOperationTripsUseCase _getTrips;
  final GetOperationBookingsUseCase _getBookings;
  final GetBookingPaymentVerificationsUseCase _getPaymentVerifications;
  final GetRevenueMetricsUseCase _getRevenueMetrics;
  final GetFleetWorkspaceUseCase _getFleetWorkspace;
  final GetCaptainRequestsUseCase _getCaptainRequests;
  final GetReviewsUseCase _getReviews;
  final GetTicketsUseCase _getTickets;
  final GetSubscriptionsUseCase _getSubscriptions;
  final GetRefundRequestsUseCase _getRefundRequests;
  final GetWalletPositionUseCase _getWalletPosition;
  final GetLiveOpsSnapshotUseCase _getLiveOps;

  Future<void> load() => _fetch(showSpinner: true);

  /// Reloads without clearing the page. The owner keeps reading the figures
  /// they have while the new ones arrive.
  Future<void> refresh() => _fetch(showSpinner: false);

  Future<void> _fetch({required bool showSpinner}) async {
    final previous = state;
    if (showSpinner || previous is! BusinessOverviewLoaded) {
      emit(const BusinessOverviewLoading());
    } else {
      emit(BusinessOverviewLoaded(previous.overview, isRefreshing: true));
    }

    final failed = <BusinessDataSource>{};

    /// Runs [call] now — so all twelve overlap rather than queueing — with the
    /// error handler attached at creation rather than at `await`. Attaching it
    /// later would let a fast failure surface as an unhandled async error
    /// before anyone is listening.
    Future<T?> guard<T>(BusinessDataSource source, Future<T> Function() call) {
      try {
        return call().then<T?>(
          (value) => value,
          onError: (Object _) {
            failed.add(source);
            return null;
          },
        );
      } catch (_) {
        failed.add(source);
        return Future<T?>.value();
      }
    }

    final trips = guard(BusinessDataSource.trips, _getTrips.call);
    final bookings = guard(BusinessDataSource.bookings, _getBookings.call);
    final verifications = guard(
      BusinessDataSource.paymentVerifications,
      _getPaymentVerifications.call,
    );
    final revenue = guard(BusinessDataSource.revenue, _getRevenueMetrics.call);
    final fleet = guard(BusinessDataSource.fleet, _getFleetWorkspace.call);
    final captains = guard(
      BusinessDataSource.captainRequests,
      _getCaptainRequests.call,
    );
    final reviews = guard(BusinessDataSource.reviews, _getReviews.call);
    final tickets = guard(BusinessDataSource.tickets, _getTickets.call);
    final subscriptions = guard(
      BusinessDataSource.subscriptions,
      _getSubscriptions.call,
    );
    final refunds = guard(BusinessDataSource.refunds, _getRefundRequests.call);
    final wallet = guard(BusinessDataSource.wallet, _getWalletPosition.call);
    final liveOps = guard(BusinessDataSource.liveOps, _getLiveOps.call);

    final overview = BusinessOverview(
      trips: await trips ?? const [],
      bookings: await bookings ?? const [],
      paymentVerifications: await verifications ?? const [],
      revenue: await revenue,
      fleet: await fleet,
      captainRequests: await captains ?? const [],
      reviews: await reviews ?? const [],
      tickets: await tickets ?? const [],
      subscriptions: await subscriptions ?? const [],
      refundRequests: await refunds ?? const [],
      wallet: await wallet,
      liveOps: await liveOps,
      unavailable: failed,
      generatedAt: DateTime.now(),
    );

    if (isClosed) return;

    if (failed.length == BusinessDataSource.values.length) {
      emit(
        const BusinessOverviewError(
          'تعذّر تحميل بيانات المكتب. تأكد من الاتصال ثم أعد المحاولة.',
        ),
      );
      return;
    }

    emit(BusinessOverviewLoaded(overview));
  }
}
