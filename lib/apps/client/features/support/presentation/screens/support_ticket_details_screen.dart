import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class SupportTicketDetailsScreen extends StatefulWidget {
  final String ticketId;

  const SupportTicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailsScreen> createState() =>
      _SupportTicketDetailsScreenState();
}

class _SupportTicketDetailsScreenState
    extends State<SupportTicketDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().openTicketDetails(widget.ticketId);
  }

  Color _getStatusColor(TicketStatus status, ColorScheme scheme) {
    switch (status) {
      case TicketStatus.submitted:
        return scheme.primary;
      case TicketStatus.underReview:
        return Colors.orange;
      case TicketStatus.contacted:
        return scheme.secondary;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return scheme.outline;
      case TicketStatus.rejected:
        return scheme.error;
    }
  }

  String _getStatusLabel(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return 'Submitted';
      case TicketStatus.underReview:
        return 'Under Review';
      case TicketStatus.contacted:
        return 'Contacted';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
      case TicketStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest.withAlpha(50),
      appBar: AppBar(
        title: Text(
          'Ticket Details',
          style: ClientTypography.headingSmall(context).copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        centerTitle: true,
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SupportLoading || state is SupportInitial) {
            return Center(child: CircularProgressIndicator(color: scheme.primary));
          }

          if (state is SupportTicketDetailsLoaded) {
            final ticket = state.ticket;
            final statusColor = _getStatusColor(ticket.status, scheme);

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Status Alert Box
                if (ticket.status == TicketStatus.submitted || ticket.status == TicketStatus.underReview)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.primary.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: scheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Our customer service team is reviewing your ticket and may contact you shortly.',
                            style: ClientTypography.bodyMedium(context).copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withAlpha(10),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.ticketNumber,
                            style: ClientTypography.labelMedium(context).copyWith(
                              color: scheme.onSurfaceVariant.withAlpha(200),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getStatusLabel(ticket.status),
                              style: ClientTypography.labelSmall(context).copyWith(
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ticket.title,
                        style: ClientTypography.headingMedium(context).copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category_rounded, size: 16, color: scheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            ticket.category,
                            style: ClientTypography.labelMedium(context).copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: scheme.outlineVariant.withAlpha(50)),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: ClientTypography.headingSmall(context).copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket.description,
                        style: ClientTypography.bodyMedium(context).copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Service Note
                if (ticket.internalNote != null && ticket.internalNote!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withAlpha(50)),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Customer Service Note',
                              style: ClientTypography.headingSmall(context).copyWith(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ticket.internalNote!,
                          style: ClientTypography.bodyMedium(context).copyWith(
                            color: Colors.orange.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Attachments
                if (state.attachments.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Attachments',
                    style: ClientTypography.headingSmall(context).copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...state.attachments.map(
                    (attachment) => Container(
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.attach_file_rounded, color: scheme.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              attachment.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ClientTypography.bodyMedium(context).copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          }

          return Center(
            child: Text(
              'Failed to load ticket details',
              style: ClientTypography.bodyLarge(context).copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
