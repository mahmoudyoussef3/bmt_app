import '../repositories/payment_repository.dart';

class ApplyPromoCodeUseCase {
  const ApplyPromoCodeUseCase(this._repository);

  final PaymentRepository _repository;

  /// Returns the discount amount for the given promo code.
  /// Returns 0 if the code is invalid, expired, or exhausted.
  Future<int> call(String code) => _repository.validatePromoCode(code);
}
