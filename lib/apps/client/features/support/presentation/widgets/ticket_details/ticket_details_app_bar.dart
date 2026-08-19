import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
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
    return ClientSliverAppBar(
      title: context.l10n.support_ticketNumberTitle(ticketNumber),
      actions: [
        IconButton(
          tooltip: context.l10n.support_refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              context.read<SupportCubit>().openTicketDetails(ticketId),
        ),
      ],
    );
  }
}
