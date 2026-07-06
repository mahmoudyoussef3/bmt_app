import '../../../../core/network/network_di.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/captain_session_store.dart';
import '../../features/onboarding/data/datasources/captain_onboarding_datasource.dart';
import '../../features/onboarding/data/repositories/captain_onboarding_repository_impl.dart';
import '../../features/onboarding/domain/repositories/captain_onboarding_repository.dart';
import '../../features/onboarding/domain/usecases/onboarding_usecases.dart';
import '../../features/onboarding/presentation/cubit/captain_onboarding_cubit.dart';

import '../../features/auth/data/datasources/captain_auth_datasource.dart';
import '../../features/auth/data/repositories/captain_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/captain_auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_captain_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_captain_usecase.dart';
import '../../features/auth/presentation/cubit/captain_auth_cubit.dart';

import '../../features/profile/data/datasources/driver_profile_datasource.dart';
import '../../features/profile/data/repositories/driver_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/driver_profile_repository.dart';
import '../../features/profile/domain/usecases/get_driver_profile_usecase.dart';
import '../../features/profile/presentation/cubit/driver_profile_cubit.dart';

import '../../features/trip_history/data/datasources/trip_history_datasource.dart';
import '../../features/trip_history/data/repositories/trip_history_repository_impl.dart';
import '../../features/trip_history/domain/repositories/trip_history_repository.dart';
import '../../features/trip_history/domain/usecases/get_trip_history_usecase.dart';
import '../../features/trip_history/presentation/cubit/trip_history_cubit.dart';

import '../../features/passenger_manifest/domain/usecases/update_passenger_status_usecase.dart';

import '../../features/notifications/data/datasources/supabase_captain_notifications_datasource.dart';
import '../../features/notifications/data/repositories/captain_notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/captain_notifications_repository.dart';
import '../../features/notifications/domain/usecases/watch_captain_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/watch_captain_unread_count_usecase.dart';
import '../../features/notifications/domain/usecases/mark_captain_notification_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_captain_notifications_read_usecase.dart';
import '../../features/notifications/presentation/cubit/captain_notifications_cubit.dart';
import '../../features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';

import '../../features/assigned_trips/data/datasources/captain_trip_remote_datasource.dart';
import '../../features/assigned_trips/data/repositories/captain_trip_repository_impl.dart';
import '../../features/assigned_trips/domain/repositories/captain_trip_repository.dart';
import '../../features/assigned_trips/domain/usecases/get_assigned_trips_usecase.dart';
import '../../features/assigned_trips/domain/usecases/watch_assigned_trips_usecase.dart';
import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/check_in/data/datasources/check_in_datasource.dart';
import '../../features/check_in/data/repositories/check_in_repository_impl.dart';
import '../../features/check_in/domain/repositories/check_in_repository.dart';
import '../../features/check_in/domain/usecases/check_passenger_usecase.dart';
import '../../features/check_in/presentation/cubit/check_in_cubit.dart';
import '../../features/communication/data/datasources/chat_datasource.dart';
import '../../features/communication/data/datasources/supabase_chat_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/get_conversation_usecase.dart';
import '../../features/communication/domain/usecases/send_message_usecase.dart';
import '../../features/communication/presentation/cubit/captain_notification_cubit.dart';
import '../../features/communication/presentation/cubit/communication_cubit.dart';
import '../../features/incidents/data/datasources/incident_datasource.dart';
import '../../features/incidents/data/datasources/supabase_incident_datasource.dart';
import '../../features/incidents/data/repositories/incident_repository_impl.dart';
import '../../features/incidents/domain/repositories/incident_repository.dart';
import '../../features/incidents/domain/usecases/report_incident_usecase.dart';
import '../../features/incidents/presentation/cubit/incident_cubit.dart';
import '../../features/live_location/data/datasources/location_datasource.dart';
import '../../features/live_location/data/datasources/supabase_location_datasource.dart';
import '../../features/live_location/data/repositories/location_repository_impl.dart';
import '../../features/live_location/domain/repositories/location_repository.dart';
import '../../features/live_location/domain/usecases/send_location_update_usecase.dart';
import '../../features/live_location/presentation/cubit/live_location_cubit.dart';
import '../../features/passenger_manifest/data/datasources/passenger_manifest_datasource.dart';
import '../../features/passenger_manifest/data/repositories/passenger_manifest_repository_impl.dart';
import '../../features/passenger_manifest/domain/repositories/passenger_manifest_repository.dart';
import '../../features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import '../../features/passenger_manifest/domain/usecases/watch_trip_passengers_usecase.dart';
import '../../features/passenger_manifest/presentation/cubit/passenger_manifest_cubit.dart';
import '../../features/trip_execution/data/datasources/trip_execution_datasource.dart';
import '../../features/trip_execution/data/repositories/trip_execution_repository_impl.dart';
import '../../features/trip_execution/domain/repositories/trip_execution_repository.dart';
import '../../features/trip_execution/domain/usecases/complete_trip_usecase.dart';
import '../../features/trip_execution/domain/usecases/start_boarding_usecase.dart';
import '../../features/trip_execution/domain/usecases/watch_trip_execution_status_usecase.dart';
import '../../features/trip_execution/domain/usecases/start_trip_usecase.dart';
import '../../features/trip_execution/presentation/cubit/trip_execution_cubit.dart';
import '../../features/trip_status_updates/data/datasources/trip_status_datasource.dart';
import '../../features/trip_status_updates/data/repositories/trip_status_repository_impl.dart';
import '../../features/trip_status_updates/domain/repositories/trip_status_repository.dart';
import '../../features/trip_status_updates/domain/usecases/update_trip_status_usecase.dart'
    as status_updates;
import '../../features/trip_status_updates/presentation/cubit/trip_status_update_cubit.dart';

final GetIt captainGetIt = GetIt.instance;

void registerCaptainDependencies() {
  if (!captainGetIt.isRegistered<SupabaseClient>()) {
    captainGetIt.registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    );
  }

  // Register Core Networking (Dio, Retrofit ApiService)
  registerNetworkDependencies(captainGetIt);

  _registerAssignedTripsDependencies();
  _registerPassengerManifestDependencies();
  _registerLiveLocationDependencies();
  _registerTripExecutionDependencies();
  _registerCommunicationDependencies();
  _registerIncidentsDependencies();
  _registerCheckInDependencies();
  _registerTripStatusUpdateDependencies();
  _registerNotificationsDependencies();
  _registerProfileDependencies();
  _registerTripHistoryDependencies();
  _registerAuthDependencies();
  _registerOnboardingDependencies();
}

void _registerOnboardingDependencies() {
  if (!captainGetIt.isRegistered<CaptainSessionStore>()) {
    captainGetIt.registerLazySingleton<CaptainSessionStore>(
      () => CaptainSessionStore(),
    );
  }
  if (!captainGetIt.isRegistered<CaptainOnboardingDatasource>()) {
    captainGetIt.registerLazySingleton<CaptainOnboardingDatasource>(
      () => CaptainOnboardingDatasource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<CaptainOnboardingRepository>()) {
    captainGetIt.registerLazySingleton<CaptainOnboardingRepository>(
      () => CaptainOnboardingRepositoryImpl(
        captainGetIt<CaptainOnboardingDatasource>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<SubmitCaptainRequestUseCase>()) {
    captainGetIt.registerLazySingleton<SubmitCaptainRequestUseCase>(
      () => SubmitCaptainRequestUseCase(
        captainGetIt<CaptainOnboardingRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<GetCaptainRequestStatusUseCase>()) {
    captainGetIt.registerLazySingleton<GetCaptainRequestStatusUseCase>(
      () => GetCaptainRequestStatusUseCase(
        captainGetIt<CaptainOnboardingRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<CaptainOnboardingCubit>()) {
    captainGetIt.registerFactory<CaptainOnboardingCubit>(
      () => CaptainOnboardingCubit(
        submit: captainGetIt<SubmitCaptainRequestUseCase>(),
        getStatus: captainGetIt<GetCaptainRequestStatusUseCase>(),
        store: captainGetIt<CaptainSessionStore>(),
      ),
    );
  }
}

void _registerAuthDependencies() {
  if (!captainGetIt.isRegistered<CaptainAuthDatasource>()) {
    captainGetIt.registerLazySingleton<CaptainAuthDatasource>(
      () => CaptainAuthDatasource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<CaptainAuthRepository>()) {
    captainGetIt.registerLazySingleton<CaptainAuthRepository>(
      () => CaptainAuthRepositoryImpl(captainGetIt<CaptainAuthDatasource>()),
    );
  }
  if (!captainGetIt.isRegistered<SignInCaptainUseCase>()) {
    captainGetIt.registerLazySingleton<SignInCaptainUseCase>(
      () => SignInCaptainUseCase(captainGetIt<CaptainAuthRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<SignOutCaptainUseCase>()) {
    captainGetIt.registerLazySingleton<SignOutCaptainUseCase>(
      () => SignOutCaptainUseCase(captainGetIt<CaptainAuthRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<CaptainAuthCubit>()) {
    captainGetIt.registerFactory<CaptainAuthCubit>(
      () => CaptainAuthCubit(
        signIn: captainGetIt<SignInCaptainUseCase>(),
        signOut: captainGetIt<SignOutCaptainUseCase>(),
      ),
    );
  }
}

void _registerAssignedTripsDependencies() {
  if (!captainGetIt.isRegistered<CaptainTripRemoteDataSource>()) {
    captainGetIt.registerLazySingleton<CaptainTripRemoteDataSource>(
      () => CaptainTripRemoteDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<CaptainTripRepository>()) {
    captainGetIt.registerLazySingleton<CaptainTripRepository>(
      () => CaptainTripRepositoryImpl(
        captainGetIt<CaptainTripRemoteDataSource>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<GetAssignedTripsUseCase>()) {
    captainGetIt.registerLazySingleton<GetAssignedTripsUseCase>(
      () => GetAssignedTripsUseCase(captainGetIt<CaptainTripRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<WatchAssignedTripsUseCase>()) {
    captainGetIt.registerLazySingleton<WatchAssignedTripsUseCase>(
      () => WatchAssignedTripsUseCase(captainGetIt<CaptainTripRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<AssignedTripsCubit>()) {
    captainGetIt.registerFactory<AssignedTripsCubit>(
      () => AssignedTripsCubit(
        getAssignedTrips: captainGetIt<GetAssignedTripsUseCase>(),
        watchAssignedTrips: captainGetIt<WatchAssignedTripsUseCase>(),
      ),
    );
  }
}

void _registerPassengerManifestDependencies() {
  if (!captainGetIt.isRegistered<PassengerManifestDataSource>()) {
    captainGetIt.registerLazySingleton<PassengerManifestDataSource>(
      () => PassengerManifestDataSource(captainGetIt()),
    );
  }
  if (!captainGetIt.isRegistered<PassengerManifestRepository>()) {
    captainGetIt.registerLazySingleton<PassengerManifestRepository>(
      () => PassengerManifestRepositoryImpl(
        captainGetIt<PassengerManifestDataSource>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<GetTripPassengersUseCase>()) {
    captainGetIt.registerLazySingleton<GetTripPassengersUseCase>(
      () =>
          GetTripPassengersUseCase(captainGetIt<PassengerManifestRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<WatchTripPassengersUseCase>()) {
    captainGetIt.registerLazySingleton<WatchTripPassengersUseCase>(
      () => WatchTripPassengersUseCase(
        captainGetIt<PassengerManifestRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<UpdatePassengerStatusUseCase>()) {
    captainGetIt.registerLazySingleton<UpdatePassengerStatusUseCase>(
      () => UpdatePassengerStatusUseCase(
        captainGetIt<PassengerManifestRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<PassengerManifestCubit>()) {
    captainGetIt.registerFactory<PassengerManifestCubit>(
      () => PassengerManifestCubit(
        getTripPassengers: captainGetIt<GetTripPassengersUseCase>(),
        watchTripPassengers: captainGetIt<WatchTripPassengersUseCase>(),
        updatePassengerStatus: captainGetIt<UpdatePassengerStatusUseCase>(),
      ),
    );
  }
}

void _registerTripExecutionDependencies() {
  if (!captainGetIt.isRegistered<TripExecutionDataSource>()) {
    captainGetIt.registerLazySingleton<TripExecutionDataSource>(
      () => TripExecutionDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<TripExecutionRepository>()) {
    captainGetIt.registerLazySingleton<TripExecutionRepository>(
      () =>
          TripExecutionRepositoryImpl(captainGetIt<TripExecutionDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<StartTripUseCase>()) {
    captainGetIt.registerLazySingleton<StartTripUseCase>(
      () => StartTripUseCase(captainGetIt<TripExecutionRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<CompleteTripUseCase>()) {
    captainGetIt.registerLazySingleton<CompleteTripUseCase>(
      () => CompleteTripUseCase(captainGetIt<TripExecutionRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<StartBoardingUseCase>()) {
    captainGetIt.registerLazySingleton<StartBoardingUseCase>(
      () => StartBoardingUseCase(captainGetIt<TripExecutionRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<WatchTripExecutionStatusUseCase>()) {
    captainGetIt.registerLazySingleton<WatchTripExecutionStatusUseCase>(
      () => WatchTripExecutionStatusUseCase(
        captainGetIt<TripExecutionRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<TripExecutionCubit>()) {
    captainGetIt.registerFactory<TripExecutionCubit>(
      () => TripExecutionCubit(
        startBoarding: captainGetIt<StartBoardingUseCase>(),
        startTrip: captainGetIt<StartTripUseCase>(),
        completeTrip: captainGetIt<CompleteTripUseCase>(),
        watchTripStatus: captainGetIt<WatchTripExecutionStatusUseCase>(),
      ),
    );
  }
}

void _registerLiveLocationDependencies() {
  if (!captainGetIt.isRegistered<LocationDatasource>()) {
    captainGetIt.registerLazySingleton<LocationDatasource>(
      () => SupabaseLocationDatasource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<LocationRepository>()) {
    captainGetIt.registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(captainGetIt<LocationDatasource>()),
    );
  }
  if (!captainGetIt.isRegistered<SendLocationUpdateUseCase>()) {
    captainGetIt.registerLazySingleton<SendLocationUpdateUseCase>(
      () => SendLocationUpdateUseCase(captainGetIt<LocationRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<LiveLocationCubit>()) {
    captainGetIt.registerFactory<LiveLocationCubit>(
      () => LiveLocationCubit(
        sendLocation: captainGetIt<SendLocationUpdateUseCase>(),
      ),
    );
  }
}

void _registerCommunicationDependencies() {
  if (!captainGetIt.isRegistered<ChatDatasource>()) {
    captainGetIt.registerLazySingleton<ChatDatasource>(
      () => SupabaseChatDatasource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<CommunicationRepository>()) {
    captainGetIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(captainGetIt<ChatDatasource>()),
    );
  }
  if (!captainGetIt.isRegistered<GetConversationUseCase>()) {
    captainGetIt.registerLazySingleton<GetConversationUseCase>(
      () => GetConversationUseCase(captainGetIt<CommunicationRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<SendMessageUseCase>()) {
    captainGetIt.registerLazySingleton<SendMessageUseCase>(
      () => SendMessageUseCase(captainGetIt<CommunicationRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<CaptainCommunicationCubit>()) {
    captainGetIt.registerFactory<CaptainCommunicationCubit>(
      () => CaptainCommunicationCubit(
        getConversation: captainGetIt<GetConversationUseCase>(),
        sendMessage: captainGetIt<SendMessageUseCase>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<CaptainNotificationCubit>()) {
    captainGetIt.registerLazySingleton<CaptainNotificationCubit>(
      () => CaptainNotificationCubit(captainGetIt<CommunicationRepository>()),
    );
  }
}

void _registerIncidentsDependencies() {
  if (!captainGetIt.isRegistered<IncidentDatasource>()) {
    captainGetIt.registerLazySingleton<IncidentDatasource>(
      () => SupabaseIncidentDatasource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<IncidentRepository>()) {
    captainGetIt.registerLazySingleton<IncidentRepository>(
      () => IncidentRepositoryImpl(captainGetIt<IncidentDatasource>()),
    );
  }
  if (!captainGetIt.isRegistered<ReportIncidentUseCase>()) {
    captainGetIt.registerLazySingleton<ReportIncidentUseCase>(
      () => ReportIncidentUseCase(captainGetIt<IncidentRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<IncidentCubit>()) {
    captainGetIt.registerFactory<IncidentCubit>(
      () => IncidentCubit(captainGetIt<ReportIncidentUseCase>()),
    );
  }
}

void _registerCheckInDependencies() {
  if (!captainGetIt.isRegistered<CheckInDataSource>()) {
    captainGetIt.registerLazySingleton<CheckInDataSource>(
      () => CheckInDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<CheckInRepository>()) {
    captainGetIt.registerLazySingleton<CheckInRepository>(
      () => CheckInRepositoryImpl(captainGetIt<CheckInDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<CheckPassengerUseCase>()) {
    captainGetIt.registerLazySingleton<CheckPassengerUseCase>(
      () => CheckPassengerUseCase(captainGetIt<CheckInRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<CheckInCubit>()) {
    captainGetIt.registerFactory<CheckInCubit>(
      () => CheckInCubit(
        captainGetIt<CheckPassengerUseCase>(),
        captainGetIt<CheckInRepository>(),
      ),
    );
  }
}

void _registerTripStatusUpdateDependencies() {
  if (!captainGetIt.isRegistered<TripStatusDataSource>()) {
    captainGetIt.registerLazySingleton<TripStatusDataSource>(
      () => TripStatusDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<TripStatusRepository>()) {
    captainGetIt.registerLazySingleton<TripStatusRepository>(
      () => TripStatusRepositoryImpl(captainGetIt<TripStatusDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<status_updates.UpdateTripStatusUseCase>()) {
    captainGetIt.registerLazySingleton<status_updates.UpdateTripStatusUseCase>(
      () => status_updates.UpdateTripStatusUseCase(
        captainGetIt<TripStatusRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<TripStatusUpdateCubit>()) {
    captainGetIt.registerFactory<TripStatusUpdateCubit>(
      () => TripStatusUpdateCubit(
        captainGetIt<status_updates.UpdateTripStatusUseCase>(),
      ),
    );
  }
}

void _registerNotificationsDependencies() {
  if (!captainGetIt.isRegistered<CaptainNotificationsDatasource>()) {
    captainGetIt.registerLazySingleton<CaptainNotificationsDatasource>(
      () => SupabaseCaptainNotificationsDatasource(
        captainGetIt<SupabaseClient>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<CaptainNotificationsRepository>()) {
    captainGetIt.registerLazySingleton<CaptainNotificationsRepository>(
      () => CaptainNotificationsRepositoryImpl(
        captainGetIt<CaptainNotificationsDatasource>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<WatchCaptainNotificationsUseCase>()) {
    captainGetIt.registerLazySingleton<WatchCaptainNotificationsUseCase>(
      () => WatchCaptainNotificationsUseCase(
        captainGetIt<CaptainNotificationsRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<WatchCaptainUnreadCountUseCase>()) {
    captainGetIt.registerLazySingleton<WatchCaptainUnreadCountUseCase>(
      () => WatchCaptainUnreadCountUseCase(
        captainGetIt<CaptainNotificationsRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<MarkCaptainNotificationReadUseCase>()) {
    captainGetIt.registerLazySingleton<MarkCaptainNotificationReadUseCase>(
      () => MarkCaptainNotificationReadUseCase(
        captainGetIt<CaptainNotificationsRepository>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<MarkAllCaptainNotificationsReadUseCase>()) {
    captainGetIt.registerLazySingleton<MarkAllCaptainNotificationsReadUseCase>(
      () => MarkAllCaptainNotificationsReadUseCase(
        captainGetIt<CaptainNotificationsRepository>(),
      ),
    );
  }
  // Singleton badge cubit — always alive.
  if (!captainGetIt.isRegistered<CaptainNotificationBadgeCubit>()) {
    captainGetIt.registerLazySingleton<CaptainNotificationBadgeCubit>(
      () => CaptainNotificationBadgeCubit(
        captainGetIt<WatchCaptainUnreadCountUseCase>(),
      ),
    );
  }
  if (!captainGetIt.isRegistered<CaptainNotificationsCubit>()) {
    captainGetIt.registerFactory<CaptainNotificationsCubit>(
      () => CaptainNotificationsCubit(
        watchNotifications: captainGetIt<WatchCaptainNotificationsUseCase>(),
        markAsRead: captainGetIt<MarkCaptainNotificationReadUseCase>(),
        markAllAsRead: captainGetIt<MarkAllCaptainNotificationsReadUseCase>(),
      ),
    );
  }
}

void _registerProfileDependencies() {
  if (!captainGetIt.isRegistered<DriverProfileDataSource>()) {
    captainGetIt.registerLazySingleton<DriverProfileDataSource>(
      () => DriverProfileDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<DriverProfileRepository>()) {
    captainGetIt.registerLazySingleton<DriverProfileRepository>(
      () =>
          DriverProfileRepositoryImpl(captainGetIt<DriverProfileDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<GetDriverProfileUseCase>()) {
    captainGetIt.registerLazySingleton<GetDriverProfileUseCase>(
      () => GetDriverProfileUseCase(captainGetIt<DriverProfileRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<DriverProfileCubit>()) {
    captainGetIt.registerFactory<DriverProfileCubit>(
      () => DriverProfileCubit(captainGetIt<GetDriverProfileUseCase>()),
    );
  }
}

void _registerTripHistoryDependencies() {
  if (!captainGetIt.isRegistered<TripHistoryDataSource>()) {
    captainGetIt.registerLazySingleton<TripHistoryDataSource>(
      () => TripHistoryDataSource(captainGetIt<SupabaseClient>()),
    );
  }
  if (!captainGetIt.isRegistered<TripHistoryRepository>()) {
    captainGetIt.registerLazySingleton<TripHistoryRepository>(
      () => TripHistoryRepositoryImpl(captainGetIt<TripHistoryDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<GetTripHistoryUseCase>()) {
    captainGetIt.registerLazySingleton<GetTripHistoryUseCase>(
      () => GetTripHistoryUseCase(captainGetIt<TripHistoryRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<TripHistoryCubit>()) {
    captainGetIt.registerFactory<TripHistoryCubit>(
      () => TripHistoryCubit(captainGetIt<GetTripHistoryUseCase>()),
    );
  }
}
