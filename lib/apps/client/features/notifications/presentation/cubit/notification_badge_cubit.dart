import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/watch_unread_count_usecase.dart';

/// Singleton cubit — always alive, drives the bell-badge in the app bar.
class NotificationBadgeCubit extends Cubit<int> {
  NotificationBadgeCubit(WatchUnreadCountUseCase watchUnreadCount) : super(0) {
    _sub = watchUnreadCount().listen(
      (count) { if (!isClosed) emit(count); },
      onError: (_) {},
    );
  }

  StreamSubscription<int>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
