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
    emit(current.withMethod(method));
  }

  Future<void> applyPromo(String code) async {
    final current = state;
    if (current is! PaymentCheckoutLoaded) return;

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      clearPromo();
      return;
    }

    emit(
      current.withPromo(
        code: normalized,
        status: PromoStatus.checking,
        discount: 0,
      ),
    );

    // A code that fails to validate is a rejected code, not a broken checkout:
    // the rider can still pay full fare, so this never surfaces as an error
    // state that would take the pay button away.
    var discount = 0;
    try {
      discount = await _applyPromoCode(normalized);
    } catch (_) {
      discount = 0;
    }

    // Re-read after the async gap in case the rider moved on.
    final latest = state;
    if (latest is! PaymentCheckoutLoaded) return;
    if (latest.promoCode != normalized) return;

    emit(
      latest.withPromo(
        code: normalized,
        status: discount > 0 ? PromoStatus.applied : PromoStatus.invalid,
        discount: discount,
      ),
    );
  }

  void clearPromo() {
    final current = state;
    if (current is! PaymentCheckoutLoaded) return;
    emit(current.withPromo(code: null, status: PromoStatus.none, discount: 0));
  }

  PaymentMethodType? _initialMethod(List<PaymentMethodData> methods) {
    if (methods.isEmpty) return null;
    for (final method in methods) {
      if (method.recommended) return method.type;
    }
    return methods.first.type;
  }
}
