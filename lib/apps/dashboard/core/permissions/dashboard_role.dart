enum DashboardRole {
  admin('المسؤول العام'),
  operationsManager('مسؤول عمليات'),
  financeAgent('مسؤول مالية'),
  supportAgent('خدمة العملاء');

  final String label;

  const DashboardRole(this.label);

  static DashboardRole fromDb(String role) => switch (role) {
    'dashboard_admin'    => DashboardRole.admin,
    'operations_manager' => DashboardRole.operationsManager,
    'finance_agent'      => DashboardRole.financeAgent,
    _                    => DashboardRole.supportAgent,
  };

  String get dbValue => switch (this) {
    DashboardRole.admin            => 'dashboard_admin',
    DashboardRole.operationsManager => 'operations_manager',
    DashboardRole.financeAgent     => 'finance_agent',
    DashboardRole.supportAgent     => 'support_agent',
  };
}
