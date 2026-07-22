import 'package:bmt_app/apps/dashboard/features/platform_admin/domain/entities/office_onboarding.dart';
import 'package:flutter_test/flutter_test.dart';

/// The client-side copy of the onboarding rules.
///
/// These same rules exist in the Edge Function and again inside
/// `platform_create_office`. Testing this copy is not testing the server — it is
/// testing that the form marks the right field, which is the only job this copy
/// has.
void main() {
  OfficeOnboardingRequest request({
    String name = 'مكتب الإسكندرية',
    String slug = 'alex-office',
    String adminUsername = 'ops.alex',
    String description = '',
    String logoUrl = '',
    String phone = '',
    String email = '',
    List<String> serviceAreas = const [],
    String adminFullName = '',
    String adminPassword = '',
  }) => OfficeOnboardingRequest(
    name: name,
    slug: slug,
    adminUsername: adminUsername,
    description: description,
    logoUrl: logoUrl,
    phone: phone,
    email: email,
    serviceAreas: serviceAreas,
    adminFullName: adminFullName,
    adminPassword: adminPassword,
  );

  group('validate', () {
    test('a complete request has no errors', () {
      expect(request().validate(), isEmpty);
    });

    test('an empty slug is allowed — the server mints one', () {
      expect(request(slug: '').validate(), isEmpty);
    });

    test('rejects a short name', () {
      expect(request(name: 'مك').validate(), containsPair('name', isNotEmpty));
    });

    test('rejects a slug with spaces', () {
      expect(request(slug: 'alex office').validate().keys, contains('slug'));
    });

    test('accepts a hyphenated lowercase slug', () {
      expect(request(slug: 'alex-office-2').validate(), isEmpty);
    });

    // Capitals are normalised rather than refused, here and in the RPC, because
    // both unique indexes are on lower(). Rejecting them would mean 'ALEX' and
    // 'alex' looked like different names while colliding in the database.
    test('accepts capitals and normalises them', () {
      expect(request(slug: 'ALEX').validate(), isEmpty);
      expect(request(adminUsername: 'OPS.Alex').validate(), isEmpty);
      expect(
        OfficeOnboardingRequest(
          name: 'مكتب',
          adminUsername: 'OPS.Alex',
          slug: 'ALEX',
        ).toPayload(),
        containsPair('slug', 'alex'),
      );
    });

    test('rejects a username with invalid characters', () {
      expect(
        request(adminUsername: 'ops alex').validate().keys,
        contains('adminUsername'),
      );
      expect(
        request(adminUsername: 'ops@alex').validate().keys,
        contains('adminUsername'),
      );
    });

    test('rejects a username shorter than three characters', () {
      expect(
        request(adminUsername: 'ab').validate().keys,
        contains('adminUsername'),
      );
    });

    test('rejects a non-https logo url', () {
      expect(
        request(logoUrl: 'http://cdn.example.com/l.png').validate().keys,
        contains('logoUrl'),
      );
      expect(
        request(logoUrl: 'https://cdn.example.com/l.png').validate(),
        isEmpty,
      );
    });

    test('rejects a malformed contact email', () {
      expect(request(email: 'not-an-email').validate().keys, contains('email'));
      expect(request(email: 'ops@example.com').validate(), isEmpty);
    });

    test('a supplied password must be at least ten characters', () {
      expect(
        request(adminPassword: 'short').validate().keys,
        contains('adminPassword'),
      );
      expect(request(adminPassword: 'a-long-enough-one').validate(), isEmpty);
    });

    test('an empty password is valid — it means "generate one"', () {
      expect(request(adminPassword: '').validate(), isEmpty);
    });

    test('rejects an over-long description', () {
      expect(
        request(description: 'ا' * 501).validate().keys,
        contains('description'),
      );
    });
  });

  group('toPayload', () {
    test('omits blank optionals rather than sending empty strings', () {
      final payload = request().toPayload();

      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('phone'), isFalse);
      expect(payload.containsKey('logo_url'), isFalse);
      expect(payload.containsKey('service_areas'), isFalse);
      expect(payload.containsKey('admin_password'), isFalse);
    });

    test('normalises the username and slug to lower case', () {
      final payload = OfficeOnboardingRequest(
        name: 'مكتب',
        adminUsername: '  OPS.Alex  ',
        slug: '  Alex-Office  ',
      ).toPayload();

      expect(payload['admin_username'], 'ops.alex');
      expect(payload['slug'], 'alex-office');
    });

    test('drops blank service areas', () {
      final payload = request(
        serviceAreas: ['القاهرة', '  ', 'الجيزة'],
      ).toPayload();

      expect(payload['service_areas'], ['القاهرة', 'الجيزة']);
    });

    test('never carries an office id, a role or a status', () {
      final payload = request(serviceAreas: const ['القاهرة']).toPayload();

      // The four values the server decides. A payload that could carry them is
      // a payload someone eventually populates.
      expect(payload.keys, isNot(contains('office_id')));
      expect(payload.keys, isNot(contains('role')));
      expect(payload.keys, isNot(contains('status')));
      expect(payload.keys, isNot(contains('listing_status')));
      expect(payload.keys, isNot(contains('join_code')));
    });
  });
}
