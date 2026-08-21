import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_permission.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who may reach platform administration.
///
/// Two independent conditions, and the second is the one that matters: the
/// office role gates the *menu*, but `isPlatformAdmin` gates the module, because
/// every other dashboard permission acts inside the operator's own office and
/// this one does not.
void main() {
  group('current_office_context parsing', () {
    test('reads the platform-admin flag and the listing status', () {
      final context = OfficeContext.fromRpc(const {
        'office_id': 'office-a',
        'office_name': 'مكتب الإسكندرية',
        'office_slug': 'alex-office',
        'role': 'dashboard_admin',
        'username': 'ops.alex',
        'full_name': 'أحمد',
        'listing_status': 'draft',
        'is_platform_admin': true,
      });

      expect(context.isPlatformAdmin, isTrue);
      expect(context.listingStatus, 'draft');
      expect(context.isListed, isFalse);
      expect(context.role, DashboardRole.admin);
    });

    test('defaults to not-a-platform-admin when the key is absent', () {
      // Older sessions and any response shape that predates the flag must not
      // be read as permission.
      final context = OfficeContext.fromRpc(const {
        'office_id': 'office-a',
        'office_name': 'مكتب',
        'office_slug': 'office',
        'role': 'support_agent',
        'username': 'ops',
      });

      expect(context.isPlatformAdmin, isFalse);
      // Absent listing status means an office that predates the column, which
      // the migration backfilled to listed.
      expect(context.listingStatus, 'listed');
      expect(context.isListed, isTrue);
    });

    test('a non-boolean flag is not permission', () {
      for (final value in ['true', 1, null, 'yes']) {
        final context = OfficeContext.fromRpc({
          'office_id': 'office-a',
          'office_name': 'مكتب',
          'office_slug': 'office',
          'role': 'dashboard_admin',
          'username': 'ops',
          'is_platform_admin': value,
        });
        expect(context.isPlatformAdmin, isFalse, reason: 'value: $value');
      }
    });
  });

  group('DashboardPermissions', () {
    test('platform offices is in the owner set only', () {
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.admin,
          DashboardPermission.platformOffices,
        ),
        isTrue,
      );
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.platformOffices,
        ),
        isFalse,
      );
    });

    test('the support-agent set is exactly this, and nothing more', () {
      expect(
        DashboardPermissions.permissionsFor(DashboardRole.supportAgent),
        const {
          // Added deliberately with the Live Operations Center: a support agent
          // answering "where is my bus?" needs the live picture. This is a
          // read-only grant — see the incident-action assertion below.
          DashboardPermission.liveOps,
          DashboardPermission.bookings,
          DashboardPermission.tickets,
          DashboardPermission.reports,
          DashboardPermission.paymentVerification,
          DashboardPermission.notifications,
          // Added deliberately with محفظة العملاء: an agent who is asked "where
          // is my refund?" must be able to see the balance and the ledger. It
          // is a read-only grant — `walletAdjustments` and `walletApprovals`
          // are owner-only, and the server checks the same thing again in
          // `public.office_can`.
          DashboardPermission.customerWallets,
          // Added deliberately with العملاء: the module aggregates bookings,
          // wallets and tickets — three surfaces this role already reads in
          // full — into one view of the person. Withholding the summary of data
          // they can already page through would protect nothing and would leave
          // the agent assembling it by hand across five modules, which is the
          // problem the module exists to remove. Read-only: the repository
          // exposes no write, and `office_can('customers_view')` is checked
          // again server-side.
          DashboardPermission.customers,
        },
      );
    });

    test('a support agent may open العملاء', () {
      // The money capabilities it sits beside are asserted owner-only by the
      // wallet test below; this only pins that the directory itself is granted.
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.customers,
        ),
        isTrue,
      );
    });

    test('a support agent may read wallets but may not move money', () {
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.customerWallets,
        ),
        isTrue,
      );
      for (final permission in const [
        DashboardPermission.walletAdjustments,
        DashboardPermission.walletApprovals,
      ]) {
        expect(
          DashboardPermissions.canAccess(
            DashboardRole.supportAgent,
            permission,
          ),
          isFalse,
          reason: '$permission moves money and is owner-only',
        );
      }
    });

    test('a support agent may watch live ops but not close incidents', () {
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.liveOps,
        ),
        isTrue,
      );
      // Deciding a captain's breakdown report is handled is an operations call
      // that writes a permanent audit trail against whoever made it.
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.liveOpsIncidentAction,
        ),
        isFalse,
      );
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.admin,
          DashboardPermission.liveOpsIncidentAction,
        ),
        isTrue,
      );
    });
  });
}
