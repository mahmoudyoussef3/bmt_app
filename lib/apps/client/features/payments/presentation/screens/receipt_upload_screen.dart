import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/core/di/client_di.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/apps/client/features/payments/domain/usecases/upload_payment_receipt_usecase.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/screens/payment_processing_screen.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class ReceiptUploadScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;
  final PaymentMethodData paymentMethod;
  final String? promoCode;
  final int promoDiscount;

  const ReceiptUploadScreen({
    super.key,
    required this.checkoutData,
    required this.paymentMethod,
    this.promoCode,
    required this.promoDiscount,
  });

  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  File? _receiptFile;
  String? _receiptName;
  int? _receiptSize;
  bool _submitting = false;

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );

    final path = result?.files.single.path;
    if (path == null) return;

    final file = File(path);
    setState(() {
      _receiptFile = file;
      _receiptName = result!.files.single.name;
      _receiptSize = result.files.single.size;
    });
  }

  void _removeReceipt() {
    setState(() {
      _receiptFile = null;
      _receiptName = null;
      _receiptSize = null;
    });
  }

  Future<void> _proceed() async {
    final file = _receiptFile;
    final fileName = _receiptName;
    if (file == null || fileName == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      final uploadReceipt = clientGetIt<UploadPaymentReceiptUseCase>();
      final receiptUrl = await uploadReceipt(
        bookingOrTripId: widget.checkoutData.tripId,
        fileName: fileName,
        bytes: await file.readAsBytes(),
        contentType: _contentTypeFor(fileName),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            checkoutData: widget.checkoutData,
            paymentMethod: widget.paymentMethod,
            promoCode: widget.promoCode,
            promoDiscount: widget.promoDiscount,
            receiptUrl: receiptUrl,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.payments_uploadReceiptError(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);
    final isInstaPay = widget.paymentMethod.type == PaymentMethodType.instapay;

    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: ClientAppBar(title: context.l10n.payments_attachReceiptTitle),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInstructionsCard(context, total, isInstaPay),
                const SizedBox(height: 20),
                _buildUploadArea(context),
                const SizedBox(height: 20),
                if (_receiptFile != null) _buildReceiptReadyBox(context),
              ],
            ),
          ),
          _buildStickyBottomPanel(context),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(
    BuildContext context,
    int total,
    bool isInstaPay,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: ClientColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.payments_transferInstructionsTitle,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 12),
          Text(
            context.l10n.payments_transferInstructionsBody,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            context,
            context.l10n.payments_amountToSendLabel,
            FormatUtil.currency(context, total),
            isBold: true,
          ),
          const SizedBox(height: 10),
          if (isInstaPay) ...[
            _buildInfoRow(
              context,
              context.l10n.payments_instapayIpaLabel,
              widget.paymentMethod.transferAccount ??
                  context.l10n.payments_notConfigured,
              showCopy: true,
              forceLtr: true,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              context,
              context.l10n.payments_accountHolderLabel,
              widget.paymentMethod.accountHolder ??
                  context.l10n.payments_notConfigured,
            ),
          ] else ...[
            _buildInfoRow(
              context,
              context.l10n.payments_mobileWalletNoLabel,
              widget.paymentMethod.transferAccount ??
                  context.l10n.payments_notConfigured,
              showCopy: true,
              forceLtr: true,
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              context,
              context.l10n.payments_walletTypeLabel,
              widget.paymentMethod.supportedChannels.isEmpty
                  ? context.l10n.payments_defaultWalletChannels
                  : widget.paymentMethod.supportedChannels.join(' / '),
            ),
          ],
          if ((widget.paymentMethod.instructions ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.paymentMethod.instructions!,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    bool showCopy = false,
    bool forceLtr = false,
  }) {
    final valueText = Text(
      value,
      style: ClientTypography.bodySmall(context).copyWith(
        fontWeight: isBold || showCopy ? FontWeight.w900 : FontWeight.w700,
        color: isBold
            ? ClientColors.primary
            : ClientColors.textPrimaryFor(context),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        Row(
          children: [
            forceLtr
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: valueText,
                  )
                : valueText,
            if (showCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.payments_copiedToClipboard(value),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: ClientColors.textTertiaryFor(context),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUploadArea(BuildContext context) {
    if (_receiptFile != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClientColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ClientColors.primaryMuted),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClientColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 28,
                color: ClientColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _receiptName ?? _receiptFile!.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(_receiptSize ?? _receiptFile!.lengthSync()),
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textTertiaryFor(context)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: ClientColors.journeyRed,
              ),
              onPressed: _removeReceipt,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickReceipt,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: ClientColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ClientColors.borderFor(context),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: ClientColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: ClientColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.payments_uploadReceiptScreenshot,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.payments_tapToSelectFile,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptReadyBox(BuildContext context) {
    return ClientCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: ClientColors.journeyCyanLightFor(context),
      borderColor: ClientColors.journeyCyanFor(context).withAlpha(80),
      useShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: ClientColors.onJourneyCyanFor(context),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.payments_receiptAttachedTitle,
                  style: ClientTypography.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: ClientColors.onJourneyCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.payments_receiptAttachedBody,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.onJourneyCyan, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomPanel(BuildContext context) {
    final hasReceipt = _receiptFile != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context).withAlpha(246),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ClientButton(
          label: _submitting
              ? context.l10n.payments_uploading
              : hasReceipt
              ? context.l10n.payments_submitPayment
              : context.l10n.payments_attachReceiptTitle,
          expand: true,
          isLoading: _submitting,
          onPressed: _submitting
              ? null
              : hasReceipt
              ? _proceed
              : _pickReceipt,
        ),
      ),
    );
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
