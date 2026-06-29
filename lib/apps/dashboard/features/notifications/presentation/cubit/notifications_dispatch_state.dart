sealed class NotificationsDispatchState {
  const NotificationsDispatchState();
}

class NotificationsDispatchIdle extends NotificationsDispatchState {
  const NotificationsDispatchIdle();
}

class NotificationsDispatchSending extends NotificationsDispatchState {
  const NotificationsDispatchSending();
}

class NotificationsDispatchSuccess extends NotificationsDispatchState {
  const NotificationsDispatchSuccess(this.recipientCount);
  final int recipientCount;
}

class NotificationsDispatchError extends NotificationsDispatchState {
  const NotificationsDispatchError(this.message);
  final String message;
}
