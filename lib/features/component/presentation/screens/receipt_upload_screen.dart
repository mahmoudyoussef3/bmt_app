import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/payment_processing_screen.dart';

class ReceiptUploadScreen extends StatefulWidget {
  final PaymentCheckoutData checkoutData;
  final PaymentMethodData paymentMethod;
  final String? promoCode;
  final int promoDiscount;
  final String? paymentNotes;

  const ReceiptUploadScreen({
    super.key,
    required this.checkoutData,
    required this.paymentMethod,
    this.promoCode,
    required this.promoDiscount,
    this.paymentNotes,
  });

  @override
  State<ReceiptUploadScreen> createState() => _ReceiptUploadScreenState();
}

class _ReceiptUploadScreenState extends State<ReceiptUploadScreen> {
  bool _receiptSelected = false;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  double _uploadProgress = 0.0;
  Timer? _progressTimer;

  // Mock Receipt Metadata
  final String _mockFileName = 'screenshot_20260603_receipt.png';
  final String _mockFileSize = '1.4 MB';

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _simulateSelectReceipt() {
    setState(() {
      _receiptSelected = true;
      _uploadSuccess = false;
      _uploadProgress = 0.0;
    });
  }

  void _removeReceipt() {
    setState(() {
      _receiptSelected = false;
      _uploadSuccess = false;
      _uploadProgress = 0.0;
    });
  }

  void _startUploadSimulation() {
    if (_isUploading) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        if (_uploadProgress < 1.0) {
          _uploadProgress += 0.1;
        } else {
          timer.cancel();
          _isUploading = false;
          _uploadSuccess = true;
        }
      });
    });
  }

  void _proceedToPaymentProcessing({required bool simulateFailure}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentProcessingScreen(
          checkoutData: widget.checkoutData,
          paymentMethod: widget.paymentMethod,
          promoCode: widget.promoCode,
          promoDiscount: widget.promoDiscount,
          simulateFailure: simulateFailure,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = widget.checkoutData.totalForDiscount(widget.promoDiscount);
    final isInstaPay = widget.paymentMethod.type == PaymentMethodType.instapay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Receipt'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.surface, scheme.surfaceContainerLowest],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Transfer instructions card
                    _buildInstructionsCard(scheme, total, isInstaPay),
                    const SizedBox(height: 20),

                    // Dashed upload zone or preview card
                    _buildUploadArea(scheme),
                    const SizedBox(height: 20),

                    // Upload Progress indicator
                    if (_isUploading) _buildUploadProgressIndicator(scheme),

                    // Success Verification Box
                    if (_uploadSuccess) _buildUploadSuccessBox(scheme),
                  ],
                ),
              ),

              // Sticky Bottom CTA Panel
              _buildStickyBottomPanel(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(ColorScheme scheme, int total, bool isInstaPay) {
    return AppSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(55)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Transfer Instructions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Please transfer the exact booking amount to the following address and upload the transaction screenshot below:',
            style: TextStyle(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Amount to send:', '$total EGP', isBold: true, color: scheme.primary),
          const SizedBox(height: 10),
          if (isInstaPay) ...[
            _buildInfoRow('InstaPay IPA:', 'megatrans@instapay', showCopy: true, color: scheme.secondary),
            const SizedBox(height: 10),
            _buildInfoRow('Account Holder:', 'Mega Transportation Services', color: scheme.onSurface),
          ] else ...[
            _buildInfoRow('Mobile Wallet No:', '0100 123 4567', showCopy: true, color: scheme.secondary),
            const SizedBox(height: 10),
            _buildInfoRow('Wallet Type:', 'Vodafone / Orange / Etisalat Cash', color: scheme.onSurface),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color, bool showCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold || showCopy ? FontWeight.w900 : FontWeight.bold,
                color: color,
              ),
            ),
            if (showCopy) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$value copied to clipboard'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildUploadArea(ColorScheme scheme) {
    if (_receiptSelected) {
      // Image preview state
      return AppSurface(
        radius: 24,
        padding: const EdgeInsets.all(16),
        color: scheme.primary.withAlpha(15),
        border: Border.all(color: scheme.primary.withAlpha(80)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image_outlined, size: 28, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mockFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mockFileSize,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              onPressed: _isUploading ? null : _removeReceipt,
            ),
          ],
        ),
      );
    }

    // Default upload area with dashed borders
    return GestureDetector(
      onTap: _simulateSelectReceipt,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outline.withAlpha(90),
            style: BorderStyle.solid, // Simulated dashed border using simple style
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_upload_outlined, size: 32, color: scheme.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Receipt Screenshot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to select a file (PNG, JPG)',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgressIndicator(ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Uploading screenshot...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${(_uploadProgress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 6,
              color: scheme.primary,
              backgroundColor: scheme.outline.withAlpha(60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSuccessBox(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receipt Verification Submitted',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 4),
                Text(
                  'Receipt uploaded successfully. We will verify your transaction shortly during checkout.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomPanel(ColorScheme scheme) {
    VoidCallback? onBtnPressed;
    String label = 'Upload & Verify';

    if (!_receiptSelected) {
      onBtnPressed = null; // disabled
    } else if (!_uploadSuccess && !_isUploading) {
      onBtnPressed = _startUploadSimulation;
    } else if (_uploadSuccess) {
      onBtnPressed = () => _proceedToPaymentProcessing(simulateFailure: false);
      label = 'Submit Payment';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(246),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(40))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _isUploading ? 'Uploading...' : label,
                  onPressed: onBtnPressed ?? () {},
                ),
              ),
            ],
          ),
          if (_uploadSuccess) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _proceedToPaymentProcessing(simulateFailure: true),
                    child: const Text('Simulate failure checkout'),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
