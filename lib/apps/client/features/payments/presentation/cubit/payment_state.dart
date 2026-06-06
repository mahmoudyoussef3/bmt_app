import '../../domain/entities/payment_models.dart';

sealed class PaymentState {
  const PaymentState();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentCheckoutLoaded extends PaymentState {
  const PaymentCheckoutLoaded({
    required this.methods,
    required this.selectedMethod,
    this.appliedPromoCode,
    this.promoDiscount = 0,
  });

  final List<PaymentMethodData> methods;
  final PaymentMethodType selectedMethod;
  final String? appliedPromoCode;
  final int promoDiscount;

  PaymentMethodData get selectedPaymentMethod {
    return methods.firstWhere((method) => method.type == selectedMethod);
  }

  bool get requiresReceipt {
    return selectedMethod == PaymentMethodType.instapay ||
        selectedMethod == PaymentMethodType.vodafoneCash;
  }

  PaymentCheckoutLoaded copyWith({
    PaymentMethodType? selectedMethod,
    String? appliedPromoCode,
    int? promoDiscount,
  }) {
    return PaymentCheckoutLoaded(
      methods: methods,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
    );
  }
}

class PaymentError extends PaymentState {
  const PaymentError(this.message);

  final String message;
}
