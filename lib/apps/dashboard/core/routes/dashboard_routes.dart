class DashboardRoutes {
  const DashboardRoutes._();

  static const home = '/';
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

  // ── The licensing console (platform admins only) ──────────────────────────
  // `plans` and `licenses`, never `packages` or `subscriptions`: both of those
  // already mean passenger fare bundles elsewhere in this app, and
  // `/subscriptions` above is one of them.
  static const platformPlans = '/platform-plans';
  static const platformFeatures = '/platform-features';
  static const platformLicenses = '/platform-licenses';
  static const platformBilling = '/platform-billing';
  static const platformUsage = '/platform-usage';
  static const platformAudit = '/platform-audit';

  /// The office's own plan and invoices. Owner only.
  static const officeBilling = '/office-billing';

  static const settings = '/settings';
  static const permissions = '/permissions';
  static const notifications = '/notifications';
}
