import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/dashboard_session.dart';
import 'data/datasources/supabase_wallet_datasource.dart';
import 'data/datasources/wallet_datasource.dart';
import 'data/repositories/wallet_repository_impl.dart';
import 'domain/repositories/wallet_repository.dart';
import 'domain/usecases/wallet_usecases.dart';
import 'presentation/cubit/wallet_cubit.dart';

/// Registers محفظة العملاء: datasource → repository → use cases → cubit.
/// Idempotent, matching the rest of `registerDashboardDependencies`.
void registerWalletDependencies(GetIt di) {
  if (!di.isRegistered<WalletDatasource>()) {
    di.registerLazySingleton<WalletDatasource>(
      () => SupabaseWalletDatasource(
        di<SupabaseClient>(),
        di<DashboardSession>(),
      ),
    );
  }

  if (!di.isRegistered<WalletRepository>()) {
    di.registerLazySingleton<WalletRepository>(
      () => WalletRepositoryImpl(di<WalletDatasource>()),
    );
  }

  void useCase<T extends Object>(T Function() create) {
    if (!di.isRegistered<T>()) di.registerLazySingleton<T>(create);
  }

  WalletRepository repository() => di<WalletRepository>();

  useCase<GetWalletWorkspaceUseCase>(
    () => GetWalletWorkspaceUseCase(repository()),
  );
  useCase<SearchWalletDirectoryUseCase>(
    () => SearchWalletDirectoryUseCase(repository()),
  );
  useCase<GetWalletSummaryUseCase>(() => GetWalletSummaryUseCase(repository()));
  useCase<GetWalletLedgerUseCase>(() => GetWalletLedgerUseCase(repository()));
  useCase<GetRefundQueueUseCase>(() => GetRefundQueueUseCase(repository()));
  useCase<GetRefundableBookingsUseCase>(
    () => GetRefundableBookingsUseCase(repository()),
  );
  useCase<GetCancelledTripsUseCase>(
    () => GetCancelledTripsUseCase(repository()),
  );
  useCase<AdjustWalletUseCase>(() => AdjustWalletUseCase(repository()));
  useCase<ReverseWalletTransactionUseCase>(
    () => ReverseWalletTransactionUseCase(repository()),
  );
  useCase<SetWalletStatusUseCase>(() => SetWalletStatusUseCase(repository()));
  useCase<VerifyWalletChainUseCase>(
    () => VerifyWalletChainUseCase(repository()),
  );
  useCase<CreateRefundUseCase>(() => CreateRefundUseCase(repository()));
  useCase<DecideRefundUseCase>(() => DecideRefundUseCase(repository()));
  useCase<RefundTripBatchUseCase>(() => RefundTripBatchUseCase(repository()));
  useCase<ExportWalletStatementUseCase>(
    () => ExportWalletStatementUseCase(repository()),
  );

  if (!di.isRegistered<WalletCubit>()) {
    di.registerFactory(
      () => WalletCubit(
        getWorkspace: di<GetWalletWorkspaceUseCase>(),
        searchDirectory: di<SearchWalletDirectoryUseCase>(),
        getSummary: di<GetWalletSummaryUseCase>(),
        getLedger: di<GetWalletLedgerUseCase>(),
        getRefundQueue: di<GetRefundQueueUseCase>(),
        getRefundableBookings: di<GetRefundableBookingsUseCase>(),
        getCancelledTrips: di<GetCancelledTripsUseCase>(),
        adjust: di<AdjustWalletUseCase>(),
        reverse: di<ReverseWalletTransactionUseCase>(),
        setStatus: di<SetWalletStatusUseCase>(),
        verifyChain: di<VerifyWalletChainUseCase>(),
        createRefund: di<CreateRefundUseCase>(),
        decideRefund: di<DecideRefundUseCase>(),
        refundTripBatch: di<RefundTripBatchUseCase>(),
        exportStatement: di<ExportWalletStatementUseCase>(),
      ),
    );
  }
}
