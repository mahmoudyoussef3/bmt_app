import 'dart:typed_data';

import '../../domain/entities/payment_models.dart';

abstract class PaymentDatasource {
  Future<List<PaymentMethodData>> getPaymentMethods();

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
