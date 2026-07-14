import '../../domain/entities/payment_models.dart';

sealed class PaymentState {
  const PaymentState();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

/// What happened to the last promo code the rider submitted. Kept separate from
/// the code itself so a rejected code can be reported by name — and so a
/// rejected code cannot leave an earlier accepted one on screen.
enum PromoStatus { none, checking, applied, invalid }

class PaymentCheckoutLoaded extends PaymentState {
  const PaymentCheckoutLoaded({
    required this.methods,
    this.selectedMethod,
    this.promoCode,
    this.promoStatus = PromoStatus.none,
    this.promoDiscount = 0,
  });

  final List<PaymentMethodData> methods;
  final PaymentMethodType? selectedMethod;

  /// The code last submitted — accepted or not. [promoStatus] says which.
  final String? promoCode;
  final PromoStatus promoStatus;
  final int promoDiscount;

  PaymentMethodData? get selectedPaymentMethod {
    final method = selectedMethod;
    if (method == null) return null;
    for (final item in methods) {
      if (item.type == method) return item;
    }
    return null;
  }

  /// Transfer methods clear only once operations have seen proof of payment, so
  /// they route through the receipt step instead of charging directly.
  bool get requiresReceipt {
    return selectedMethod == PaymentMethodType.instapay ||
        selectedMethod == PaymentMethodType.vodafoneCash ||
        selectedMethod == PaymentMethodType.bankTransfer;
  }

  PaymentCheckoutLoaded withMethod(PaymentMethodType method) {
    return PaymentCheckoutLoaded(
      methods: methods,
      selectedMethod: method,
      promoCode: promoCode,
      promoStatus: promoStatus,
      promoDiscount: promoDiscount,
    );
  }

  PaymentCheckoutLoaded withPromo({
    required String? code,
    required PromoStatus status,
    required int discount,
  }) {
    return PaymentCheckoutLoaded(
      methods: methods,
      selectedMethod: selectedMethod,
      promoCode: code,
      promoStatus: status,
      promoDiscount: discount,
    );
  }
}

class PaymentError extends PaymentState {
  const PaymentError(this.message);

  final String message;
}
