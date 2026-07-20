import '../entities/payment_models.dart';
import '../repositories/payment_repository.dart';

/// Waits for the gateway's own verdict to reach our database.
///
/// The rider comes back from the Paymob WebView before Paymob's callback has
/// necessarily arrived, so the moment the WebView closes proves nothing either
/// way. This polls the booking's real payment row for a short window and
/// reports what the server settled on — never what the redirect URL claimed.
///
/// A timeout is not a failure: the money may well have moved and the callback
/// simply be late. The caller is expected to treat [CardPaymentState.pending]
/// as "we are still checking", not as "you were not charged".
class AwaitCardSettlementUseCase {
  const AwaitCardSettlementUseCase(
    this._repository, {
    this.pollTimeout = defaultTimeout,
    this.pollInterval = defaultInterval,
  });

  final PaymentRepository _repository;

  /// How long to keep asking, and how often. Paymob's callback normally lands
  /// within a couple of seconds of the rider finishing 3-D Secure. Both are
  /// injectable so tests can exercise the wait without spending it.
  static const Duration defaultTimeout = Duration(seconds: 20);
  static const Duration defaultInterval = Duration(milliseconds: 1500);

  final Duration pollTimeout;
  final Duration pollInterval;

  /// Pass [timeout] `Duration.zero` to ask exactly once — the right shape when
  /// the rider abandoned the gateway themselves and there is no callback worth
  /// waiting for.
  Future<CardPaymentState> call(String bookingId, {Duration? timeout}) async {
    final deadline = DateTime.now().add(timeout ?? pollTimeout);
    CardPaymentState? last;

    while (true) {
      try {
        final state = await _repository.getCardPaymentState(bookingId);
        last = state;
        if (!state.pending) return state;
      } catch (_) {
        // A dropped poll is not an answer — keep asking until the deadline
        // rather than reporting a network blip as an unpaid booking.
      }
      if (!DateTime.now().add(pollInterval).isBefore(deadline)) break;
      await Future<void>.delayed(pollInterval);
    }

    return last ??
        const CardPaymentState(
          settled: false,
          failed: false,
          bookingStatus: '',
          paymentStatus: '',
        );
  }
}
