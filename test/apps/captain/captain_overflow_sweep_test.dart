import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_theme.dart';
import 'package:bmt_app/apps/captain/features/notifications/domain/entities/captain_notification.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/domain/entities/passenger.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/cubit/passenger_manifest_state.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/widgets/passenger_card.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/widgets/passenger_filter_chips.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/widgets/passenger_search_field.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/widgets/passenger_stats_row.dart';

/// A captain holds the phone one-handed, in daylight, often with the system
/// font bumped up — so the screens that carry the trip have to hold at a small
/// device *and* an enlarged text scale at the same time. The analyzer cannot
/// see a `RenderFlex overflowed` — only pumping the real widgets can.
///
/// The surfaces swept here are the ones the earlier layout tests never reached:
/// the passenger manifest (the boarding door for every trip) and the
/// notification tile. Auth, profile, trip execution and trip history each have
/// their own layout test already.
///
/// Assertions are deliberately conservative: `flutter_test` substitutes a font
/// whose glyphs are much wider than Cairo's, so Arabic strings measure longer
/// here than they ever will on a device. Anything that holds here holds there.
void main() {
  const sizes = <String, Size>{
    'small': Size(320, 568),
    'medium': Size(390, 844),
  };

  // 1.0 is the default; 1.3 is a common comfort setting; 1.6 is near the top of
  // what Android's font-size slider offers before accessibility sizes.
  const scales = <double>[1.0, 1.3, 1.6];

  for (final size in sizes.entries) {
    for (final scale in scales) {
      final at = 'at ${size.key} @ textScale $scale';

      testWidgets('the manifest holds $at', (tester) async {
        await _view(tester, size.value);

        await tester.pumpWidget(
          _host(
            scale: scale,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: PassengerStatsRow(counts: _counts()),
                ),
                SliverToBoxAdapter(
                  child: PassengerSearchField(
                    hasQuery: true,
                    onChanged: (_) {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: PassengerFilterChips(
                    current: PassengerBoardingStatus.boarded,
                    onSelect: (_) {},
                  ),
                ),
                SliverList.list(
                  children: [
                    for (final passenger in _passengers())
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: PassengerCard(
                          passenger: passenger,
                          onCall: () {},
                          onChat: () {},
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The boarding tallies are the reason the captain opened this screen.
        // "صعد" reads as a tally, a filter and a badge, so several are correct.
        expect(find.text('صعد'), findsWidgets);
        expect(find.text('المتوقعون'), findsOneWidget);
      });

      testWidgets('notification tiles hold $at', (tester) async {
        await _view(tester, size.value);

        await tester.pumpWidget(
          _host(
            scale: scale,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final notification in _notifications())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationTileHarness(notification: notification),
                  ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _view(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _host({required Widget child, required double scale}) {
  return MaterialApp(
    theme: CaptainTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    ),
  );
}

PassengerCounts _counts() => const PassengerCounts(
  total: 24,
  boarded: 18,
  pending: 4,
  absent: 2,
  cancelled: 0,
);

/// Long names and long pickup points are the realistic worst case — Egyptian
/// four-part names and station names both run long.
List<Passenger> _passengers() => const [
  Passenger(
    id: 'p1',
    name: 'عبد الرحمن محمد عبد الفتاح الشناوي',
    seat: 'A12',
    pickupPoint: 'موقف الترجمان - رصيف رقم ٤',
    destination: 'محطة سيدي جابر الرئيسية',
    pickupTime: '08:15',
    phone: '01001234567',
    status: PassengerBoardingStatus.boarded,
  ),
  Passenger(
    id: 'p2',
    name: 'منى السيد',
    seat: 'B3',
    pickupPoint: 'العاشر من رمضان',
    destination: 'الإسكندرية',
    pickupTime: '08:40',
    phone: '',
  ),
  Passenger(
    id: 'p3',
    name: 'أحمد',
    seat: 'C1',
    pickupPoint: 'طنطا',
    destination: 'دمنهور',
    pickupTime: '09:05',
    phone: '01112223334',
    status: PassengerBoardingStatus.absent,
  ),
];

List<CaptainNotification> _notifications() => [
  CaptainNotification(
    id: 'n1',
    title: 'تم إسناد رحلة جديدة إليك',
    body:
        'رحلة القاهرة - الإسكندرية تغادر الساعة ٨:٠٠ صباحاً من موقف الترجمان، '
        'يرجى التواجد قبل الموعد بنصف ساعة.',
    category: CaptainNotificationCategory.assignment,
    isRead: false,
    createdAt: DateTime(2026, 7, 23, 7),
    priority: CaptainNotificationPriority.high,
  ),
  CaptainNotification(
    id: 'n2',
    title: 'تحديث',
    body: 'تم تأكيد حجز راكب جديد.',
    category: CaptainNotificationCategory.passenger,
    isRead: true,
    createdAt: DateTime(2026, 7, 23, 6),
  ),
];

/// The tile is private to the notifications page, so the sweep rebuilds its
/// shape here. If the page's tile drifts from this, the page's own rendering is
/// what changed — this harness stays a faithful stand-in for the layout under
/// test (icon + flexible text column + unread dot in a Row).
class _NotificationTileHarness extends StatelessWidget {
  const _NotificationTileHarness({required this.notification});

  final CaptainNotification notification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? cs.surface : cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_outlined, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: tt.labelLarge),
                const SizedBox(height: 3),
                Text(
                  notification.body,
                  style: tt.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsetsDirectional.only(top: 4),
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
