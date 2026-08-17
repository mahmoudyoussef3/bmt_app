import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/core/tracking/fix_validator.dart';
import 'package:bmt_app/core/tracking/tracking_config.dart';
import 'package:bmt_app/core/tracking/valid_fix_filter.dart';
import 'package:bmt_app/core/tracking/vehicle_fix.dart';

/// The gate in front of the throttle. Every fix it drops is a database write, a
/// WAL row and a realtime fan-out to every passenger on the trip that would have
/// been spent on a position nobody could draw.
void main() {
  final base = DateTime.utc(2026, 8, 17, 9);

  VehicleFix fix({
    double latitude = 30.0444,
    double longitude = 31.2357,
    Duration age = Duration.zero,
    double? accuracy = 10,
  }) {
    return VehicleFix(
      latitude: latitude,
      longitude: longitude,
      recordedAt: base.add(age),
      accuracyMeters: accuracy,
    );
  }

  Future<List<VehicleFix>> filtered(
    List<VehicleFix> input, {
    List<FixRejection>? rejections,
  }) {
    return Stream.fromIterable(input)
        .transform(ValidFixFilter(onRejected: rejections?.add))
        .toList();
  }

  test('passes a plausible sequence through untouched', () async {
    final out = await filtered([
      fix(),
      fix(latitude: 30.0450, age: const Duration(seconds: 10)),
      fix(latitude: 30.0460, age: const Duration(seconds: 20)),
    ]);

    expect(out, hasLength(3));
  });

  group('junk the device reports', () {
    test('drops a (0,0) cold-start fix', () async {
      final rejections = <FixRejection>[];
      final out = await filtered([
        fix(latitude: 0, longitude: 0),
        fix(),
      ], rejections: rejections);

      expect(out, hasLength(1));
      expect(rejections, [FixRejection.invalidCoordinates]);
    });

    test('drops non-finite coordinates', () async {
      final out = await filtered([
        fix(latitude: double.nan),
        fix(longitude: double.infinity, age: const Duration(seconds: 5)),
      ]);

      expect(out, isEmpty);
    });

    test('drops coordinates outside the globe', () async {
      final out = await filtered([
        fix(latitude: 91),
        fix(longitude: 181, age: const Duration(seconds: 5)),
      ]);

      expect(out, isEmpty);
    });
  });

  group('accuracy', () {
    test('drops a fix coarser than the configured ceiling', () async {
      final rejections = <FixRejection>[];
      final out = await filtered([
        fix(accuracy: 250),
        fix(accuracy: 15, age: const Duration(seconds: 5)),
      ], rejections: rejections);

      expect(out, hasLength(1));
      expect(out.single.accuracyMeters, 15);
      expect(rejections, [FixRejection.poorAccuracy]);
    });

    test('keeps a fix the device could not rate at all', () async {
      // A missing accuracy is not a bad accuracy. Refusing it would silence a
      // device that simply does not report the figure.
      final out = await filtered([fix(accuracy: null)]);

      expect(out, hasLength(1));
    });

    test('honours a caller-supplied ceiling', () async {
      final out = await Stream.fromIterable([fix(accuracy: 60)])
          .transform(
            ValidFixFilter(config: const TrackingConfig(maxAccuracyMeters: 50)),
          )
          .toList();

      expect(out, isEmpty);
    });
  });

  group('ordering and duplicates', () {
    test('drops an exact duplicate', () async {
      final rejections = <FixRejection>[];
      final out = await filtered([
        fix(),
        fix(),
      ], rejections: rejections);

      expect(
        out,
        hasLength(1),
        reason: 'the same reading twice is one position, and one write',
      );
      expect(rejections, [FixRejection.outOfOrder]);
    });

    test('drops a fix that arrives out of order', () async {
      final out = await filtered([
        fix(age: const Duration(seconds: 30)),
        fix(age: const Duration(seconds: 10)),
        fix(age: const Duration(seconds: 40)),
      ]);

      expect(out.map((f) => f.recordedAt), [
        base.add(const Duration(seconds: 30)),
        base.add(const Duration(seconds: 40)),
      ]);
    });

    test('drops a teleport', () async {
      final rejections = <FixRejection>[];
      // ~90 km in ten seconds. A bus did not do that.
      final out = await filtered([
        fix(),
        fix(latitude: 30.85, age: const Duration(seconds: 10)),
      ], rejections: rejections);

      expect(out, hasLength(1));
      expect(rejections, [FixRejection.implausibleJump]);
    });

    test('allows a fast but possible stretch of road', () async {
      // ~1.1 km in 40 s is about 100 km/h — a bus on a desert highway.
      final out = await filtered([
        fix(),
        fix(latitude: 30.0544, age: const Duration(seconds: 40)),
      ]);

      expect(out, hasLength(2));
    });
  });

  test('each subscription judges fixes against its own history', () async {
    final filter = ValidFixFilter();
    final first = StreamController<VehicleFix>();
    final second = StreamController<VehicleFix>();
    final a = <VehicleFix>[];
    final b = <VehicleFix>[];
    first.stream.transform(filter).listen(a.add);
    second.stream.transform(filter).listen(b.add);

    // The same timestamp on both streams. If history were shared, the second
    // would be rejected as a duplicate of the first.
    first.add(fix());
    second.add(fix());
    await Future<void>.delayed(Duration.zero);

    expect(a, hasLength(1));
    expect(
      b,
      hasLength(1),
      reason: 'one vehicle\'s history must not veto another\'s fixes',
    );

    await first.close();
    await second.close();
  });
}
