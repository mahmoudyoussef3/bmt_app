import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = FixValidator(TrackingConfig());
  final t0 = DateTime.utc(2026, 7, 6, 10);

  VehicleFix fix({
    double lat = 30.0,
    double lng = 31.0,
    int secondsAfterT0 = 0,
    double? accuracy,
  }) {
    return VehicleFix(
      latitude: lat,
      longitude: lng,
      recordedAt: t0.add(Duration(seconds: secondsAfterT0)),
      accuracyMeters: accuracy,
    );
  }

  test('accepts a sane first fix', () {
    expect(validator.validate(null, fix()), isNull);
  });

  test('rejects the (0,0) no-lock placeholder', () {
    expect(
      validator.validate(null, fix(lat: 0, lng: 0)),
      FixRejection.invalidCoordinates,
    );
  });

  test('rejects non-finite and out-of-range coordinates', () {
    expect(
      validator.validate(null, fix(lat: double.nan)),
      FixRejection.invalidCoordinates,
    );
    expect(
      validator.validate(null, fix(lat: 95)),
      FixRejection.invalidCoordinates,
    );
    expect(
      validator.validate(null, fix(lng: 181)),
      FixRejection.invalidCoordinates,
    );
  });

  test('rejects fixes with accuracy worse than the threshold', () {
    expect(
      validator.validate(null, fix(accuracy: 150)),
      FixRejection.poorAccuracy,
    );
    expect(validator.validate(null, fix(accuracy: 40)), isNull);
  });

  test('rejects out-of-order and duplicate timestamps', () {
    final previous = fix(secondsAfterT0: 10);
    expect(
      validator.validate(previous, fix(secondsAfterT0: 5)),
      FixRejection.outOfOrder,
    );
    expect(
      validator.validate(previous, fix(secondsAfterT0: 10)),
      FixRejection.outOfOrder,
    );
  });

  test('rejects physically implausible jumps', () {
    final previous = fix();
    // ~111 km north in 10 seconds ⇒ ~11 km/s.
    final teleport = fix(lat: 31.0, secondsAfterT0: 10);
    expect(
      validator.validate(previous, teleport),
      FixRejection.implausibleJump,
    );
  });

  test('accepts a plausible highway-speed move', () {
    final previous = fix();
    // ~500 m north in 20 s ⇒ 25 m/s ≈ 90 km/h.
    final next = fix(lat: 30.0045, secondsAfterT0: 20);
    expect(validator.validate(previous, next), isNull);
  });
}
