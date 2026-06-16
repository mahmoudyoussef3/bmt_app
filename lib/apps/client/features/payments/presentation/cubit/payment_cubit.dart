import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_models.dart';
import '../../domain/usecases/apply_promo_code_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit({
    required GetPaymentMethodsUseCase getPaymentMethods,
    required ApplyPromoCodeUseCase applyPromoCode,
  }) : _getPaymentMethods = getPaymentMethods,
       _applyPromoCode = applyPromoCode,
       super(const PaymentLoading());

  final GetPaymentMethodsUseCase _getPaymentMethods;
  final ApplyPromoCodeUseCase _applyPromoCode;

  Future<void> loadCheckout() async {
    emit(const PaymentLoading());
    try {
      final methods = await _getPaymentMethods();
      emit(
        PaymentCheckoutLoaded(
          methods: methods,
          selectedMethod: _initialMethod(methods),
        ),
      );
    } catch (error) {
      emit(PaymentError(error.toString()));
    }
  }

  void selectMethod(PaymentMethodType method) {
    final current = state;
    if (current is! PaymentCheckoutLoaded) return;
    emit(current.copyWith(selectedMethod: method));
  }

  void applyPromo(String code) {
    final current = state;
    if (current is! PaymentCheckoutLoaded) return;
    final normalized = code.trim().toUpperCase();
    emit(
      current.copyWith(
        appliedPromoCode: normalized.isEmpty ? null : normalized,
        promoDiscount: normalized.isEmpty ? 0 : _applyPromoCode(normalized),
      ),
    );
  }

  PaymentMethodType? _initialMethod(List<PaymentMethodData> methods) {
    if (methods.isEmpty) return null;
    for (final method in methods) {
      if (method.recommended) return method.type;
    }
    return methods.first.type;
  }
}
