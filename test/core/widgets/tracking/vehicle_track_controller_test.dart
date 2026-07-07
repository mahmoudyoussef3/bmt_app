import 'package:bmt_app/core/tracking/tracking.dart';
import 'package:bmt_app/core/widgets/tracking/vehicle_track_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rec0 = DateTime.utc(2026, 7, 6, 10);

  VehicleFix fix({double lat = 30.0, int secondsAfterRec0 = 0}) {
    return VehicleFix(
      latitude: lat,
      longitude: 31.0,
      recordedAt: rec0.add(Duration(seconds: secondsAfterRec0)),
    );
  }

  testWidgets('animates samples between fixes and stops when settled', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 7, 6, 10, 0, 30);
    final controller = VehicleTrackController(
      vsync: const TestVSync(),
      clock: () => now,
    );

    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.sample, isNull);
    expect(controller.addFix(fix()), isTrue);
    expect(controller.sample!.latitude, 30.0);
    expect(notifications, 1);

    // Second fix four seconds later (~100 km/h) starts an interpolation.
    now = now.add(const Duration(seconds: 4));
    expect(controller.addFix(fix(lat: 30.001, secondsAfterRec0: 4)), isTrue);

    // Halfway through the window the sample sits strictly between the fixes.
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    final midLat = controller.sample!.latitude;
    expect(midLat, greaterThan(30.0));
    expect(midLat, lessThan(30.001));
    expect(notifications, greaterThan(1));

    // Once the window has fully elapsed the marker has settled on the fix
    // and the ticker shuts itself off (no more frame callbacks needed).
    now = now.add(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    expect(controller.sample!.latitude, closeTo(30.001, 1e-9));
    expect(controller.sample!.isInterpolating, isFalse);
    await tester.pump(const Duration(seconds: 1));

    controller.reset();
    expect(controller.sample, isNull);

    // Dispose inside the test body: the stale-refresh timer must be gone
    // before the binding's pending-timer check runs.
    controller.dispose();
  });

  testWidgets('drops rejected fixes without notifying listeners', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 7, 6, 10, 0, 30);
    final controller = VehicleTrackController(
      vsync: const TestVSync(),
      clock: () => now,
    );

    controller.addFix(fix(secondsAfterRec0: 10));
    var notifications = 0;
    controller.addListener(() => notifications++);

    now = now.add(const Duration(seconds: 1));
    expect(controller.addFix(fix(lat: 30.5, secondsAfterRec0: 5)), isFalse);
    expect(controller.lastRejection, FixRejection.outOfOrder);
    expect(notifications, 0);
    expect(controller.targetFix!.latitude, 30.0);

    controller.dispose();
  });
}
