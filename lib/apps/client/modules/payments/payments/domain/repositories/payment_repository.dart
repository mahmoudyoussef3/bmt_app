import 'dart:typed_data';

import '../entities/payment_models.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethodData>> getPaymentMethods();

  /// Returns the discount amount in piastres/EGP for the given promo code, or
  /// 0 if the code is invalid / expired.
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
}
