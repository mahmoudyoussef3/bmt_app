import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/client_wallet.dart';
import '../../domain/usecases/get_client_wallet_summary_usecase.dart';

sealed class ClientWalletState {
  const ClientWalletState();
}

class ClientWalletLoading extends ClientWalletState {
  const ClientWalletLoading();
}

class ClientWalletError extends ClientWalletState {
  const ClientWalletError(this.message);

  final String message;
}

class ClientWalletLoaded extends ClientWalletState {
  const ClientWalletLoaded({required this.summary, this.expandedWalletId});

  final ClientWalletSummary summary;

  /// The office whose history is open. One at a time: three offices' ledgers
  /// stacked on a phone is a scroll, not an answer.
  final String? expandedWalletId;

  ClientWalletLoaded copyWith({
    ClientWalletSummary? summary,
    String? expandedWalletId,
    bool collapse = false,
  }) {
    return ClientWalletLoaded(
      summary: summary ?? this.summary,
      expandedWalletId: collapse
          ? null
          : (expandedWalletId ?? this.expandedWalletId),
    );
  }
}

/// Drives the rider's read-only wallet screen.
///
/// There is no action here beyond loading and expanding, and that is the point:
/// the balance always comes from the server and is never computed on the device
/// (§14 case 15). A phone that added up its own ledger would disagree with the
/// office the moment an operator posted an entry.
class ClientWalletCubit extends Cubit<ClientWalletState> {
  ClientWalletCubit(this._getSummary) : super(const ClientWalletLoading());

  final GetClientWalletSummaryUseCase _getSummary;

  Future<void> load() async {
    emit(const ClientWalletLoading());
    try {
      final summary = await _getSummary();
      if (isClosed) return;
      emit(
        ClientWalletLoaded(
          summary: summary,
          // With one office there is nothing to choose between, so its history
          // opens straight away.
          expandedWalletId: summary.wallets.length == 1
              ? summary.wallets.first.walletId
              : null,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(ClientWalletError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Silent re-read for pull-to-refresh: keeps the open office open and never
  /// replaces a good screen with a spinner.
  Future<void> refresh() async {
    final current = state;
    if (current is! ClientWalletLoaded) return await load();
    try {
      final summary = await _getSummary();
      if (isClosed) return;
      emit(current.copyWith(summary: summary));
    } catch (_) {
      // Keep what is on screen. The next pull retries.
    }
  }

  void toggleWallet(String walletId) {
    final current = state;
    if (current is! ClientWalletLoaded) return;
    emit(
      current.expandedWalletId == walletId
          ? current.copyWith(collapse: true)
          : current.copyWith(expandedWalletId: walletId),
    );
  }
}
