enum DashboardRole {
  admin('المالك'),
  supportAgent('خدمة العملاء');

  final String label;

  const DashboardRole(this.label);

  static DashboardRole fromDb(String role) => switch (role) {
    'dashboard_admin' => DashboardRole.admin,
    _                 => DashboardRole.supportAgent,
  };

  String get dbValue => switch (this) {
    DashboardRole.admin        => 'dashboard_admin',
    DashboardRole.supportAgent => 'support_agent',
  };
}
