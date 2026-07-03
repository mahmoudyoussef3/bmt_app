import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

/// Holds all user selections throughout the booking wizard.
/// The session object is the state — each selection emits a new session.
class BookingWizardCubit extends Cubit<BookingWizardSession> {
  BookingWizardCubit(RouteOptionData route)
      : super(BookingWizardSession(route: route));

  void selectPickup(RoutePointData stop) {
    emit(state.copyWith(pickupStop: stop, clearDropoff: true));
  }

  void selectDropoff(RoutePointData stop) {
    emit(state.copyWith(dropoffStop: stop));
  }

  void selectTrip(RouteTripOptionData trip) {
    emit(state.copyWith(selectedTrip: trip));
  }

  void selectSeat(String seatId, String label) {
    emit(state.copyWith(selectedSeatId: seatId, selectedSeatLabel: label));
  }

  void clearSeat() {
    emit(BookingWizardSession(
      route: state.route,
      pickupStop: state.pickupStop,
      dropoffStop: state.dropoffStop,
      selectedTrip: state.selectedTrip,
      selectedPackage: state.selectedPackage,
      packageStartDate: state.packageStartDate,
      paymentMethod: state.paymentMethod,
      receiptUrl: state.receiptUrl,
    ));
  }

  void selectPackage(PackagePlan plan, DateTime startDate) {
    emit(state.copyWith(selectedPackage: plan, packageStartDate: startDate));
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void setReceiptUrl(String url) {
    emit(state.copyWith(receiptUrl: url));
  }
}
