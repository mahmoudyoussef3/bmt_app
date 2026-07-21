import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/core/session/dashboard_session.dart';
import 'package:bmt_app/apps/dashboard/core/session/office_context.dart';
import 'package:flutter_test/flutter_test.dart';

OfficeContext _ctx({String officeId = 'office-a', DashboardRole? role}) {
  return OfficeContext(
    officeId: officeId,
    officeName: 'Office A',
    officeSlug: 'office-a',
    role: role ?? DashboardRole.admin,
    username: 'ops',
  );
}

void main() {
  group('OfficeContext.fromRpc', () {
    test('maps the current_office_context payload', () {
      final ctx = OfficeContext.fromRpc(const {
        'office_id': 'office-b',
        'office_name': 'Office B',
        'office_slug': 'office-b',
        'role': 'support_agent',
        'username': 'agent1',
        'full_name': 'Agent One',
        'logo_url': 'https://example.test/logo.png',
      });

      expect(ctx.officeId, 'office-b');
      expect(ctx.role, DashboardRole.supportAgent);
      expect(ctx.displayName, 'Agent One');
    });

    test('an unknown role never silently becomes admin', () {
      final ctx = OfficeContext.fromRpc(const {
        'office_id': 'office-b',
        'role': 'something_new',
        'username': 'agent1',
      });

      // DashboardRole.fromDb maps anything it does not recognise to the least
      // privileged role. Defaulting the other way would hand full access to an
      // account whose role we failed to parse.
      expect(ctx.role, DashboardRole.supportAgent);
    });

    test('falls back to the username when no full name is recorded', () {
      final ctx = OfficeContext.fromRpc(const {
        'office_id': 'office-b',
        'role': 'dashboard_admin',
        'username': 'ops',
        'full_name': '   ',
      });

      expect(ctx.displayName, 'ops');
    });
  });

  group('DashboardSession', () {
    test('starts signed out', () {
      final session = DashboardSession();

      expect(session.isAuthenticated, isFalse);
      expect(session.officeIdOrNull, isNull);
    });

    test('reading officeId while signed out throws instead of returning null', () {
      final session = DashboardSession();

      // The whole point: a scoped query must never be able to fall back to an
      // unfiltered read, which is what a null office id would produce.
      expect(() => session.officeId, throwsStateError);
    });

    test('exposes the office after sign-in', () {
      final session = DashboardSession()..start(_ctx());

      expect(session.isAuthenticated, isTrue);
      expect(session.officeId, 'office-a');
    });

    test('clear() revokes access to the office id', () {
      final session = DashboardSession()..start(_ctx());
      session.clear();

      expect(session.isAuthenticated, isFalse);
      expect(() => session.officeId, throwsStateError);
    });

    test('switching operator swaps the office rather than merging', () {
      final session = DashboardSession()..start(_ctx(officeId: 'office-a'));
      session.start(_ctx(officeId: 'office-b'));

      expect(session.officeId, 'office-b');
    });

    test('notifies listeners on sign-in and sign-out', () {
      final session = DashboardSession();
      var notifications = 0;
      session.addListener(() => notifications++);

      session.start(_ctx());
      session.clear();

      expect(notifications, 2);
    });

    test('clearing an already-cleared session does not notify', () {
      final session = DashboardSession();
      var notifications = 0;
      session.addListener(() => notifications++);

      session.clear();

      expect(notifications, 0);
    });
  });
}
