import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/auth/presentation/screens/captain_request_access_screen.dart';
import 'package:bmt_app/apps/captain/features/check_in/presentation/pages/check_in_page.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chat_details_page.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chats_page.dart';
import 'package:bmt_app/apps/captain/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/pages/live_location_page.dart';
import 'package:bmt_app/apps/captain/features/notifications/presentation/pages/captain_notifications_page.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/pages/trip_execution_page.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/presentation/pages/status_update_page.dart';

import 'captain_app_shell.dart';
import 'captain_route_args.dart';
import 'captain_routes.dart';

/// Builds a screen for every captain route name.
///
/// This is the one place that casts `settings.arguments` back to a type. Every
/// call site goes through the `CaptainNav` extension instead, which is typed —
/// so a wrong argument is a compile error there rather than a cast failure
/// here.
///
/// Screens keep providing their own cubits. The playbook wires `BlocProvider`
/// in the router, but these pages already self-provide (each is reachable both
/// as a route and, in a couple of cases, hosted inline by the auth gate);
/// moving that wiring is a presentation refactor, not routing.
class CaptainAppRouter {
  const CaptainAppRouter._();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    return switch (settings.name) {
      CaptainRoutes.home => _page(settings, const CaptainAppShell()),

      CaptainRoutes.requestAccess => _page(
        settings,
        const CaptainRequestAccessScreen(),
      ),

      CaptainRoutes.notifications => _page(
        settings,
        const CaptainNotificationsPage(),
      ),

      CaptainRoutes.tripExecution => _page(
        settings,
        TripExecutionPage(trip: args! as AssignedTrip),
      ),

      CaptainRoutes.passengerManifest => _page(
        settings,
        PassengerListPage(tripId: args! as String),
      ),

      CaptainRoutes.checkIn => _page(
        settings,
        CheckInPage(tripId: args! as String),
      ),

      CaptainRoutes.locationUpdate => _page(
        settings,
        LocationUpdatePage(tripId: args! as String),
      ),

      CaptainRoutes.chats => _page(
        settings,
        ChatsPage(tripId: args! as String),
      ),

      CaptainRoutes.statusUpdate => _page(
        settings,
        StatusUpdatePage(tripId: args! as String),
      ),

      CaptainRoutes.chatDetails => _buildChatDetails(
        settings,
        args! as ChatDetailsArgs,
      ),

      CaptainRoutes.reportIncident => _buildReportIncident(
        settings,
        args! as ReportIncidentArgs,
      ),

      _ => null,
    };
  }

  static Route<dynamic> _buildChatDetails(
    RouteSettings settings,
    ChatDetailsArgs args,
  ) {
    return _page(
      settings,
      ChatDetailsPage(
        tripId: args.tripId,
        title: args.title,
        passengerId: args.passengerId,
      ),
    );
  }

  static Route<dynamic> _buildReportIncident(
    RouteSettings settings,
    ReportIncidentArgs args,
  ) {
    return _page(
      settings,
      ReportIncidentPage(tripId: args.tripId, initialType: args.initialType),
    );
  }

  static Route<dynamic> _page(RouteSettings settings, Widget child) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}
