import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../cubit/tickets_cubit.dart';
import '../cubit/tickets_state.dart';

import '../widgets/tickets_board.dart';
import '../widgets/tickets_format.dart';
import '../widgets/tickets_summary.dart';
import '../widgets/tickets_toolbar.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/query/dashboard_query_caps.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_cap_notice.dart';

/// Customer support desk: triage the complaint queue and work a ticket to
/// resolution.
///
/// Mounted inside the dashboard shell, which already supplies the page chrome
/// (title bar, navigation, RTL) — so this screen contributes only its own
/// content, exactly like every other module.
///
/// ## One shape for the whole الدعم section
///
/// Header with its foldable KPI strip → the shared filter bar (queue strip,
/// pinned search and ordering, the rest behind one fold) → the results header →
/// the rows. التقييمات next door is composed the same way, and so are the three
/// المبيعات modules: the section an operator is in should never change what the
/// controls are or where they live.
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
        TicketsLoading() => const DashboardLoading(rows: 6),
        TicketsError(:final message) => DashboardErrorState(
          title: 'تعذر تحميل الشكاوى',
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
    final cubit = context.read<TicketsCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.ticketsActive,
          title: 'مركز الشكاوى والدعم',
          subtitle: 'راجع شكاوى العملاء، أسندها لموظف، وتابعها حتى الإغلاق.',
          actions: [
            if (state.capReached)
              const DashboardCapNotice(
                rowCap: DashboardQueryCaps.tickets,
                noun: 'تذكرة',
                hint: 'ضيّق الفلاتر للوصول لشكاوى أقدم.',
              ),
            if (state.actionLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: cubit.load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          sectionId: DashboardSectionIds.ticketsHeader,
          // Open, like every other list module's header: the four counts *are*
          // what the desk is opened to read, and each tile is the shortcut to
          // the queue behind it. Folded, the module would open on a table with
          // no answer to "how many, and how many need me".
          initiallyExpanded: true,
          collapsedSummary: DashboardSectionSummary(
            items: [
              'جديدة ${TicketsFormat.count(state.newCount)}',
              'قيد المراجعة ${TicketsFormat.count(state.underReviewCount)}',
              'تم الحل ${TicketsFormat.count(state.resolvedCount)}',
              'متأخرة ${TicketsFormat.count(state.delayedCount)}',
            ],
          ),
          summary: SummaryStats(state: state, onOpenQueue: cubit.switchTab),
        ),
        const SizedBox(height: AppSpacing.medium),
        TicketsToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        TicketsBoard(state: state),
      ],
    );
  }
}
