import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

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

  test('setBookingId tracks the booking id in the session state', () async {
    final cubit = BookingWizardCubit(route);

    expect(cubit.state.bookingId, isNull);
    expect(cubit.state.bookingRef, isNull);

    cubit.setBookingId(bookingId: 'uuid-1234', bookingRef: 'BK-1234');

    expect(cubit.state.bookingId, 'uuid-1234');
    expect(cubit.state.bookingRef, 'BK-1234');

    await cubit.close();
  });

  test('booking id survives seat and package clears during recovery flow', () async {
    final cubit = BookingWizardCubit(route)
      ..setBookingId(bookingId: 'uuid-1234', bookingRef: 'BK-1234')
      ..selectPaymentMethod('bank_transfer')
      ..setReceiptUrl('receipt-url')
      ..clearSeat();

    expect(cubit.state.bookingId, 'uuid-1234');
    expect(cubit.state.bookingRef, 'BK-1234');

    cubit.clearPackage();

    expect(cubit.state.bookingId, 'uuid-1234');
    expect(cubit.state.bookingRef, 'BK-1234');

    await cubit.close();
  });
}
