import '../../domain/entities/operational_alert.dart';

sealed class OperationalAlertsState {
  const OperationalAlertsState();
}

class OperationalAlertsInitial extends OperationalAlertsState {
  const OperationalAlertsInitial();
}

class OperationalAlertsLoading extends OperationalAlertsState {
  const OperationalAlertsLoading();
}

class OperationalAlertsLoaded extends OperationalAlertsState {
  const OperationalAlertsLoaded(this.alerts, {this.activeType});

  final List<OperationalAlert> alerts;
  final OperationalAlertType? activeType;

  List<OperationalAlert> get filtered => activeType == null
      ? alerts
      : alerts.where((a) => a.type == activeType).toList();

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  OperationalAlertsLoaded withType(OperationalAlertType? type) =>
      OperationalAlertsLoaded(alerts, activeType: type);

  OperationalAlertsLoaded withReadToggled(String id) {
    final updated = alerts
        .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
        .toList();
    return OperationalAlertsLoaded(updated, activeType: activeType);
  }

  OperationalAlertsLoaded withAllRead() {
    final updated = alerts.map((a) => a.copyWith(isRead: true)).toList();
    return OperationalAlertsLoaded(updated, activeType: activeType);
  }
}

class OperationalAlertsError extends OperationalAlertsState {
  const OperationalAlertsError(this.message);

  final String message;
}
