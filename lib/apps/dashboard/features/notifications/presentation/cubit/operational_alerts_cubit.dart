import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operational_alert.dart';
import '../../domain/usecases/mark_alert_read_usecase.dart';
import '../../domain/usecases/mark_all_alerts_read_usecase.dart';
import '../../domain/usecases/watch_operational_alerts_usecase.dart';
import 'operational_alerts_state.dart';

class OperationalAlertsCubit extends Cubit<OperationalAlertsState> {
  OperationalAlertsCubit({
    required WatchOperationalAlertsUseCase watchAlerts,
    required MarkAlertReadUseCase markAsRead,
    required MarkAllAlertsReadUseCase markAllAsRead,
  }) : _watch = watchAlerts,
       _markAsRead = markAsRead,
       _markAllAsRead = markAllAsRead,
       super(const OperationalAlertsInitial());

  final WatchOperationalAlertsUseCase _watch;
  final MarkAlertReadUseCase _markAsRead;
  final MarkAllAlertsReadUseCase _markAllAsRead;
  StreamSubscription<List<OperationalAlert>>? _sub;

  void startWatching() {
    if (isClosed) return;
    emit(const OperationalAlertsLoading());
    _sub?.cancel();
    _sub = _watch().listen(
      (list) {
        if (isClosed) return;
        final prev = state;
        final type = prev is OperationalAlertsLoaded ? prev.activeType : null;
        emit(OperationalAlertsLoaded(list, activeType: type));
      },
      onError: (e) {
        if (!isClosed) emit(OperationalAlertsError(e.toString()));
      },
    );
  }

  void filterByType(OperationalAlertType? type) {
    final s = state;
    if (s is OperationalAlertsLoaded) emit(s.withType(type));
  }

  Future<void> markAsRead(String id) async {
    final s = state;
    if (s is OperationalAlertsLoaded) emit(s.withReadToggled(id));
    await _markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final s = state;
    if (s is OperationalAlertsLoaded) emit(s.withAllRead());
    await _markAllAsRead();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
