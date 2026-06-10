import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_trip.dart';
import '../../domain/usecases/call_driver_usecase.dart';
import '../../domain/usecases/complete_live_trip_usecase.dart';
import '../../domain/usecases/get_live_trips_usecase.dart';
import '../../domain/usecases/mark_route_point_arrived_usecase.dart';
import '../../domain/usecases/mark_route_point_completed_usecase.dart';
import '../../domain/usecases/pause_live_trip_usecase.dart';
import '../../domain/usecases/report_live_trip_alert_usecase.dart';
import '../../domain/usecases/resolve_live_trip_alert_usecase.dart';
import '../../domain/usecases/resume_live_trip_usecase.dart';
import '../../domain/usecases/send_driver_message_usecase.dart';
import '../../domain/usecases/skip_route_point_usecase.dart';
import '../../domain/usecases/start_live_trip_usecase.dart';
import 'live_trips_state.dart';

class LiveTripsCubit extends Cubit<LiveTripsState> {
  final GetLiveTripsUseCase _getLiveTrips;
  final StartLiveTripUseCase _startTrip;
  final PauseLiveTripUseCase _pauseTrip;
  final ResumeLiveTripUseCase _resumeTrip;
  final CompleteLiveTripUseCase _completeTrip;
  final MarkRoutePointArrivedUseCase _markPointArrived;
  final MarkRoutePointCompletedUseCase _markPointCompleted;
  final SkipRoutePointUseCase _skipPoint;
  final ResolveLiveTripAlertUseCase _resolveAlert;
  final ReportLiveTripAlertUseCase _reportAlert;
  final CallDriverUseCase _callDriver;
  final SendDriverMessageUseCase _messageDriver;

  LiveTripsCubit({
    required GetLiveTripsUseCase getLiveTrips,
    required StartLiveTripUseCase startTrip,
    required PauseLiveTripUseCase pauseTrip,
    required ResumeLiveTripUseCase resumeTrip,
    required CompleteLiveTripUseCase completeTrip,
    required MarkRoutePointArrivedUseCase markPointArrived,
    required MarkRoutePointCompletedUseCase markPointCompleted,
    required SkipRoutePointUseCase skipPoint,
    required ResolveLiveTripAlertUseCase resolveAlert,
    required ReportLiveTripAlertUseCase reportAlert,
    required CallDriverUseCase callDriver,
    required SendDriverMessageUseCase messageDriver,
  })  : _getLiveTrips = getLiveTrips,
        _startTrip = startTrip,
        _pauseTrip = pauseTrip,
        _resumeTrip = resumeTrip,
        _completeTrip = completeTrip,
        _markPointArrived = markPointArrived,
        _markPointCompleted = markPointCompleted,
        _skipPoint = skipPoint,
        _resolveAlert = resolveAlert,
        _reportAlert = reportAlert,
        _callDriver = callDriver,
        _messageDriver = messageDriver,
        super(const LiveTripsLoading());

  Future<void> loadLiveTrips() async {
    emit(const LiveTripsLoading());
    try {
      final trips = await _getLiveTrips();
      emit(
        LiveTripsLoaded(
          trips: trips,
          selectedTripId: trips.isEmpty ? null : trips.first.id,
        ),
      );
    } catch (error) {
      emit(LiveTripsError(error.toString()));
    }
  }

  void selectTrip(String tripId) {
    final current = state;
    if (current is! LiveTripsLoaded) return;
    emit(current.copyWith(selectedTripId: tripId, clearMessage: true));
  }

  Future<void> startSelectedTrip() {
    return _runTripAction(
      action: (trip) => _startTrip(trip.id),
      successMessage: 'تم بدء الرحلة بنجاح',
    );
  }

  Future<void> pauseSelectedTrip() {
    return _runTripAction(
      action: (trip) => _pauseTrip(trip.id),
      successMessage: 'تم إيقاف الرحلة مؤقتًا',
    );
  }

  Future<void> resumeSelectedTrip() {
    return _runTripAction(
      action: (trip) => _resumeTrip(trip.id),
      successMessage: 'تم استكمال الرحلة',
    );
  }

  Future<void> completeSelectedTrip() {
    return _runTripAction(
      action: (trip) => _completeTrip(trip.id),
      successMessage: 'تم إنهاء الرحلة',
    );
  }

  Future<void> markCurrentPointArrived() {
    return _runTripAction(
      action: (trip) {
        final point = trip.currentPoint;
        if (point == null) throw Exception('لا توجد محطة حالية');
        return _markPointArrived(trip.id, point.id);
      },
      successMessage: 'تم تسجيل الوصول للمحطة',
    );
  }

  Future<void> markCurrentPointCompleted() {
    return _runTripAction(
      action: (trip) {
        final point = trip.currentPoint;
        if (point == null) throw Exception('لا توجد محطة حالية');
        return _markPointCompleted(trip.id, point.id);
      },
      successMessage: 'تم إنهاء المحطة الحالية',
    );
  }

  Future<void> skipCurrentPoint() {
    return _runTripAction(
      action: (trip) {
        final point = trip.currentPoint;
        if (point == null) throw Exception('لا توجد محطة حالية');
        return _skipPoint(trip.id, point.id);
      },
      successMessage: 'تم تخطي المحطة الحالية',
    );
  }

  Future<void> resolveAlert(String alertId) {
    return _runTripAction(
      action: (trip) => _resolveAlert(trip.id, alertId),
      successMessage: 'تم حل التنبيه',
    );
  }

  Future<void> reportDelayAlert() {
    return _runTripAction(
      action: (trip) => _reportAlert(
        tripId: trip.id,
        type: LiveTripAlertType.delay,
        severity: LiveTripAlertSeverity.warning,
        title: 'تأخير جديد',
        message: 'تم تسجيل تأخير جديد على الرحلة.',
      ),
      successMessage: 'تم إضافة تنبيه تأخير',
    );
  }

  Future<void> reportEmergencyAlert() {
    return _runTripAction(
      action: (trip) => _reportAlert(
        tripId: trip.id,
        type: LiveTripAlertType.emergency,
        severity: LiveTripAlertSeverity.critical,
        title: 'تنبيه طوارئ',
        message: 'تم تسجيل تنبيه طوارئ يحتاج تدخل فوري.',
      ),
      successMessage: 'تم إضافة تنبيه طوارئ',
    );
  }

  Future<void> callSelectedDriver() async {
    final current = state;
    if (current is! LiveTripsLoaded) return;
    final trip = current.selectedTrip;
    if (trip == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final message = await _callDriver(trip.driverPhone);
      emit(current.copyWith(actionLoading: false, actionMessage: message));
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  Future<void> messageSelectedDriver() async {
    final current = state;
    if (current is! LiveTripsLoaded) return;
    final trip = current.selectedTrip;
    if (trip == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));
    try {
      final message = await _messageDriver(
        trip.driverPhone,
        'برجاء تحديث حالتك الحالية على الرحلة.',
      );
      emit(current.copyWith(actionLoading: false, actionMessage: message));
    } catch (error) {
      emit(current.copyWith(actionLoading: false, actionMessage: error.toString()));
    }
  }

  void clearActionMessage() {
    final current = state;
    if (current is LiveTripsLoaded) {
      emit(current.copyWith(clearMessage: true));
    }
  }

  Future<void> _runTripAction({
    required Future<LiveTrip> Function(LiveTrip trip) action,
    required String successMessage,
  }) async {
    final current = state;
    if (current is! LiveTripsLoaded) return;

    final selectedTrip = current.selectedTrip;
    if (selectedTrip == null) return;

    emit(current.copyWith(actionLoading: true, clearMessage: true));

    try {
      final updatedTrip = await action(selectedTrip);
      final updatedTrips = current.trips
          .map((trip) => trip.id == updatedTrip.id ? updatedTrip : trip)
          .toList();

      emit(
        current.copyWith(
          trips: updatedTrips,
          actionLoading: false,
          actionMessage: successMessage,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          actionLoading: false,
          actionMessage: error.toString(),
        ),
      );
    }
  }
}
