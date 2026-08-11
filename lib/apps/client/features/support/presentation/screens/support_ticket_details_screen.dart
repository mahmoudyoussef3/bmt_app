import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/support_cubit.dart';
import '../cubit/support_state.dart';
import '../widgets/ticket_details/ticket_details_body.dart';
import '../widgets/ticket_details/ticket_details_placeholder.dart';

/// One support ticket in full: its status, the note customer service left, and
/// anything the client attached.
///
/// The ticket is loaded by `ClientCubitScopes.supportTicketDetails`, which owns
/// the id — this screen only renders whatever the cubit is holding.
class SupportTicketDetailsScreen extends StatelessWidget {
  const SupportTicketDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: BlocConsumer<SupportCubit, SupportState>(
        listenWhen: (previous, current) => current is SupportError,
        listener: (context, state) =>
            _showError(context, (state as SupportError).message),
        builder: (context, state) => switch (state) {
          SupportTicketDetailsLoaded(:final ticket, :final attachments) =>
            TicketDetailsBody(ticket: ticket, attachments: attachments),
          SupportInitial() || SupportLoading() => TicketDetailsPlaceholder(
            child: CircularProgressIndicator(color: scheme.primary),
          ),
          
          _ => TicketDetailsPlaceholder(
            child: Text(
              context.l10n.support_failedToLoad,
              style: ClientTypography.bodyLarge(
                context,
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        },
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: scheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
