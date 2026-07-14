import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_payment_mapping.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_receipt_upload.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_transfer_panel.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_assurance.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_fare_card.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_method_picker.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_notice.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_pay_bar.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_ticket_card.dart';

/// The wizard's last step, drawn with the same checkout the rest of the app
/// pays through — the ticket, the fare, the methods, the pay bar.
///
/// The wizard supplies the frame (its own app bar and progress rail), so this
/// is the checkout body only: no header, no second progress indicator.
class WizardPaymentBody extends StatelessWidget {
  const WizardPaymentBody({
    super.key,
    required this.session,
    required this.methods,
    required this.uploading,
    required this.uploadError,
    required this.onPickReceipt,
    required this.onConfirm,
    required this.onFix,
  });

  final BookingWizardSession session;
  final List<PaymentMethodData> methods;
  final bool uploading;
  final String? uploadError;
  final VoidCallback onPickReceipt;

  /// Null while a confirm is already in flight — the bar disables itself.
  final VoidCallback? onConfirm;

  /// Sends the rider back to the step that owns whatever the booking is missing.
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final data = wizardCheckoutData(session);
    final selectedType = wizardPaymentMethodType(session.paymentMethod);
    final selected = methods
        .where((method) => method.type == selectedType)
        .firstOrNull;
    final needsReceipt = wizardMethodRequiresReceipt(session.paymentMethod);
    final blocked = wizardPaymentBlockedReason(
      session: session,
      data: data,
      uploading: uploading,
    );
    final padding = MediaQuery.sizeOf(context).width < 380 ? 16.0 : 20.0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(padding, 12, padding, 24),
            children: [
              if (!data.isReadyForPayment) ...[
                CheckoutNotice(
                  missing: data.missingRequiredFields,
                  onFix: onFix,
                ),
                const SizedBox(height: 14),
              ],
              CheckoutTicketCard(data: data),
              const SizedBox(height: 16),
              CheckoutFareCard(
                data: data,
                promoDiscount: 0,
                // Promo codes belong to the standalone checkout: the booking
                // RPCs this wizard calls take no promo code, so offering a
                // field here would take a code we could never redeem.
                promoField: const SizedBox.shrink(),
              ),
              const SizedBox(height: 22),
              CheckoutMethodPicker(
                methods: methods,
                selected: selectedType,
                walletBalance: 0,
                total: data.subtotal,
                onSelect: (type) => _select(context, type),
              ),
              if (needsReceipt && selected != null) ...[
                const SizedBox(height: 16),
                WizardTransferPanel(
                  key: ValueKey(selected.type),
                  method: selected,
                ),
                const SizedBox(height: 12),
                WizardReceiptUpload(
                  uploaded: session.receiptUrl != null,
                  uploading: uploading,
                  error: uploadError,
                  onPick: onPickReceipt,
                ),
              ],
              const SizedBox(height: 16),
              CheckoutAssurance(requiresReceipt: needsReceipt),
            ],
          ),
        ),
        CheckoutPayBar(
          total: data.subtotal,
          subtotal: data.subtotal,
          label: needsReceipt ? 'Submit receipt' : 'Pay now',
          blockedReason: blocked,
          onPay: blocked == null ? onConfirm : null,
        ),
      ],
    );
  }

  void _select(BuildContext context, PaymentMethodType type) {
    final id = wizardPaymentMethodId(type);
    if (id == null) return;
    context.read<BookingWizardCubit>().selectPaymentMethod(id);
  }
}
