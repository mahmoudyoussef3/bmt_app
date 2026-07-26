import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/support_ticket.dart';
import '../../utils/support_status_visuals.dart';
import '../support_ticket_labels.dart';
import 'ticket_assigned_agent_badge.dart';

/// Tinted middle band of the details card: where the ticket currently stands
/// and who is handling it.
class TicketDetailsStatusBand extends StatelessWidget {
  const TicketDetailsStatusBand({super.key, required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = SupportStatusVisuals.colorFor(context, ticket.status);
    final agentName = ticket.assignedAgentName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: scheme.outlineVariant.withAlpha(30)),
        ),
      ),
      child: Row(
        children: [
          if (ticket.status == TicketStatus.submitted ||
              ticket.status == TicketStatus.underReview ||
              ticket.status == TicketStatus.contacted)
            _PulseIcon(
              statusColor: statusColor,
              icon: SupportStatusVisuals.iconFor(ticket.status),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                SupportStatusVisuals.iconFor(ticket.status),
                color: statusColor,
                size: 24,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.support_currentStatus,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supportStatusLabel(context, ticket.status),
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(color: statusColor, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (agentName != null) TicketAssignedAgentBadge(agentName: agentName),
        ],
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  const _PulseIcon({required this.statusColor, required this.icon});
  final Color statusColor;
  final IconData icon;

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.statusColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              color: widget.statusColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
