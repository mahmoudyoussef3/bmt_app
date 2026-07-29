import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/packages/domain/entities/my_subscription.dart';
import 'package:bmt_app/apps/client/features/packages/domain/entities/package_plan.dart';
import 'package:bmt_app/apps/client/features/packages/domain/repositories/packages_repository.dart';
import 'package:bmt_app/apps/client/features/packages/domain/usecases/get_my_subscription_usecase.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/cubit/my_subscription_cubit.dart';
import 'package:bmt_app/apps/client/features/packages/presentation/screens/my_subscription_screen.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

class _StaticPackagesRepository implements PackagesRepository {
  _StaticPackagesRepository({this.subscription, this.error});

  final MySubscription? subscription;
  final Object? error;

  @override
  Future<MySubscription?> getMySubscription() async {
    final error = this.error;
    if (error != null) throw error;
    return subscription;
  }

  @override
  Future<List<PackagePlan>> getPackages() => throw UnimplementedError();

  @override
  Future<List<PackagePlan>> getOfficePackages(String officeId) =>
      throw UnimplementedError();
}

Future<MySubscriptionCubit> _pump(
  WidgetTester tester,
  _StaticPackagesRepository repo,
) async {
  final cubit = MySubscriptionCubit(GetMySubscriptionUseCase(repo));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<MySubscriptionCubit>.value(
        // Mirrors ClientCubitScopes.mySubscription, which owns the load.
        value: cubit..load(),
        child: const MySubscriptionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets(
    'renders the rider\'s own subscription usage, not the catalogue',
    (tester) async {
      final cubit = await _pump(
        tester,
        _StaticPackagesRepository(
          subscription: MySubscription(
            id: 'sub-1',
            packageName: 'Monthly Commute',
            routeName: 'Maadi - Downtown',
            status: 'active',
            tripsTotal: 30,
            tripsUsed: 12,
            startDate: DateTime(2026, 7, 1),
            endDate: DateTime(2026, 7, 31),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Monthly Commute'), findsOneWidget);
      expect(find.text('Maadi - Downtown'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('12 of 30 trips used'), findsOneWidget);
      expect(find.text('18 trips remaining'), findsOneWidget);
      expect(find.text('Jul 1, 2026'), findsOneWidget);
      expect(find.text('Jul 31, 2026'), findsOneWidget);
      // The bug this screen fixes: tapping the active-package card must never
      // land on the plan catalogue.
      expect(find.text('Commute Packages'), findsNothing);

      await cubit.close();
    },
  );

  testWidgets('unlimited-trip packages skip the used/remaining copy', (
    tester,
  ) async {
    final cubit = await _pump(
      tester,
      _StaticPackagesRepository(
        subscription: MySubscription(
          id: 'sub-2',
          packageName: 'Unlimited Pass',
          routeName: '',
          status: 'active',
          tripsTotal: 0,
          tripsUsed: 0,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Unlimited trips'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('no active subscription shows the empty state, not an error', (
    tester,
  ) async {
    final cubit = await _pump(tester, _StaticPackagesRepository());

    expect(tester.takeException(), isNull);
    expect(find.text('No active subscription'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('a fetch failure surfaces the retryable error card', (
    tester,
  ) async {
    final cubit = await _pump(
      tester,
      _StaticPackagesRepository(error: Exception('network down')),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('network down'), findsOneWidget);

    await cubit.close();
  });
}
