import '../../domain/entities/routes_hub_data.dart';

sealed class RoutesHubState {
  const RoutesHubState();
}

class RoutesHubLoading extends RoutesHubState {
  const RoutesHubLoading();
}

class RoutesHubLoaded extends RoutesHubState {
  const RoutesHubLoaded(this.data, {this.refreshFailure});

  final RoutesHubData data;

  /// Set when a pull-to-refresh failed while this data was on screen —
  /// the UI keeps the content and surfaces the failure non-destructively.
  final String? refreshFailure;
}

class RoutesHubError extends RoutesHubState {
  const RoutesHubError(this.message);

  final String message;
}
