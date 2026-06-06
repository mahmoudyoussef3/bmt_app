import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/data/datasources/captain_trip_remote_datasource.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/data/repositories/captain_trip_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/usecases/get_assigned_trips_usecase.dart';
import 'package:bmt_app/apps/captain/features/check_in/data/datasources/check_in_datasource.dart';
import 'package:bmt_app/apps/captain/features/check_in/data/repositories/check_in_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/check_in/domain/entities/check_in_result.dart';
import 'package:bmt_app/apps/captain/features/check_in/domain/usecases/check_passenger_usecase.dart';
import 'package:bmt_app/apps/captain/features/communication/data/datasources/chat_datasource.dart';
import 'package:bmt_app/apps/captain/features/communication/data/repositories/communication_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/entities/conversation.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/usecases/get_conversation_usecase.dart';
import 'package:bmt_app/apps/captain/features/communication/domain/usecases/send_message_usecase.dart';
import 'package:bmt_app/apps/captain/features/incidents/data/datasources/incident_datasource.dart';
import 'package:bmt_app/apps/captain/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/usecases/report_incident_usecase.dart';
import 'package:bmt_app/apps/captain/features/live_location/data/datasources/location_datasource.dart';
import 'package:bmt_app/apps/captain/features/live_location/data/repositories/location_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/live_location/domain/usecases/start_location_sharing_usecase.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/data/datasources/passenger_manifest_datasource.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/data/repositories/passenger_manifest_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/usecases/get_trip_passengers_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/data/datasources/trip_execution_datasource.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/data/repositories/trip_execution_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/entities/trip_execution_state.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/domain/usecases/start_trip_usecase.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/data/datasources/trip_status_datasource.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/data/repositories/trip_status_repository_impl.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/domain/entities/captain_trip_status.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/domain/usecases/update_trip_status_usecase.dart';

void main() {
  group('Captain clean feature modules', () {
    test('assigned trips returns customer-service assigned trips', () async {
      final repository = CaptainTripRepositoryImpl(
        const CaptainTripRemoteDataSource(),
      );
      final trips = await GetAssignedTripsUseCase(repository)();

      expect(trips, hasLength(2));
      expect(trips.first.route, 'Banha → Smart Village');
      expect(trips.first.passengerCount, 9);
    });

    test('passenger manifest returns passengers for current trip', () async {
      final repository = PassengerManifestRepositoryImpl(
        const PassengerManifestDataSource(),
      );
      final passengers = await GetTripPassengersUseCase(repository)('t1');

      expect(passengers, hasLength(9));
      expect(passengers.first.seat, '1');
    });

    test('trip execution starts the assigned trip', () async {
      final repository = TripExecutionRepositoryImpl(
        const TripExecutionDataSource(),
      );
      final result = await StartTripUseCase(repository)('t1');

      expect(result.status, TripExecutionStatus.inProgress);
    });

    test('live location starts sharing current trip location', () async {
      final repository = LocationRepositoryImpl(const LocationDataSource());
      final result = await StartLocationSharingUseCase(repository)('t1');

      expect(result.enabled, isTrue);
    });

    test('communication supports broadcast and passenger messages', () async {
      final repository = CommunicationRepositoryImpl(const ChatDataSource());
      final broadcast = await GetConversationUseCase(repository)(tripId: 't1');
      final passenger = await SendMessageUseCase(repository)(
        tripId: 't1',
        passengerId: 'p1',
        text: 'Arriving now',
        type: CaptainMessageType.text,
      );

      expect(broadcast.broadcast, isTrue);
      expect(passenger.passengerId, 'p1');
      expect(passenger.messages.last.text, 'Arriving now');
    });

    test('incidents submits captain report', () async {
      final repository = IncidentRepositoryImpl(const IncidentDataSource());
      final result = await ReportIncidentUseCase(repository)(
        const IncidentReport(
          tripId: 't1',
          type: IncidentType.delay,
          description: 'Traffic delay',
        ),
      );

      expect(result.type, IncidentType.delay);
    });

    test('check-in records boarding status', () async {
      final repository = CheckInRepositoryImpl(const CheckInDataSource());
      final result = await CheckPassengerUseCase(repository)(
        tripId: 't1',
        passengerId: 'p1',
        status: CheckInStatus.boarded,
      );

      expect(result.status, CheckInStatus.boarded);
    });

    test('trip status updates notify current trip status', () async {
      final repository = TripStatusRepositoryImpl(const TripStatusDataSource());
      final result = await UpdateTripStatusUseCase(repository)(
        't1',
        CaptainTripStatus.boarding,
      );

      expect(result.status, CaptainTripStatus.boarding);
    });
  });
}
