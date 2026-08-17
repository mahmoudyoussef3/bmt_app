import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/complaint.dart';
import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

import '../widgets/tickets_summary.dart';
import '../widgets/tickets_table.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

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
            icon: DashboardIcons.ticketsActive,
            title: 'مركز الشكاوى والدعم',
            subtitle: 'راجع شكاوى العملاء، أسندها لموظف، وتابعها حتى الإغلاق.',
            actions: [
              StatusChip(label: '${state.tickets.length} تذكرة'),
              if (state.capReached)
                const DashboardCapNotice(
                  rowCap: DashboardQueryCaps.tickets,
                  noun: 'تذكرة',
                  hint: 'ضيّق الفلاتر للوصول لشكاوى أقدم.',
                ),
              OutlinedButton.icon(
                onPressed: () => context.read<TicketsCubit>().load(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
            sectionId: DashboardSectionIds.ticketsHeader,
            summary: SummaryStats(state: state),
            // The toolbar stays out of the fold: search and the two filters are
            // the only way to reach a ticket that is not on the first page.
            pinned: _TicketsToolbar(state: state),
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: SingleChildScrollView(child: TicketsTable(state: state)),
          ),
        ],
      ),
    );
  }
}

/// Search plus the two queue filters, on one line where there is room for it.
///
/// The status and priority filters existed in the cubit and in
/// [TicketsLoaded.filteredTickets] from the start, but nothing on screen ever
/// called them — the queue could only be searched, never narrowed.
class _TicketsToolbar extends StatelessWidget {
  final TicketsLoaded state;

  const _TicketsToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TicketsCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        final search = DebouncedSearchField(
          hintText: 'ابحث برقم التذكرة أو اسم العميل أو الهاتف...',
          initialValue: state.searchQuery,
          onChanged: cubit.setSearchQuery,
        );

        final statusFilter = DropdownButtonFormField<TicketStatus?>(
          initialValue: state.filterStatus,
          decoration: const InputDecoration(labelText: 'الحالة'),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الحالات')),
            ...TicketStatus.values.map(
              (s) => DropdownMenuItem(value: s, child: Text(s.label)),
            ),
          ],
          onChanged: cubit.setFilterStatus,
        );

        final priorityFilter = DropdownButtonFormField<TicketPriority?>(
          initialValue: state.filterPriority,
          decoration: const InputDecoration(labelText: 'الأولوية'),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الأولويات')),
            ...TicketPriority.values.map(
              (p) => DropdownMenuItem(value: p, child: Text(p.label)),
            ),
          ],
          onChanged: cubit.setFilterPriority,
        );

        final chip = StatusChip(
          label:
              '${state.filteredTickets.length}/${state.tickets.length} تذكرة',
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppSpacing.small),
              statusFilter,
              const SizedBox(height: AppSpacing.small),
              priorityFilter,
              const SizedBox(height: AppSpacing.small),
              Align(alignment: AlignmentDirectional.centerStart, child: chip),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: AppSpacing.medium),
            SizedBox(width: 190, child: statusFilter),
            const SizedBox(width: AppSpacing.medium),
            SizedBox(width: 170, child: priorityFilter),
            const SizedBox(width: AppSpacing.medium),
            chip,
          ],
        );
      },
    );
  }
}
