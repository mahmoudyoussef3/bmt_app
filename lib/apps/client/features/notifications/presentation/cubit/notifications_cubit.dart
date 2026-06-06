import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_notifications_usecase.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._getNotifications)
    : super(const NotificationsLoading());

  final GetNotificationsUseCase _getNotifications;

  Future<void> load() async {
    emit(const NotificationsLoading());
    try {
      final notifications = await _getNotifications();
      emit(NotificationsLoaded(notifications));
    } catch (error) {
      emit(NotificationsError(error.toString()));
    }
  }
}
