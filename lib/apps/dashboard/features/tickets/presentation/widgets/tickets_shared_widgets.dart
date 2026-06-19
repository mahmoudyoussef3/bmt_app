import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../../domain/entities/complaint.dart';

class StatusBadge extends StatelessWidget {
  final TicketStatus status;
  const StatusBadge({super.key, required this.status});

  (Color bg, Color fg) get _colors => switch (status) {
    TicketStatus.submitted => (
      AppStatusColors.infoContainer,
      AppStatusColors.onInfoContainer,
    ),
    TicketStatus.underReview => (
      AppStatusColors.warningContainer,
      AppStatusColors.onWarningContainer,
    ),
    TicketStatus.contacted => (
      AppStatusColors.specialContainer,
      AppStatusColors.onSpecialContainer,
    ),
    TicketStatus.resolved => (
      AppStatusColors.successContainer,
      AppStatusColors.onSuccessContainer,
    ),
    TicketStatus.closed => (
      AppStatusColors.neutralContainer,
      AppStatusColors.onNeutralContainer,
    ),
    TicketStatus.rejected => (
      AppStatusColors.errorContainer,
      AppStatusColors.onErrorContainer,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  const PriorityBadge({super.key, required this.priority});

  (Color bg, Color fg) get _colors => switch (priority) {
    TicketPriority.low => (
      AppStatusColors.neutralContainer,
      AppStatusColors.onNeutralContainer,
    ),
    TicketPriority.medium => (
      AppStatusColors.infoContainer,
      AppStatusColors.onInfoContainer,
    ),
    TicketPriority.high => (
      AppStatusColors.warningContainer,
      AppStatusColors.onWarningContainer,
    ),
    TicketPriority.urgent => (
      AppStatusColors.errorContainer,
      AppStatusColors.onErrorContainer,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class DetailField extends StatelessWidget {
  final String label;
  final String value;
  const DetailField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label: ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool isAlert;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Container(
        decoration: isAlert
            ? BoxDecoration(
                border: Border.all(
                  color: AppStatusColors.onErrorContainer.withValues(
                    alpha: 0.4,
                  ),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              radius: 24,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: AppSpacing.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isAlert
                        ? AppStatusColors.onErrorContainer
                        : scheme.onSurface,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
