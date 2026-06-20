import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/payments/presentation/widgets/payment_widgets.dart';

void main() {
  testWidgets('PromoCodeCard lays out in a narrow payment list', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: ListView(
                children: [
                  PromoCodeCard(
                    controller: controller,
                    appliedCode: null,
                    promoDiscount: 0,
                    onApply: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Promo code'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });
}
