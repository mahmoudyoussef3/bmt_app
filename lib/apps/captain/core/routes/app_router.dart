import 'package:bmt_app/apps/captain/modules/trips/trip_execution/presentation/pages/trip_execution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_routes.dart';

// Cubits
import 'package:bmt_app/apps/captain/modules/trips/trip_execution/presentation/cubit/trip_execution_cubit.dart';
import 'package:bmt_app/apps/captain/modules/passengers/passenger_manifest/presentation/cubit/passenger_manifest_cubit.dart';
import 'package:bmt_app/apps/captain/modules/passengers/check_in/presentation/cubit/check_in_cubit.dart';
import 'package:bmt_app/apps/captain/modules/operations/communication/presentation/cubit/communication_cubit.dart';
import 'package:bmt_app/apps/captain/modules/operations/incidents/presentation/cubit/incident_cubit.dart';
import 'package:bmt_app/apps/captain/modules/operations/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/apps/captain/modules/notifications/notifications/presentation/cubit/captain_notifications_cubit.dart';
import 'package:bmt_app/apps/captain/modules/tracking/live_location/presentation/cubit/live_location_cubit.dart';
import 'package:bmt_app/apps/captain/modules/trips/trip_status_updates/presentation/cubit/trip_status_update_cubit.dart';

// Screens / Pages
import 'package:bmt_app/apps/captain/modules/passengers/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/modules/passengers/check_in/presentation/pages/check_in_page.dart';
import 'package:bmt_app/apps/captain/modules/operations/communication/presentation/pages/chats_page.dart';
import 'package:bmt_app/apps/captain/modules/operations/incidents/presentation/pages/report_incident_page.dart';
import 'package:bmt_app/apps/captain/modules/notifications/notifications/presentation/pages/captain_notifications_page.dart';
import 'package:bmt_app/apps/captain/modules/tracking/live_location/presentation/pages/live_location_page.dart';
import 'package:bmt_app/apps/captain/modules/trips/trip_status_updates/presentation/pages/status_update_page.dart';

import 'package:bmt_app/apps/captain/modules/trips/assigned_trips/domain/entities/assigned_trip.dart';

class AppRouter {
  static Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case CaptainRoutes.tripExecution:
        final trip = settings.arguments as AssignedTrip;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<TripExecutionCubit>(),
            child: TripExecutionPage(trip: trip),
          ),
        );
      case CaptainRoutes.passengerManifest:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<PassengerManifestCubit>()..load(tripId),
            child: PassengerListPage(tripId: tripId),
          ),
        );
      case CaptainRoutes.checkIn:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<CheckInCubit>(),
            child: CheckInPage(tripId: tripId),
          ),
        );
      case CaptainRoutes.communication:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<CaptainCommunicationCubit>(),
            child: ChatsPage(tripId: tripId),
          ),
        );
      case CaptainRoutes.incidents:
        String tripId;
        IncidentType? type;
        if (settings.arguments is Map) {
          final args = settings.arguments as Map;
          tripId = args['tripId'] as String;
          type = args['initialType'] as IncidentType?;
        } else {
          tripId = settings.arguments as String;
        }
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<IncidentCubit>(),
            child: ReportIncidentPage(
              tripId: tripId,
              initialType: type ?? IncidentType.delay,
            ),
          ),
        );
      case CaptainRoutes.liveLocation:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<LiveLocationCubit>(),
            child: LiveLocationPage(tripId: tripId),
          ),
        );
      case CaptainRoutes.statusUpdate:
        final tripId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<TripStatusUpdateCubit>(),
            child: StatusUpdatePage(tripId: tripId),
          ),
        );
      case CaptainRoutes.notifications:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => captainGetIt<CaptainNotificationsCubit>(),
            child: const CaptainNotificationsPage(),
          ),
        );
      default:
        return null;
    }
  }
}
