import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/receipt_picker.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_payment_body.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/payment/wizard_payment_mapping.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/widgets/checkout/checkout_skeleton.dart';

/// Pays for the seat the wizard has been assembling.
///
/// The screen is the shared checkout — same ticket, fare card, method tiles and
/// pay bar as the standalone [PaymentCheckoutScreen] — so a rider who bought a
/// package and a rider who booked a seat pay on the same surface.
class WizardPaymentStep extends StatefulWidget {
  const WizardPaymentStep({
    super.key,
    required this.onConfirm,
    required this.onFix,
  });

  /// Null while a confirm is in flight.
  final VoidCallback? onConfirm;

  /// Jumps back to the step that owns a missing booking detail.
  final VoidCallback onFix;

  @override
  State<WizardPaymentStep> createState() => _WizardPaymentStepState();
}

class _WizardPaymentStepState extends State<WizardPaymentStep> {
  late Future<List<PaymentMethodData>> _methods;
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _methods = _loadMethods();
  }

  Future<List<PaymentMethodData>> _loadMethods() async {
    final methods = await clientGetIt<GetPaymentMethodsUseCase>()();
    return methods
        .where((method) => wizardPaymentMethodId(method.type) != null)
        .toList();
  }

  Future<void> _pickReceipt(BookingWizardSession session) async {
    final tripId = session.selectedTrip?.id;
    if (_uploading || tripId == null || tripId.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final url = await pickAndUploadReceipt(bookingOrTripId: tripId);
      if (!mounted || url == null) return;
      context.read<BookingWizardCubit>().setReceiptUrl(url);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploadError = error.toString().replaceFirst(
          RegExp(r'^Exception: ?'),
          '',
        );
      });
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentMethodData>>(
      future: _methods,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CheckoutSkeleton();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: ClientErrorCard.fullScreen(
              message:
                  'We could not load the ways to pay. Your seat is still '
                  'yours — try again.',
              onRetry: () => setState(() => _methods = _loadMethods()),
            ),
          );
        }
        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) => WizardPaymentBody(
            session: session,
            methods: snapshot.data ?? const [],
            uploading: _uploading,
            uploadError: _uploadError,
            onPickReceipt: () => _pickReceipt(session),
            onConfirm: widget.onConfirm,
            onFix: widget.onFix,
          ),
        );
      },
    );
  }
}
