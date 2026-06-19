import 'package:bmt_app/apps/dashboard/features/live_trips/data/datasources/live_trips_datasource.dart';
import 'package:bmt_app/apps/dashboard/features/live_trips/domain/entities/live_trip.dart';

class FakeLiveTripsDatasource implements LiveTripsDatasource {
  FakeLiveTripsDatasource() {
    _trips = _seedTrips();
  }

  late List<LiveTrip> _trips;

  @override
  Future<List<LiveTrip>> getLiveTrips() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List<LiveTrip>.from(_trips);
  }

  @override
  Future<LiveTrip> getLiveTripDetails(String tripId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _findTrip(tripId);
  }

  @override
  Future<LiveTrip> startTrip(String tripId) async {
    final trip = _findTrip(tripId);
    final updatedPoints = trip.routePoints.asMap().entries.map((entry) {
      if (entry.key == 0) {
        return entry.value.copyWith(status: LivePointStatus.current);
      }
      return entry.value.copyWith(status: LivePointStatus.pending);
    }).toList();

    return _replaceTrip(
      trip.copyWith(
        status: LiveTripStatus.inProgress,
        health: LiveTripHealth.normal,
        actualStartTime: DateTime.now(),
        currentPointIndex: 0,
        progressPercent: 5,
        routePoints: updatedPoints,
      ),
    );
  }

  @override
  Future<LiveTrip> pauseTrip(String tripId) async {
    final trip = _findTrip(tripId);
    return _replaceTrip(trip.copyWith(status: LiveTripStatus.paused));
  }

  @override
  Future<LiveTrip> resumeTrip(String tripId) async {
    final trip = _findTrip(tripId);
    return _replaceTrip(trip.copyWith(status: LiveTripStatus.inProgress));
  }

  @override
  Future<LiveTrip> completeTrip(String tripId) async {
    final trip = _findTrip(tripId);
    final updatedPoints = trip.routePoints
        .map((point) => point.copyWith(status: LivePointStatus.completed))
        .toList();

    return _replaceTrip(
      trip.copyWith(
        status: LiveTripStatus.completed,
        health: LiveTripHealth.normal,
        progressPercent: 100,
        currentPointIndex: trip.routePoints.length - 1,
        routePoints: updatedPoints,
      ),
    );
  }

  @override
  Future<LiveTrip> markPointArrived(String tripId, String pointId) async {
    final trip = _findTrip(tripId);
    final pointIndex = trip.routePoints.indexWhere((p) => p.id == pointId);
    if (pointIndex == -1) throw Exception('المحطة غير موجودة');

    final updatedPoints = trip.routePoints.asMap().entries.map((entry) {
      if (entry.value.id == pointId) {
        return entry.value.copyWith(
          status: LivePointStatus.arrived,
          actualArrivalTime: DateTime.now(),
        );
      }
      return entry.value;
    }).toList();

    return _replaceTrip(
      trip.copyWith(
        routePoints: updatedPoints,
        currentPointIndex: pointIndex,
        progressPercent: _calculateProgress(
          pointIndex,
          trip.routePoints.length,
        ),
      ),
    );
  }

  @override
  Future<LiveTrip> markPointCompleted(String tripId, String pointId) async {
    final trip = _findTrip(tripId);
    final pointIndex = trip.routePoints.indexWhere((p) => p.id == pointId);
    if (pointIndex == -1) throw Exception('المحطة غير موجودة');

    final nextIndex = (pointIndex + 1).clamp(0, trip.routePoints.length - 1);

    final updatedPoints = trip.routePoints.asMap().entries.map((entry) {
      if (entry.key == pointIndex) {
        return entry.value.copyWith(status: LivePointStatus.completed);
      }
      if (entry.key == nextIndex && entry.key != pointIndex) {
        return entry.value.copyWith(status: LivePointStatus.current);
      }
      return entry.value;
    }).toList();

    final completed = pointIndex == trip.routePoints.length - 1;

    return _replaceTrip(
      trip.copyWith(
        routePoints: updatedPoints,
        currentPointIndex: nextIndex,
        progressPercent: completed
            ? 100
            : _calculateProgress(nextIndex, trip.routePoints.length),
        status: completed ? LiveTripStatus.completed : trip.status,
      ),
    );
  }

  @override
  Future<LiveTrip> skipPoint(String tripId, String pointId) async {
    final trip = _findTrip(tripId);
    final pointIndex = trip.routePoints.indexWhere((p) => p.id == pointId);
    if (pointIndex == -1) throw Exception('المحطة غير موجودة');

    final nextIndex = (pointIndex + 1).clamp(0, trip.routePoints.length - 1);

    final updatedPoints = trip.routePoints.asMap().entries.map((entry) {
      if (entry.key == pointIndex) {
        return entry.value.copyWith(status: LivePointStatus.skipped);
      }
      if (entry.key == nextIndex && entry.key != pointIndex) {
        return entry.value.copyWith(status: LivePointStatus.current);
      }
      return entry.value;
    }).toList();

    return _replaceTrip(
      trip.copyWith(
        routePoints: updatedPoints,
        currentPointIndex: nextIndex,
        progressPercent: _calculateProgress(nextIndex, trip.routePoints.length),
        health: LiveTripHealth.warning,
        alerts: [
          LiveTripAlert(
            id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
            type: LiveTripAlertType.routeDeviation,
            severity: LiveTripAlertSeverity.warning,
            title: 'تم تخطي محطة',
            message: 'تم تخطي محطة ${trip.routePoints[pointIndex].name}.',
            createdAt: DateTime.now(),
            resolved: false,
          ),
          ...trip.alerts,
        ],
      ),
    );
  }

  @override
  Future<LiveTrip> resolveAlert(String tripId, String alertId) async {
    final trip = _findTrip(tripId);
    final alerts = trip.alerts
        .map(
          (alert) =>
              alert.id == alertId ? alert.copyWith(resolved: true) : alert,
        )
        .toList();

    final hasCritical = alerts.any(
      (alert) =>
          !alert.resolved && alert.severity == LiveTripAlertSeverity.critical,
    );

    return _replaceTrip(
      trip.copyWith(
        alerts: alerts,
        health: hasCritical ? LiveTripHealth.critical : LiveTripHealth.normal,
      ),
    );
  }

  @override
  Future<LiveTrip> reportAlert({
    required String tripId,
    required LiveTripAlertType type,
    required LiveTripAlertSeverity severity,
    required String title,
    required String message,
  }) async {
    final trip = _findTrip(tripId);
    final alert = LiveTripAlert(
      id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      severity: severity,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      resolved: false,
    );

    DateTime? updatedExpectedArrival = trip.expectedArrivalTime;
    if (type == LiveTripAlertType.delay) {
      final reg = RegExp(r'\d+');
      final match = reg.firstMatch(message);
      int delayMins = 15; // default
      if (match != null) {
        delayMins = int.tryParse(match.group(0)!) ?? 15;
      }
      final currentExpected =
          trip.expectedArrivalTime ??
          trip.scheduledStartTime.add(const Duration(hours: 1, minutes: 30));
      updatedExpectedArrival = currentExpected.add(
        Duration(minutes: delayMins),
      );
    }

    return _replaceTrip(
      trip.copyWith(
        alerts: [alert, ...trip.alerts],
        expectedArrivalTime: updatedExpectedArrival,
        health: severity == LiveTripAlertSeverity.critical
            ? LiveTripHealth.critical
            : LiveTripHealth.warning,
      ),
    );
  }

  @override
  Future<String> callDriver(String driverPhone) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return 'تم تجهيز الاتصال بالسائق: $driverPhone';
  }

  @override
  Future<String> sendDriverMessage(String driverPhone, String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return 'تم إرسال رسالة للسائق: $message';
  }

  @override
  Future<LiveTrip> togglePassengerCheckin(
    String tripId,
    String passengerId,
  ) async {
    final trip = _findTrip(tripId);
    final updatedPassengers = trip.passengers.map((p) {
      if (p.id == passengerId) {
        final nextCheckedIn = !p.checkedIn;
        return p.copyWith(
          checkedIn: nextCheckedIn,
          checkedInAt: nextCheckedIn ? DateTime.now() : null,
        );
      }
      return p;
    }).toList();

    final checkedInCount = updatedPassengers.where((p) => p.checkedIn).length;
    final missingCount = updatedPassengers.where((p) => !p.checkedIn).length;

    return _replaceTrip(
      trip.copyWith(
        passengers: updatedPassengers,
        checkedInPassengersCount: checkedInCount,
        missingPassengersCount: missingCount,
      ),
    );
  }

  @override
  Stream<VehiclePosition> watchVehiclePosition(String tripId) async* {
    final trip = _findTrip(tripId);
    final point = trip.routePoints.elementAt(
      trip.currentPointIndex.clamp(0, trip.routePoints.length - 1),
    );
    yield VehiclePosition(
      latitude: point.latitude,
      longitude: point.longitude,
      speed: 8,
      updatedAt: DateTime.now(),
    );
  }

  LiveTrip _findTrip(String tripId) {
    return _trips.firstWhere(
      (trip) => trip.id == tripId,
      orElse: () => throw Exception('الرحلة غير موجودة'),
    );
  }

  LiveTrip _replaceTrip(LiveTrip updatedTrip) {
    _trips = _trips
        .map((trip) => trip.id == updatedTrip.id ? updatedTrip : trip)
        .toList();
    return updatedTrip;
  }

  int _calculateProgress(int currentIndex, int totalPoints) {
    if (totalPoints <= 1) return 0;
    return ((currentIndex / (totalPoints - 1)) * 100).round().clamp(0, 100);
  }

  List<LiveTrip> _seedTrips() {
    final now = DateTime.now();

    return [
      LiveTrip(
        id: 'live-1',
        tripCode: 'TR-1024',
        routeId: 'route-banha-fifth',
        routeName: 'بنها → التجمع الخامس',
        driverId: 'driver-1',
        driverName: 'محمد أحمد',
        driverPhone: '01012345678',
        vehicleId: 'vehicle-1',
        vehiclePlate: 'س ب ج 4821',
        vehicleType: 'Toyota Hiace',
        status: LiveTripStatus.inProgress,
        health: LiveTripHealth.delayed,
        passengersCount: 18,
        checkedInPassengersCount: 15,
        missingPassengersCount: 3,
        progressPercent: 42,
        scheduledStartTime: now.subtract(const Duration(minutes: 40)),
        actualStartTime: now.subtract(const Duration(minutes: 35)),
        expectedArrivalTime: now.add(const Duration(minutes: 52)),
        currentPointIndex: 2,
        routePoints: [
          LiveRoutePoint(
            id: 'p1',
            name: 'بنها',
            latitude: 30.4667,
            longitude: 31.1837,
            order: 1,
            plannedArrivalTime: now.subtract(const Duration(minutes: 40)),
            actualArrivalTime: now.subtract(const Duration(minutes: 35)),
            status: LivePointStatus.completed,
            waitingPassengersCount: 0,
            boardedPassengersCount: 8,
          ),
          LiveRoutePoint(
            id: 'p2',
            name: 'شبرا الخيمة',
            latitude: 30.1241,
            longitude: 31.2609,
            order: 2,
            plannedArrivalTime: now.subtract(const Duration(minutes: 10)),
            actualArrivalTime: now.subtract(const Duration(minutes: 5)),
            status: LivePointStatus.completed,
            waitingPassengersCount: 0,
            boardedPassengersCount: 5,
          ),
          LiveRoutePoint(
            id: 'p3',
            name: 'رمسيس',
            latitude: 30.0626,
            longitude: 31.2460,
            order: 3,
            plannedArrivalTime: now.add(const Duration(minutes: 5)),
            status: LivePointStatus.current,
            waitingPassengersCount: 3,
            boardedPassengersCount: 2,
          ),
          LiveRoutePoint(
            id: 'p4',
            name: 'مدينة نصر',
            latitude: 30.0561,
            longitude: 31.3300,
            order: 4,
            plannedArrivalTime: now.add(const Duration(minutes: 30)),
            status: LivePointStatus.pending,
            waitingPassengersCount: 4,
            boardedPassengersCount: 0,
          ),
          LiveRoutePoint(
            id: 'p5',
            name: 'التجمع الخامس',
            latitude: 30.0284,
            longitude: 31.4913,
            order: 5,
            plannedArrivalTime: now.add(const Duration(minutes: 55)),
            status: LivePointStatus.pending,
            waitingPassengersCount: 0,
            boardedPassengersCount: 0,
          ),
        ],
        alerts: [
          LiveTripAlert(
            id: 'a1',
            type: LiveTripAlertType.delay,
            severity: LiveTripAlertSeverity.warning,
            title: 'تأخير بسيط',
            message: 'الرحلة متأخرة ٨ دقائق بسبب كثافة مرورية عند شبرا.',
            createdAt: now.subtract(const Duration(minutes: 8)),
            resolved: false,
          ),
        ],
        passengers: [
          LivePassengerCheckin(
            id: 'ps1',
            passengerName: 'أحمد محمد',
            passengerPhone: '01000000001',
            pickupPointName: 'بنها',
            checkedIn: true,
            checkedInAt: now.subtract(const Duration(minutes: 34)),
          ),
          LivePassengerCheckin(
            id: 'ps2',
            passengerName: 'محمود علي',
            passengerPhone: '01000000002',
            pickupPointName: 'رمسيس',
            checkedIn: false,
          ),
          LivePassengerCheckin(
            id: 'ps3',
            passengerName: 'سارة حسن',
            passengerPhone: '01000000003',
            pickupPointName: 'مدينة نصر',
            checkedIn: false,
          ),
        ],
      ),
      LiveTrip(
        id: 'live-2',
        tripCode: 'TR-1025',
        routeId: 'route-maadi-smart',
        routeName: 'المعادي → سمارت فيلدج',
        driverId: 'driver-2',
        driverName: 'أحمد سمير',
        driverPhone: '01122223333',
        vehicleId: 'vehicle-2',
        vehiclePlate: 'ق ل م 7391',
        vehicleType: 'Mercedes Sprinter',
        status: LiveTripStatus.preparing,
        health: LiveTripHealth.normal,
        passengersCount: 12,
        checkedInPassengersCount: 0,
        missingPassengersCount: 0,
        progressPercent: 0,
        scheduledStartTime: now.add(const Duration(minutes: 20)),
        expectedArrivalTime: now.add(const Duration(hours: 1, minutes: 30)),
        currentPointIndex: 0,
        routePoints: [
          LiveRoutePoint(
            id: 'm1',
            name: 'المعادي',
            latitude: 29.9602,
            longitude: 31.2569,
            order: 1,
            plannedArrivalTime: now.add(const Duration(minutes: 20)),
            status: LivePointStatus.pending,
            waitingPassengersCount: 6,
            boardedPassengersCount: 0,
          ),
          LiveRoutePoint(
            id: 'm2',
            name: 'ميدان لبنان',
            latitude: 30.0589,
            longitude: 31.2000,
            order: 2,
            plannedArrivalTime: now.add(const Duration(minutes: 45)),
            status: LivePointStatus.pending,
            waitingPassengersCount: 4,
            boardedPassengersCount: 0,
          ),
          LiveRoutePoint(
            id: 'm3',
            name: 'سمارت فيلدج',
            latitude: 30.0714,
            longitude: 30.9424,
            order: 3,
            plannedArrivalTime: now.add(const Duration(hours: 1, minutes: 30)),
            status: LivePointStatus.pending,
            waitingPassengersCount: 0,
            boardedPassengersCount: 0,
          ),
        ],
        alerts: const [],
        passengers: const [],
      ),
    ];
  }
}
