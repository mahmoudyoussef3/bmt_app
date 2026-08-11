import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_transfer_account.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// What the rider needs in order to transfer, and what we need in order to
/// recognise the transfer once it lands.
///
/// Both fields are optional: a receipt alone is enough for an operator to
/// verify the payment, and blocking the booking on a reference number the rider
/// may not have yet would strand them here.
class WizardTransferPanel extends StatefulWidget {
  const WizardTransferPanel({super.key, required this.method});

  final PaymentMethodData method;

  @override
  State<WizardTransferPanel> createState() => _WizardTransferPanelState();
}

class _WizardTransferPanelState extends State<WizardTransferPanel> {
  late final TextEditingController _reference;
  late final TextEditingController _payerPhone;

  @override
  void initState() {
    super.initState();
    
    final session = context.read<BookingWizardCubit>().state;
    _reference = TextEditingController(text: session.paymentReference ?? '');
    _payerPhone = TextEditingController(text: session.payerPhone ?? '');
  }

  @override
  void dispose() {
    _reference.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  void _save() {
    context.read<BookingWizardCubit>().setManualPaymentDetails(
      paymentReference: _reference.text,
      payerPhone: _payerPhone.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WizardTransferAccount(method: widget.method),
        const SizedBox(height: 12),
        TextField(
          controller: _reference,
          onChanged: (_) => _save(),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.l10n.booking_transferReferenceOptional,
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _payerPhone,
          onChanged: (_) => _save(),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: context.l10n.booking_paidFromPhoneOptional,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ),
      ],
    );
  }
}
