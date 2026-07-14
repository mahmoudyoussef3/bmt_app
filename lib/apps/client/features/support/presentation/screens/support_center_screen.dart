import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_cubit.dart';
import 'package:bmt_app/apps/client/features/support/presentation/cubit/support_state.dart';

import '../widgets/support_center_app_bar.dart';
import '../widgets/support_center_loading_view.dart';
import '../widgets/support_center_empty_view.dart';
import '../widgets/support_ticket_list_view.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadTickets();
  }

  /// The create screen runs on its own cubit instance, so a ticket filed there
  /// is invisible here until we pull the list again on return.
  Future<void> _openCreateTicket() async {
    await Navigator.pushNamed(context, ClientRoutes.createTicket);
    if (!mounted) return;
    await _refresh();
  }

  /// Used by the pull-to-refresh gesture, the app bar's refresh button, and
  /// the return from the create screen. On failure the ticket list stays
  /// exactly as it was — only a toast reports the problem, since a background
  /// refresh failing is not reason enough to blow away data the client can
  /// already see.
  Future<void> _refresh() async {
    try {
      await context.read<SupportCubit>().refreshTickets();
    } catch (e) {
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: SupportCenterAppBar(onRefresh: _refresh),
      body: BlocBuilder<SupportCubit, SupportState>(
        builder: (context, state) {
          if (state is SupportError) {
            return ClientErrorCard.fullScreen(
              message: state.message,
              onRetry: () => context.read<SupportCubit>().loadTickets(),
            );
          }

          if (state is SupportLoaded) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: scheme.primary,
              backgroundColor: scheme.surface,
              child: state.tickets.isEmpty
                  ? SupportCenterEmptyView(onCreateTicket: _openCreateTicket)
                  : SupportTicketListView(
                      tickets: state.tickets,
                      onCreateTicket: _openCreateTicket,
                    ),
            );
          }

          // SupportInitial / SupportLoading, and defensively any transient
          // state this screen's cubit should never actually emit (ticket
          // creation and details states belong to their own screens' cubit
          // instances) — a skeleton is always a safe default.
          return const SupportCenterLoadingView();
        },
      ),
    );
  }
}
