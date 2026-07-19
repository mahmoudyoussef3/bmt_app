import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/loyalty/data/mappers/loyalty_mappers.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_account_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_reward_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_snapshot_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/loyalty_tier_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/models/points_transaction_model.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/loyalty_data.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/entities/redeemable_reward.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/repositories/loyalty_repository.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/cubit/loyalty_state.dart';
import 'package:bmt_app/apps/client/features/loyalty/presentation/screens/loyalty_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class _StaticRepository implements LoyaltyRepository {
  _StaticRepository(this.data);

  final LoyaltyData data;

  @override
  Future<LoyaltyData> getLoyaltyData() async => data;

  @override
  Future<void> redeemReward(RedeemableReward reward) async {}
}

LoyaltyData _data({
  int points = 2500,
  bool withTiers = true,
  bool withRows = true,
}) {
  return LoyaltySnapshotModel(
    account: LoyaltyAccountModel(points: points),
    transactions: withRows
        ? [
            PointsTransactionModel.fromJson({
              'title': 'Trip to AUC',
              'points': 120,
              'is_earned': true,
              'created_at': '2026-07-10T09:00:00.000Z',
            }),
            PointsTransactionModel.fromJson({
              'title': 'Redeemed: Free ride',
              'points': -300,
              'is_earned': false,
              'created_at': '2026-07-12T09:00:00.000Z',
            }),
          ]
        : const [],
    tiers: withTiers
        ? [
            LoyaltyTierModel.fromJson({
              'name': 'Gold',
              'points_required': '2000 pts',
              'icon_key': 'stars',
              'gradient_colors': ['4294951175', '4294924066'],
              'perks': ['Priority boarding', 'Double points weekends'],
            }),
          ]
        : const [],
    rewards: withRows
        ? [
            LoyaltyRewardModel.fromJson({
              'id': 'r1',
              'title': 'Free ride',
              'description': 'One free journey',
              'points_cost': 300,
              'value_label': '100% OFF',
              'category': 'FreeRide',
              'coupon_code': 'FREE1',
            }),
          ]
        : const [],
  ).toEntity();
}

Future<LoyaltyCubit> _pumpHub(WidgetTester tester, LoyaltyData data) async {
  final repo = _StaticRepository(data);
  final cubit = LoyaltyCubit(
    getData: GetLoyaltyDataUseCase(repo),
    redeemReward: RedeemLoyaltyRewardUseCase(repo),
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<LoyaltyCubit>.value(
        value: cubit..load(),
        child: const LoyaltyScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('renders all three panels without overflow or paint errors', (
    tester,
  ) async {
    final cubit = await _pumpHub(tester, _data());

    expect(find.text('Loyalty Portal'), findsOneWidget);
    expect(find.text('Priority boarding'), findsOneWidget);

    cubit.showView(LoyaltyView.history);
    await tester.pumpAndSettle();
    expect(find.text('Points Ledger Logs'), findsOneWidget);
    // Redemptions render one minus sign, not two.
    expect(find.text('-300 pts'), findsOneWidget);
    expect(find.text('+120 pts'), findsOneWidget);

    cubit.showView(LoyaltyView.rewards);
    await tester.pumpAndSettle();
    expect(find.text('Redeem Points Catalog'), findsOneWidget);
    // The badge reflects the earned tier rather than a hardcoded "Gold".
    expect(find.text('Gold Level Member'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('an unprovisioned tier catalog degrades instead of crashing', (
    tester,
  ) async {
    // The dashboard used to call firstWhere with no orElse here and throw.
    final cubit = await _pumpHub(
      tester,
      _data(withTiers: false, withRows: false),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Loyalty Portal'), findsOneWidget);
    expect(find.text("Membership levels aren't available right now."),
        findsOneWidget);

    await cubit.close();
  });

  testWidgets('empty ledger and catalog show empty states', (tester) async {
    final cubit = await _pumpHub(tester, _data(withRows: false));

    cubit.showView(LoyaltyView.history);
    await tester.pumpAndSettle();
    expect(find.text('No points activity yet'), findsOneWidget);

    cubit.showView(LoyaltyView.rewards);
    await tester.pumpAndSettle();
    expect(find.text('No rewards available'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('a Bronze rider is not labelled a Gold member', (tester) async {
    final cubit = await _pumpHub(tester, _data(points: 100));

    cubit.showView(LoyaltyView.rewards);
    await tester.pumpAndSettle();
    expect(find.text('Bronze Level Member'), findsOneWidget);
    expect(find.text('Gold Level Member'), findsNothing);

    await cubit.close();
  });
}
