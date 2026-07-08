import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_ticket.dart';
import 'package:bmt_app/apps/client/features/support/domain/entities/support_attachment.dart';
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

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.submitted:
        return Icons.mark_email_unread_rounded;
      case TicketStatus.underReview:
        return Icons.hourglass_top_rounded;
      case TicketStatus.contacted:
        return Icons.support_agent_rounded;
      case TicketStatus.resolved:
        return Icons.check_circle_rounded;
      case TicketStatus.closed:
        return Icons.lock_rounded;
      case TicketStatus.rejected:
        return Icons.cancel_rounded;
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest.withAlpha(50),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: (context, state) {
          if (state is SupportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SupportLoading || state is SupportInitial) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: scheme.onSurface),
              ),
              body: Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
            );
          }

          if (state is SupportTicketDetailsLoaded) {
            final ticket = state.ticket;
            final statusColor = _getStatusColor(ticket.status, scheme);
            final statusIcon = _getStatusIcon(ticket.status);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, ticket, scheme),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusAlertBox(context, ticket, scheme),
                        _buildMainDetailsCard(
                          context,
                          ticket,
                          scheme,
                          statusColor,
                          statusIcon,
                        ),
                        if (ticket.internalNote != null &&
                            ticket.internalNote!.isNotEmpty)
                          _buildCustomerServiceNote(context, ticket, scheme),
                        if (state.attachments.isNotEmpty)
                          _buildAttachmentsList(
                            context,
                            state.attachments,
                            scheme,
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: scheme.onSurface),
            ),
            body: Center(
              child: Text(
                'Failed to load ticket details',
                style: ClientTypography.bodyLarge(
                  context,
                ).copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    SupportTicket ticket,
    ColorScheme scheme,
  ) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurface),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              context.read<SupportCubit>().openTicketDetails(ticket.id),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 48, right: 24, bottom: 16),
        title: Text(
          'Ticket ${ticket.ticketNumber}',
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w900),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary.withAlpha(20), scheme.surface],
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -20,
              child: Icon(
                Icons.support_agent_rounded,
                size: 200,
                color: scheme.primary.withAlpha(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAlertBox(
    BuildContext context,
    SupportTicket ticket,
    ColorScheme scheme,
  ) {
    if (ticket.status != TicketStatus.submitted &&
        ticket.status != TicketStatus.underReview) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: scheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Our customer service team is reviewing your ticket and may contact you shortly.',
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDetailsCard(
    BuildContext context,
    SupportTicket ticket,
    ColorScheme scheme,
    Color statusColor,
    IconData statusIcon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: ClientTypography.headingMedium(context).copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_rounded,
                            size: 14,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ticket.category,
                            style: ClientTypography.labelMedium(context)
                                .copyWith(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                          style: ClientTypography.labelMedium(context).copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withAlpha(80),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: scheme.outlineVariant.withAlpha(30),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status',
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(ticket.status),
                        style: ClientTypography.labelMedium(context).copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ticket.assignedAgentName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outlineVariant.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Assigned to',
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.assignedAgentName!,
                              style: ClientTypography.labelMedium(context)
                                  .copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    color: scheme.onSurfaceVariant.withAlpha(220),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerServiceNote(
    BuildContext context,
    SupportTicket ticket,
    ColorScheme scheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
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
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: Colors.orange.shade900, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(
    BuildContext context,
    List<SupportAttachment> attachments,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...attachments.map(
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
                      if (attachment.fileSize != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatFileSize(attachment.fileSize!),
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
          ),
        ),
      ],
    );
  }
}
