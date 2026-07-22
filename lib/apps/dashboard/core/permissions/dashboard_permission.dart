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
        DashboardPermission.bookings,
        DashboardPermission.tickets,
        DashboardPermission.reports,
        DashboardPermission.paymentVerification,
        DashboardPermission.notifications,
      },
    };
  }
}
