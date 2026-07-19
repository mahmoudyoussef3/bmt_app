import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/support_cubit.dart';

/// Collapsing header of the ticket details screen, titled with the ticket
/// number and carrying the manual refresh action.
class TicketDetailsAppBar extends StatelessWidget {
  const TicketDetailsAppBar({
    super.key,
    required this.ticketId,
    required this.ticketNumber,
  });

  final String ticketId;
  final String ticketNumber;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurface),
      actions: [
        IconButton(
          tooltip: context.l10n.support_refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              context.read<SupportCubit>().openTicketDetails(ticketId),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: 48,
          end: 24,
          bottom: 16,
        ),
        title: Text(
          context.l10n.support_ticketNumberTitle(ticketNumber),
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w900),
        ),
        background: const _TicketDetailsAppBarBackground(),
      ),
    );
  }
}

/// Decorative gradient wash with an oversized watermark icon bleeding off the
/// trailing edge.
class _TicketDetailsAppBarBackground extends StatelessWidget {
  const _TicketDetailsAppBarBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
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
        PositionedDirectional(
          end: -40,
          top: -20,
          child: Icon(
            Icons.support_agent_rounded,
            size: 200,
            color: scheme.primary.withAlpha(10),
          ),
        ),
      ],
    );
  }
}
