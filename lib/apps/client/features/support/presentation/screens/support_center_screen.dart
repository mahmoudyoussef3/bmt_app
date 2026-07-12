import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/core/routes/client_routes.dart';

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
    context.read<SupportCubit>().loadWorkspace();
  }

  /// Used by both the pull-to-refresh gesture and the app bar's refresh
  /// button. On failure the ticket list stays exactly as it was — only a
  /// toast reports the problem, since a background refresh failing is not
  /// reason enough to blow away data the client can already see.
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      floatingActionButton: BlocBuilder<SupportCubit, SupportState>(
        builder: (context, state) {
          if (state is! SupportLoaded) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () =>
                Navigator.pushNamed(context, ClientRoutes.createTicket),
            backgroundColor: scheme.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.add_rounded, color: scheme.onPrimary),
            label: Text(
              'Create Ticket',
              style: ClientTypography.labelLarge(context).copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
      body: BlocBuilder<SupportCubit, SupportState>(
        builder: (context, state) {
          if (state is SupportError) {
            return ClientErrorCard.fullScreen(
              message: state.message,
              onRetry: () => context.read<SupportCubit>().loadWorkspace(),
            );
          }

          if (state is SupportLoaded) {
            return RefreshIndicator(
              onRefresh: _refresh,
              color: scheme.primary,
              backgroundColor: scheme.surface,
              child: state.tickets.isEmpty
                  ? SupportCenterEmptyView(categories: state.categories)
                  : SupportTicketListView(
                      categories: state.categories,
                      tickets: state.tickets,
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
