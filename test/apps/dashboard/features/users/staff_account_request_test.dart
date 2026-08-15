import 'package:bmt_app/apps/dashboard/core/permissions/dashboard_role.dart';
import 'package:bmt_app/apps/dashboard/features/users/domain/entities/staff_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validate', () {
    test('accepts a well-formed request', () {
      const request = StaffAccountRequest(
        username: 'ops.sara',
        fullName: 'سارة محمد',
        role: DashboardRole.supportAgent,
      );

      expect(request.validate(), isEmpty);
    });

    test('rejects a username shorter than three characters', () {
      const request = StaffAccountRequest(username: 'ab');

      expect(request.validate(), contains('username'));
    });

    test('rejects a username with characters the server forbids', () {
      for (final username in ['ops sara', 'sara@office', '_sara', 'ops/sara']) {
        expect(
          StaffAccountRequest(username: username).validate(),
          contains('username'),
          reason: '$username must be rejected before it reaches the server',
        );
      }
    });

    test('normalises case rather than rejecting it', () {
      // The Edge Function and `office_create_staff` both lowercase before matching,
      // so refusing capitals here would reject a name the server would have accepted.
      const request = StaffAccountRequest(username: 'Ops.Sara');

      expect(request.validate(), isEmpty);
      expect(request.toPayload()['username'], 'ops.sara');
    });

    test('rejects a full name over 120 characters', () {
      final request = StaffAccountRequest(
        username: 'ops.sara',
        fullName: 'ا' * 121,
      );

      expect(request.validate(), contains('fullName'));
    });

    test('rejects a chosen password under ten characters', () {
      const request = StaffAccountRequest(
        username: 'ops.sara',
        password: 'short',
      );

      expect(request.validate(), contains('password'));
    });

    test('accepts a blank password — it means "generate one"', () {
      const request = StaffAccountRequest(username: 'ops.sara');

      expect(request.validate(), isEmpty);
    });
  });

  group('toPayload', () {
    test('lowercases the username and names the create action', () {
      const request = StaffAccountRequest(username: '  OPS.Sara  ');

      final payload = request.toPayload();

      expect(payload['action'], 'create');
      expect(payload['username'], 'ops.sara');
    });

    test('sends the role as its database value', () {
      const owner = StaffAccountRequest(
        username: 'ops.sara',
        role: DashboardRole.admin,
      );
      const agent = StaffAccountRequest(username: 'ops.omar');

      expect(owner.toPayload()['role'], 'dashboard_admin');
      expect(agent.toPayload()['role'], 'support_agent');
    });

    test('omits a blank password so the server generates one', () {
      const request = StaffAccountRequest(username: 'ops.sara');

      expect(request.toPayload().containsKey('password'), isFalse);
    });

    test('omits a blank full name rather than sending an empty string', () {
      const request = StaffAccountRequest(username: 'ops.sara');

      expect(request.toPayload().containsKey('full_name'), isFalse);
    });

    test('carries no office id — the server decides that from the session', () {
      const request = StaffAccountRequest(username: 'ops.sara');

      expect(request.toPayload().keys, isNot(contains('office_id')));
    });
  });
}
