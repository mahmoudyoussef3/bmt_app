import 'dart:typed_data';

import '../../domain/entities/payment_models.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._datasource);

  final PaymentDatasource _datasource;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() {
    return _datasource.getPaymentMethods();
  }

  @override
  Future<int> validatePromoCode(String code) {
    return _datasource.validatePromoCode(code);
  }

  @override
  Future<String> uploadReceipt({
    required String bookingOrTripId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) {
    return _datasource.uploadReceipt(
      bookingOrTripId: bookingOrTripId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  @override
  Future<CardPaymentSession> createCardPaymentSession({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  }) {
    return _datasource.createCardPaymentSession(
      checkoutData: checkoutData,
      paymentMethod: paymentMethod,
      bookingId: bookingId,
      amount: amount,
    );
  }
}
