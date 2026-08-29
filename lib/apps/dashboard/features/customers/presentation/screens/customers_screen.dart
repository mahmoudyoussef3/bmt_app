import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/usecases/customers_usecases.dart';
import '../cubit/customer_profile_cubit.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../widgets/customer_profile_view.dart';
import '../widgets/customers_format.dart';
import '../widgets/customers_kpi_strip.dart';
import '../widgets/customers_table.dart';
import '../widgets/customers_toolbar.dart';

/// العملاء — the Customer 360 module.
///
/// ## Two surfaces, not a split pane
///
/// The directory browses; opening a customer replaces it with a full-width
/// workspace. That is the console's standing rule — *browse in a grid, work
/// full width; split panes are for reading, not editing* — and a Customer 360
/// with five tabs is work: crammed into three fifths of the window beside a
/// list, every tab inside it would need its own horizontal scroll.
///
/// ## Why the open customer is widget state
///
/// The shell has no navigator, so "which customer is open" is not a route. It
/// is deliberately *not* in [CustomersCubit] either: the directory's state
/// survives the round trip precisely because the cubit never learns about the
/// profile, and the profile gets a fresh cubit per customer with no stale tab
/// from the last one.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String? _openClientId;
  String? _openClientName;

  void _open(String clientId, String name) {
    setState(() {
      _openClientId = clientId;
      _openClientName = name;
    });
  }

  void _back() {
    setState(() {
      _openClientId = null;
      _openClientName = null;
    });
    // The profile is read-only, so nothing behind it can have changed — but a
    // colleague's booking can land while it is open, and the directory the
    // operator returns to should not be older than the profile they just read.
    context.read<CustomersCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final clientId = _openClientId;
    if (clientId != null) {
      return BlocProvider<CustomerProfileCubit>(
        // Keyed on the customer so opening a second profile builds a second
        // cubit rather than reusing the first one's loaded tabs.
        key: ValueKey(clientId),
        create: (_) => CustomerProfileCubit(
          clientId: clientId,
          getProfile: dashboardDi<GetCustomerProfileUseCase>(),
          getTrips: dashboardDi<GetCustomerTripsUseCase>(),
          getSubscriptions: dashboardDi<GetCustomerSubscriptionsUseCase>(),
          getPayments: dashboardDi<GetCustomerPaymentsUseCase>(),
          getActivity: dashboardDi<GetCustomerActivityUseCase>(),
        )..load(),
        child: CustomerProfileView(
          fallbackName: _openClientName ?? '',
          onBack: _back,
        ),
      );
    }

    return _CustomersDirectory(onOpen: _open);
  }
}

class _CustomersDirectory extends StatelessWidget {
  const _CustomersDirectory({required this.onOpen});

  /// Opens a customer's workspace. Passed down rather than reached for through
  /// the element tree: the directory does not navigate, its host does.
  final void Function(String clientId, String name) onOpen;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (previous, current) =>
          current is CustomersLoadedState && current.actionError != null,
      listener: (context, state) {
        if (state is! CustomersLoadedState) return;
        final message = state.actionError;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 6),
            ),
          );
      },
      builder: (context, state) => switch (state) {
        CustomersLoadingState() => const DashboardLoading(rows: 6),
        CustomersErrorState(:final message) => DashboardErrorState(
          title: 'تعذر تحميل العملاء',
          message: message,
          onRetry: () => context.read<CustomersCubit>().load(),
        ),
        CustomersLoadedState() => _DirectoryBody(state: state, onOpen: onOpen),
      },
    );
  }
}

class _DirectoryBody extends StatelessWidget {
  const _DirectoryBody({required this.state, required this.onOpen});

  final CustomersLoadedState state;
  final void Function(String clientId, String name) onOpen;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    // One clock for the whole build, so every "منذ ٣ ساعات" on the page agrees.
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.customersActive,
          title: 'العملاء',
          subtitle:
              'اعرض العملاء وتابع حجوزاتهم واشتراكاتهم ومدفوعاتهم ونشاطهم مع المكتب.',
          sectionId: DashboardSectionIds.customersHeader,
          actions: [
            if (state.listLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: state.listLoading ? null : cubit.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث'),
            ),
          ],
          // Headers fold their summary by default across the console. This one
          // opens: the four counts *are* this module's headline, and each tile
          // is the shortcut to the list behind it — folded, the module opens on
          // a table with no answer to "how many, and how many need me".
          initiallyExpanded: true,
          collapsedSummary: DashboardSectionSummary(
            items: [
              'إجمالي ${CustomersFormat.count(state.overview.totalCustomers)}',
              'نشط ${CustomersFormat.count(state.overview.activeCustomers)}',
              'باشتراك '
                  '${CustomersFormat.count(state.overview.withActiveSubscription)}',
              'برحلة قادمة '
                  '${CustomersFormat.count(state.overview.withUpcomingTrip)}',
            ],
          ),
          summary: CustomersKpiStrip(
            overview: state.overview,
            filters: state.filters,
            onFilter: cubit.applyFilters,
          ),
        ),
        if (state.overviewFailed) ...[
          const SizedBox(height: AppSpacing.small),
          const DashboardPartialDataNotice(sources: ['ملخص العملاء']),
        ],
        const SizedBox(height: AppSpacing.medium),
        CustomersToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _ResultsHeader(state: state),
        const SizedBox(height: AppSpacing.small),
        // A refetch dims the rows rather than replacing them: losing the list
        // while a filter is applied loses the operator's place in it.
        AnimatedOpacity(
          opacity: state.listLoading ? 0.55 : 1,
          duration: const Duration(milliseconds: 150),
          child: CustomersTable(
            state: state,
            now: now,
            onOpen: (customer) => onOpen(customer.clientId, customer.fullName),
            onPageChanged: cubit.setPage,
            onSort: cubit.setSort,
            onClearFilters: cubit.clearFilters,
          ),
        ),
      ],
    );
  }
}

/// The same strip الحجوزات and الاشتراكات put above their rows: what this list
/// is, and how much of it is on screen.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.state});

  final CustomersLoadedState state;

  @override
  Widget build(BuildContext context) {
    final showing = state.page.rows.length;
    final first = showing == 0 ? 0 : state.pageIndex * customersPageSize + 1;
    final last = first == 0 ? 0 : first + showing - 1;

    return DashboardResultsHeader(
      icon: DashboardIcons.customers,
      title: 'قائمة العملاء',
      subtitle: showing == 0
          ? 'لا نتائج'
          : 'عرض ${CustomersFormat.count(first)}–${CustomersFormat.count(last)} '
                'من ${CustomersFormat.count(state.page.total)}',
    );
  }
}
