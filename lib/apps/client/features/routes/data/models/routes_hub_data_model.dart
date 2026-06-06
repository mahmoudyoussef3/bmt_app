import '../../domain/entities/routes_hub_data.dart';

class RoutesHubActionModel {
  const RoutesHubActionModel({required this.route, this.arguments = const {}});

  final String route;
  final Map<String, String> arguments;

  RoutesHubAction toEntity() {
    return RoutesHubAction(route: route, arguments: arguments);
  }
}

class RoutesHubFlowStepModel {
  const RoutesHubFlowStepModel({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final String title;
  final String subtitle;

  RoutesHubFlowStep toEntity() {
    return RoutesHubFlowStep(step: step, title: title, subtitle: subtitle);
  }
}

class RoutesHubDataModel {
  const RoutesHubDataModel({
    required this.title,
    required this.subtitle,
    required this.searchTitle,
    required this.searchDescription,
    required this.searchAction,
    required this.popularRoutesAction,
    required this.flowSteps,
  });

  final String title;
  final String subtitle;
  final String searchTitle;
  final String searchDescription;
  final RoutesHubActionModel searchAction;
  final RoutesHubActionModel popularRoutesAction;
  final List<RoutesHubFlowStepModel> flowSteps;

  RoutesHubData toEntity() {
    return RoutesHubData(
      title: title,
      subtitle: subtitle,
      searchTitle: searchTitle,
      searchDescription: searchDescription,
      searchAction: searchAction.toEntity(),
      popularRoutesAction: popularRoutesAction.toEntity(),
      flowSteps: flowSteps.map((step) => step.toEntity()).toList(),
    );
  }
}
