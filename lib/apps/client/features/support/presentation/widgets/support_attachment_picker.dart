import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Optional evidence for a ticket — a receipt screenshot, a photo of a
/// damaged package. Empty is a perfectly valid state, so this never blocks
/// submission.
class SupportAttachmentPicker extends StatelessWidget {
  const SupportAttachmentPicker({
    super.key,
    required this.attachment,
    required this.onPick,
    required this.onClear,
  });

  final File? attachment;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFile = attachment != null;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? scheme.primary.withAlpha(15)
              : scheme.surfaceContainerHighest.withAlpha(30),
          border: Border.all(
            color: hasFile
                ? scheme.primary.withAlpha(80)
                : scheme.outlineVariant.withAlpha(80),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile
                    ? Icons.file_present_rounded
                    : Icons.cloud_upload_rounded,
                color: hasFile ? scheme.primary : scheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile
                        ? attachment!.path.split('/').last
                        : 'Upload image or document',
                    style: ClientTypography.bodyMedium(context).copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!hasFile) ...[
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, or PDF up to 5MB',
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (hasFile)
              IconButton(
                icon: Icon(Icons.close_rounded, color: scheme.error),
                tooltip: 'Remove attachment',
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
