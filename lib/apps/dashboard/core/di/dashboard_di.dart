import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/fleet/data/datasources/supabase_fleet_datasource.dart';


import '../../features/assignments/data/datasources/mock_fleet_assignments_datasource.dart';
import '../../features/assignments/data/repositories/fleet_assignments_repository_impl.dart';
import '../../features/assignments/domain/repositories/fleet_assignments_repository.dart';
import '../../features/assignments/domain/usecases/assign_vehicle_to_driver_usecase.dart';
import '../../features/assignments/domain/usecases/change_fleet_assignment_usecase.dart';
import '../../features/assignments/domain/usecases/get_fleet_assignments_usecase.dart';
import '../../features/assignments/domain/usecases/remove_fleet_assignment_usecase.dart';
import '../../features/assignments/presentation/cubit/fleet_assignments_cubit.dart';
import '../../features/bookings/data/datasources/mock_bookings_datasource.dart';
import '../../features/bookings/data/repositories/bookings_repository_impl.dart';
import '../../features/bookings/domain/repositories/bookings_repository.dart';
import '../../features/bookings/domain/usecases/approve_booking_usecase.dart';
import '../../features/bookings/domain/usecases/assign_bookings_to_trip_usecase.dart';
import '../../features/bookings/domain/usecases/bulk_update_bookings_status_usecase.dart';
import '../../features/bookings/domain/usecases/get_operation_bookings_usecase.dart';
import '../../features/bookings/domain/usecases/reject_booking_usecase.dart';
import '../../features/bookings/domain/usecases/request_reupload_usecase.dart';
import '../../features/bookings/domain/usecases/update_booking_status_usecase.dart';
import '../../features/bookings/presentation/cubit/bookings_cubit.dart';
import '../../features/dashboard_home/data/datasources/mock_dashboard_home_datasource.dart';
import '../../features/dashboard_home/data/repositories/dashboard_home_repository_impl.dart';
import '../../features/dashboard_home/domain/repositories/dashboard_home_repository.dart';
import '../../features/dashboard_home/domain/usecases/get_dashboard_home_usecase.dart';
import '../../features/dashboard_home/presentation/cubit/dashboard_home_cubit.dart';
import '../../features/dashboard_operations/data/datasources/mock_dashboard_operations_datasource.dart';
import '../../features/dashboard_operations/data/repositories/dashboard_operations_repository_impl.dart';
import '../../features/dashboard_operations/domain/repositories/dashboard_operations_repository.dart';
import '../../features/dashboard_operations/domain/usecases/get_dashboard_workspace_usecase.dart';
import '../../features/dashboard_operations/presentation/cubit/dashboard_workspace_cubit.dart';
import '../../features/drivers/data/datasources/mock_drivers_datasource.dart';
import '../../features/drivers/data/repositories/drivers_repository_impl.dart';
import '../../features/drivers/domain/repositories/drivers_repository.dart';
import '../../features/drivers/domain/usecases/create_driver_usecase.dart';
import '../../features/drivers/domain/usecases/delete_driver_usecase.dart';
import '../../features/drivers/domain/usecases/get_drivers_usecase.dart';
import '../../features/drivers/domain/usecases/update_driver_status_usecase.dart';
import '../../features/drivers/domain/usecases/update_driver_usecase.dart';
import '../../features/drivers/presentation/cubit/drivers_cubit.dart';
import '../../features/fleet/data/datasources/mock_fleet_datasource.dart';
import '../../features/fleet/data/repositories/fleet_repository_impl.dart';
import '../../features/fleet/domain/repositories/fleet_repository.dart';
import '../../features/fleet/domain/usecases/fleet_usecases.dart';
import '../../features/fleet/presentation/cubit/fleet_cubit.dart';
import '../../features/live_trips/data/datasources/mock_live_trips_datasource.dart';
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
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/payments/domain/usecases/add_payment_note_usecase.dart';
import '../../features/payments/domain/usecases/get_finance_payments_usecase.dart';
import '../../features/payments/domain/usecases/update_payment_review_status_usecase.dart';
import '../../features/payments/presentation/cubit/payments_cubit.dart';
import '../../features/payment_verification/data/datasources/mock_booking_payment_verification_datasource.dart';
import '../../features/payment_verification/data/repositories/booking_payment_verification_repository_impl.dart';
import '../../features/payment_verification/domain/repositories/booking_payment_verification_repository.dart';
import '../../features/payment_verification/domain/usecases/add_booking_payment_note_usecase.dart';
import '../../features/payment_verification/domain/usecases/approve_booking_payment_usecase.dart';
import '../../features/payment_verification/domain/usecases/get_booking_payment_verifications_usecase.dart';
import '../../features/payment_verification/domain/usecases/reject_booking_payment_usecase.dart';
import '../../features/payment_verification/domain/usecases/request_booking_payment_review_usecase.dart';
import '../../features/payment_verification/presentation/cubit/payment_verification_cubit.dart';
import '../../features/routes/data/datasources/mock_routes_datasource.dart';
import '../../features/routes/data/repositories/routes_repository_impl.dart';
import '../../features/routes/domain/repositories/routes_repository.dart';
import '../../features/routes/domain/usecases/add_route_station_usecase.dart';
import '../../features/routes/domain/usecases/create_route_usecase.dart';
import '../../features/routes/domain/usecases/delete_route_station_usecase.dart';
import '../../features/routes/domain/usecases/get_operation_routes_usecase.dart';
import '../../features/routes/domain/usecases/reorder_route_stations_usecase.dart';
import '../../features/routes/domain/usecases/update_route_station_usecase.dart';
import '../../features/routes/domain/usecases/update_route_usecase.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../../features/subscriptions/data/datasources/mock_subscriptions_datasource.dart';
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
import '../../features/trips/data/datasources/mock_trips_datasource.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/repositories/trips_repository.dart';
import '../../features/trips/domain/usecases/get_operation_trips_usecase.dart';
import '../../features/trips/domain/usecases/trip_pricing_usecases.dart';
import '../../features/trips/domain/usecases/trip_operations_usecases.dart';
import '../../features/trips/domain/usecases/update_trip_seat_state_usecase.dart';
import '../../features/trips/domain/usecases/update_trip_status_usecase.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../../features/vehicles/data/datasources/mock_vehicles_datasource.dart';
import '../../features/vehicles/data/repositories/vehicles_repository_impl.dart';
import '../../features/vehicles/domain/repositories/vehicles_repository.dart';
import '../../features/vehicles/domain/usecases/create_vehicle_usecase.dart';
import '../../features/vehicles/domain/usecases/get_vehicles_usecase.dart';
import '../../features/vehicles/domain/usecases/renew_vehicle_document_usecase.dart';
import '../../features/vehicles/domain/usecases/update_vehicle_status_usecase.dart';
import '../../features/vehicles/domain/usecases/update_vehicle_usecase.dart';
import '../../features/vehicles/presentation/cubit/vehicles_cubit.dart';
import '../../features/tickets/data/datasources/tickets_datasource.dart';
import '../../features/tickets/data/repositories/tickets_repository_impl.dart';
import '../../features/tickets/domain/repositories/tickets_repository.dart';
import '../../features/tickets/domain/usecases/assign_complaint_usecase.dart';
import '../../features/tickets/domain/usecases/close_complaint_usecase.dart';
import '../../features/tickets/domain/usecases/escalate_complaint_usecase.dart';
import '../../features/tickets/domain/usecases/get_complaints_usecase.dart';
import '../../features/tickets/domain/usecases/respond_to_complaint_usecase.dart';
import '../../features/tickets/domain/usecases/update_complaint_status_usecase.dart';
import '../../features/tickets/presentation/cubit/tickets_cubit.dart';
import '../../features/finance/data/datasources/mock_finance_datasource.dart';
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
import '../../features/finance/presentation/cubit/finance_cubit.dart';
import '../../features/reports/data/datasources/mock_reports_datasource.dart';
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
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder-project.supabase.co');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-anon-key');
    try {
      Supabase.instance;
    } catch (_) {
      try {
        Supabase.initialize(url: url, anonKey: anonKey);
      } catch (_) {}
    }
    dashboardDi.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

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
      MockDashboardHomeDatasource.new,
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

  if (!dashboardDi.isRegistered<CreateFleetDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetDriverUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateFleetDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetDriverUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateFleetDriverStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetDriverStatusUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetVehicleUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetVehicleUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateFleetVehicleStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetVehicleStatusUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AssignFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AssignFleetVehicleUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ReassignFleetVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ReassignFleetVehicleUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RemoveUnifiedFleetAssignmentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RemoveUnifiedFleetAssignmentUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateFleetDocumentUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateFleetDocumentUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DeleteFleetDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetDocumentUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UploadFleetFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UploadFleetFileUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DeleteFleetFileUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteFleetFileUseCase(dashboardDi<FleetRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<FleetCubit>()) {
    dashboardDi.registerFactory(
      () => FleetCubit(
        getWorkspace: dashboardDi<GetFleetWorkspaceUseCase>(),
        createDriver: dashboardDi<CreateFleetDriverUseCase>(),
        updateDriver: dashboardDi<UpdateFleetDriverUseCase>(),
        updateDriverStatus: dashboardDi<UpdateFleetDriverStatusUseCase>(),
        createVehicle: dashboardDi<CreateFleetVehicleUseCase>(),
        updateVehicle: dashboardDi<UpdateFleetVehicleUseCase>(),
        updateVehicleStatus: dashboardDi<UpdateFleetVehicleStatusUseCase>(),
        assignVehicle: dashboardDi<AssignFleetVehicleUseCase>(),
        reassignVehicle: dashboardDi<ReassignFleetVehicleUseCase>(),
        removeAssignment: dashboardDi<RemoveUnifiedFleetAssignmentUseCase>(),
        createDocument: dashboardDi<CreateFleetDocumentUseCase>(),
        updateDocument: dashboardDi<UpdateFleetDocumentUseCase>(),
        deleteDocument: dashboardDi<DeleteFleetDocumentUseCase>(),
        uploadFile: dashboardDi<UploadFleetFileUseCase>(),
        deleteFile: dashboardDi<DeleteFleetFileUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<BookingsDatasource>()) {
    dashboardDi.registerLazySingleton<BookingsDatasource>(
      MockBookingsDatasource.new,
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
      ),
    );
  }

  if (!dashboardDi.isRegistered<DriversDatasource>()) {
    dashboardDi.registerLazySingleton<DriversDatasource>(
      MockDriversDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<DriversRepository>()) {
    dashboardDi.registerLazySingleton<DriversRepository>(
      () => DriversRepositoryImpl(dashboardDi<DriversDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetDriversUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetDriversUseCase(dashboardDi<DriversRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateDriverUseCase(dashboardDi<DriversRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateDriverUseCase(dashboardDi<DriversRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateDriverStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateDriverStatusUseCase(dashboardDi<DriversRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DeleteDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => DeleteDriverUseCase(dashboardDi<DriversRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<DriversCubit>()) {
    dashboardDi.registerFactory(
      () => DriversCubit(
        getDrivers: dashboardDi<GetDriversUseCase>(),
        createDriver: dashboardDi<CreateDriverUseCase>(),
        updateDriver: dashboardDi<UpdateDriverUseCase>(),
        updateDriverStatus: dashboardDi<UpdateDriverStatusUseCase>(),
        deleteDriver: dashboardDi<DeleteDriverUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<LiveTripsDatasource>()) {
    dashboardDi.registerLazySingleton<LiveTripsDatasource>(
      MockLiveTripsDatasource.new,
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

  if (!dashboardDi.isRegistered<FleetAssignmentsDatasource>()) {
    dashboardDi.registerLazySingleton<FleetAssignmentsDatasource>(
      MockFleetAssignmentsDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<FleetAssignmentsRepository>()) {
    dashboardDi.registerLazySingleton<FleetAssignmentsRepository>(
      () => FleetAssignmentsRepositoryImpl(
        dashboardDi<FleetAssignmentsDatasource>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<GetFleetAssignmentsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () =>
          GetFleetAssignmentsUseCase(dashboardDi<FleetAssignmentsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AssignVehicleToDriverUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AssignVehicleToDriverUseCase(
        dashboardDi<FleetAssignmentsRepository>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<ChangeFleetAssignmentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ChangeFleetAssignmentUseCase(
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

  if (!dashboardDi.isRegistered<FleetAssignmentsCubit>()) {
    dashboardDi.registerFactory(
      () => FleetAssignmentsCubit(
        getAssignments: dashboardDi<GetFleetAssignmentsUseCase>(),
        assignVehicleToDriver: dashboardDi<AssignVehicleToDriverUseCase>(),
        changeAssignment: dashboardDi<ChangeFleetAssignmentUseCase>(),
        removeAssignment: dashboardDi<RemoveFleetAssignmentUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<PaymentsDatasource>()) {
    dashboardDi.registerLazySingleton<PaymentsDatasource>(
      MockPaymentsDatasource.new,
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

  if (!dashboardDi.isRegistered<PaymentsCubit>()) {
    dashboardDi.registerFactory(
      () => PaymentsCubit(
        getPayments: dashboardDi<GetFinancePaymentsUseCase>(),
        updateStatus: dashboardDi<UpdatePaymentReviewStatusUseCase>(),
        addNote: dashboardDi<AddPaymentNoteUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<BookingPaymentVerificationDatasource>()) {
    dashboardDi.registerLazySingleton<BookingPaymentVerificationDatasource>(
      MockBookingPaymentVerificationDatasource.new,
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
      MockRoutesDatasource.new,
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
        addStation: dashboardDi<AddRouteStationUseCase>(),
        updateStation: dashboardDi<UpdateRouteStationUseCase>(),
        deleteStation: dashboardDi<DeleteRouteStationUseCase>(),
        reorderStations: dashboardDi<ReorderRouteStationsUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<TripsDatasource>()) {
    dashboardDi.registerLazySingleton<TripsDatasource>(MockTripsDatasource.new);
  }

  if (!dashboardDi.isRegistered<SubscriptionsDatasource>()) {
    dashboardDi.registerLazySingleton<SubscriptionsDatasource>(
      MockSubscriptionsDatasource.new,
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

  if (!dashboardDi.isRegistered<TripsRepository>()) {
    dashboardDi.registerLazySingleton<TripsRepository>(
      () => TripsRepositoryImpl(dashboardDi<TripsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetOperationTripsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetOperationTripsUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateTripStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateTripStatusUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateTripSeatStateUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateTripSeatStateUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateOperationTripUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateOperationTripUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateTripInfoUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateTripInfoUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateTripPassengerUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateTripPassengerUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CancelTripPassengerUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CancelTripPassengerUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<MoveTripPassengerUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => MoveTripPassengerUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<ValidateTripPricingUseCase>()) {
    dashboardDi.registerLazySingleton(ValidateTripPricingUseCase.new);
  }

  if (!dashboardDi.isRegistered<GetTripPricingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetTripPricingUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<SaveTripSegmentPricingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => SaveTripSegmentPricingUseCase(
        dashboardDi<TripsRepository>(),
        dashboardDi<ValidateTripPricingUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<ToggleTripSegmentPricingUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => ToggleTripSegmentPricingUseCase(dashboardDi<TripsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<TripsCubit>()) {
    dashboardDi.registerFactory(
      () => TripsCubit(
        getTrips: dashboardDi<GetOperationTripsUseCase>(),
        updateTripStatus: dashboardDi<UpdateTripStatusUseCase>(),
        updateSeatState: dashboardDi<UpdateTripSeatStateUseCase>(),
        createTrip: dashboardDi<CreateOperationTripUseCase>(),
        updateTripInfo: dashboardDi<UpdateTripInfoUseCase>(),
        updatePassenger: dashboardDi<UpdateTripPassengerUseCase>(),
        cancelPassenger: dashboardDi<CancelTripPassengerUseCase>(),
        movePassenger: dashboardDi<MoveTripPassengerUseCase>(),
        getTripPricing: dashboardDi<GetTripPricingUseCase>(),
        saveTripPricing: dashboardDi<SaveTripSegmentPricingUseCase>(),
        toggleTripPricing: dashboardDi<ToggleTripSegmentPricingUseCase>(),
        getRoutes: dashboardDi<GetOperationRoutesUseCase>(),
        getVehicles: dashboardDi<GetVehiclesUseCase>(),
        getDrivers: dashboardDi<GetDriversUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<VehiclesDatasource>()) {
    dashboardDi.registerLazySingleton<VehiclesDatasource>(
      MockVehiclesDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<VehiclesRepository>()) {
    dashboardDi.registerLazySingleton<VehiclesRepository>(
      () => VehiclesRepositoryImpl(dashboardDi<VehiclesDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetVehiclesUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetVehiclesUseCase(dashboardDi<VehiclesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CreateVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CreateVehicleUseCase(dashboardDi<VehiclesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateVehicleUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateVehicleUseCase(dashboardDi<VehiclesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateVehicleStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateVehicleStatusUseCase(dashboardDi<VehiclesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RenewVehicleDocumentUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RenewVehicleDocumentUseCase(dashboardDi<VehiclesRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<VehiclesCubit>()) {
    dashboardDi.registerFactory(
      () => VehiclesCubit(
        getVehicles: dashboardDi<GetVehiclesUseCase>(),
        createVehicle: dashboardDi<CreateVehicleUseCase>(),
        updateVehicle: dashboardDi<UpdateVehicleUseCase>(),
        updateVehicleStatus: dashboardDi<UpdateVehicleStatusUseCase>(),
        renewDocument: dashboardDi<RenewVehicleDocumentUseCase>(),
      ),
    );
  }

  if (!dashboardDi.isRegistered<TicketsDatasource>()) {
    dashboardDi.registerLazySingleton<TicketsDatasource>(
      MockTicketsDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<TicketsRepository>()) {
    dashboardDi.registerLazySingleton<TicketsRepository>(
      () => TicketsRepositoryImpl(dashboardDi<TicketsDatasource>()),
    );
  }

  if (!dashboardDi.isRegistered<GetComplaintsUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => GetComplaintsUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<AssignComplaintUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => AssignComplaintUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<RespondToComplaintUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => RespondToComplaintUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<UpdateComplaintStatusUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => UpdateComplaintStatusUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<EscalateComplaintUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => EscalateComplaintUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<CloseComplaintUseCase>()) {
    dashboardDi.registerLazySingleton(
      () => CloseComplaintUseCase(dashboardDi<TicketsRepository>()),
    );
  }

  if (!dashboardDi.isRegistered<TicketsCubit>()) {
    dashboardDi.registerFactory(
      () => TicketsCubit(
        getComplaints: dashboardDi<GetComplaintsUseCase>(),
        assignComplaint: dashboardDi<AssignComplaintUseCase>(),
        respondToComplaint: dashboardDi<RespondToComplaintUseCase>(),
        updateComplaintStatus: dashboardDi<UpdateComplaintStatusUseCase>(),
        escalateComplaint: dashboardDi<EscalateComplaintUseCase>(),
        closeComplaint: dashboardDi<CloseComplaintUseCase>(),
      ),
    );
  }

  // Finance Feature Registration
  if (!dashboardDi.isRegistered<MockFinanceDatasource>()) {
    dashboardDi.registerLazySingleton<MockFinanceDatasource>(
      MockFinanceDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<FinanceRepository>()) {
    dashboardDi.registerLazySingleton<FinanceRepository>(
      () => FinanceRepositoryImpl(dashboardDi<MockFinanceDatasource>()),
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
  if (!dashboardDi.isRegistered<MockReportsDatasource>()) {
    dashboardDi.registerLazySingleton<MockReportsDatasource>(
      MockReportsDatasource.new,
    );
  }

  if (!dashboardDi.isRegistered<ReportsRepository>()) {
    dashboardDi.registerLazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(dashboardDi<MockReportsDatasource>()),
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
}
