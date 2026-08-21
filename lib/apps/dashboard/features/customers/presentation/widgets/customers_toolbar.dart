import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/customer_filters.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';

/// Search, four filters and a sort — the same toolbar shape الحجوزات and
/// الاشتراكات use, so an operator moving between modules keeps the same muscle
/// memory.
///
/// The filters fold into a summary rather than standing open, because the
/// search field is the control used ninety percent of the time and the rest are
/// occasional. What is folded still says what it is holding: a collapsed filter
/// the operator forgot they set is how a partial list gets read as the whole
/// list.
class CustomersToolbar extends StatelessWidget {
  const CustomersToolbar({super.key, required this.state});

  final CustomersLoadedState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final filters = state.filters;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.medium,
              AppSpacing.medium,
              AppSpacing.medium,
              0,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = DebouncedSearchField(
                  // Keyed on the term so clearing the filters from anywhere
                  // else — a KPI tile, the "مسح" button — resets the field
                  // rather than leaving stale text above an unfiltered list.
                  key: ValueKey(filters.search),
                  initialValue: filters.search,
                  hintText: 'ابحث بالاسم أو رقم الهاتف أو البريد أو رقم العميل',
                  onChanged: cubit.search,
                );
                final sort = _SortField(
                  value: filters.sort,
                  onChanged: cubit.setSort,
                );

                // Below ~720 the toolbars wrap across the console; a 260px sort
                // control beside a search field is unusable before that.
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: [
                      search,
                      const SizedBox(height: AppSpacing.small),
                      sort,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: search),
                    const SizedBox(width: AppSpacing.small),
                    SizedBox(width: 240, child: sort),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          DashboardCollapsibleSection.bare(
            sectionId: DashboardSectionIds.customersFilters,
            icon: Icons.filter_alt_outlined,
            title: 'التصفية',
            initiallyExpanded: false,
            collapsedSummary: DashboardSectionSummary(items: _summary(filters)),
            child: _FiltersRow(state: state, cubit: cubit),
          ),
        ],
      ),
    );
  }

  /// What the folded filter row is still doing, in the operator's own words.
  static List<String> _summary(CustomerFilters filters) {
    if (filters.activeCount == 0) return const ['بدون تصفية'];
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.subscription != CustomerSubscriptionFilter.any)
        filters.subscription.label,
      if (filters.upcoming != CustomerUpcomingFilter.any)
        filters.upcoming.label,
      if (filters.activity != CustomerActivityFilter.any)
        filters.activity.label,
      if (filters.status != null) 'الحالة: ${filters.status}',
    ];
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({required this.state, required this.cubit});

  final CustomersLoadedState state;
  final CustomersCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: _Dropdown<CustomerSubscriptionFilter>(
            label: 'الاشتراك',
            value: filters.subscription,
            values: CustomerSubscriptionFilter.values,
            labelOf: (value) => value.label,
            onChanged: cubit.setSubscriptionFilter,
          ),
        ),
        SizedBox(
          width: 220,
          child: _Dropdown<CustomerUpcomingFilter>(
            label: 'الرحلات القادمة',
            value: filters.upcoming,
            values: CustomerUpcomingFilter.values,
            labelOf: (value) => value.label,
            onChanged: cubit.setUpcomingFilter,
          ),
        ),
        SizedBox(
          width: 220,
          child: _Dropdown<CustomerActivityFilter>(
            label: 'النشاط',
            value: filters.activity,
            values: CustomerActivityFilter.values,
            labelOf: (value) => value.label,
            onChanged: cubit.setActivityFilter,
          ),
        ),
        SizedBox(
          width: 200,
          child: _Dropdown<String?>(
            label: 'حالة الحساب',
            value: filters.status,
            // `clients.status` is the passenger's own account state and the
            // office does not own it, so the options mirror the database rather
            // than being invented here.
            values: const [null, 'active', 'suspended', 'blocked'],
            labelOf: (value) => switch (value) {
              null => 'الكل',
              'active' => 'نشط',
              'suspended' => 'موقوف',
              'blocked' => 'محظور',
              _ => value,
            },
            onChanged: cubit.setStatusFilter,
          ),
        ),
        if (filters.activeCount > 0)
          TextButton.icon(
            onPressed: cubit.clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: Text('مسح التصفية (${filters.activeCount})'),
          ),
      ],
    );
  }
}

class _SortField extends StatelessWidget {
  const _SortField({required this.value, required this.onChanged});

  final CustomerSort value;
  final ValueChanged<CustomerSort> onChanged;

  @override
  Widget build(BuildContext context) => _Dropdown<CustomerSort>(
    label: 'الترتيب',
    value: value,
    values: CustomerSort.values,
    labelOf: (sort) => sort.label,
    onChanged: onChanged,
  );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(
            value: item,
            child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        // A dropdown reports null when it is cleared, which none of these can
        // be — every set includes its own "الكل" member. The type test also
        // admits null for the nullable T (حالة الحساب), where null *is* "الكل".
        if (selected is T) onChanged(selected);
      },
    );
  }
}
