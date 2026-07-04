import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

void main() {
  const route = RouteOptionData(
    id: 'route-1',
    routeName: 'القاهرة - الإسكندرية',
    pickup: 'القاهرة',
    destination: 'الإسكندرية',
    distance: '220 كم',
    duration: '3 ساعات',
    availableSeats: 1,
    startingPrice: 'EGP 100',
    priceRange: 'EGP 100',
    availableTrips: [],
  );
  const package = PackagePlan(
    id: 'package-1',
    nameAr: 'ذهاب فقط',
    nameEn: 'Just Go',
    packageType: 'just_go',
    durationDays: 1,
    rideCount: 1,
    price: 100,
  );

  test(
    'manual payment is valid only after method and receipt are provided',
    () {
      final session = BookingWizardSession(route: route)
          .copyWith(paymentMethod: 'instapay')
          .copyWith(receiptUrl: 'signed-receipt-url');

      expect(session.paymentValid, isTrue);
    },
  );

  test('package price is the server-facing total shown to the client', () {
    final session = BookingWizardSession(route: route).copyWith(
      selectedPackage: package,
      packageStartDate: DateTime(2026, 7, 4),
    );

    expect(session.packageValid, isTrue);
    expect(session.totalPrice, 100);
  });

  test('payment metadata survives seat reset', () async {
    final cubit = BookingWizardCubit(route)
      ..selectPaymentMethod('bank_transfer')
      ..setReceiptUrl('signed-receipt-url')
      ..setManualPaymentDetails(
        paymentReference: 'REF-123',
        payerPhone: '01000000000',
      )
      ..clearSeat();

    expect(cubit.state.paymentReference, 'REF-123');
    expect(cubit.state.payerPhone, '01000000000');
    expect(cubit.state.receiptUrl, 'signed-receipt-url');
    await cubit.close();
  });
}
