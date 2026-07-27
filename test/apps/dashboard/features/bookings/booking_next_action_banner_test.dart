import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_app_theme.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/domain/entities/operation_booking.dart';
import 'package:bmt_app/apps/dashboard/features/bookings/presentation/widgets/booking_next_action_banner.dart';

/// The inspector is the narrowest panel in the dashboard, and its reason lines
/// are full sentences — the combination most likely to overflow.
const _widths = <double>[300, 360, 480, 900];
const _textScales = <double>[1.0, 1.3, 1.6];

OperationBooking _booking({
  required BookingStatus status,
  required PaymentStatus paymentStatus,
  String? receiptUrl = 'https://example.test/receipt.png',
}) => OperationBooking(
  id: 'b1',
  bookingNumber: 'BK-1001',
  clientId: 'c1',
  passengerName: 'أحمد محمد عبد الرحمن',
  phone: '01001234567',
  route: 'المنصورة - القاهرة',
  tripTime: '08:00',
  date: '2026-07-27',
  seat: 'A1',
  paymentMethod: BookingPaymentMethod.instaPay,
  status: status,
  paymentStatus: paymentStatus,
  paymentAmount: 120,
  packageName: '',
  createdAt: DateTime(2026, 7, 27),
  tripDetails: BookingTripDetails.empty,
  notes: const [],
  timeline: const [],
  receiptUrl: receiptUrl,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 480,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: DashboardAppTheme.light(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a submitted receipt reads as an instruction to review', (
    tester,
  ) async {
    await _pump(
      tester,
      BookingNextActionBanner(
        booking: _booking(
          status: BookingStatus.reserved,
          paymentStatus: PaymentStatus.submitted,
        ),
      ),
    );
    expect(find.text('مراجعة الدفع'), findsOneWidget);
  });

  testWidgets('paid-but-cancelled shouts, and says the money is still held', (
    tester,
  ) async {
    await _pump(
      tester,
      BookingNextActionBanner(
        booking: _booking(
          status: BookingStatus.cancelled,
          paymentStatus: PaymentStatus.approved,
        ),
      ),
    );
    expect(find.text('تعارض في الحالة'), findsOneWidget);
    expect(find.textContaining('لم يُرد للعميل'), findsOneWidget);
  });

  testWidgets('a clean booking states that nothing is needed', (tester) async {
    await _pump(
      tester,
      BookingNextActionBanner(
        booking: _booking(
          status: BookingStatus.confirmed,
          paymentStatus: PaymentStatus.approved,
        ),
      ),
    );
    expect(find.text('جاهز للسفر'), findsOneWidget);
    expect(find.text('تعارض في الحالة'), findsNothing);
  });

  testWidgets('a cancelled payment is no longer mislabelled as pending', (
    tester,
  ) async {
    await _pump(
      tester,
      BookingNextActionBanner(
        booking: _booking(
          status: BookingStatus.cancelled,
          paymentStatus: PaymentStatus.cancelled,
        ),
      ),
    );
    // Previously PaymentStatus.cancelled fell back to `pending`, which produced
    // "waiting for the customer to upload a receipt" on a dead booking.
    expect(find.text('بانتظار العميل'), findsNothing);
    expect(find.text('لا إجراء'), findsOneWidget);
  });

  group('banner never overflows', () {
    for (final width in _widths) {
      for (final scale in _textScales) {
        testWidgets('@ ${width}px ${scale}x', (tester) async {
          await _pump(
            tester,
            BookingNextActionBanner(
              booking: _booking(
                status: BookingStatus.confirmed,
                paymentStatus: PaymentStatus.pending,
              ),
            ),
            width: width,
            textScale: scale,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'overflowed at ${width}px @ ${scale}x',
          );
        });
      }
    }
  });
}
