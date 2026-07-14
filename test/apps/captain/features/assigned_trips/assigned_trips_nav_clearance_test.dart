import 'package:bmt_app/apps/captain/core/widgets/captain_bottom_nav.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/presentation/widgets/assigned_trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The captain shell runs with `extendBody: true`, so tab content is painted
/// under the floating nav bar. A page that under-reserves bottom space buries
/// its last trip card's actions behind the bar — the captain then cannot start
/// their last trip of the day.
void main() {
  testWidgets('last trip card actions stay clear of the floating nav bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    // A device with a home indicator: the bar floats above that inset too.
    tester.view.viewPadding = const FakeViewPadding(bottom: 102);
    tester.view.padding = const FakeViewPadding(bottom: 102);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const _ShellHarness(tripCount: 5));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final navTop = tester.getTopLeft(find.byType(CaptainBottomNav)).dy;
    final lastAction = find.widgetWithText(CaptainButton, 'بدء الرحلة').last;

    expect(
      tester.getBottomLeft(lastAction).dy,
      lessThanOrEqualTo(navTop),
      reason: 'the last trip\'s action button is hidden behind the nav bar',
    );
  });
}

class _ShellHarness extends StatelessWidget {
  const _ShellHarness({required this.tripCount});

  final int tripCount;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBody: true,
          body: Builder(
            builder: (context) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    CaptainBottomNav.reservedSpace(context),
                  ),
                  sliver: SliverList.list(
                    children: [
                      for (var i = 0; i < tripCount; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AssignedTripCard(
                            trip: _trip(i),
                            onOpen: () {},
                            onManifest: () {},
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CaptainBottomNav(
            currentIndex: 0,
            tabs: const [
              CaptainNavTab(
                label: 'اليوم',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              CaptainNavTab(
                label: 'السجل',
                icon: Icons.history_rounded,
                activeIcon: Icons.history_rounded,
              ),
            ],
            onTabChanged: (_) {},
          ),
        ),
      ),
    );
  }

  AssignedTrip _trip(int index) {
    final departure = DateTime(2026, 7, 14, 8 + index);
    return AssignedTrip(
      id: 'trip-$index',
      route: 'القاهرة - الإسكندرية',
      vehicleNumber: 'BUS-$index',
      plateNumber: 'أ ب ج 123',
      departureTime: departure,
      expectedArrivalTime: departure.add(const Duration(hours: 3)),
      stops: const [],
      passengerCount: 20,
      boardedCount: 4,
    );
  }
}
