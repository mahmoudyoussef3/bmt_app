import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/loyalty/data/mappers/loyalty_mappers.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_account_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_reward_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_snapshot_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_tier_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/points_transaction_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/loyalty_data.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/loyalty_tier_ladder.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/redeemable_reward.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_state.dart';

/// Repository whose reads and redemptions are scripted per test.
class _FakeLoyaltyRepository implements LoyaltyRepository {
  _FakeLoyaltyRepository({required this.data, this.onRedeem});

  LoyaltyData data;
  final Object? Function()? onRedeem;
  int redeemCalls = 0;

  @override
  Future<LoyaltyData> getLoyaltyData() async => data;

  @override
  Future<void> redeemReward(RedeemableReward reward) async {
    redeemCalls++;
    final failure = onRedeem?.call();
    if (failure != null) throw failure;
  }
}

LoyaltyData _dataWith({
  int points = 500,
  List<dynamic> tierRows = const <dynamic>[],
}) {
  return LoyaltySnapshotModel(
    account: LoyaltyAccountModel(points: points),
    transactions: const [],
    tiers: tierRows
        .map((row) => LoyaltyTierModel.fromJson(row as Map<String, dynamic>))
        .toList(),
    rewards: const [],
  ).toEntity();
}

const _reward = RedeemableReward(
  id: 'r1',
  title: 'Free ride',
  description: '',
  pointsCost: 300,
  valueLabel: '100%',
  category: 'FreeRide',
  couponCode: 'ABC123',
);

void main() {
  group('LoyaltyTierLadder', () {
    test('is the single authority on tier names and progress', () {
      expect(LoyaltyTierLadder.tierNameFor(0), 'Bronze');
      expect(LoyaltyTierLadder.tierNameFor(1000), 'Silver');
      expect(LoyaltyTierLadder.tierNameFor(2000), 'Gold');
      expect(LoyaltyTierLadder.tierNameFor(3500), 'Platinum');

      expect(LoyaltyTierLadder.progressToTop(1500), closeTo(0.5, 0.001));
      expect(LoyaltyTierLadder.progressToTop(9999), 1.0);
      expect(LoyaltyTierLadder.pointsToTop(1000), 2000);
      expect(LoyaltyTierLadder.pointsToTop(9999), 0);
    });
  });

  group('LoyaltyData.activeTier', () {
    test('returns null instead of throwing when tiers are unprovisioned', () {
      // The datasource degrades a missing `loyalty_tiers` table to an empty
      // list; resolving the active tier used to throw a StateError here.
      expect(_dataWith(points: 500).activeTier, isNull);
    });

    test('returns null when no row matches the earned tier', () {
      final data = _dataWith(
        points: 2500, // Gold
        tierRows: [
          {'name': 'Bronze', 'points_required': '0 pts'},
        ],
      );
      expect(data.currentTierName, 'Gold');
      expect(data.activeTier, isNull);
    });

    test('resolves the matching tier when present', () {
      final data = _dataWith(
        points: 2500,
        tierRows: [
          {'name': 'Gold', 'points_required': '2000 pts'},
        ],
      );
      expect(data.activeTier?.name, 'Gold');
    });
  });

  group('LoyaltyTierModel gradient stops', () {
    test('falls back when the column is missing, empty or too short', () {
      for (final raw in [
        null,
        <dynamic>[],
        <dynamic>['4294967295'],
        <dynamic>['not-a-color'],
      ]) {
        final tier = LoyaltyTierModel.fromJson({'gradient_colors': raw});
        // LinearGradient needs at least two stops or it throws when painted.
        expect(tier.gradientColors.length, greaterThanOrEqualTo(2));
      }
    });

    test('keeps operator-configured stops', () {
      final tier = LoyaltyTierModel.fromJson({
        'gradient_colors': ['16711680', '255'],
      });
      expect(tier.gradientColors, [16711680, 255]);
    });
  });

  group('PointsTransaction mapping', () {
    test('normalizes a negative redemption to a magnitude', () {
      // The ledger stores redemptions negative; rendering that alongside the
      // "-" prefix produced "--300 pts".
      final tx = PointsTransactionModel.fromJson({
        'title': 'Redeemed: Free ride',
        'points': -300,
        'is_earned': false,
        'created_at': '2026-07-18T10:22:31.000Z',
      }).toEntity();

      expect(tx.points, 300);
      expect(tx.isEarned, isFalse);
      expect(tx.date, '2026-07-18');
    });

    test('leaves title and date empty rather than inventing English text', () {
      final tx = PointsTransactionModel.fromJson(
        const <String, dynamic>{},
      ).toEntity();
      expect(tx.title, isEmpty);
      expect(tx.date, isEmpty);
    });
  });

  group('LoyaltyRewardModel', () {
    test('defaults defensively', () {
      final reward = LoyaltyRewardModel.fromJson(
        const <String, dynamic>{},
      ).toEntity();
      expect(reward.pointsCost, 0);
      expect(reward.category, 'Discount');
    });
  });

  group('LoyaltyCubit', () {
    test('load emits loading then loaded', () async {
      final repo = _FakeLoyaltyRepository(data: _dataWith());
      final cubit = _cubitFor(repo);
      final emitted = expectLater(
        cubit.stream,
        emitsInOrder([isA<LoyaltyLoading>(), isA<LoyaltyLoaded>()]),
      );

      await cubit.load();

      await emitted;
      await cubit.close();
    });

    test('a failed redeem keeps the panel loaded and reports the reason',
        () async {
      final repo = _FakeLoyaltyRepository(
        data: _dataWith(),
        onRedeem: () => Exception('nope'),
      );
      final cubit = _cubitFor(repo);
      await cubit.load();
      cubit.showView(LoyaltyView.rewards);

      final failure = await cubit.redeem(_reward);

      expect(failure, contains('nope'));
      final state = cubit.state;
      // Losing the whole hub over one unavailable reward is what we fixed.
      expect(state, isA<LoyaltyLoaded>());
      expect((state as LoyaltyLoaded).isRedeeming, isFalse);
      expect(state.view, LoyaltyView.rewards);
      await cubit.close();
    });

    test('a successful redeem re-reads and stays on the same panel', () async {
      final repo = _FakeLoyaltyRepository(data: _dataWith(points: 500));
      final cubit = _cubitFor(repo);
      await cubit.load();
      cubit.showView(LoyaltyView.rewards);
      repo.data = _dataWith(points: 200);

      final failure = await cubit.redeem(_reward);

      expect(failure, isNull);
      final state = cubit.state as LoyaltyLoaded;
      expect(state.data.currentPoints, 200);
      expect(state.view, LoyaltyView.rewards);
      await cubit.close();
    });

    test('ignores a second redeem while one is in flight', () async {
      final repo = _FakeLoyaltyRepository(data: _dataWith());
      final cubit = _cubitFor(repo);
      await cubit.load();

      await Future.wait([cubit.redeem(_reward), cubit.redeem(_reward)]);

      expect(repo.redeemCalls, 1);
      await cubit.close();
    });

    test('popView closes a panel, then reports nothing left to close',
        () async {
      final cubit = _cubitFor(_FakeLoyaltyRepository(data: _dataWith()));
      await cubit.load();
      cubit.showView(LoyaltyView.history);

      expect(cubit.popView(), isTrue);
      expect((cubit.state as LoyaltyLoaded).view, LoyaltyView.dashboard);
      expect(cubit.popView(), isFalse);
      await cubit.close();
    });
  });
}

LoyaltyCubit _cubitFor(LoyaltyRepository repo) => LoyaltyCubit(
  getData: GetLoyaltyDataUseCase(repo),
  redeemReward: RedeemLoyaltyRewardUseCase(repo),
);
