import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/notifications/domain/entities/client_notification.dart';
import 'package:bmt_app/apps/client/features/notifications/domain/entities/notification_destination.dart';
import 'package:bmt_app/apps/client/features/wallet/domain/entities/client_wallet.dart';
import 'package:bmt_app/apps/client/features/wallet/domain/repositories/client_wallet_repository.dart';
import 'package:bmt_app/apps/client/features/wallet/domain/usecases/get_client_wallet_summary_usecase.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/cubit/client_wallet_cubit.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/routes/wallet_routes.dart';

void main() {
  group('ClientWalletCubit', () {
    test('opens the only office automatically, and none when there are two',
        () async {
      // With one office there is nothing to choose between; with several,
      // auto-expanding one would be an arbitrary claim about which matters.
      var cubit = ClientWalletCubit(
        GetClientWalletSummaryUseCase(_FakeRepository(offices: 1)),
      );
      await cubit.load();
      expect((cubit.state as ClientWalletLoaded).expandedWalletId, 'wallet-0');

      cubit = ClientWalletCubit(
        GetClientWalletSummaryUseCase(_FakeRepository(offices: 2)),
      );
      await cubit.load();
      expect((cubit.state as ClientWalletLoaded).expandedWalletId, isNull);
    });

    test('tapping the open office collapses it', () async {
      final cubit = ClientWalletCubit(
        GetClientWalletSummaryUseCase(_FakeRepository(offices: 2)),
      );
      await cubit.load();

      cubit.toggleWallet('wallet-1');
      expect((cubit.state as ClientWalletLoaded).expandedWalletId, 'wallet-1');

      cubit.toggleWallet('wallet-1');
      expect((cubit.state as ClientWalletLoaded).expandedWalletId, isNull);
    });

    test('a refresh failure keeps the last good screen', () async {
      final repository = _FakeRepository(offices: 1);
      final cubit = ClientWalletCubit(GetClientWalletSummaryUseCase(repository));
      await cubit.load();

      repository.fail = true;
      await cubit.refresh();

      expect(cubit.state, isA<ClientWalletLoaded>());
    });

    test('a first-load failure surfaces as an error, not an empty wallet',
        () async {
      // "You have no balance" and "we could not check" are different claims,
      // and confusing them is how a rider concludes their refund vanished.
      final repository = _FakeRepository(offices: 1)..fail = true;
      final cubit = ClientWalletCubit(GetClientWalletSummaryUseCase(repository));
      await cubit.load();

      expect(cubit.state, isA<ClientWalletError>());
    });

    test('the total comes from the server, never re-added on the device',
        () async {
      // §14 case 15: a device that summed its own ledger would disagree with
      // the office the moment an operator posted an entry.
      final cubit = ClientWalletCubit(
        GetClientWalletSummaryUseCase(_FakeRepository(offices: 2)),
      );
      await cubit.load();

      expect((cubit.state as ClientWalletLoaded).summary.totalBalance, 999);
    });
  });

  group('notification deep link', () {
    test('a wallet notification routes to the wallet screen', () {
      final destination = resolveNotificationDestination(
        ClientNotification(
          id: 'n1',
          title: 'إضافة رصيد إلى محفظتك',
          body: 'تمت إضافة 100 ج.م',
          type: 'payment',
          category: NotificationCategory.payment,
          isRead: false,
          createdAt: DateTime(2026, 8, 6),
          actionUrl: '/wallet',
          data: const {'wallet_transaction_id': 't1', 'kind': 'cashback'},
        ),
      );

      expect(destination?.route, WalletRoutes.wallet);
    });

    test('the route constant matches the action_url the backend stamps', () {
      // `push_notification(..., '/wallet')` in the wallet RPCs and this
      // constant must not drift apart.
      expect(WalletRoutes.wallet, '/wallet');
    });
  });
}

class _FakeRepository implements ClientWalletRepository {
  _FakeRepository({required this.offices});

  final int offices;
  bool fail = false;

  @override
  Future<ClientWalletSummary> getSummary() async {
    if (fail) throw Exception('تعذر تحميل المحفظة');
    return ClientWalletSummary(
      totalBalance: 999,
      wallets: [
        for (var i = 0; i < offices; i++)
          ClientWallet(
            walletId: 'wallet-$i',
            officeId: 'office-$i',
            officeName: 'مكتب $i',
            balance: 100,
            availableBalance: 100,
            status: 'active',
            entryCount: 2,
            entries: [
              ClientWalletEntry(
                id: 'e$i',
                seq: 1,
                kind: ClientWalletEntryKind.refund,
                category: 'trip_cancelled',
                amount: 100,
                balanceAfter: 100,
                status: 'posted',
                reason: 'إلغاء الرحلة',
                createdAt: DateTime(2026, 8, 6),
              ),
            ],
          ),
      ],
      generatedAt: DateTime(2026, 8, 6),
    );
  }
}
