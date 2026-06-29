import '../../domain/entities/loyalty_data.dart';

sealed class LoyaltyState {
  const LoyaltyState();
}

class LoyaltyLoading extends LoyaltyState {
  const LoyaltyLoading();
}

class LoyaltyLoaded extends LoyaltyState {
  const LoyaltyLoaded(this.data);

  final LoyaltyData data;
}

class LoyaltyError extends LoyaltyState {
  const LoyaltyError(this.message);

  final String message;
}
