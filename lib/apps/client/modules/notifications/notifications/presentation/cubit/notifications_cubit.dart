import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client_notification.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/watch_notifications_usecase.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required WatchNotificationsUseCase watchNotifications,
    required MarkAsReadUseCase markAsRead,
    required MarkAllAsReadUseCase markAllAsRead,
  })  : _watch = watchNotifications,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead,
        super(const NotificationsInitial());

  final WatchNotificationsUseCase _watch;
  final MarkAsReadUseCase _markAsRead;
  final MarkAllAsReadUseCase _markAllAsRead;
  StreamSubscription<List<ClientNotification>>? _sub;

  void startWatching() {
    if (isClosed) return;
    emit(const NotificationsLoading());
    _sub?.cancel();
    _sub = _watch().listen(
      (list) {
        if (isClosed) return;
        final prev = state;
        final cat = prev is NotificationsLoaded ? prev.activeCategory : null;
        emit(NotificationsLoaded(list, activeCategory: cat));
      },
      onError: (e) {
        if (!isClosed) emit(NotificationsError(e.toString()));
      },
    );
  }

  void filterByCategory(NotificationCategory? cat) {
    final s = state;
    if (s is NotificationsLoaded) emit(s.withCategory(cat));
  }

  Future<void> markAsRead(String id) async {
    final s = state;
    if (s is NotificationsLoaded) emit(s.withReadToggled(id));
    await _markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final s = state;
    if (s is NotificationsLoaded) emit(s.withAllRead());
    await _markAllAsRead();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
