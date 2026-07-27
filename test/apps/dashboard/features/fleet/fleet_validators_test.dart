import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_validators.dart';

/// Regression cover for the bug that made a whole class of Egyptian number plates
/// unsaveable — and with them the vehicle's seat layout, driver and documents,
/// because the form validates before it does anything else.

void main() {
  group('normalizeDigits', () {
    test('rewrites Arabic-Indic digits as ASCII', () {
      expect(FleetValidators.normalizeDigits('٣٣٠٠'), '3300');
      expect(FleetValidators.normalizeDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('rewrites Extended Arabic-Indic digits as ASCII', () {
      expect(FleetValidators.normalizeDigits('۴۵۶'), '456');
    });

    test('leaves letters and separators alone', () {
      expect(FleetValidators.normalizeDigits('٣٣٠٠ ق ل'), '3300 ق ل');
      expect(FleetValidators.normalizeDigits('ABC-123'), 'ABC-123');
    });
  });

  group('validatePlateNumber', () {
    test('accepts a plate written in Arabic-Indic digits', () {
      // The exact plate the vehicle form fixture uses, and the shape an Egyptian
      // operator types because it is what is printed on the vehicle. This used
      // to be rejected outright: `\d` does not match ٣, and the Arabic "letters"
      // range contains ٣, so the plate read as letters-only.
      expect(FleetValidators.validatePlateNumber('٣٣٠٠ ق ل'), isNull);
      expect(FleetValidators.validatePlateNumber('١٢٣٤ أ ب ج'), isNull);
    });

    test('accepts the ASCII-digit and Latin-letter forms', () {
      expect(FleetValidators.validatePlateNumber('3300 ق ل'), isNull);
      expect(FleetValidators.validatePlateNumber('123 ABC'), isNull);
    });

    test('still rejects digits with no letters, in either script', () {
      expect(FleetValidators.validatePlateNumber('3300'), isNotNull);
      expect(
        FleetValidators.validatePlateNumber('٣٣٠٠'),
        isNotNull,
        reason: 'Arabic-Indic digits are digits, not letters',
      );
    });

    test('still rejects letters with no digits', () {
      expect(FleetValidators.validatePlateNumber('ق ل م'), isNotNull);
      expect(FleetValidators.validatePlateNumber('ABC'), isNotNull);
    });

    test('still rejects an empty plate', () {
      expect(FleetValidators.validatePlateNumber(''), isNotNull);
      expect(FleetValidators.validatePlateNumber('   '), isNotNull);
      expect(FleetValidators.validatePlateNumber(null), isNotNull);
    });
  });
}
