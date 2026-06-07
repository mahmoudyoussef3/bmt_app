class DashboardWorkspace {
  final String id;
  final String title;
  final String subtitle;
  final List<DashboardWorkspaceAction> actions;
  final List<DashboardWorkspaceMetric> metrics;
  final List<DashboardWorkspaceTab> tabs;
  final List<String> columns;
  final List<DashboardWorkspaceRow> rows;
  final List<DashboardWorkspaceSection> sections;
  final List<String> statusOptions;

  const DashboardWorkspace({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.metrics,
    required this.tabs,
    required this.columns,
    required this.rows,
    required this.sections,
    this.statusOptions = const [],
  });

  DashboardWorkspace copyWith({
    List<DashboardWorkspaceMetric>? metrics,
    List<DashboardWorkspaceRow>? rows,
  }) {
    return DashboardWorkspace(
      id: id,
      title: title,
      subtitle: subtitle,
      actions: actions,
      metrics: metrics ?? this.metrics,
      tabs: tabs,
      columns: columns,
      rows: rows ?? this.rows,
      sections: sections,
      statusOptions: statusOptions,
    );
  }
}

class DashboardWorkspaceAction {
  final String label;
  final String message;

  const DashboardWorkspaceAction({required this.label, required this.message});
}

class DashboardWorkspaceMetric {
  final String label;
  final String value;
  final String note;

  const DashboardWorkspaceMetric({
    required this.label,
    required this.value,
    required this.note,
  });
}

class DashboardWorkspaceTab {
  final String label;
  final String filter;

  const DashboardWorkspaceTab({required this.label, required this.filter});
}

class DashboardWorkspaceRow {
  final List<String> cells;
  final String status;
  final String details;
  final List<DashboardWorkspaceField> fields;
  final List<DashboardWorkspaceSection> tabs;
  final List<String> attachments;
  final List<String> timeline;

  const DashboardWorkspaceRow({
    required this.cells,
    required this.status,
    required this.details,
    this.fields = const [],
    this.tabs = const [],
    this.attachments = const [],
    this.timeline = const [],
  });

  DashboardWorkspaceRow copyWith({
    List<String>? cells,
    String? status,
    String? details,
    List<DashboardWorkspaceField>? fields,
    List<DashboardWorkspaceSection>? tabs,
    List<String>? attachments,
    List<String>? timeline,
  }) {
    return DashboardWorkspaceRow(
      cells: cells ?? this.cells,
      status: status ?? this.status,
      details: details ?? this.details,
      fields: fields ?? this.fields,
      tabs: tabs ?? this.tabs,
      attachments: attachments ?? this.attachments,
      timeline: timeline ?? this.timeline,
    );
  }
}

class DashboardWorkspaceSection {
  final String title;
  final List<String> items;

  const DashboardWorkspaceSection({required this.title, required this.items});
}

class DashboardWorkspaceField {
  final String label;
  final String value;

  const DashboardWorkspaceField({required this.label, required this.value});
}
