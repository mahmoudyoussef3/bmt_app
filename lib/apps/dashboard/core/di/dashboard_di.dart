import '../../../../core/network/network_di.dart';
import '../session/dashboard_session.dart';
import '../../features/auth/data/datasources/dashboard_auth_datasource.dart';
import '../../features/auth/presentation/cubit/dashboard_auth_cubit.dart';
import '../../features/captain_requests/data/datasources/supabase_captain_requests_datasource.dart';
import '../../features/captain_requests/data/repositories/captain_requests_repository_impl.dart';
import '../../features/captain_requests/domain/repositories/captain_requests_repository.dart';
import '../../features/captain_requests/domain/usecases/captain_requests_usecases.dart';
import '../../features/captain_requests/presentation/cubit/captain_requests_cubit.dart';
import '../../features/notifications/data/datasources/supabase_notifications_dispatch_datasource.dart';
import '../../features/notifications/data/datasources/supabase_operational_alerts_datasource.dart';
import '../../features/notifications/data/repositories/notifications_dispatch_repository_impl.dart';
import '../../features/notifications/data/repositories/operational_alerts_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_dispatch_repository.dart';
import '../../features/notifications/domain/repositories/operational_alerts_repository.dart';
import '../../features/notifications/domain/usecases/mark_alert_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_alerts_read_usecase.dart';
import '../../features/notifications/domain/usecases/send_notification_usecase.dart';
import '../../features/notifications/domain/usecases/watch_operational_alerts_usecase.dart';
import '../../features/notifications/domain/usecases/watch_unread_alerts_count_usecase.dart';
import '../../features/notifications/presentation/cubit/notifications_dispatch_cubit.dart';
import '../../features/notifications/presentation/cubit/operational_alerts_badge_cubit.dart';
import '../../features/notifications/presentation/cubit/operational_alerts_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/data/datasources/bookings_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/users/data/datasources/users_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/repositories/users_repository.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/get_current_user_role_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/get_users_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/usecases/update_user_role_usecase.dart';
import 'package:bmt_app/apps/dashboard/features/users/presentation/cubit/users_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/bookings/data/datasources/supabase_bookings_datasource.dart';
import '../../features/bookings/data/repositories/bookings_repository_impl.dart';
import '../../features/bookings/domain/repositories/bookings_repository.dart';
import '../../features/bookings/domain/usecases/approve_booking_usecase.dart';
import '../../features/bookings/domain/usecases/bulk_approve_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/bulk_reject_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/reassign_booking_usecase.dart';
import '../../features/bookings/domain/usecases/reject_booking_usecase.dart';
import '../../features/bookings/domain/usecases/request_reupload_usecase.dart';
import '../../features/bookings/domain/usecases/watch_bookings_usecase.dart';
import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/office_profile/data/datasources/office_profile_datasource.dart';
import '../../features/office_profile/data/datasources/supabase_office_profile_datasource.dart';
import '../../features/office_profile/data/repositories/office_profile_repository_impl.dart';
import '../../features/office_profile/domain/repositories/office_profile_repository.dart';
import '../../features/office_profile/domain/usecases/office_profile_usecases.dart';
import '../../features/office_profile/presentation/cubit/office_profile_cubit.dart';
import '../../features/platform_admin/data/datasources/platform_admin_datasource.dart';
import '../../features/platform_admin/data/datasources/supabase_platform_admin_datasource.dart';
import '../../features/platform_admin/data/repositories/platform_admin_repository_impl.dart';
import '../../features/platform_admin/domain/repositories/platform_admin_repository.dart';
import '../../features/platform_admin/domain/usecases/platform_admin_usecases.dart';
import '../../features/platform_admin/presentation/cubit/platform_admin_cubit.dart';
import '../../features/referrals/data/datasources/referral_datasource.dart';
import '../../features/referrals/data/datasources/supabase_referral_datasource.dart';
import '../../features/referrals/data/repositories/referral_repository_impl.dart';
import '../../features/referrals/domain/repositories/referral_repository.dart';
import '../../features/referrals/domain/usecases/referral_usecases.dart';
import '../../features/referrals/presentation/cubit/referral_cubit.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/trips/trip_management/domain/usecases/trip_management_usecases.dart';

// ── Fleet Sub-modules ────────────────────────────────────────────────
import '../../features/fleet/fleet_drivers/data/repositories/fleet_drivers_repository_impl.dart';
import '../../features/fleet/fleet_drivers/domain/repositories/fleet_drivers_repository.dart';
import '../../features/fleet/fleet_drivers/domain/usecases/fleet_drivers_usecases.dart';
import '../../features/fleet/fleet_drivers/presentation/cubit/fleet_drivers_cubit.dart';

import '../../features/fleet/fleet_vehicles/data/repositories/fleet_vehicles_repository_impl.dart';
import '../../features/fleet/fleet_vehicles/domain/repositories/fleet_vehicles_repository.dart';
import '../../features/fleet/fleet_vehicles/domain/usecases/fleet_vehicles_usecases.dart';
import '../../features/fleet/fleet_vehicles/presentation/cubit/fleet_vehicles_cubit.dart';

import '../../features/fleet/fleet_assignments/data/repositories/fleet_assignments_repository_impl.dart';
import '../../features/fleet/fleet_assignments/domain/repositories/fleet_assignments_repository.dart';
import '../../features/fleet/fleet_assignments/domain/usecases/fleet_assignments_usecases.dart';
import '../../features/fleet/fleet_assignments/presentation/cubit/fleet_assignments_cubit.dart';

import '../../features/fleet/fleet_documents/data/repositories/fleet_documents_repository_impl.dart';
import '../../features/fleet/fleet_documents/domain/repositories/fleet_documents_repository.dart';
import '../../features/fleet/fleet_documents/domain/usecases/fleet_documents_usecases.dart';
import '../../features/fleet/fleet_documents/presentation/cubit/fleet_documents_cubit.dart';

import '../../features/fleet/data/datasources/fleet_datasource.dart';
import '../../features/fleet/data/datasources/supabase_fleet_datasource.dart';
import '../../features/fleet/data/repositories/fleet_repository_impl.dart';
import '../../features/fleet/domain/repositories/fleet_repository.dart';
import '../../features/fleet/domain/usecases/fleet_usecases.dart';
import '../../features/fleet/overview/presentation/cubit/fleet_overview_cubit.dart';
import '../../features/payment_verification/data/datasources/booking_payment_verification_datasource.dart';
import '../../features/payment_verification/data/datasources/supabase_booking_payment_verification_datasource.dart';
import '../../features/payment_verification/data/repositories/booking_payment_verification_repository_impl.dart';
import '../../features/payment_verification/domain/repositories/booking_payment_verification_repository.dart';
import '../../features/payment_verification/domain/usecases/add_booking_payment_note_usecase.dart';
import '../../features/payment_verification/domain/usecases/approve_booking_payment_usecase.dart';
import '../../features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import '../../features/payment_verification/domain/usecases/reject_booking_payment_usecase.dart';
import '../../features/payment_verification/domain/usecases/request_booking_payment_review_usecase.dart';
import '../../features/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import '../../features/routes/data/datasources/routes_datasource.dart';
import '../../features/routes/data/datasources/supabase_routes_datasource.dart';
import '../../features/routes/data/repositories/routes_repository_impl.dart';
import '../../features/routes/domain/repositories/routes_repository.dart';
import '../../features/routes/domain/usecases/add_route_station_usecase.dart';
import '../../features/routes/domain/usecases/create_route_usecase.dart';
import '../../features/routes/domain/usecases/delete_route_usecase.dart';
import '../../features/routes/domain/usecases/delete_route_station_usecase.dart';
import '../../features/routes/domain/usecases/get_operation_routes_usecase.dart';
import '../../features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import '../../features/routes/domain/usecases/update_route_station_usecase.dart';
import '../../features/routes/domain/usecases/update_route_usecase.dart';
import '../../features/routes/domain/usecases/search_places_usecase.dart';
import '../../features/routes/domain/usecases/get_route_geometry_usecase.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import 'package:bmt_app/core/geo/geo_service.dart';
import 'package:bmt_app/core/geo/ors_geo_service.dart';
import '../../features/subscriptions/data/datasources/subscriptions_datasource.dart';
import '../../features/subscriptions/data/datasources/supabase_subscriptions_datasource.dart';
import '../../features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscriptions_repository.dart';
import '../../features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/confirm_payment_usecase.dart';
import '../../features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecases/mark_subscription_ride_used_usecase.dart';
import '../../features/subscriptions/domain/usecases/renew_subscription_usecase.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/subscriptions/plans/data/datasources/subscription_plans_datasource.dart';
import '../../features/subscriptions/plans/data/repositories/subscription_plans_repository_impl.dart';
import '../../features/subscriptions/plans/domain/repositories/subscription_plans_repository.dart';
import '../../features/subscriptions/plans/domain/usecases/subscription_plans_usecases.dart';
import '../../features/subscriptions/plans/presentation/cubit/subscription_plans_cubit.dart';
import '../../features/trips/trips_di.dart';
// Mock vehicles removed
import '../../features/tickets/data/datasources/supabase_tickets_datasource.dart';
import '../../features/tickets/data/repositories/tickets_repository_impl.dart';
import '../../features/tickets/domain/repositories/tickets_repository.dart';
import '../../features/tickets/domain/usecases/close_ticket_usecase.dart';
import '../../features/tickets/domain/usecases/get_tickets_usecase.dart';
import '../../features/tickets/domain/usecases/update_ticket_status_usecase.dart';
import '../../features/tickets/domain/usecases/save_internal_note_usecase.dart';
import '../../features/tickets/domain/usecases/mark_customer_contacted_usecase.dart';
import '../../features/tickets/domain/usecases/assign_agent_usecase.dart';
import '../../features/tickets/domain/usecases/get_ticket_attachments_usecase.dart';
import '../../features/tickets/presentation/cubit/tickets_cubit.dart';
import '../../features/finance/data/repositories/finance_repository_impl.dart';
import '../../features/finance/domain/repositories/finance_repository.dart';
import '../../features/finance/domain/usecases/cancel_subscription_usecase.dart';
import '../../features/finance/domain/usecases/get_payments_usecase.dart';
import '../../features/finance/domain/usecases/get_receipt_reviews_usecase.dart';
import '../../features/finance/domain/usecases/get_refund_requests_usecase.dart';
import '../../features/finance/domain/usecases/get_revenue_metrics_usecase.dart';
import '../../features/finance/domain/usecases/get_revenue_trend_usecase.dart';
import '../../features/finance/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/finance/domain/usecases/process_refund_usecase.dart';
import '../../features/finance/domain/usecases/review_receipt_usecase.dart';
import '../../features/finance/data/datasources/finance_datasource.dart';
import '../../features/finance/data/datasources/supabase_finance_datasource.dart';
import '../../features/finance/presentation/cubit/finance_cubit.dart';
import '../../features/owner_overview/data/datasources/owner_overview_datasource.dart';
import '../../features/owner_overview/data/repositories/owner_overview_repository_impl.dart';
import '../../features/owner_overview/domain/repositories/owner_overview_repository.dart';
import '../../features/owner_overview/domain/usecases/get_owner_overview_usecase.dart';
import '../../features/owner_overview/presentation/cubit/owner_overview_cubit.dart';
import '../../features/reports/data/datasources/reports_datasource.dart';
import '../../features/reports/data/datasources/supabase_reports_datasource.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/domain/usecases/export_report_usecase.dart';
import '../../features/reports/domain/usecases/get_available_drivers_usecase.dart';
import '../../features/reports/domain/usecases/get_available_packages_usecase.dart';
import '../../features/reports/domain/usecases/get_available_routes_usecase.dart';
import '../../features/reports/domain/usecases/get_available_vehicles_usecase.dart';
import '../../features/reports/domain/usecases/get_report_data_usecase.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/reviews/data/datasources/reviews_datasource.dart';
import '../../features/reviews/data/datasources/supabase_reviews_datasource.dart';
import '../../features/reviews/data/repositories/reviews_repository_impl.dart';
import '../../features/reviews/domain/repositories/reviews_repository.dart';
import '../../features/reviews/domain/usecases/reviews_usecases.dart';
import '../../features/reviews/presentation/cubit/reviews_cubit.dart';
import '../theme/dashboard_theme_cubit.dart';
import '../theme/dashboard_theme_repository.dart';

final GetIt dashboardDi = GetIt.instance;

void registerDashboardDependencies() {
  if (!dashboardDi.isRegistered<SupabaseClient>()) {
    dashboardDi.registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    );
  }

  // Registered first: office-scoped datasources are lazy singletons built before
  // anyone signs in, so they hold this and read the office id per query.
  if (!dashboardDi.isRegistered<DashboardSession>()) {
    dashboardDi.registerLazySingleton<DashboardSession>(DashboardSession.new);
  }

  registerNetworkDependencies(dashboardDi);
  if (!dashboardDi.isRegistered<DashboardThemeRepository>()) {
    dashboardDi.registerLazySingleton<DashboardThemeRepository>(
      DashboardThemeRepository.new,
    );
  }

  if (!dashboardDi.isRegistered<DashboardThemeCubit>()) {
    dashboardDi.registerFactory(
      () => DashboardThemeCubit(dashboardDi<DashboardThemeRepository>()),
    );
  }

  // DashboardHomeCubit owns no data source of its own: it is a pure
  // composition root over use cases every sibling feature already registers
  // (below and via `registerTripsDependencies`, called later in this
  // function). Registered as a factory, so resolution is deferred until the
  // Home route actually mounts — by which point every dependency here is
  // registered regardless of declaration order.
  if (!dashboardDi.isRegistered<DashboardHomeCubit>()) {
    dashboardDi.registerFactory(
      () => DashboardHomeCubit(
        getTrips: dashboardDi<GetOperationTripsUseCase>(),
        getBookings: dashboardDi<GetOperationBookingsUseCase>(),
        getPaymentVerifications:
            dashboardDi<GetBookingPaymentVerificationsUseCase>(),
        getRevenueMetrics: dashboardDi<GetRevenueMetricsUseCase>(),
        getFleetWorkspace: dashboardDi<GetFleetWorkspaceUseCase>(),
        getCaptainRequests: dashboardDi<GetCaptainRequestsUseCase>(),
        getReviews: dashboardDi<GetReviewsUseCase>(),
        getOfficeProfile: dashboardDi<GetOfficeProfileUseCase>(),
        getTickets: dashboardDi<GetTicketsUseCase>(),
        getSubscriptions: dashboardDi<GetSubscriptionsUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<FleetDatasource>()) {
    dashboardDi.registerLazySingleton<FleetDatasource>(
      () => SupabaseFleetDatasource(
        dashboardDi<SupabaseClient>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<FleetRepository>()) {
    dashboardDi.registerLazySingleton<FleetRepository>(
      () => FleetRepositoryImpl(dashboardDi<FleetDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetFleetWorkspaceUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFleetWorkspaceUseCase(dashboardDi<FleetRepository>()),
    );
  }

  // ── Fleet Drivers Module ──────────────────────────────────────────────
  if (!dashboardDi.isRegistered<FleetDriversRepository>()) {
    dashboardDi.registerLazySingleton<FleetDriversRepository>(
      () => FleetDriversRepositoryImpl(dashboardDi<FleetDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetFleetDriversUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFleetDriversUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<CreateFleetDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetDriverUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateFleetDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetDriverUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateFleetDriverStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          UpdateFleetDriverStatusUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<DeleteFleetDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetDriverUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UploadDriverFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UploadDriverFileUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<DeleteDriverFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteDriverFileUseCase(dashboardDi<FleetDriversRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<FleetDriversCubit>()) {
    dashboardDi.registerFactory(
      () => FleetDriversCubit(
        getDrivers: dashboardDi<GetFleetDriversUseCase>(),
        createDriver: dashboardDi<CreateFleetDriverUseCase>(),
        updateDriver: dashboardDi<UpdateFleetDriverUseCase>(),
        updateDriverStatus: dashboardDi<UpdateFleetDriverStatusUseCase>(),
        deleteDriver: dashboardDi<DeleteFleetDriverUseCase>(),
        uploadFile: dashboardDi<UploadDriverFileUseCase>(),
        deleteFile: dashboardDi<DeleteDriverFileUseCase>(),
      ),
    );
  }

  // ── Fleet Vehicles Module ─────────────────────────────────────────────
  if (!dashboardDi.isRegistered<FleetVehiclesRepository>()) {
    dashboardDi.registerLazySingleton<FleetVehiclesRepository>(
      () => FleetVehiclesRepositoryImpl(dashboardDi<FleetDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetFleetVehiclesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFleetVehiclesUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<CreateFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetVehicleUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetVehicleUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateFleetVehicleStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetVehicleStatusUseCase(
        dashboardDi<FleetVehiclesRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<DeleteFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetVehicleUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UploadVehicleFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UploadVehicleFileUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<DeleteVehicleFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteVehicleFileUseCase(dashboardDi<FleetVehiclesRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<FleetVehiclesCubit>()) {
    dashboardDi.registerFactory(
      () => FleetVehiclesCubit(
        getVehicles: dashboardDi<GetFleetVehiclesUseCase>(),
        createVehicle: dashboardDi<CreateFleetVehicleUseCase>(),
        updateVehicle: dashboardDi<UpdateFleetVehicleUseCase>(),
        updateVehicleStatus: dashboardDi<UpdateFleetVehicleStatusUseCase>(),
        deleteVehicle: dashboardDi<DeleteFleetVehicleUseCase>(),
        uploadFile: dashboardDi<UploadVehicleFileUseCase>(),
        deleteFile: dashboardDi<DeleteVehicleFileUseCase>(),
      ),
    );
  }

  // ── Fleet Assignments Module ──────────────────────────────────────────
  if (!dashboardDi.isRegistered<FleetAssignmentsRepository>()) {
    dashboardDi.registerLazySingleton<FleetAssignmentsRepository>(
      () => FleetAssignmentsRepositoryImpl(dashboardDi<FleetDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetFleetAssignmentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          GetFleetAssignmentsUseCase(dashboardDi<FleetAssignmentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetAssignmentDriversUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAssignmentDriversUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<GetAssignmentVehiclesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAssignmentVehiclesUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<AssignFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          AssignFleetVehicleUseCase(dashboardDi<FleetAssignmentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<ReassignFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReassignFleetVehicleUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<RemoveFleetAssignmentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RemoveFleetAssignmentUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<DeleteFleetAssignmentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetAssignmentUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<FleetAssignmentsCubit>()) {
    dashboardDi.registerFactory(
      () => FleetAssignmentsCubit(
        getAssignments: dashboardDi<GetFleetAssignmentsUseCase>(),
        getDrivers: dashboardDi<GetAssignmentDriversUseCase>(),
        getVehicles: dashboardDi<GetAssignmentVehiclesUseCase>(),
        assignVehicle: dashboardDi<AssignFleetVehicleUseCase>(),
        reassignVehicle: dashboardDi<ReassignFleetVehicleUseCase>(),
        removeAssignment: dashboardDi<RemoveFleetAssignmentUseCase>(),
        deleteAssignment: dashboardDi<DeleteFleetAssignmentUseCase>(),
      ),
    );
  }

  // ── Fleet Documents Module ────────────────────────────────────────────
  if (!dashboardDi.isRegistered<FleetDocumentsRepository>()) {
    dashboardDi.registerLazySingleton<FleetDocumentsRepository>(
      () => FleetDocumentsRepositoryImpl(dashboardDi<FleetDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetFleetDocumentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFleetDocumentsUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<CreateFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetDocumentUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetDocumentUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<DeleteFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetDocumentUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UploadDocumentFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UploadDocumentFileUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<DeleteDocumentFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteDocumentFileUseCase(dashboardDi<FleetDocumentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<FleetDocumentsCubit>()) {
    dashboardDi.registerFactory(
      () => FleetDocumentsCubit(
        getDocuments: dashboardDi<GetFleetDocumentsUseCase>(),
        createDocument: dashboardDi<CreateFleetDocumentUseCase>(),
        updateDocument: dashboardDi<UpdateFleetDocumentUseCase>(),
        deleteDocument: dashboardDi<DeleteFleetDocumentUseCase>(),
        uploadFile: dashboardDi<UploadDocumentFileUseCase>(),
        deleteFile: dashboardDi<DeleteDocumentFileUseCase>(),
      ),
    );
  }

  // ── Fleet Overview Cubit ─────────────────────────────────────────────
  if (!dashboardDi.isRegistered<FleetOverviewCubit>()) {
    dashboardDi.registerFactory(
      () => FleetOverviewCubit(
        getWorkspace: dashboardDi<GetFleetWorkspaceUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<BookingsDatasource>()) {
    dashboardDi.registerLazySingleton<BookingsDatasource>(
      () => SupabaseBookingsDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<BookingsRepository>()) {
    dashboardDi.registerLazySingleton<BookingsRepository>(
      () => BookingsRepositoryImpl(dashboardDi<BookingsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetOperationBookingsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetOperationBookingsUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<BulkApproveBookingsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => BulkApproveBookingsUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<BulkRejectBookingsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => BulkRejectBookingsUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ApproveBookingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ApproveBookingUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RejectBookingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RejectBookingUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RequestReuploadUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RequestReuploadUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<WatchBookingsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => WatchBookingsUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<BookingsCubit>()) {
    dashboardDi.registerFactory(
      () => BookingsCubit(
        getBookings: dashboardDi<GetOperationBookingsUseCase>(),
        approveBooking: dashboardDi<ApproveBookingUseCase>(),
        rejectBooking: dashboardDi<RejectBookingUseCase>(),
        requestReupload: dashboardDi<RequestReuploadUseCase>(),
        bulkApprove: dashboardDi<BulkApproveBookingsUseCase>(),
        bulkReject: dashboardDi<BulkRejectBookingsUseCase>(),
        watchBookings: dashboardDi<WatchBookingsUseCase>(),
        reassignBooking: dashboardDi<ReassignBookingUseCase>(),
        getReassignmentTargets: dashboardDi<GetReassignmentTargetsUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<ReassignBookingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReassignBookingUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetReassignmentTargetsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReassignmentTargetsUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  // Mock drivers registrations removed

  // Mock assignments registrations removed

  if (!dashboardDi.isRegistered<BookingPaymentVerificationDatasource>()) {
    dashboardDi.registerLazySingleton<BookingPaymentVerificationDatasource>(
      () => SupabaseBookingPaymentVerificationDatasource(
        dashboardDi<SupabaseClient>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<BookingPaymentVerificationRepository>()) {
    dashboardDi.registerLazySingleton<BookingPaymentVerificationRepository>(
      () => BookingPaymentVerificationRepositoryImpl(
        dashboardDi<BookingPaymentVerificationDatasource>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<GetBookingPaymentVerificationsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetBookingPaymentVerificationsUseCase(
        dashboardDi<BookingPaymentVerificationRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<ApproveBookingPaymentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ApproveBookingPaymentUseCase(
        dashboardDi<BookingPaymentVerificationRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<RejectBookingPaymentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RejectBookingPaymentUseCase(
        dashboardDi<BookingPaymentVerificationRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<RequestBookingPaymentReviewUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RequestBookingPaymentReviewUseCase(
        dashboardDi<BookingPaymentVerificationRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<AddBookingPaymentNoteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AddBookingPaymentNoteUseCase(
        dashboardDi<BookingPaymentVerificationRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<PaymentVerificationCubit>()) {
    dashboardDi.registerFactory(
      () => PaymentVerificationCubit(
        getQueue: dashboardDi<GetBookingPaymentVerificationsUseCase>(),
        approve: dashboardDi<ApproveBookingPaymentUseCase>(),
        reject: dashboardDi<RejectBookingPaymentUseCase>(),
        requestReview: dashboardDi<RequestBookingPaymentReviewUseCase>(),
        addNote: dashboardDi<AddBookingPaymentNoteUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<RoutesDatasource>()) {
    dashboardDi.registerLazySingleton<RoutesDatasource>(
      () => SupabaseRoutesDatasource(
        dashboardDi<SupabaseClient>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<RoutesRepository>()) {
    dashboardDi.registerLazySingleton<RoutesRepository>(
      () => RoutesRepositoryImpl(dashboardDi<RoutesDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetOperationRoutesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetOperationRoutesUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateRouteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateRouteUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateRouteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateRouteUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DeleteRouteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteRouteUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AddRouteStationUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AddRouteStationUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateRouteStationUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateRouteStationUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DeleteRouteStationUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteRouteStationUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ReorderRouteStationsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReorderRouteStationsUseCase(dashboardDi<RoutesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GeoService>()) {
    dashboardDi.registerLazySingleton<GeoService>(() => OrsGeoService());
  }

  if (!dashboardDi.isRegistered<SearchPlacesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SearchPlacesUseCase(dashboardDi<GeoService>()),
    );
  }

  if (!dashboardDi.isRegistered<GetRouteGeometryUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetRouteGeometryUseCase(dashboardDi<GeoService>()),
    );
  }

  if (!dashboardDi.isRegistered<RoutesCubit>()) {
    dashboardDi.registerFactory(
      () => RoutesCubit(
        getRoutes: dashboardDi<GetOperationRoutesUseCase>(),
        createRoute: dashboardDi<CreateRouteUseCase>(),
        updateRoute: dashboardDi<UpdateRouteUseCase>(),
        deleteRoute: dashboardDi<DeleteRouteUseCase>(),
        addStation: dashboardDi<AddRouteStationUseCase>(),
        updateStation: dashboardDi<UpdateRouteStationUseCase>(),
        deleteStation: dashboardDi<DeleteRouteStationUseCase>(),
        reorderStations: dashboardDi<ReorderRouteStationsUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<SubscriptionsDatasource>()) {
    dashboardDi.registerLazySingleton<SubscriptionsDatasource>(
      () => SupabaseSubscriptionsDatasource(
        dashboardDi<SupabaseClient>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<SubscriptionsRepository>()) {
    dashboardDi.registerLazySingleton<SubscriptionsRepository>(
      () => SubscriptionsRepositoryImpl(dashboardDi<SubscriptionsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetSubscriptionsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetSubscriptionsUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetSubscriptionDetailsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          GetSubscriptionDetailsUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateSubscriptionUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateSubscriptionUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CancelSubscriptionUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CancelSubscriptionUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RenewSubscriptionUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RenewSubscriptionUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<MarkSubscriptionRideUsedUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => MarkSubscriptionRideUsedUseCase(
        dashboardDi<SubscriptionsRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<GetSubscriptionCreationOptionsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetSubscriptionCreationOptionsUseCase(
        dashboardDi<SubscriptionsRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<ConfirmPaymentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ConfirmPaymentUseCase(dashboardDi<SubscriptionsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<SubscriptionsCubit>()) {
    dashboardDi.registerFactory(
      () => SubscriptionsCubit(
        getSubscriptions: dashboardDi<GetSubscriptionsUseCase>(),
        getDetails: dashboardDi<GetSubscriptionDetailsUseCase>(),
        createSubscription: dashboardDi<CreateSubscriptionUseCase>(),
        cancelSubscription: dashboardDi<CancelSubscriptionUseCase>(),
        renewSubscription: dashboardDi<RenewSubscriptionUseCase>(),
        markRideUsed: dashboardDi<MarkSubscriptionRideUsedUseCase>(),
        confirmPayment: dashboardDi<ConfirmPaymentUseCase>(),
        getCreationOptions:
            dashboardDi<GetSubscriptionCreationOptionsUseCase>(),
      ),
    );
  }

  // Subscription Plans (packages) CRUD
  if (!dashboardDi.isRegistered<SubscriptionPlansDatasource>()) {
    dashboardDi.registerLazySingleton(
      () => SubscriptionPlansDatasource(
        dashboardDi<SupabaseClient>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<SubscriptionPlansRepository>()) {
    dashboardDi.registerLazySingleton<SubscriptionPlansRepository>(
      () => SubscriptionPlansRepositoryImpl(
        dashboardDi<SubscriptionPlansDatasource>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<GetSubscriptionPlansUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetSubscriptionPlansUseCase(
        dashboardDi<SubscriptionPlansRepository>(),
      ),
    );
    dashboardDi.registerLazySingleton(
      () => CreateSubscriptionPlanUseCase(
        dashboardDi<SubscriptionPlansRepository>(),
      ),
    );
    dashboardDi.registerLazySingleton(
      () => UpdateSubscriptionPlanUseCase(
        dashboardDi<SubscriptionPlansRepository>(),
      ),
    );
    dashboardDi.registerLazySingleton(
      () => SetSubscriptionPlanStatusUseCase(
        dashboardDi<SubscriptionPlansRepository>(),
      ),
    );
    dashboardDi.registerLazySingleton(
      () => DeleteSubscriptionPlanUseCase(
        dashboardDi<SubscriptionPlansRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<SubscriptionPlansCubit>()) {
    dashboardDi.registerFactory(
      () => SubscriptionPlansCubit(
        getPlans: dashboardDi<GetSubscriptionPlansUseCase>(),
        createPlan: dashboardDi<CreateSubscriptionPlanUseCase>(),
        updatePlan: dashboardDi<UpdateSubscriptionPlanUseCase>(),
        setStatus: dashboardDi<SetSubscriptionPlanStatusUseCase>(),
        deletePlan: dashboardDi<DeleteSubscriptionPlanUseCase>(),
      ),
    );
  }

  registerTripsDependencies(dashboardDi);

  // Mock vehicles registrations removed

  if (!dashboardDi.isRegistered<SupabaseTicketsDatasource>()) {
    dashboardDi.registerLazySingleton<SupabaseTicketsDatasource>(
      () => SupabaseTicketsDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<TicketsRepository>()) {
    dashboardDi.registerLazySingleton<TicketsRepository>(
      () => TicketsRepositoryImpl(dashboardDi<SupabaseTicketsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetTicketsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetTicketsUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateTicketStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateTicketStatusUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<SaveInternalNoteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SaveInternalNoteUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<MarkCustomerContactedUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => MarkCustomerContactedUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CloseTicketUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CloseTicketUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetTicketAttachmentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetTicketAttachmentsUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AssignAgentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AssignAgentUseCase(dashboardDi<TicketsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetAgentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAgentsUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<TicketsCubit>()) {
    dashboardDi.registerFactory(
      () => TicketsCubit(
        getTickets: dashboardDi<GetTicketsUseCase>(),
        updateTicketStatus: dashboardDi<UpdateTicketStatusUseCase>(),
        saveInternalNote: dashboardDi<SaveInternalNoteUseCase>(),
        markCustomerContacted: dashboardDi<MarkCustomerContactedUseCase>(),
        closeTicket: dashboardDi<CloseTicketUseCase>(),
        getTicketAttachments: dashboardDi<GetTicketAttachmentsUseCase>(),
        assignAgent: dashboardDi<AssignAgentUseCase>(),
        getAgents: dashboardDi<GetAgentsUseCase>(),
      ),
    );
  }

  // Finance Feature Registration
  if (!dashboardDi.isRegistered<FinanceDatasource>()) {
    dashboardDi.registerLazySingleton<FinanceDatasource>(
      () => SupabaseFinanceDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<FinanceRepository>()) {
    dashboardDi.registerLazySingleton<FinanceRepository>(
      () => FinanceRepositoryImpl(dashboardDi<FinanceDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetPaymentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetPaymentsUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetReceiptReviewsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReceiptReviewsUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetRefundRequestsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetRefundRequestsUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetFinanceSubscriptionsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFinanceSubscriptionsUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetRevenueMetricsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetRevenueMetricsUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetRevenueTrendUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetRevenueTrendUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ReviewReceiptUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReviewReceiptUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ProcessRefundUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ProcessRefundUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CancelFinanceSubscriptionUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CancelFinanceSubscriptionUseCase(dashboardDi<FinanceRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<FinanceCubit>()) {
    dashboardDi.registerFactory(
      () => FinanceCubit(
        getPayments: dashboardDi<GetPaymentsUseCase>(),
        getReceiptReviews: dashboardDi<GetReceiptReviewsUseCase>(),
        getRefundRequests: dashboardDi<GetRefundRequestsUseCase>(),
        getSubscriptions: dashboardDi<GetFinanceSubscriptionsUseCase>(),
        getRevenueMetrics: dashboardDi<GetRevenueMetricsUseCase>(),
        getRevenueTrend: dashboardDi<GetRevenueTrendUseCase>(),
        reviewReceipt: dashboardDi<ReviewReceiptUseCase>(),
        processRefund: dashboardDi<ProcessRefundUseCase>(),
        cancelSubscription: dashboardDi<CancelFinanceSubscriptionUseCase>(),
      ),
    );
  }

  // Owner / Revenue Overview Registration
  if (!dashboardDi.isRegistered<OwnerOverviewDatasource>()) {
    dashboardDi.registerLazySingleton(
      () => OwnerOverviewDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<OwnerOverviewRepository>()) {
    dashboardDi.registerLazySingleton<OwnerOverviewRepository>(
      () => OwnerOverviewRepositoryImpl(dashboardDi<OwnerOverviewDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetOwnerOverviewUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetOwnerOverviewUseCase(dashboardDi<OwnerOverviewRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<OwnerOverviewCubit>()) {
    dashboardDi.registerFactory(
      () => OwnerOverviewCubit(
        getOverview: dashboardDi<GetOwnerOverviewUseCase>(),
      ),
    );
  }

  // Reports Feature Registration
  if (!dashboardDi.isRegistered<ReportsDatasource>()) {
    dashboardDi.registerLazySingleton<ReportsDatasource>(
      () => SupabaseReportsDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<ReportsRepository>()) {
    dashboardDi.registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(dashboardDi<ReportsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetReportDataUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReportDataUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ExportReportUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ExportReportUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetAvailableRoutesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAvailableRoutesUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetAvailableDriversUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAvailableDriversUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetAvailableVehiclesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAvailableVehiclesUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetAvailablePackagesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAvailablePackagesUseCase(dashboardDi<ReportsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ReportsCubit>()) {
    dashboardDi.registerFactory(
      () => ReportsCubit(
        getReportData: dashboardDi<GetReportDataUseCase>(),
        exportReport: dashboardDi<ExportReportUseCase>(),
        getAvailableRoutes: dashboardDi<GetAvailableRoutesUseCase>(),
        getAvailableDrivers: dashboardDi<GetAvailableDriversUseCase>(),
        getAvailableVehicles: dashboardDi<GetAvailableVehiclesUseCase>(),
        getAvailablePackages: dashboardDi<GetAvailablePackagesUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<UsersRepository>()) {
    dashboardDi.registerLazySingleton<UsersRepository>(
      () => SupabaseUsersDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<GetCurrentUserRoleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetCurrentUserRoleUseCase(dashboardDi<UsersRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetUsersUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetUsersUseCase(dashboardDi<UsersRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateUserRoleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateUserRoleUseCase(dashboardDi<UsersRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UsersCubit>()) {
    dashboardDi.registerFactory(
      () => UsersCubit(
        getUsers: dashboardDi<GetUsersUseCase>(),
        updateRole: dashboardDi<UpdateUserRoleUseCase>(),
      ),
    );
  }

  // ── Referrals ────────────────────────────────────────────────────────
  if (!dashboardDi.isRegistered<ReferralDatasource>()) {
    dashboardDi.registerLazySingleton<ReferralDatasource>(
      () => SupabaseReferralDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<ReferralRepository>()) {
    dashboardDi.registerLazySingleton<ReferralRepository>(
      () => ReferralRepositoryImpl(dashboardDi<ReferralDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReferralRewardConfigUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReferralRewardConfigUseCase(dashboardDi<ReferralRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateReferralRewardConfigUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          UpdateReferralRewardConfigUseCase(dashboardDi<ReferralRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReferralAnalyticsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReferralAnalyticsUseCase(dashboardDi<ReferralRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReferralLeaderboardUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReferralLeaderboardUseCase(dashboardDi<ReferralRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReferralHistoryUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReferralHistoryUseCase(dashboardDi<ReferralRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReferralRewardTransactionsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReferralRewardTransactionsUseCase(
        dashboardDi<ReferralRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<ReferralCubit>()) {
    dashboardDi.registerFactory(
      () => ReferralCubit(
        getConfig: dashboardDi<GetReferralRewardConfigUseCase>(),
        updateConfig: dashboardDi<UpdateReferralRewardConfigUseCase>(),
        getAnalytics: dashboardDi<GetReferralAnalyticsUseCase>(),
        getLeaderboard: dashboardDi<GetReferralLeaderboardUseCase>(),
        getHistory: dashboardDi<GetReferralHistoryUseCase>(),
        getTransactions: dashboardDi<GetReferralRewardTransactionsUseCase>(),
      ),
    );
  }

  _registerNotificationsDispatchDependencies();
  _registerCaptainRequestsDependencies();
  _registerReviewsDependencies();
  _registerOfficeProfileDependencies();
  _registerPlatformAdminDependencies();
}

void _registerPlatformAdminDependencies() {
  if (!dashboardDi.isRegistered<PlatformAdminDatasource>()) {
    dashboardDi.registerLazySingleton<PlatformAdminDatasource>(
      // No DashboardSession here, unlike every other datasource: these calls act
      // across offices, and the RPCs resolve the caller's platform-admin
      // identity server-side. There is nothing office-scoped to inject.
      () => SupabasePlatformAdminDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<PlatformAdminRepository>()) {
    dashboardDi.registerLazySingleton<PlatformAdminRepository>(
      () => PlatformAdminRepositoryImpl(dashboardDi<PlatformAdminDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetPlatformOfficesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetPlatformOfficesUseCase(dashboardDi<PlatformAdminRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetPlatformAnalyticsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetPlatformAnalyticsUseCase(dashboardDi<PlatformAdminRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<GetPlatformOfficeDetailsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetPlatformOfficeDetailsUseCase(
        dashboardDi<PlatformAdminRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<OnboardOfficeUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => OnboardOfficeUseCase(dashboardDi<PlatformAdminRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<SetOfficeListingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SetOfficeListingUseCase(dashboardDi<PlatformAdminRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<SetOfficeStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SetOfficeStatusUseCase(dashboardDi<PlatformAdminRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<PlatformAdminCubit>()) {
    dashboardDi.registerFactory(
      () => PlatformAdminCubit(
        getOffices: dashboardDi<GetPlatformOfficesUseCase>(),
        getAnalytics: dashboardDi<GetPlatformAnalyticsUseCase>(),
        getOfficeDetails: dashboardDi<GetPlatformOfficeDetailsUseCase>(),
        onboardOffice: dashboardDi<OnboardOfficeUseCase>(),
        setListing: dashboardDi<SetOfficeListingUseCase>(),
        setStatus: dashboardDi<SetOfficeStatusUseCase>(),
      ),
    );
  }
}

void _registerOfficeProfileDependencies() {
  if (!dashboardDi.isRegistered<OfficeProfileDatasource>()) {
    dashboardDi.registerLazySingleton<OfficeProfileDatasource>(
      () => SupabaseOfficeProfileDatasource(
        dashboardDi<SupabaseClient>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<OfficeProfileRepository>()) {
    dashboardDi.registerLazySingleton<OfficeProfileRepository>(
      () => OfficeProfileRepositoryImpl(dashboardDi<OfficeProfileDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetOfficeProfileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetOfficeProfileUseCase(dashboardDi<OfficeProfileRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<UpdateOfficeProfileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateOfficeProfileUseCase(dashboardDi<OfficeProfileRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<OfficeProfileCubit>()) {
    dashboardDi.registerFactory(
      () => OfficeProfileCubit(
        getProfile: dashboardDi<GetOfficeProfileUseCase>(),
        updateProfile: dashboardDi<UpdateOfficeProfileUseCase>(),
      ),
    );
  }
}

void _registerReviewsDependencies() {
  if (!dashboardDi.isRegistered<ReviewsDatasource>()) {
    dashboardDi.registerLazySingleton<ReviewsDatasource>(
      () => SupabaseReviewsDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<ReviewsRepository>()) {
    dashboardDi.registerLazySingleton<ReviewsRepository>(
      () => ReviewsRepositoryImpl(dashboardDi<ReviewsDatasource>()),
    );
  }
  if (!dashboardDi.isRegistered<GetReviewsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetReviewsUseCase(dashboardDi<ReviewsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<WatchReviewsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => WatchReviewsUseCase(dashboardDi<ReviewsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<ReviewsCubit>()) {
    dashboardDi.registerFactory<ReviewsCubit>(
      () => ReviewsCubit(
        getReviews: dashboardDi<GetReviewsUseCase>(),
        watchReviews: dashboardDi<WatchReviewsUseCase>(),
      ),
    );
  }
}

void _registerCaptainRequestsDependencies() {
  if (!dashboardDi.isRegistered<SupabaseCaptainRequestsDatasource>()) {
    dashboardDi.registerLazySingleton<SupabaseCaptainRequestsDatasource>(
      () => SupabaseCaptainRequestsDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<CaptainRequestsRepository>()) {
    dashboardDi.registerLazySingleton<CaptainRequestsRepository>(
      () => CaptainRequestsRepositoryImpl(
        dashboardDi<SupabaseCaptainRequestsDatasource>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<GetCaptainRequestsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetCaptainRequestsUseCase(dashboardDi<CaptainRequestsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<WatchCaptainRequestsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          WatchCaptainRequestsUseCase(dashboardDi<CaptainRequestsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<ApproveCaptainRequestUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ApproveCaptainRequestUseCase(
        dashboardDi<CaptainRequestsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<RejectCaptainRequestUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          RejectCaptainRequestUseCase(dashboardDi<CaptainRequestsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<CaptainRequestsCubit>()) {
    dashboardDi.registerFactory<CaptainRequestsCubit>(
      () => CaptainRequestsCubit(
        getRequests: dashboardDi<GetCaptainRequestsUseCase>(),
        watchRequests: dashboardDi<WatchCaptainRequestsUseCase>(),
        approve: dashboardDi<ApproveCaptainRequestUseCase>(),
        reject: dashboardDi<RejectCaptainRequestUseCase>(),
      ),
    );
  }
}

void _registerNotificationsDispatchDependencies() {
  if (!dashboardDi.isRegistered<NotificationsDispatchDatasource>()) {
    dashboardDi.registerLazySingleton<NotificationsDispatchDatasource>(
      () => SupabaseNotificationsDispatchDatasource(
        dashboardDi<SupabaseClient>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<NotificationsDispatchRepository>()) {
    dashboardDi.registerLazySingleton<NotificationsDispatchRepository>(
      () => NotificationsDispatchRepositoryImpl(
        dashboardDi<NotificationsDispatchDatasource>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<SendNotificationUseCase>()) {
    dashboardDi.registerLazySingleton<SendNotificationUseCase>(
      () => SendNotificationUseCase(
        dashboardDi<NotificationsDispatchRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<NotificationsDispatchCubit>()) {
    dashboardDi.registerFactory<NotificationsDispatchCubit>(
      () => NotificationsDispatchCubit(dashboardDi<SendNotificationUseCase>()),
    );
  }

  _registerOperationalAlertsDependencies();

  if (!dashboardDi.isRegistered<DashboardAuthDatasource>()) {
    dashboardDi.registerLazySingleton<DashboardAuthDatasource>(
      () => DashboardAuthDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  // Singleton, not a factory: the auth gate and the sign-out button must act on the
  // same instance, and the session it owns is read by every office-scoped datasource.
  if (!dashboardDi.isRegistered<DashboardAuthCubit>()) {
    dashboardDi.registerLazySingleton<DashboardAuthCubit>(
      () => DashboardAuthCubit(
        dashboardDi<DashboardAuthDatasource>(),
        dashboardDi<DashboardSession>(),
      ),
    );
  }
}

void _registerOperationalAlertsDependencies() {
  if (!dashboardDi.isRegistered<OperationalAlertsDatasource>()) {
    dashboardDi.registerLazySingleton<OperationalAlertsDatasource>(
      () => SupabaseOperationalAlertsDatasource(dashboardDi<SupabaseClient>()),
    );
  }
  if (!dashboardDi.isRegistered<OperationalAlertsRepository>()) {
    dashboardDi.registerLazySingleton<OperationalAlertsRepository>(
      () => OperationalAlertsRepositoryImpl(
        dashboardDi<OperationalAlertsDatasource>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<WatchOperationalAlertsUseCase>()) {
    dashboardDi.registerLazySingleton<WatchOperationalAlertsUseCase>(
      () => WatchOperationalAlertsUseCase(
        dashboardDi<OperationalAlertsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<WatchUnreadAlertsCountUseCase>()) {
    dashboardDi.registerLazySingleton<WatchUnreadAlertsCountUseCase>(
      () => WatchUnreadAlertsCountUseCase(
        dashboardDi<OperationalAlertsRepository>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<MarkAlertReadUseCase>()) {
    dashboardDi.registerLazySingleton<MarkAlertReadUseCase>(
      () => MarkAlertReadUseCase(dashboardDi<OperationalAlertsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<MarkAllAlertsReadUseCase>()) {
    dashboardDi.registerLazySingleton<MarkAllAlertsReadUseCase>(
      () =>
          MarkAllAlertsReadUseCase(dashboardDi<OperationalAlertsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<OperationalAlertsBadgeCubit>()) {
    dashboardDi.registerLazySingleton<OperationalAlertsBadgeCubit>(
      () => OperationalAlertsBadgeCubit(
        dashboardDi<WatchUnreadAlertsCountUseCase>(),
      ),
    );
  }
  if (!dashboardDi.isRegistered<OperationalAlertsCubit>()) {
    dashboardDi.registerFactory<OperationalAlertsCubit>(
      () => OperationalAlertsCubit(
        watchAlerts: dashboardDi<WatchOperationalAlertsUseCase>(),
        markAsRead: dashboardDi<MarkAlertReadUseCase>(),
        markAllAsRead: dashboardDi<MarkAllAlertsReadUseCase>(),
      ),
    );
  }
}
