import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class PaymobCheckoutWebViewScreen extends StatefulWidget {
  const PaymobCheckoutWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.bookingReference,
  });

  final String checkoutUrl;
  final String bookingReference;

  @override
  State<PaymobCheckoutWebViewScreen> createState() =>
      _PaymobCheckoutWebViewScreenState();
}

class _PaymobCheckoutWebViewScreenState
    extends State<PaymobCheckoutWebViewScreen> {
  late final WebViewController _controller;
  var _progress = 0;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final outcome = _readOutcome(request.url);
            if (outcome == null) return NavigationDecision.navigate;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop(outcome);
            });
            return NavigationDecision.prevent;
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _pageError = null);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() => _pageError = error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Reads Paymob's redirect for the outcome it is claiming, or null while the
  /// rider is still inside the payment flow.
  ///
  /// What comes back here is only a claim — the redirect is a URL, and the
  /// booking is settled from Paymob's signed server-to-server callback, not
  /// from this. It decides when to close the sheet, never whether the rider
  /// was charged.
  bool? _readOutcome(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final params = uri.queryParameters;
    final success = params['success']?.trim().toLowerCase();
    final pending = params['pending']?.trim().toLowerCase() == 'true';
    final responseCode = params['txn_response_code']?.trim().toUpperCase();

    // No verdict fields at all: still somewhere inside the gateway's own flow.
    if (success == null && responseCode == null) return null;

    if (success == 'true' || responseCode == 'APPROVED') return true;

    // A payment left pending (3-D Secure still finishing) is not a refusal.
    // Reporting it as paid hands the wait to the settlement check, which
    // asks our own backend rather than guessing here.
    if (pending) return true;

    if (success == 'false' ||
        responseCode == 'DECLINED' ||
        responseCode == 'CANCELLED') {
      return false;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceFor(context),
      appBar: AppBar(
        backgroundColor: ClientColors.surfaceFor(context),
        foregroundColor: ClientColors.textPrimaryFor(context),
        elevation: 0,
        leading: IconButton(
          tooltip: context.l10n.payments_closeCheckoutTooltip,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.payments_paymobCheckoutTitle,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              widget.bookingReference,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.payments_reloadTooltip,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(
              value: _progress / 100,
              minHeight: 3,
              color: ClientColors.primary,
              backgroundColor: ClientColors.primaryLight,
            )
          else
            const SizedBox(height: 3),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_pageError != null)
                  _CheckoutErrorOverlay(
                    message: _pageError!,
                    onRetry: () => _controller.reload(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutErrorOverlay extends StatelessWidget {
  const _CheckoutErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ClientColors.surfaceFor(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: ClientColors.journeyRed,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.payments_unableToLoadCheckout,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.common_retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
