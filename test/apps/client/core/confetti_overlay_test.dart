import 'package:bmt_app/apps/client/core/widgets/confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts the overlay the way the celebration screens do: full-bleed inside a
/// Scaffold body, stacked over content.
Widget _host(ConfettiController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          const SizedBox.expand(),
          ConfettiOverlay(controller: controller),
        ],
      ),
    ),
  );
}

void main() {
  group('ConfettiController', () {
    test('is idle until fired', () {
      final controller = ConfettiController();
      addTearDown(controller.dispose);

      expect(controller.isActive, isFalse);
      expect(controller.particles, isEmpty);
    });

    test('fire() requests a burst that spawns on the next layout', () {
      final controller = ConfettiController(particleCount: 12);
      addTearDown(controller.dispose);

      controller.fire();
      expect(controller.isActive, isTrue, reason: 'burst is pending');
      expect(controller.particles, isEmpty, reason: 'not spawned until bounds');

      controller.spawnPendingBurst(const Size(400, 800));
      expect(controller.particles, hasLength(12));
    });

    test('spawnPendingBurst is a no-op without a pending request', () {
      final controller = ConfettiController();
      addTearDown(controller.dispose);

      controller.spawnPendingBurst(const Size(400, 800));
      expect(controller.particles, isEmpty);
    });

    test('advance() retires flecks that fall past the bounds', () {
      final controller = ConfettiController(particleCount: 8);
      addTearDown(controller.dispose);
      const bounds = Size(400, 800);

      controller.fire();
      controller.spawnPendingBurst(bounds);
      expect(controller.particles, isNotEmpty);

      // Gravity dominates within a few hundred steps; the burst must terminate.
      var steps = 0;
      while (controller.advance(bounds) && steps < 2000) {
        steps++;
      }

      expect(controller.particles, isEmpty, reason: 'burst must terminate');
      expect(steps, lessThan(2000), reason: 'must not run forever');
    });
  });

  group('ConfettiOverlay', () {
    // Screens own the controller and dispose it in their own State.dispose(),
    // which the framework runs *after* the overlay's — children unmount first
    // (see _InactiveElements._unmount). These tests mirror that ordering:
    // unmount the tree, then dispose the controller.
    testWidgets('does not intercept taps on content beneath it', (
      tester,
    ) async {
      final controller = ConfettiController();
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox.expand(),
                ),
                ConfettiOverlay(controller: controller),
              ],
            ),
          ),
        ),
      );

      controller.fire();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byType(Scaffold), warnIfMissed: false);

      expect(taps, 1, reason: 'overlay must stay pointer-transparent');

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('runs a burst to completion and stops ticking', (tester) async {
      final controller = ConfettiController(particleCount: 20);

      await tester.pumpWidget(_host(controller));
      controller.fire();

      // First frame spawns the burst using the overlay's real bounds.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.particles, isNotEmpty);

      // Drive the simulation out; pumpAndSettle would hang on a live ticker.
      for (var i = 0; i < 600 && controller.particles.isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(controller.particles, isEmpty);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'ticker must stop once the burst is spent',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });

    testWidgets('unmounting mid-burst leaves no live ticker', (tester) async {
      final controller = ConfettiController();

      await tester.pumpWidget(_host(controller));
      controller.fire();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.particles, isNotEmpty, reason: 'burst in flight');

      // Tearing the overlay down mid-flight must not throw or leave a ticker.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);

      controller.dispose();
    });
  });
}
