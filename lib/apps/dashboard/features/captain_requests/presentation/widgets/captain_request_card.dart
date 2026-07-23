import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/captain_request.dart';

class CaptainRequestCard extends StatelessWidget {
  final CaptainRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const CaptainRequestCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = request.fullName.isNotEmpty
        ? request.fullName.characters.first
        : '؟';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primary.withAlpha(28),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        request.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          if (request.status == CaptainRequestStatus.rejected &&
              (request.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              'سبب الرفض: ${request.rejectionReason}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (request.isPending) ...[
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('قبول واستكمال البيانات'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CaptainRequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color color, Color text) = switch (status) {
      CaptainRequestStatus.pending => (
        scheme.tertiary.withAlpha(28),
        scheme.tertiary,
      ),
      CaptainRequestStatus.approved => (
        Colors.green.withAlpha(30),
        Colors.green.shade700,
      ),
      CaptainRequestStatus.rejected => (
        scheme.error.withAlpha(28),
        scheme.error,
      ),
    };
    return StatusChip(label: status.label, color: color, textColor: text);
  }
}
