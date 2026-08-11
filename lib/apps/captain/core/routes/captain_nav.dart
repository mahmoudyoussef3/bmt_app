import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';

import 'captain_route_args.dart';
import 'captain_routes.dart';

extension CaptainNav on BuildContext {
  Future<T?> _push<T>(String route, [Object? arguments]) =>
      Navigator.of(this).pushNamed<T>(route, arguments: arguments);

  void closeScreen() => Navigator.of(this).maybePop();

  Future<void> openTripExecution(AssignedTrip trip) =>
      _push<void>(CaptainRoutes.tripExecution, trip);

  Future<void> openTripMap(AssignedTrip trip) =>
      _push<void>(CaptainRoutes.tripMap, trip);

  Future<void> openPassengerManifest(String tripId) =>
      _push<void>(CaptainRoutes.passengerManifest, tripId);

  Future<void> openLocationUpdate(String tripId) =>
      _push<void>(CaptainRoutes.locationUpdate, tripId);

  Future<void> openStatusUpdate(String tripId) =>
      _push<void>(CaptainRoutes.statusUpdate, tripId);

  Future<void> openNotifications() => _push<void>(CaptainRoutes.notifications);

  Future<void> openRequestAccess() => _push<void>(CaptainRoutes.requestAccess);

  Future<void> openTripHistoryDetail(TripHistoryItem trip) =>
      _push<void>(CaptainRoutes.tripHistoryDetail, trip);

  Future<void> openReportIncident(
    String tripId, {
    IncidentType initialType = IncidentType.delay,
  }) => _push<void>(
    CaptainRoutes.reportIncident,
    ReportIncidentArgs(tripId: tripId, initialType: initialType),
  );
}
