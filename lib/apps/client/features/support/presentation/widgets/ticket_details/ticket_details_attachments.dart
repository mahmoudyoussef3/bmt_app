import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/support_attachment.dart';
import 'ticket_attachment_tile.dart';

/// Files the client sent along with the ticket. Collapses entirely when there
/// are none rather than showing an empty section header.
class TicketDetailsAttachments extends StatelessWidget {
  const TicketDetailsAttachments({super.key, required this.attachments});

  final List<SupportAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.support_attachments,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...attachments.map(
          (attachment) => TicketAttachmentTile(attachment: attachment),
        ),
      ],
    );
  }
}
