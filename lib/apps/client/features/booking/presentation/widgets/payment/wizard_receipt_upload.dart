import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The proof an operator will read before this booking is confirmed.
///
/// The state of the upload is on the tile itself — a rider who has attached
/// their receipt should never have to guess whether it arrived.
class WizardReceiptUpload extends StatelessWidget {
  const WizardReceiptUpload({
    super.key,
    required this.uploaded,
    required this.uploading,
    required this.error,
    required this.onPick,
  });

  final bool uploaded;
  final bool uploading;
  final String? error;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    final done = uploaded && !uploading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
        border: Border.all(
          color: failed
              ? ClientColors.journeyRed
              : done
              ? ClientColors.primaryFor(context)
              : ClientColors.borderFor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof of transfer',
            style: ClientTypography.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            done
                ? 'Attached. Our team will check it against your transfer.'
                : 'A screenshot or PDF of the transfer — up to 8 MB.',
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          if (failed) ...[
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
              onPressed: uploading ? null : onPick,
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      size: 18,
                    ),
              label: Text(
                uploading
                    ? 'Uploading…'
                    : done
                    ? 'Replace receipt'
                    : 'Attach receipt',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
