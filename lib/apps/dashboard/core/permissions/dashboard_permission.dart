import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  drivers,
  fleet,
  captainRequests,
  assignments,
  vehicles,
  routes,
  trips,
  // The live operations center — active trips, tracking health, and the open
  // incident queue. Available to support agents too: "what is affecting a
  // customer or captain right now" is exactly their remit during an incident.
  // This grants *visibility* only; closing a report needs the permission below.
  liveOps,
  // Acknowledging, resolving or dismissing a captain's incident report. Owner
  // only, and deliberately separate from [liveOps]: a support agent answering a
  // passenger needs to see that a bus broke down, but deciding that the breakdown
  // is *handled* is an operations call with a permanent audit trail attached to
  // whoever made it.
  liveOpsIncidentAction,
  bookings,
  subscriptions,
  referrals,
  payments,
  paymentVerification,
  tickets,
  // Individual passenger reviews (with their written feedback) are for the
  // owner only — deliberately absent from the support-agent set below.
  reviews,
  reports,
  ownerOverview,
  notifications,
  // The office's own marketplace record. Owner-only to match the
  // `offices_operator_update` policy, which requires `dashboard_admin`.
  officeProfile,
  // Onboarding new offices onto the platform. Being in the owner's set is
  // necessary but NOT sufficient: the module is additionally gated on
  // `OfficeContext.isPlatformAdmin`, because this is the one permission that
  // reaches outside the signed-in office. See `_DashboardNavItem.platformOnly`.
  platformOffices,
  settings,
  permissions,
}

class DashboardPermissions {
  const DashboardPermissions._();

  static bool canAccess(DashboardRole role, DashboardPermission permission) {
    return permissionsFor(role).contains(permission);
  }

  static Set<DashboardPermission> permissionsFor(DashboardRole role) {
    return switch (role) {
      DashboardRole.admin => DashboardPermission.values.toSet(),
      DashboardRole.supportAgent => const {
        DashboardPermission.liveOps,
        DashboardPermission.bookings,
        DashboardPermission.tickets,
        DashboardPermission.reports,
        DashboardPermission.paymentVerification,
        DashboardPermission.notifications,
      },
    };
  }
}
