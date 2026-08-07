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
  // ── محفظة العملاء ─────────────────────────────────────────────────────────
  // Three permissions, not eight. Eight capability flags across a two-role
  // system is administration theatre; the *server* keeps the fine-grained
  // capability list (`public.office_can`) so more roles can be added later
  // without touching call sites.
  //
  // See the wallet, and every entry in its ledger. Granted to support agents
  // too: they are the ones who hear "where is my money", so denying visibility
  // just makes them guess.
  customerWallets,
  // Move money — cashback, manual credit, manual debit. Owner only.
  walletAdjustments,
  // Decide refund requests, reverse an entry, freeze a wallet, edit policy, and
  // export history. Owner only. Export is here rather than under
  // [customerWallets] because a full customer financial history in a
  // spreadsheet is a data-exfiltration surface, and it is the one read that
  // leaves the audited system.
  walletApprovals,
  tickets,
  // Individual passenger reviews (with their written feedback) are for the
  // owner only — deliberately absent from the support-agent set below.
  reviews,
  reports,
  // The executive overview: revenue, wallet liability, customer base and the
  // owner's decision queue on one page. Owner only — and deliberately its own
  // permission rather than a reuse of [ownerOverview], because the two grant
  // different things and a future role that should see one but not the other
  // must be expressible without editing every call site.
  businessOverview,
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
  // The licensing console: plans, the feature catalog, office licences,
  // platform billing, usage and the decision trail. Owner-set *and*
  // `platformOnly`, exactly like [platformOffices] — it reaches across offices,
  // so an office role alone cannot authorise it.
  platformLicensing,
  // The office's own plan, usage and invoices. Owner only: a support agent has
  // no business seeing the office's commercial terms.
  officeBilling,
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
        // Sees every balance and every entry; holds neither
        // [walletAdjustments] nor [walletApprovals], so the only wallet action
        // available to them is raising a refund *request* for the owner to
        // decide. That escalation path already exists in the data model.
        DashboardPermission.customerWallets,
      },
    };
  }
}
