import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';

/// Holds all user selections throughout the booking wizard.
/// The session object is the state — each selection emits a new session.
class BookingWizardCubit extends Cubit<BookingWizardSession> {
  BookingWizardCubit(RouteOptionData route, {this.initialPackageId})
    : super(BookingWizardSession(route: route));

  /// A package the rider reviewed before this search, if any — the package
  /// step applies it once, the first time its catalogue loads with no
  /// selection made yet.
  final String? initialPackageId;

  void selectPickup(RoutePointData stop) {
    emit(state.copyWith(pickupStop: stop, clearDropoff: true));
  }

  void selectDropoff(RoutePointData stop) {
    emit(state.copyWith(dropoffStop: stop));
  }

  void selectTrip(RouteTripOptionData trip) {
    
    emit(state.copyWith(selectedTrip: trip));
    clearSeat();
    clearPackage();
  }

  void selectSeat(String seatId, String label) {
    emit(state.copyWith(selectedSeatId: seatId, selectedSeatLabel: label));
  }

  void clearSeat() {
    emit(
      BookingWizardSession(
        route: state.route,
        pickupStop: state.pickupStop,
        dropoffStop: state.dropoffStop,
        selectedTrip: state.selectedTrip,
        selectedPackage: state.selectedPackage,
        paymentMethod: state.paymentMethod,
        receiptUrl: state.receiptUrl,
        paymentReference: state.paymentReference,
        payerPhone: state.payerPhone,
        bookingId: state.bookingId,
        bookingRef: state.bookingRef,
      ),
    );
  }

  void clearPackage() {
    emit(
      BookingWizardSession(
        route: state.route,
        pickupStop: state.pickupStop,
        dropoffStop: state.dropoffStop,
        selectedTrip: state.selectedTrip,
        selectedSeatId: state.selectedSeatId,
        selectedSeatLabel: state.selectedSeatLabel,
        selectedPackage: null,
        paymentMethod: state.paymentMethod,
        receiptUrl: state.receiptUrl,
        paymentReference: state.paymentReference,
        payerPhone: state.payerPhone,
        bookingId: state.bookingId,
        bookingRef: state.bookingRef,
      ),
    );
  }

  /// No start date: a plan runs from the date of the trip already selected.
  void selectPackage(PackagePlan plan) {
    emit(state.copyWith(selectedPackage: plan));
  }

  void selectPaymentMethod(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void setReceiptUrl(String url) {
    emit(state.copyWith(receiptUrl: url));
  }

  void setManualPaymentDetails({
    required String paymentReference,
    required String payerPhone,
  }) {
    emit(
      state.copyWith(
        paymentReference: paymentReference.trim(),
        payerPhone: payerPhone.trim(),
      ),
    );
  }

  void setBookingId({required String bookingId, required String bookingRef}) {
    emit(state.copyWith(bookingId: bookingId, bookingRef: bookingRef));
  }
}
