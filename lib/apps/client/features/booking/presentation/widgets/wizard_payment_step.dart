import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';

const _methods = [
  _PaymentMethod('instapay', 'InstaPay', Icons.send_to_mobile_rounded, 'Transfer to 01012345678 (InstaPay)'),
  _PaymentMethod('vodafone_cash', 'Vodafone Cash', Icons.phone_android_rounded, 'Transfer to 01012345678'),
  _PaymentMethod('bank_transfer', 'Bank Transfer', Icons.account_balance_rounded, 'Transfer to Bank Account'),
];

class WizardPaymentStep extends StatelessWidget {
  const WizardPaymentStep({super.key, required this.onConfirm});
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
      builder: (context, session) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('How would you like to pay?',
                      style: ClientTypography.headingSmall(context)),
                  const SizedBox(height: 4),
                  Text('Choose your preferred payment method',
                      style: ClientTypography.bodySmall(context)
                          .copyWith(color: ClientColors.textSecondaryFor(context))),
                  const SizedBox(height: 20),
                  ..._methods.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MethodTile(
                          method: m,
                          isSelected: session.paymentMethod == m.id,
                          onTap: () {
                            context.read<BookingWizardCubit>().selectPaymentMethod(m.id);
                          },
                        ),
                      )),
                  if (session.paymentMethod != null) ...[
                    const SizedBox(height: 20),
                    _ReceiptUploadSection(session: session),
                  ],
                  const SizedBox(height: 20),
                  _TotalBanner(session: session),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ClientButton(
                  label: 'Submit for Review',
                  onPressed: session.paymentValid ? onConfirm : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.method, required this.isSelected, required this.onTap});
  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ClientColors.primaryLight : ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? ClientColors.primary : ClientColors.borderFor(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? ClientColors.primary : ClientColors.surfaceSubtleFor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method.icon, size: 22,
                  color: isSelected ? Colors.white : ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(method.label, style: ClientTypography.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w600)),
                Text(method.description,
                    style: ClientTypography.bodySmall(context)
                        .copyWith(color: ClientColors.textSecondaryFor(context))),
              ]),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: ClientColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.session});
  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(children: [
        Expanded(child: Text('Total amount',
            style: ClientTypography.bodyMedium(context)
                .copyWith(fontWeight: FontWeight.w600))),
        Text('EGP ${session.totalPrice.toStringAsFixed(0)}',
            style: ClientTypography.headingSmall(context).copyWith(
              color: ClientColors.primary, fontWeight: FontWeight.w700,
            )),
      ]),
    );
  }
}

class _ReceiptUploadSection extends StatelessWidget {
  const _ReceiptUploadSection({required this.session});
  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final hasReceipt = session.receiptUrl != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Proof',
              style: ClientTypography.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Please transfer the total amount and upload the receipt to confirm your booking.',
              style: ClientTypography.bodySmall(context)
                  .copyWith(color: ClientColors.textSecondaryFor(context))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Simulate file upload
                context.read<BookingWizardCubit>().setReceiptUrl('https://example.com/receipt.jpg');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt uploaded successfully (Simulated)')),
                );
              },
              icon: Icon(
                hasReceipt ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: hasReceipt ? ClientColors.journeyGreen : ClientColors.primary,
              ),
              label: Text(hasReceipt ? 'Receipt Uploaded' : 'Upload Receipt'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: hasReceipt ? ClientColors.journeyGreen : ClientColors.primary,
                side: BorderSide(
                  color: hasReceipt ? ClientColors.journeyGreen : ClientColors.primary,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod(this.id, this.label, this.icon, this.description);
  final String id;
  final String label;
  final IconData icon;
  final String description;
}
