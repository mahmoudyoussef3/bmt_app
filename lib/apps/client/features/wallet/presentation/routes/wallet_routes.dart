/// Named routes for the rider's wallet.
///
/// `/wallet` is also the `action_url` the backend stamps on every wallet and
/// refund notification, so this constant and that string must stay in step —
/// `notification_destination_test.dart` asserts the pair.
class WalletRoutes {
  WalletRoutes._();

  static const wallet = '/wallet';
}
