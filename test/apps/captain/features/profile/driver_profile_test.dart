import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/profile/domain/entities/driver_profile.dart';

void main() {
  DriverProfile profileWithExpiry(DateTime? expiry) {
    return DriverProfile(
      id: 'driver-1',
      name: 'كابتن',
      phone: '0100000000',
      averageRating: 0,
      totalTrips: 0,
      totalPassengers: 0,
      licenseExpiryDate: expiry,
    );
  }

  group('isLicenseExpired', () {
    test('is false when there is no recorded expiry date', () {
      expect(profileWithExpiry(null).isLicenseExpired, isFalse);
    });

    test('is true for a date in the past', () {
      final expiry = DateTime.now().subtract(const Duration(days: 1));
      expect(profileWithExpiry(expiry).isLicenseExpired, isTrue);
    });

    test('is false for a date in the future', () {
      final expiry = DateTime.now().add(const Duration(days: 60));
      expect(profileWithExpiry(expiry).isLicenseExpired, isFalse);
    });
  });

  group('isLicenseExpiringSoon', () {
    test('is false when there is no recorded expiry date', () {
      expect(profileWithExpiry(null).isLicenseExpiringSoon, isFalse);
    });

    test('is false once the license has already expired — that is a '
        'different, more urgent state', () {
      final expiry = DateTime.now().subtract(const Duration(days: 1));
      expect(profileWithExpiry(expiry).isLicenseExpiringSoon, isFalse);
    });

    test('is true within the 30-day warning window', () {
      final expiry = DateTime.now().add(const Duration(days: 10));
      expect(profileWithExpiry(expiry).isLicenseExpiringSoon, isTrue);
    });

    test('is false outside the 30-day warning window', () {
      final expiry = DateTime.now().add(const Duration(days: 90));
      expect(profileWithExpiry(expiry).isLicenseExpiringSoon, isFalse);
    });
  });
}
