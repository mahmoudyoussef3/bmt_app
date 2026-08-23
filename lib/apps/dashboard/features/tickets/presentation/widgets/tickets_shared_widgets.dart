import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../../domain/entities/complaint.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';

/// Same 6px-rect [DashboardStatusChip] every other module's table uses for
/// status — this used to be a bespoke pill with a bigger radius, the one
/// place in Tickets that didn't match Trips, Bookings, Fleet, or the ticket
/// details dialog's own [DashboardStatusChip]-based badges.
class StatusBadge extends StatelessWidget {
  final TicketStatus status;
  const StatusBadge({super.key, required this.status});

  AppStatusTone get _tone => switch (status) {
    TicketStatus.submitted => AppStatusTone.info,
    TicketStatus.underReview => AppStatusTone.warning,
    TicketStatus.contacted => AppStatusTone.special,
    TicketStatus.resolved => AppStatusTone.success,
    TicketStatus.closed => AppStatusTone.neutral,
    TicketStatus.rejected => AppStatusTone.error,
  };

  @override
  Widget build(BuildContext context) {
    final tone = context.status(_tone);
    return DashboardStatusChip(
      label: status.label,
      color: tone.tint,
      textColor: tone.ink,
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final TicketPriority priority;
  const PriorityBadge({super.key, required this.priority});

  AppStatusTone get _tone => switch (priority) {
    TicketPriority.low => AppStatusTone.neutral,
    TicketPriority.medium => AppStatusTone.info,
    TicketPriority.high => AppStatusTone.warning,
    TicketPriority.urgent => AppStatusTone.error,
  };

  @override
  Widget build(BuildContext context) {
    final tone = context.status(_tone);
    return DashboardStatusChip(
      label: priority.label,
      color: tone.tint,
      textColor: tone.ink,
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
                  color: context
                      .status(AppStatusTone.error)
                      .ink
                      .withValues(alpha: 0.4),
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
                        ? context.status(AppStatusTone.error).ink
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
