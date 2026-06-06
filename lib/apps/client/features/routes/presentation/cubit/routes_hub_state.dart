import '../../domain/entities/routes_hub_data.dart';

sealed class RoutesHubState {
  const RoutesHubState();
}

class RoutesHubLoading extends RoutesHubState {
  const RoutesHubLoading();
}

class RoutesHubLoaded extends RoutesHubState {
  const RoutesHubLoaded(this.data);

  final RoutesHubData data;
}

class RoutesHubError extends RoutesHubState {
  const RoutesHubError(this.message);

  final String message;
}
