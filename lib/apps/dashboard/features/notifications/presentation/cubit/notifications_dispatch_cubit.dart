import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_draft.dart';
import '../../domain/usecases/send_notification_usecase.dart';
import 'notifications_dispatch_state.dart';

class NotificationsDispatchCubit extends Cubit<NotificationsDispatchState> {
  NotificationsDispatchCubit(this._send)
      : super(const NotificationsDispatchIdle());

  final SendNotificationUseCase _send;

  Future<void> dispatch(NotificationDraft draft) async {
    emit(const NotificationsDispatchSending());
    try {
      final count = await _send(draft);
      emit(NotificationsDispatchSuccess(count));
    } catch (e) {
      emit(NotificationsDispatchError(e.toString()));
    }
  }

  void reset() => emit(const NotificationsDispatchIdle());
}
