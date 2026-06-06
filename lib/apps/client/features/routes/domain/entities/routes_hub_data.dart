class RoutesHubAction {
  const RoutesHubAction({required this.route, this.arguments = const {}});

  final String route;
  final Map<String, String> arguments;
}

class RoutesHubFlowStep {
  const RoutesHubFlowStep({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final String title;
  final String subtitle;
}

class RoutesHubData {
  const RoutesHubData({
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
  final RoutesHubAction searchAction;
  final RoutesHubAction popularRoutesAction;
  final List<RoutesHubFlowStep> flowSteps;
}
