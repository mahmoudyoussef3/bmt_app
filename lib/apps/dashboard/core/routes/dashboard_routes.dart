class DashboardRoutes {
  const DashboardRoutes._();

  static const home = '/';

  /// The executive tab: how the business is performing, and what needs the
  /// owner. Distinct from [home], which is the operator's working console.
  ///
  /// It replaced `/owner-overview`, a second revenue aggregate that no nav item
  /// and no screen ever linked to. Every figure that screen carried is here or
  /// in [payments], derived from the same use cases the modules use.
  static const businessOverview = '/business-overview';

  static const liveOps = '/live-ops';
  static const bookings = '/bookings';
  static const trips = '/trips';
  static const fleet = '/fleet';
  static const captainRequests = '/captain-requests';
  static const drivers = '/drivers';
  static const vehicles = '/vehicles';
  static const routes = '/routes';
  static const users = '/users';
  static const subscriptions = '/subscriptions';
  static const referrals = '/referrals';
  static const payments = '/payments';

  /// العملاء — the Customer 360 directory. Distinct from [wallet], which is
  /// the same people seen through their money alone.
  static const customers = '/customers';

  static const wallet = '/wallet';
  static const paymentVerification = '/payment-verification';
  static const tickets = '/tickets';
  static const reviews = '/reviews';
  static const reports = '/reports';
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
