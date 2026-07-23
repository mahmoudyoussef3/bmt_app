import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/captain_notification.dart';
import '../../domain/usecases/mark_all_captain_notifications_read_usecase.dart';
import '../../domain/usecases/mark_captain_notification_read_usecase.dart';
import '../../domain/usecases/watch_captain_notifications_usecase.dart';
import 'captain_notifications_state.dart';

class CaptainNotificationsCubit extends Cubit<CaptainNotificationsState> {
  CaptainNotificationsCubit({
    required WatchCaptainNotificationsUseCase watchNotifications,
    required MarkCaptainNotificationReadUseCase markAsRead,
    required MarkAllCaptainNotificationsReadUseCase markAllAsRead,
  }) : _watch = watchNotifications,
       _markAsRead = markAsRead,
       _markAllAsRead = markAllAsRead,
       super(const CaptainNotificationsInitial());

  final WatchCaptainNotificationsUseCase _watch;
  final MarkCaptainNotificationReadUseCase _markAsRead;
  final MarkAllCaptainNotificationsReadUseCase _markAllAsRead;
  StreamSubscription<List<CaptainNotification>>? _sub;

  void startWatching() {
    if (isClosed) return;
    emit(const CaptainNotificationsLoading());
    _sub?.cancel();
    _sub = _watch().listen(
      (list) {
        if (!isClosed) emit(CaptainNotificationsLoaded(list));
      },
      onError: (e) {
        if (!isClosed) emit(CaptainNotificationsError(e.toString()));
      },
    );
  }

  /// Marking read is optimistic — the row greys out under the captain's finger
  /// rather than after a round trip. A failure is swallowed on purpose: the
  /// watch stream is the source of truth and re-emits the true read state on
  /// its next tick, so the only thing an error could add here is a dialog over
  /// a notification list about a notification. Left unguarded it was worse than
  /// silent: the call is fired from a tap handler that never awaits it, so a
  /// throw surfaced as an unhandled async error.
  Future<void> markAsRead(String id) async {
    final s = state;
    if (s is CaptainNotificationsLoaded) emit(s.withReadToggled(id));
    try {
      await _markAsRead(id);
    } catch (_) {
      // Corrected by the next stream emission.
    }
  }

  Future<void> markAllAsRead() async {
    final s = state;
    if (s is CaptainNotificationsLoaded) emit(s.withAllRead());
    try {
      await _markAllAsRead();
    } catch (_) {
      // Corrected by the next stream emission.
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
