import 'dashboard_role.dart';

enum DashboardPermission {
  users,
  drivers,
  fleet,
  assignments,
  vehicles,
  routes,
  trips,
  liveTrips,
  bookings,
  subscriptions,
  payments,
  paymentVerification,
  tickets,
  reports,
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
      DashboardRole.operationsManager => const {
        DashboardPermission.bookings,
        DashboardPermission.trips,
        DashboardPermission.liveTrips,
        DashboardPermission.fleet,
        DashboardPermission.drivers,
        DashboardPermission.assignments,
        DashboardPermission.vehicles,
        DashboardPermission.routes,
        DashboardPermission.reports,
      },
      DashboardRole.financeAgent => const {
        DashboardPermission.payments,
        DashboardPermission.paymentVerification,
        DashboardPermission.subscriptions,
        DashboardPermission.reports,
      },
      DashboardRole.supportAgent => const {
        DashboardPermission.bookings,
        DashboardPermission.tickets,
        DashboardPermission.reports,
        DashboardPermission.paymentVerification,
      },
    };
  }
}
