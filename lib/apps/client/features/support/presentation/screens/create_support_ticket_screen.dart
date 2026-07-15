import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/create_ticket_form.dart';

class CreateSupportTicketScreen extends StatelessWidget {
  const CreateSupportTicketScreen({super.key});

  /// On success we replace this screen with the new ticket's details, so the
  /// client lands on the thing they just created rather than back on an empty
  /// form.
  void _onStateChanged(BuildContext context, SupportState state) {
    if (state is SupportSuccess) {
      _showSnack(
        context,
        context.l10n.support_ticketCreatedSnack,
      );
      Navigator.pop(context);
      if (state.ticket != null) {
        Navigator.pushNamed(
          context,
          ClientRoutes.ticketDetails,
          arguments: state.ticket!.id,
        );
      }
    } else if (state is SupportError) {
      _showSnack(context, state.message, isError: true);
    }
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          context.l10n.support_newTicketTitle,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(color: scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        centerTitle: true,
      ),
      body: BlocConsumer<SupportCubit, SupportState>(
        listener: _onStateChanged,
        builder: (context, state) {
          return CreateTicketForm(isSubmitting: state is SupportActionLoading);
        },
      ),
    );
  }
}
