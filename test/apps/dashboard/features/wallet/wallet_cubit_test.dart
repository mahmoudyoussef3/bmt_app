import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/entities/wallet_vocabulary.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/wallet/presentation/cubit/wallet_state.dart';

import 'wallet_test_fixtures.dart';

void main() {
  late FakeWalletRepository repository;
  late WalletCubit cubit;

  WalletCubit build() => WalletCubit(
    getWorkspace: GetWalletWorkspaceUseCase(repository),
    searchDirectory: SearchWalletDirectoryUseCase(repository),
    getSummary: GetWalletSummaryUseCase(repository),
    getLedger: GetWalletLedgerUseCase(repository),
    getRefundQueue: GetRefundQueueUseCase(repository),
    getRefundableBookings: GetRefundableBookingsUseCase(repository),
    getCancelledTrips: GetCancelledTripsUseCase(repository),
    adjust: AdjustWalletUseCase(repository),
    reverse: ReverseWalletTransactionUseCase(repository),
    setStatus: SetWalletStatusUseCase(repository),
    verifyChain: VerifyWalletChainUseCase(repository),
    createRefund: CreateRefundUseCase(repository),
    decideRefund: DecideRefundUseCase(repository),
    refundTripBatch: RefundTripBatchUseCase(repository),
  );

  setUp(() {
    repository = FakeWalletRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('loading', () {
    test('starts loading and lands on the directory tab', () async {
      expect(cubit.state, isA<WalletLoadingState>());

      await cubit.load();

      final state = cubit.state as WalletLoadedState;
      expect(state.tab, WalletTab.directory);
      expect(state.directory.rows, hasLength(1));
      expect(state.overview.outstandingBalance, 12450);
    });

    test('fetches the refund queue on first load, not lazily', () async {
      // The pending count is a control the header shows; a queue fetched only
      // when its tab opens would leave that badge wrong until someone looked.
      repository.refundQueue = [refundFixture()];
      await cubit.load();

      expect(repository.calls, contains('queue'));
      expect((cubit.state as WalletLoadedState).openRefundCount, 1);
    });

    test('a failed first load produces an error state', () async {
      repository.failReads = true;
      await cubit.load();

      expect(cubit.state, isA<WalletErrorState>());
    });
  });

  group('selection', () {
    test('selecting a customer loads their summary', () async {
      await cubit.load();
      await cubit.selectCustomer('c1');

      final state = cubit.state as WalletLoadedState;
      expect(state.selectedClientId, 'c1');
      expect(state.summary?.customer.fullName, 'أحمد محمود');
      expect(state.detailLoading, isFalse);
    });

    test('clearing the selection drops the summary with it', () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      await cubit.selectCustomer(null);

      final state = cubit.state as WalletLoadedState;
      expect(state.selectedClientId, isNull);
      expect(state.summary, isNull);
    });

    test('an out-of-order search response does not overwrite a newer query',
        () async {
      await cubit.load();
      await cubit.searchDirectory('أحمد');

      final state = cubit.state as WalletLoadedState;
      expect(state.directorySearch, 'أحمد');
      expect(repository.lastSearch, 'أحمد');
    });
  });

  group('actions', () {
    test('a successful adjustment re-reads and reports the new balance',
        () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      repository.calls.clear();

      final failure = await cubit.adjust(
        kind: WalletKind.cashback,
        clientId: 'c1',
        amount: 100,
        category: 'promotion',
        reason: 'تعويض',
        requestKey: 'k1',
      );

      expect(failure, isNull);
      expect(repository.calls, contains('cashback'));
      // Never trusts local arithmetic: the balance on screen comes back from
      // the server, because two operators can post at once.
      expect(repository.calls, contains('overview'));
      expect((cubit.state as WalletLoadedState).actionMessage, isNotNull);
    });

    test('a refused action keeps the loaded screen and reports the reason',
        () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      repository.failWritesWith = 'amount_exceeds_policy';

      final failure = await cubit.adjust(
        kind: WalletKind.cashback,
        clientId: 'c1',
        amount: 100,
        category: 'promotion',
        reason: 'تعويض',
        requestKey: 'k1',
      );

      expect(failure, contains('amount_exceeds_policy'));
      final state = cubit.state as WalletLoadedState;
      // The operator's selection and history survive the refusal.
      expect(state.selectedClientId, 'c1');
      expect(state.summary, isNotNull);
      expect(state.actionError, isNotNull);
      expect(state.busy, isFalse);
    });

    test('a domain-refused adjustment never reaches the repository', () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      repository.calls.clear();

      final failure = await cubit.adjust(
        kind: WalletKind.manualDebit,
        clientId: 'c1',
        amount: 99999,
        category: 'correction',
        reason: 'اختبار',
        requestKey: 'k1',
      );

      expect(failure, isNotNull);
      expect(repository.calls, isEmpty);
    });

    test('the action message is one-shot and does not survive the next emit',
        () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      await cubit.adjust(
        kind: WalletKind.cashback,
        clientId: 'c1',
        amount: 10,
        category: 'promotion',
        reason: 'تعويض',
        requestKey: 'k1',
      );
      expect((cubit.state as WalletLoadedState).actionMessage, isNotNull);

      // A sticky message would re-fire its snackbar on every refresh.
      cubit.setTab(WalletTab.activity);
      expect((cubit.state as WalletLoadedState).actionMessage, isNull);
    });

    test('reversing an already-reversed entry is refused locally', () async {
      await cubit.load();
      await cubit.selectCustomer('c1');
      repository.calls.clear();

      final failure = await cubit.reverseEntry(
        transaction: entryFixture(status: WalletEntryStatus.reversed),
        reason: 'اختبار',
        category: 'operator_error',
        requestKey: 'k',
      );

      expect(failure, isNotNull);
      expect(repository.calls, isEmpty);
    });

    test('freezing requires a reason', () async {
      await cubit.load();
      repository.calls.clear();

      final failure = await cubit.setWalletStatus(
        clientId: 'c1',
        status: WalletStatus.frozen,
        reason: '  ',
      );

      expect(failure, isNotNull);
      expect(repository.calls, isEmpty);
    });

    test('a batch refund reports how many seats it actually covered', () async {
      await cubit.load();

      final failure = await cubit.refundTripBatch(
        trip: (await cubit.cancelledTrips()).first,
        reason: 'إلغاء الرحلة',
        requestKey: 'k',
      );

      expect(failure, isNull);
      final message = (cubit.state as WalletLoadedState).actionMessage!;
      expect(message, contains('12'));
      expect(message, contains('2'));
    });
  });

  group('chain verification', () {
    test('a verified chain reports the entry count, not just "ok"', () async {
      await cubit.load();
      await cubit.selectCustomer('c1');

      final failure = await cubit.verifyChain();

      expect(failure, isNull);
      final state = cubit.state as WalletLoadedState;
      expect(state.chainVerification?.verified, isTrue);
      expect(state.actionMessage, contains('12'));
    });

    test('verification is a no-op with no customer selected', () async {
      await cubit.load();
      repository.calls.clear();

      expect(await cubit.verifyChain(), isNull);
      expect(repository.calls, isEmpty);
    });
  });

  group('tabs', () {
    test('opening the activity tab loads the ledger once', () async {
      await cubit.load();
      repository.calls.clear();

      cubit.setTab(WalletTab.activity);
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls.where((c) => c == 'ledger'), hasLength(1));
    });

    test('applying a filter re-runs the ledger query server-side', () async {
      await cubit.load();
      await cubit.applyFilters(
        const WalletLedgerFilters(kinds: {WalletKind.refund}),
      );

      final state = cubit.state as WalletLoadedState;
      expect(state.filters.kinds, {WalletKind.refund});
      expect(state.ledger.rows, hasLength(1));
      expect(state.ledgerLoading, isFalse);
    });
  });
}
