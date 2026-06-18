import '../../../../core/network/network_di.dart';
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
import '../../features/bookings/domain/usecases/assign_bookings_to_trip_usecase.dart';
import '../../features/bookings/domain/usecases/bulk_update_bookings_status_usecase.dart';
import '../../features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/reject_booking_usecase.dart';
import '../../features/bookings/domain/usecases/request_reupload_usecase.dart';
import '../../features/bookings/domain/usecases/update_booking_status_usecase.dart';
import '../../features/bookings/domain/usecases/watch_bookings_usecase.dart';
import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/dashboard_home/data/datasources/dashboard_home_datasource.dart';
import '../../features/dashboard_home/data/datasources/supabase_dashboard_home_datasource.dart';
import '../../features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import '../../features/dashboard_home/domain/repositories/dashboard_home_repository.dart';
import '../../features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/dashboard_operations/data/datasources/mock_dashboard_operations_datasource.dart';
import '../../features/dashboard_operations/data/repositories/dashboard_operations_repository_impl.dart';
import '../../features/dashboard_operations/domain/repositories/dashboard_operations_repository.dart';
import '../../features/dashboard_operations/domain/usecases/get_dashboard_workspace_usecase.dart';
import '../../features/dashboard_operations/presentation/cubit/dashboard_workspace_cubit.dart';

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
import '../../features/live_trips/data/datasources/mock_live_trips_datasource.dart';
import '../../features/live_trips/data/datasources/supabase_live_trips_datasource.dart';
import '../../features/live_trips/data/repositories/live_trips_repository_impl.dart';
import '../../features/live_trips/domain/repositories/live_trips_repository.dart';
import '../../features/live_trips/domain/usecases/get_live_trips_usecase.dart';
import '../../features/live_trips/domain/usecases/get_live_trip_details_usecase.dart';
import '../../features/live_trips/domain/usecases/start_live_trip_usecase.dart';
import '../../features/live_trips/domain/usecases/pause_live_trip_usecase.dart';
import '../../features/live_trips/domain/usecases/resume_live_trip_usecase.dart';
import '../../features/live_trips/domain/usecases/complete_live_trip_usecase.dart';
import '../../features/live_trips/domain/usecases/mark_route_point_arrived_usecase.dart';
import '../../features/live_trips/domain/usecases/mark_route_point_completed_usecase.dart';
import '../../features/live_trips/domain/usecases/skip_route_point_usecase.dart';
import '../../features/live_trips/domain/usecases/resolve_live_trip_alert_usecase.dart';
import '../../features/live_trips/domain/usecases/report_live_trip_alert_usecase.dart';
import '../../features/live_trips/domain/usecases/call_driver_usecase.dart';
import '../../features/live_trips/domain/usecases/send_driver_message_usecase.dart';
import '../../features/live_trips/domain/usecases/toggle_passenger_checkin_usecase.dart';
import '../../features/live_trips/presentation/cubit/live_trips_cubit.dart';
import '../../features/payments/data/datasources/mock_payments_datasource.dart';
import '../../features/payments/data/datasources/supabase_payments_datasource.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/domain/usecases/add_payment_note_usecase.dart';
import '../../features/payments/domain/usecases/get_finance_payments_usecase.dart';
import '../../features/payments/domain/usecases/reassign_booking_usecase.dart';
import '../../features/payments/domain/usecases/update_payment_review_status_usecase.dart';
import '../../features/payments/presentation/cubit/payments_cubit.dart';
import '../../features/payment_verification/data/datasources/mock_booking_payment_verification_datasource.dart';
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
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../../features/subscriptions/data/datasources/mock_subscriptions_datasource.dart';
import '../../features/subscriptions/data/datasources/supabase_subscriptions_datasource.dart';
import '../../features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscriptions_repository.dart';
import '../../features/subscriptions/domain/usecases/cancel_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/create_subscription_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscription_creation_options_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscription_details_usecase.dart';
import '../../features/subscriptions/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/subscriptions/domain/usecases/mark_subscription_ride_used_usecase.dart';
import '../../features/subscriptions/domain/usecases/renew_subscription_usecase.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
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
import '../../features/finance/domain/usecases/get_subscriptions_usecase.dart';
import '../../features/finance/domain/usecases/process_refund_usecase.dart';
import '../../features/finance/domain/usecases/review_receipt_usecase.dart';
import '../../features/finance/data/datasources/finance_datasource.dart';
import '../../features/finance/data/datasources/supabase_finance_datasource.dart';
import '../../features/finance/presentation/cubit/finance_cubit.dart';
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
import '../theme/dashboard_theme_cubit.dart';
import '../theme/dashboard_theme_repository.dart';

final GetIt dashboardDi = GetIt.instance;

void registerDashboardDependencies() {
  if (!dashboardDi.isRegistered<SupabaseClient>()) {
    dashboardDi.registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    );
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

  if (!dashboardDi.isRegistered<DashboardHomeDatasource>()) {
    dashboardDi.registerLazySingleton<DashboardHomeDatasource>(
      () => SupabaseDashboardHomeDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<DashboardHomeRepository>()) {
    dashboardDi.registerLazySingleton<DashboardHomeRepository>(
      () => DashboardHomeRepositoryImpl(dashboardDi<DashboardHomeDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetDashboardHomeUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetDashboardHomeUseCase(dashboardDi<DashboardHomeRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DashboardHomeCubit>()) {
    dashboardDi.registerFactory(
      () => DashboardHomeCubit(dashboardDi<GetDashboardHomeUseCase>()),
    );
  }

  if (!dashboardDi.isRegistered<DashboardOperationsDatasource>()) {
    dashboardDi.registerLazySingleton<DashboardOperationsDatasource>(
      MockDashboardOperationsDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<DashboardOperationsRepository>()) {
    dashboardDi.registerLazySingleton<DashboardOperationsRepository>(
      () => DashboardOperationsRepositoryImpl(
        dashboardDi<DashboardOperationsDatasource>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<GetDashboardWorkspaceUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetDashboardWorkspaceUseCase(
        dashboardDi<DashboardOperationsRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<DashboardWorkspaceCubit>()) {
    dashboardDi.registerFactory(
      () =>
          DashboardWorkspaceCubit(dashboardDi<GetDashboardWorkspaceUseCase>()),
    );
  }

  if (!dashboardDi.isRegistered<FleetDatasource>()) {
    dashboardDi.registerLazySingleton<FleetDatasource>(
      () => SupabaseFleetDatasource(dashboardDi<SupabaseClient>()),
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

  if (!dashboardDi.isRegistered<UpdateBookingStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateBookingStatusUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<BulkUpdateBookingsStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => BulkUpdateBookingsStatusUseCase(dashboardDi<BookingsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AssignBookingsToTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AssignBookingsToTripUseCase(dashboardDi<BookingsRepository>()),
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
        updateStatus: dashboardDi<UpdateBookingStatusUseCase>(),
        bulkUpdateStatus: dashboardDi<BulkUpdateBookingsStatusUseCase>(),
        assignToTrip: dashboardDi<AssignBookingsToTripUseCase>(),
        approveBooking: dashboardDi<ApproveBookingUseCase>(),
        rejectBooking: dashboardDi<RejectBookingUseCase>(),
        requestReupload: dashboardDi<RequestReuploadUseCase>(),
        watchBookings: dashboardDi<WatchBookingsUseCase>(),
      ),
    );
  }

  // Mock drivers registrations removed

  if (!dashboardDi.isRegistered<LiveTripsDatasource>()) {
    dashboardDi.registerLazySingleton<LiveTripsDatasource>(
      () => SupabaseLiveTripsDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<LiveTripsRepository>()) {
    dashboardDi.registerLazySingleton<LiveTripsRepository>(
      () => LiveTripsRepositoryImpl(dashboardDi<LiveTripsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetLiveTripsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetLiveTripsUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetLiveTripDetailsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetLiveTripDetailsUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<StartLiveTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => StartLiveTripUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<PauseLiveTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => PauseLiveTripUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ResumeLiveTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ResumeLiveTripUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CompleteLiveTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CompleteLiveTripUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<MarkRoutePointArrivedUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => MarkRoutePointArrivedUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<MarkRoutePointCompletedUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => MarkRoutePointCompletedUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<SkipRoutePointUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SkipRoutePointUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ResolveLiveTripAlertUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ResolveLiveTripAlertUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ReportLiveTripAlertUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReportLiveTripAlertUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CallDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CallDriverUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<SendDriverMessageUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SendDriverMessageUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<TogglePassengerCheckinUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => TogglePassengerCheckinUseCase(dashboardDi<LiveTripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<LiveTripsCubit>()) {
    dashboardDi.registerFactory(
      () => LiveTripsCubit(
        getLiveTrips: dashboardDi<GetLiveTripsUseCase>(),
        startTrip: dashboardDi<StartLiveTripUseCase>(),
        pauseTrip: dashboardDi<PauseLiveTripUseCase>(),
        resumeTrip: dashboardDi<ResumeLiveTripUseCase>(),
        completeTrip: dashboardDi<CompleteLiveTripUseCase>(),
        markPointArrived: dashboardDi<MarkRoutePointArrivedUseCase>(),
        markPointCompleted: dashboardDi<MarkRoutePointCompletedUseCase>(),
        skipPoint: dashboardDi<SkipRoutePointUseCase>(),
        resolveAlert: dashboardDi<ResolveLiveTripAlertUseCase>(),
        reportAlert: dashboardDi<ReportLiveTripAlertUseCase>(),
        callDriver: dashboardDi<CallDriverUseCase>(),
        messageDriver: dashboardDi<SendDriverMessageUseCase>(),
        togglePassengerCheckin: dashboardDi<TogglePassengerCheckinUseCase>(),
      ),
    );
  }

  // Mock assignments registrations removed

  if (!dashboardDi.isRegistered<PaymentsDatasource>()) {
    dashboardDi.registerLazySingleton<PaymentsDatasource>(
      () => SupabasePaymentsDatasource(dashboardDi<SupabaseClient>()),
    );
  }

  if (!dashboardDi.isRegistered<PaymentsRepository>()) {
    dashboardDi.registerLazySingleton<PaymentsRepository>(
      () => PaymentsRepositoryImpl(dashboardDi<PaymentsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetFinancePaymentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetFinancePaymentsUseCase(dashboardDi<PaymentsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdatePaymentReviewStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdatePaymentReviewStatusUseCase(dashboardDi<PaymentsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AddPaymentNoteUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AddPaymentNoteUseCase(dashboardDi<PaymentsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<GetAvailableTripsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetAvailableTripsUseCase(dashboardDi<PaymentsRepository>()),
    );
  }
  if (!dashboardDi.isRegistered<ReassignBookingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReassignBookingUseCase(dashboardDi<PaymentsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<PaymentsCubit>()) {
    dashboardDi.registerFactory(
      () => PaymentsCubit(
        getPayments: dashboardDi<GetFinancePaymentsUseCase>(),
        updateStatus: dashboardDi<UpdatePaymentReviewStatusUseCase>(),
        addNote: dashboardDi<AddPaymentNoteUseCase>(),
        getAvailableTrips: dashboardDi<GetAvailableTripsUseCase>(),
        reassignBooking: dashboardDi<ReassignBookingUseCase>(),
      ),
    );
  }

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
      () => SupabaseRoutesDatasource(dashboardDi<SupabaseClient>()),
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
      () => SupabaseSubscriptionsDatasource(dashboardDi<SupabaseClient>()),
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

  if (!dashboardDi.isRegistered<SubscriptionsCubit>()) {
    dashboardDi.registerFactory(
      () => SubscriptionsCubit(
        getSubscriptions: dashboardDi<GetSubscriptionsUseCase>(),
        getDetails: dashboardDi<GetSubscriptionDetailsUseCase>(),
        createSubscription: dashboardDi<CreateSubscriptionUseCase>(),
        cancelSubscription: dashboardDi<CancelSubscriptionUseCase>(),
        renewSubscription: dashboardDi<RenewSubscriptionUseCase>(),
        markRideUsed: dashboardDi<MarkSubscriptionRideUsedUseCase>(),
        getCreationOptions:
            dashboardDi<GetSubscriptionCreationOptionsUseCase>(),
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
        reviewReceipt: dashboardDi<ReviewReceiptUseCase>(),
        processRefund: dashboardDi<ProcessRefundUseCase>(),
        cancelSubscription: dashboardDi<CancelFinanceSubscriptionUseCase>(),
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
}
