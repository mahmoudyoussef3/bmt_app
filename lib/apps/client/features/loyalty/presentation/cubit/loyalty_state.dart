import '../../domain/entities/loyalty_data.dart';

/// Which of the hub's three panels is on screen.
///
/// This is cubit-owned rather than `setState`-owned: it is view state the
/// screen reads, so it belongs in the loaded state and the screens stay
/// stateless.
enum LoyaltyView { dashboard, history, rewards }

sealed class LoyaltyState {
  const LoyaltyState();
}

class LoyaltyLoading extends LoyaltyState {
  const LoyaltyLoading();
}

class LoyaltyLoaded extends LoyaltyState {
  const LoyaltyLoaded(
    this.data, {
    this.view = LoyaltyView.dashboard,
    this.isRedeeming = false,
  });

  final LoyaltyData data;
  final LoyaltyView view;

  /// True while a redemption is in flight. The panel stays on screen so the
  /// rider keeps their context instead of dropping to a full-screen spinner.
  final bool isRedeeming;

  LoyaltyLoaded copyWith({
    LoyaltyData? data,
    LoyaltyView? view,
    bool? isRedeeming,
  }) {
    return LoyaltyLoaded(
      data ?? this.data,
      view: view ?? this.view,
      isRedeeming: isRedeeming ?? this.isRedeeming,
    );
  }
}

class LoyaltyError extends LoyaltyState {
  const LoyaltyError(this.message);

  final String message;
}
