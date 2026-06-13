import '../../../../core/network/network_di.dart';
import 'package:get_it/get_it.dart';

import '../../features/assigned_trips/data/datasources/captain_trip_remote_datasource.dart';
import '../../features/assigned_trips/data/repositories/captain_trip_repository_impl.dart';
import '../../features/assigned_trips/domain/repositories/captain_trip_repository.dart';
import '../../features/assigned_trips/domain/usecases/get_assigned_trips_usecase.dart';
import '../../features/assigned_trips/presentation/cubit/assigned_trips_cubit.dart';
import '../../features/check_in/data/datasources/check_in_datasource.dart';
import '../../features/check_in/data/repositories/check_in_repository_impl.dart';
import '../../features/check_in/domain/repositories/check_in_repository.dart';
import '../../features/check_in/domain/usecases/check_passenger_usecase.dart';
import '../../features/check_in/presentation/cubit/check_in_cubit.dart';
import '../../features/communication/data/datasources/chat_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/get_conversation_usecase.dart';
import '../../features/communication/domain/usecases/send_message_usecase.dart';
import '../../features/communication/presentation/cubit/communication_cubit.dart';
import '../../features/incidents/data/datasources/incident_datasource.dart';
import '../../features/incidents/data/repositories/incident_repository_impl.dart';
import '../../features/incidents/domain/repositories/incident_repository.dart';
import '../../features/incidents/domain/usecases/report_incident_usecase.dart';
import '../../features/incidents/presentation/cubit/incident_cubit.dart';
import '../../features/live_location/data/datasources/location_datasource.dart';
import '../../features/live_location/data/repositories/location_repository_impl.dart';
import '../../features/live_location/domain/repositories/location_repository.dart';
import '../../features/live_location/domain/usecases/start_location_sharing_usecase.dart';
import '../../features/live_location/domain/usecases/stop_location_sharing_usecase.dart';
import '../../features/live_location/presentation/cubit/live_location_cubit.dart';
import '../../features/passenger_manifest/data/datasources/passenger_manifest_datasource.dart';
import '../../features/passenger_manifest/data/repositories/passenger_manifest_repository_impl.dart';
import '../../features/passenger_manifest/domain/repositories/passenger_manifest_repository.dart';
import '../../features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import '../../features/passenger_manifest/presentation/cubit/passenger_manifest_cubit.dart';
import '../../features/trip_execution/data/datasources/trip_execution_datasource.dart';
import '../../features/trip_execution/data/repositories/trip_execution_repository_impl.dart';
import '../../features/trip_execution/domain/repositories/trip_execution_repository.dart';
import '../../features/trip_execution/domain/usecases/complete_trip_usecase.dart';
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
  // Register Core Networking (Dio, Retrofit ApiService)
  registerNetworkDependencies(captainGetIt);

  _registerAssignedTripsDependencies();
  _registerPassengerManifestDependencies();
  _registerTripExecutionDependencies();
  _registerLiveLocationDependencies();
  _registerCommunicationDependencies();
  _registerIncidentsDependencies();
  _registerCheckInDependencies();
  _registerTripStatusUpdateDependencies();
}

void _registerAssignedTripsDependencies() {
  if (!captainGetIt.isRegistered<CaptainTripRemoteDataSource>()) {
    captainGetIt.registerLazySingleton<CaptainTripRemoteDataSource>(
      () => const CaptainTripRemoteDataSource(),
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
  if (!captainGetIt.isRegistered<AssignedTripsCubit>()) {
    captainGetIt.registerFactory<AssignedTripsCubit>(
      () => AssignedTripsCubit(captainGetIt<GetAssignedTripsUseCase>()),
    );
  }
}

void _registerPassengerManifestDependencies() {
  if (!captainGetIt.isRegistered<PassengerManifestDataSource>()) {
    captainGetIt.registerLazySingleton<PassengerManifestDataSource>(
      () => const PassengerManifestDataSource(),
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
  if (!captainGetIt.isRegistered<PassengerManifestCubit>()) {
    captainGetIt.registerFactory<PassengerManifestCubit>(
      () => PassengerManifestCubit(captainGetIt<GetTripPassengersUseCase>()),
    );
  }
}

void _registerTripExecutionDependencies() {
  if (!captainGetIt.isRegistered<TripExecutionDataSource>()) {
    captainGetIt.registerLazySingleton<TripExecutionDataSource>(
      () => const TripExecutionDataSource(),
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
  if (!captainGetIt.isRegistered<TripExecutionCubit>()) {
    captainGetIt.registerFactory<TripExecutionCubit>(
      () => TripExecutionCubit(
        startTrip: captainGetIt<StartTripUseCase>(),
        completeTrip: captainGetIt<CompleteTripUseCase>(),
      ),
    );
  }
}

void _registerLiveLocationDependencies() {
  if (!captainGetIt.isRegistered<LocationDataSource>()) {
    captainGetIt.registerLazySingleton<LocationDataSource>(
      () => const LocationDataSource(),
    );
  }
  if (!captainGetIt.isRegistered<LocationRepository>()) {
    captainGetIt.registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(captainGetIt<LocationDataSource>()),
    );
  }
  if (!captainGetIt.isRegistered<StartLocationSharingUseCase>()) {
    captainGetIt.registerLazySingleton<StartLocationSharingUseCase>(
      () => StartLocationSharingUseCase(captainGetIt<LocationRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<StopLocationSharingUseCase>()) {
    captainGetIt.registerLazySingleton<StopLocationSharingUseCase>(
      () => StopLocationSharingUseCase(captainGetIt<LocationRepository>()),
    );
  }
  if (!captainGetIt.isRegistered<LiveLocationCubit>()) {
    captainGetIt.registerFactory<LiveLocationCubit>(
      () => LiveLocationCubit(
        startSharing: captainGetIt<StartLocationSharingUseCase>(),
        stopSharing: captainGetIt<StopLocationSharingUseCase>(),
      ),
    );
  }
}

void _registerCommunicationDependencies() {
  if (!captainGetIt.isRegistered<ChatDataSource>()) {
    captainGetIt.registerLazySingleton<ChatDataSource>(
      () => const ChatDataSource(),
    );
  }
  if (!captainGetIt.isRegistered<CommunicationRepository>()) {
    captainGetIt.registerLazySingleton<CommunicationRepository>(
      () => CommunicationRepositoryImpl(captainGetIt<ChatDataSource>()),
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
}

void _registerIncidentsDependencies() {
  if (!captainGetIt.isRegistered<IncidentDataSource>()) {
    captainGetIt.registerLazySingleton<IncidentDataSource>(
      () => const IncidentDataSource(),
    );
  }
  if (!captainGetIt.isRegistered<IncidentRepository>()) {
    captainGetIt.registerLazySingleton<IncidentRepository>(
      () => IncidentRepositoryImpl(captainGetIt<IncidentDataSource>()),
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
      () => const CheckInDataSource(),
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
      () => CheckInCubit(captainGetIt<CheckPassengerUseCase>()),
    );
  }
}

void _registerTripStatusUpdateDependencies() {
  if (!captainGetIt.isRegistered<TripStatusDataSource>()) {
    captainGetIt.registerLazySingleton<TripStatusDataSource>(
      () => const TripStatusDataSource(),
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
