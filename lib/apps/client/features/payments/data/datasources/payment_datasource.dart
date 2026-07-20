import 'dart:typed_data';

import '../../domain/entities/payment_models.dart';

abstract class PaymentDatasource {
  Future<List<PaymentMethodData>> getPaymentMethods();

  Future<int> validatePromoCode(String code);

  Future<String> uploadReceipt({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  Future<CardPaymentSession> createCardPaymentSession({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  });

  /// What our database says about a card booking, independent of whatever the
  /// gateway's WebView claimed on its way back.
  Future<CardPaymentState> getCardPaymentState(String bookingId);
}
