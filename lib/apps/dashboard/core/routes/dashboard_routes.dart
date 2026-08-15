class DashboardRoutes {
  const DashboardRoutes._();

  static const home = '/';

  /// The executive tab: how the business is performing, and what needs the
  /// owner. Distinct from [home], which is the operator's working console, and
  /// from [ownerOverview], which is a revenue aggregate.
  static const businessOverview = '/business-overview';

  static const liveOps = '/live-ops';
  static const bookings = '/bookings';
  static const trips = '/trips';
  static const fleet = '/fleet';
  static const captainRequests = '/captain-requests';
  static const drivers = '/drivers';
  static const assignments = '/assignments';
  static const vehicles = '/vehicles';
  static const routes = '/routes';
  static const users = '/users';
  static const subscriptions = '/subscriptions';
  static const referrals = '/referrals';
  static const payments = '/payments';
  static const wallet = '/wallet';
  static const paymentVerification = '/payment-verification';
  static const tickets = '/tickets';
  static const reviews = '/reviews';
  static const reports = '/reports';
  static const ownerOverview = '/owner-overview';
  static const officeProfile = '/office-profile';
  static const platformOffices = '/platform-offices';

  /// The platform console, four destinations rather than the seven it opened
  /// with. «كتالوج الميزات» folded into [platformCatalog], «الاستخدام» into the
  /// office workspace on [platformLicenses], and «سجل التغييرات» into
  /// [platformBilling] — each was a sidebar row for a section of a job, not a
  /// job.
  static const platformCatalog = '/platform-catalog';
  static const platformLicenses = '/platform-licenses';
  static const platformBilling = '/platform-billing';

  /// The office's own plan and invoices. Owner only.
  static const officeBilling = '/office-billing';

  static const settings = '/settings';
  static const permissions = '/permissions';
  static const notifications = '/notifications';
}
