import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/watch_unread_alerts_count_usecase.dart';

/// Singleton cubit — always alive, drives the top-bar bell badge on the
/// Dashboard shell.
class OperationalAlertsBadgeCubit extends Cubit<int> {
  OperationalAlertsBadgeCubit(WatchUnreadAlertsCountUseCase watchUnreadCount)
    : super(0) {
    _sub = watchUnreadCount().listen((count) {
      if (!isClosed) emit(count);
    }, onError: (_) {});
  }

  StreamSubscription<int>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
