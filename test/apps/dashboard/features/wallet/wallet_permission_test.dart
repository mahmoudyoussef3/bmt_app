import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_permission.dart';
import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';

/// The Dart permission set is UX; `public.office_can` is the security boundary.
/// These tests pin the UX half — the SQL half is proved by
/// `supabase/tests/wallet_authority_regression.sql`, which asserts that a
/// demoted operator is refused by the server even if a screen offered them the
/// button.
void main() {
  group('wallet permissions', () {
    test('the owner holds all three wallet permissions', () {
      for (final permission in const [
        DashboardPermission.customerWallets,
        DashboardPermission.walletAdjustments,
        DashboardPermission.walletApprovals,
      ]) {
        expect(
          DashboardPermissions.canAccess(DashboardRole.admin, permission),
          isTrue,
          reason: 'the owner must hold $permission',
        );
      }
    });

    test('a support agent may look and may not move money', () {
      // §6: they are the ones who hear "where is my money", so denying
      // visibility just makes them guess — but the money itself is an owner
      // decision with a permanent audit trail attached.
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.customerWallets,
        ),
        isTrue,
      );
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.walletAdjustments,
        ),
        isFalse,
      );
      expect(
        DashboardPermissions.canAccess(
          DashboardRole.supportAgent,
          DashboardPermission.walletApprovals,
        ),
        isFalse,
      );
    });

    test('there are exactly three wallet permissions, not eight', () {
      // Eight capability flags across a two-role system is administration
      // theatre. The fine-grained list lives server-side in `office_can`, so a
      // third role changes one function rather than twelve call sites.
      final walletPermissions = DashboardPermission.values
          .where((p) => p.name.toLowerCase().contains('wallet'))
          .toList();

      expect(walletPermissions, hasLength(3));
    });
  });
}
