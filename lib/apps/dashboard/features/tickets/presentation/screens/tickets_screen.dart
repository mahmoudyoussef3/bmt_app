import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

import '../widgets/tickets_summary.dart';
import '../widgets/tickets_table.dart';

/// Customer support desk: triage the complaint queue and work a ticket to
/// resolution.
///
/// Mounted inside the dashboard shell, which already supplies the page chrome
/// (title bar, navigation, RTL) — so this screen contributes only its own
/// content, exactly like every other module.
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TicketsCubit, TicketsState>(
      listenWhen: (previous, current) =>
          current is TicketsLoaded && current.actionMessage != null,
      listener: (context, state) {
        if (state is! TicketsLoaded || state.actionMessage == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<TicketsCubit>().clearActionMessage();
      },
      builder: (context, state) => switch (state) {
        TicketsLoading() => const DashboardLoading(),
        TicketsError(:final message) => DashboardErrorState(
          message: message,
          onRetry: () => context.read<TicketsCubit>().load(),
        ),
        TicketsLoaded() => _LoadedView(state: state),
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final TicketsLoaded state;

  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardModuleHeader(
            icon: Icons.support_agent_rounded,
            title: 'مركز الشكاوى والدعم',
            subtitle: 'راجع شكاوى العملاء، أسندها لموظف، وتابعها حتى الإغلاق.',
            actions: [
              StatusChip(label: '${state.tickets.length} تذكرة'),
              OutlinedButton.icon(
                onPressed: () => context.read<TicketsCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
            child: Column(
              children: [
                SummaryStats(state: state),
                const SizedBox(height: AppSpacing.medium),
                DebouncedSearchField(
                  hintText: 'ابحث برقم التذكرة أو اسم العميل أو الهاتف...',
                  initialValue: state.searchQuery,
                  onChanged: (value) =>
                      context.read<TicketsCubit>().setSearchQuery(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(child: TicketsTable(state: state)),
        ],
      ),
    );
  }
}
