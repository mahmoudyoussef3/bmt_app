import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

import '../../../domain/entities/support_attachment.dart';

/// One file the client attached to the ticket.
class TicketAttachmentTile extends StatelessWidget {
  const TicketAttachmentTile({super.key, required this.attachment});

  final SupportAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fileSize = attachment.fileSize;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant.withAlpha(50)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.insert_drive_file_rounded,
              color: scheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatFileSize(fileSize),
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.file_download_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
