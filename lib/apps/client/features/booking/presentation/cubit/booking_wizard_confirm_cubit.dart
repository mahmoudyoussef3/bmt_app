import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../payments/domain/usecases/start_card_checkout_usecase.dart';
import '../../../seat_selection/domain/usecases/place_seat_booking_usecase.dart';
import '../../../seat_selection/domain/usecases/update_existing_booking_payment_usecase.dart';
import '../../domain/entities/booking_wizard_session.dart';
import '../utils/wizard_booking_params.dart';
import '../widgets/payment/wizard_payment_mapping.dart';
import 'booking_wizard_confirm_state.dart';

/// Spends the answers the wizard collected: writes the booking, then settles
/// the fare. A card leg leaves the app for the gateway, so the cubit stops at
/// [BookingWizardCardCheckout] and resumes on [cardPaymentFinished].
class BookingWizardConfirmCubit extends Cubit<BookingWizardConfirmState> {
  BookingWizardConfirmCubit({
    required PlaceSeatBookingUseCase placeSeatBooking,
    required UpdateExistingBookingPaymentUseCase updateExistingBookingPayment,
    required StartCardCheckoutUseCase startCardCheckout,
  }) : _placeSeatBooking = placeSeatBooking,
       _updateExistingBookingPayment = updateExistingBookingPayment,
       _startCardCheckout = startCardCheckout,
       super(const BookingWizardConfirmIdle());

  final PlaceSeatBookingUseCase _placeSeatBooking;
  final UpdateExistingBookingPaymentUseCase _updateExistingBookingPayment;
  final StartCardCheckoutUseCase _startCardCheckout;

  WizardBookingRecord? _record;
  bool _requiresVerification = false;

  Future<void> confirm(BookingWizardSession session) async {
    final tripId = session.selectedTrip?.id ?? '';
    final seatId = session.selectedSeatId ?? '';
    if (tripId.isEmpty || seatId.isEmpty) return;

    _requiresVerification = wizardMethodRequiresReceipt(session.paymentMethod);
    emit(const BookingWizardConfirming());

    try {
      final isNew = session.bookingId == null;
      final booking = isNew
          ? await _placeSeatBooking(
              tripId: tripId,
              seatId: seatId,
              params: wizardConfirmBookingParams(session),
            )
          : await _updateExistingBookingPayment(
              wizardUpdatePaymentParams(session),
            );

      final record = WizardBookingRecord.fromRpc(booking, isNew: isNew);
      _record = record;

      if (!session.isCardPayment) {
        _emit(
          BookingWizardConfirmed(
            record: record,
            requiresVerification: _requiresVerification,
          ),
        );
        return;
      }

      final bookingId = record.id;
      if (bookingId == null || bookingId.isEmpty) {
        throw Exception('booking_reference_missing');
      }
      final checkout = await _startCardCheckout(
        checkoutData: wizardCheckoutData(session),
        bookingId: bookingId,
        amount: session.totalPrice.round(),
      );
      _emit(
        BookingWizardCardCheckout(
          checkoutUrl: checkout.checkoutUrl,
          record: record,
        ),
      );
    } catch (error) {
      _emit(BookingWizardConfirmFailed(_reasonOf(error)));
    }
  }

  /// The gateway webview closed. A seat whose card payment never completed
  /// keeps its five-minute hold, so the rider can pick another method and
  /// settle the booking that already exists.
  void cardPaymentFinished(bool paid) {
    final record = _record;
    if (state is! BookingWizardCardCheckout || record == null) return;
    _emit(
      paid
          ? BookingWizardConfirmed(
              record: record,
              requiresVerification: _requiresVerification,
            )
          : const BookingWizardConfirmFailed('card_payment_not_completed'),
    );
  }

  /// Re-arms the pay button once the rider has read why the attempt failed.
  void reset() => _emit(const BookingWizardConfirmIdle());

  /// The rider can leave the wizard while a confirm is still in flight.
  void _emit(BookingWizardConfirmState next) {
    if (!isClosed) emit(next);
  }

  String _reasonOf(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
}
