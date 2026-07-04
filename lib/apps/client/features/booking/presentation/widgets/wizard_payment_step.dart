import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/get_payment_methods_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/upload_payment_receipt_usecase.dart';

class WizardPaymentStep extends StatefulWidget {
  const WizardPaymentStep({super.key, required this.onConfirm});

  final VoidCallback? onConfirm;

  @override
  State<WizardPaymentStep> createState() => _WizardPaymentStepState();
}

class _WizardPaymentStepState extends State<WizardPaymentStep> {
  late final Future<List<PaymentMethodData>> _methods;
  final _reference = TextEditingController();
  final _payerPhone = TextEditingController();
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _methods = clientGetIt<GetPaymentMethodsUseCase>()().then(
      (methods) => methods.where((method) {
        return method.type == PaymentMethodType.instapay ||
            method.type == PaymentMethodType.vodafoneCash ||
            method.type == PaymentMethodType.bankTransfer;
      }).toList(),
    );
  }

  @override
  void dispose() {
    _reference.dispose();
    _payerPhone.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(BookingWizardSession session) async {
    if (_uploading || session.selectedTrip == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    final picked = result?.files.single;
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final bytes =
          picked.bytes ??
          (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('تعذر قراءة الملف المحدد.');
      }
      if (picked.size > 8 * 1024 * 1024) {
        throw Exception('الحد الأقصى لحجم الإيصال هو 8 ميجابايت.');
      }
      final url = await clientGetIt<UploadPaymentReceiptUseCase>()(
        bookingOrTripId: session.selectedTrip!.id,
        fileName: picked.name,
        bytes: bytes,
        contentType: _contentType(picked.extension),
      );
      if (!mounted) return;
      context.read<BookingWizardCubit>().setReceiptUrl(url);
    } catch (error) {
      if (mounted) setState(() => _uploadError = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _contentType(String? extension) => switch (extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };

  void _savePaymentDetails() {
    context.read<BookingWizardCubit>().setManualPaymentDetails(
      paymentReference: _reference.text,
      payerPhone: _payerPhone.text,
    );
  }

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
                  Text(
                    'اختر طريقة الدفع',
                    style: ClientTypography.headingSmall(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الدفع النقدي للكابتن غير متاح. حوّل المبلغ ثم أرفق الإيصال.',
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<PaymentMethodData>>(
                    future: _methods,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return _MessageBox(
                          message: 'تعذر تحميل طرق الدفع: ${snapshot.error}',
                          isError: true,
                        );
                      }
                      final methods = snapshot.data ?? const [];
                      if (methods.isEmpty) {
                        return const _MessageBox(
                          message:
                              'لا توجد طريقة دفع إلكترونية مفعلة حالياً. تواصل مع الدعم.',
                          isError: true,
                        );
                      }
                      return Column(
                        children: methods.map((method) {
                          final id = _methodId(method.type);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MethodTile(
                              method: method,
                              isSelected: session.paymentMethod == id,
                              onTap: () => context
                                  .read<BookingWizardCubit>()
                                  .selectPaymentMethod(id),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  if (session.paymentMethod != null) ...[
                    const SizedBox(height: 14),
                    _TransferDetails(
                      methodId: session.paymentMethod!,
                      methods: _methods,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _reference,
                      onChanged: (_) => _savePaymentDetails(),
                      decoration: const InputDecoration(
                        labelText: 'مرجع التحويل (اختياري)',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _payerPhone,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => _savePaymentDetails(),
                      decoration: const InputDecoration(
                        labelText: 'رقم هاتف المحوّل (اختياري)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ReceiptUpload(
                      uploaded: session.receiptUrl != null,
                      uploading: _uploading,
                      error: _uploadError,
                      onPressed: () => _pickAndUpload(session),
                    ),
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
                  label: 'إرسال للمراجعة',
                  onPressed: session.paymentValid && !_uploading
                      ? widget.onConfirm
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _methodId(PaymentMethodType type) => switch (type) {
    PaymentMethodType.instapay => 'instapay',
    PaymentMethodType.vodafoneCash => 'vodafone_cash',
    PaymentMethodType.bankTransfer => 'bank_transfer',
    _ => '',
  };
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethodData method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withAlpha(isDark ? 30 : 20)
              : (isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerLow),
          borderRadius: BorderRadius.circular(ClientRadius.xl),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : (isDark ? scheme.outline.withAlpha(40) : scheme.outline.withAlpha(60)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? ClientElevation.sm(context) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : (isDark ? scheme.surface : Colors.white),
                shape: BoxShape.circle,
                boxShadow: ClientElevation.sm(context),
              ),
              child: Icon(
                method.type == PaymentMethodType.bankTransfer
                    ? Icons.account_balance_rounded
                    : Icons.send_to_mobile_rounded,
                color: isSelected ? scheme.onPrimary : scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: scheme.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

class _TransferDetails extends StatelessWidget {
  const _TransferDetails({required this.methodId, required this.methods});

  final String methodId;
  final Future<List<PaymentMethodData>> methods;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentMethodData>>(
      future: methods,
      builder: (context, snapshot) {
        final selected = snapshot.data?.where((method) {
          final type = method.type;
          return (methodId == 'instapay' &&
                  type == PaymentMethodType.instapay) ||
              (methodId == 'vodafone_cash' &&
                  type == PaymentMethodType.vodafoneCash) ||
              (methodId == 'bank_transfer' &&
                  type == PaymentMethodType.bankTransfer);
        }).firstOrNull;
        if (selected == null) return const SizedBox.shrink();
        final account = selected.transferAccount?.trim() ?? '';
        final instructions = selected.instructions?.trim() ?? '';
        return _MessageBox(
          message: [
            if (account.isNotEmpty) 'حوّل إلى: $account',
            if ((selected.accountHolder ?? '').trim().isNotEmpty)
              'اسم الحساب: ${selected.accountHolder}',
            if (instructions.isNotEmpty) instructions,
          ].join('\n'),
        );
      },
    );
  }
}

class _ReceiptUpload extends StatelessWidget {
  const _ReceiptUpload({
    required this.uploaded,
    required this.uploading,
    required this.error,
    required this.onPressed,
  });

  final bool uploaded;
  final bool uploading;
  final String? error;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
          Text(
            'إثبات الدفع',
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG أو PNG أو PDF، بحد أقصى 8 ميجابايت.',
            style: ClientTypography.bodySmall(context),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.journeyRed),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: uploading ? null : onPressed,
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      uploaded
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                    ),
              label: Text(
                uploading
                    ? 'جارٍ الرفع...'
                    : uploaded
                    ? 'تم رفع الإيصال — تغيير'
                    : 'رفع الإيصال',
              ),
            ),
          ),
        ],
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الإجمالي',
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${session.totalPrice.toStringAsFixed(0)} ج.م',
            style: ClientTypography.headingSmall(context).copyWith(
              color: ClientColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isError ? ClientColors.journeyRed : ClientColors.primary)
            .withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: ClientTypography.bodySmall(context).copyWith(
          color: isError
              ? ClientColors.journeyRed
              : ClientColors.textPrimaryFor(context),
          height: 1.5,
        ),
      ),
    );
  }
}
