import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/captain_requests/domain/usecases/captain_requests_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/finance/domain/entities/finance_entities.dart'
    show RevenueMetrics;
import 'package:bmt_app/apps/dashboard/features/finance/domain/usecases/get_revenue_metrics_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
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
///
/// **It tolerates partial failure**, the way `BusinessOverviewCubit` already
/// did. Nine independent feeds behind one `Future.wait` meant any single
/// rejection — one licensing refusal, one dropped connection — turned the
/// console's landing page into a full-screen error for an office whose business
/// was running fine. Each feed is guarded on its own now and its absence is
/// named on the page; the error state is reserved for the case where nothing at
/// all answered.
class DashboardHomeCubit extends Cubit<DashboardHomeState> {
  DashboardHomeCubit({
    required GetOperationTripsUseCase getTrips,
    required GetOperationBookingsUseCase getBookings,
    required GetRevenueMetricsUseCase getRevenueMetrics,
    required GetFleetWorkspaceUseCase getFleetWorkspace,
    required GetCaptainRequestsUseCase getCaptainRequests,
    required GetReviewsUseCase getReviews,
    required GetTicketsUseCase getTickets,
    required GetSubscriptionsUseCase getSubscriptions,
  }) : _getTrips = getTrips,
       _getBookings = getBookings,
       _getRevenueMetrics = getRevenueMetrics,
       _getFleetWorkspace = getFleetWorkspace,
       _getCaptainRequests = getCaptainRequests,
       _getReviews = getReviews,
       _getTickets = getTickets,
       _getSubscriptions = getSubscriptions,
       super(const DashboardHomeLoading());

  final GetOperationTripsUseCase _getTrips;
  final GetOperationBookingsUseCase _getBookings;
  final GetRevenueMetricsUseCase _getRevenueMetrics;
  final GetFleetWorkspaceUseCase _getFleetWorkspace;
  final GetCaptainRequestsUseCase _getCaptainRequests;
  final GetReviewsUseCase _getReviews;
  final GetTicketsUseCase _getTickets;
  final GetSubscriptionsUseCase _getSubscriptions;

  static const _emptyRevenue = RevenueMetrics(
    todayRevenue: 0,
    weeklyRevenue: 0,
    monthlyRevenue: 0,
    activeSubscriptions: 0,
    totalBookingsRevenue: 0,
  );

  static const _emptyFleet = FleetWorkspace(
    drivers: [],
    vehicles: [],
    assignments: [],
    documents: [],
  );

  Future<void> load() async {
    emit(const DashboardHomeLoading());

    final failed = <String>[];

    /// Starts [call] immediately — so all nine overlap rather than queueing —
    /// with the error handler attached at creation rather than at `await`.
    /// Attaching it later would let a fast failure surface as an unhandled
    /// async error before anyone is listening.
    Future<T?> guard<T>(String name, Future<T> Function() call) {
      try {
        return call().then<T?>(
          (value) => value,
          onError: (Object _) {
            failed.add(name);
            return null;
          },
        );
      } catch (_) {
        failed.add(name);
        return Future<T?>.value();
      }
    }

    final trips = guard('الرحلات', _getTrips.call);
    final bookings = guard('الحجوزات', _getBookings.call);
    final revenue = guard('الإيرادات', _getRevenueMetrics.call);
    final fleet = guard('الأسطول', _getFleetWorkspace.call);
    final captains = guard('طلبات الكباتن', _getCaptainRequests.call);
    final reviews = guard('التقييمات', _getReviews.call);
    final tickets = guard('الشكاوى', _getTickets.call);
    final subscriptions = guard('الاشتراكات', _getSubscriptions.call);

    final summary = DashboardHomeSummary(
      trips: await trips ?? const [],
      bookings: await bookings ?? const [],
      revenue: await revenue ?? _emptyRevenue,
      fleet: await fleet ?? _emptyFleet,
      captainRequests: await captains ?? const [],
      reviews: await reviews ?? const [],
      tickets: await tickets ?? const [],
      subscriptions: await subscriptions ?? const [],
      unavailable: failed,
    );

    if (isClosed) return;

    if (summary.isEmptyShell) {
      emit(
        const DashboardHomeError(
          'تعذّر تحميل بيانات المكتب. تأكد من الاتصال ثم أعد المحاولة.',
        ),
      );
      return;
    }

    emit(DashboardHomeLoaded(summary));
  }
}
