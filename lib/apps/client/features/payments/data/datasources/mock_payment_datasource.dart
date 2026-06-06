import '../../domain/entities/payment_models.dart';

class MockPaymentDatasource {
  const MockPaymentDatasource();

  Future<List<PaymentMethodData>> getPaymentMethods() async {
    return _paymentMethods;
  }
}

const _paymentMethods = [
  PaymentMethodData(
    type: PaymentMethodType.creditCard,
    title: 'Credit Card',
    subtitle: 'Pay securely using your Visa or Mastercard',
    recommended: true,
  ),
  PaymentMethodData(
    type: PaymentMethodType.instapay,
    title: 'InstaPay',
    subtitle: 'Transfer directly using InstaPay ID & upload receipt',
  ),
  PaymentMethodData(
    type: PaymentMethodType.vodafoneCash,
    title: 'Mobile Wallet',
    subtitle: 'Pay via Vodafone Cash or other wallets & upload receipt',
  ),
  PaymentMethodData(
    type: PaymentMethodType.cashOnBoarding,
    title: 'Cash with Driver',
    subtitle: 'Pay cash directly to driver upon boarding',
  ),
  PaymentMethodData(
    type: PaymentMethodType.walletBalance,
    title: 'User Balance',
    subtitle: 'Deduct fare instantly from your account balance',
  ),
];
