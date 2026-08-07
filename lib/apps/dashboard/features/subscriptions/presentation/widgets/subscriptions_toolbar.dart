import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_section_state_store.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_collapsible_section.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';

import '../../domain/entities/subscription_trip.dart';
import '../cubit/subscriptions_cubit.dart';
import '../cubit/subscriptions_state.dart';
import '../models/subscription_filters.dart';
import '../models/subscription_queue_tab.dart';
import '../models/subscription_sort.dart';
import 'subscription_formatting.dart';

/// Queue tabs, then the filter row — the same toolbar shape the Bookings board
/// uses, so an operator moving between modules keeps the same muscle memory.
class SubscriptionsToolbar extends StatelessWidget {
  const SubscriptionsToolbar({super.key, required this.state});

  final SubscriptionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<SubscriptionsCubit>();

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
            child: _QueueTabBar(state: state, onSelected: cubit.switchTab),
          ),
          const SizedBox(height: AppSpacing.medium),
          Divider(height: 1, color: scheme.outline.withAlpha(60)),
          // Matches the Bookings board: tabs stay, filters fold.
          DashboardCollapsibleSection.bare(
            sectionId: DashboardSectionIds.subscriptionsFilters,
            icon: Icons.filter_alt_outlined,
            title: 'التصفية',
            collapsedSummary: DashboardSectionSummary(
              items: _filterSummary(state),
            ),
            child: _FiltersBar(state: state, cubit: cubit),
          ),
        ],
      ),
    );
  }

  /// Trip and route filters hold ids, so the summary resolves them back to the
  /// names the operator picked — an id in a chip would tell them nothing.
  static List<String> _filterSummary(SubscriptionsLoaded state) {
    final filters = state.filters;
    if (!filters.isActive) return const ['بدون تصفية'];
    return [
      if (filters.search.trim().isNotEmpty) 'بحث: ${filters.search.trim()}',
      if (filters.tripId.isNotEmpty) 'رحلة محددة',
      if (filters.routeId.isNotEmpty) 'خط سير محدد',
      if (filters.packageName.isNotEmpty) 'باقة: ${filters.packageName}',
      if (filters.unpaidOnly) 'غير المسددين فقط',
    ];
  }
}

class _QueueTabBar extends StatelessWidget {
  const _QueueTabBar({required this.state, required this.onSelected});

  final SubscriptionsLoaded state;
  final ValueChanged<SubscriptionQueueTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in SubscriptionQueueTab.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
              child: _QueueTab(
                label: tab.label,
                count: state.countForTab(tab),
                selected: state.activeTab == tab,
                urgent: tab.isWorkQueue,
                onTap: () => onSelected(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  const _QueueTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.urgent,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final accent = urgent && count > 0 ? scheme.tertiary : scheme.primary;
    final background = selected ? accent : scheme.surfaceContainerHighest;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: AppTokens.motionFast,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? accent : scheme.outline.withAlpha(90),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.onPrimary.withAlpha(55)
                        : accent.withAlpha(28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    arabicNumber(count),
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: selected ? scheme.onPrimary : accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({required this.state, required this.cubit});

  final SubscriptionsLoaded state;
  final SubscriptionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    void update(SubscriptionFilters next) => cubit.updateFilters(next);

    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final compact = full < 720;
        final double fieldWidth = compact
            ? full
            : full < 1080
            ? (full - AppSpacing.small) / 2
            : 230;

        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? full : (full < 1080 ? fieldWidth : 280),
              child: DebouncedSearchField(
                // Keyed on the value so "clear filters" empties the box: the
                // field owns its controller and would otherwise keep the
                // stale query on screen.
                key: ValueKey('subscription-search-${filters.search}'),
                initialValue: filters.search,
                hintText: 'اسم، هاتف، باقة، خط سير',
                onChanged: (value) => update(filters.copyWith(search: value)),
              ),
            ),
            SizedBox(
              width: compact ? full : (full < 1080 ? fieldWidth : 320),
              child: _TripFilter(state: state, cubit: cubit),
            ),
            SizedBox(
              width: fieldWidth,
              child: _RouteFilter(
                routes: state.availableRoutes,
                value: filters.routeId.isEmpty ? null : filters.routeId,
                // A trip already pins the route; offering both invites them to
                // disagree.
                enabled: !filters.hasTrip,
                onChanged: (value) =>
                    update(filters.copyWith(routeId: value ?? '')),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _PackageFilter(
                packages: state.availablePackages,
                value: filters.packageName.isEmpty ? null : filters.packageName,
                onChanged: (value) =>
                    update(filters.copyWith(packageName: value ?? '')),
              ),
            ),
            _UnpaidToggle(
              selected: filters.unpaidOnly,
              onChanged: (value) => update(filters.copyWith(unpaidOnly: value)),
            ),
            _SortControl(state: state, cubit: cubit),
            if (filters.isActive)
              SizedBox(
                width: compact ? full : null,
                child: OutlinedButton.icon(
                  onPressed: cubit.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: Text(
                    'مسح الفلاتر (${arabicNumber(filters.activeCount)})',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The trip picker — the filter this whole screen was rebuilt around.
///
/// Each option carries how many subscribers that departure has, so an operator
/// can find the trip worth opening without opening all of them.
class _TripFilter extends StatelessWidget {
  const _TripFilter({required this.state, required this.cubit});

  final SubscriptionsLoaded state;
  final SubscriptionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final trips = state.trips;
    final value = state.filters.tripId.isEmpty ? null : state.filters.tripId;

    if (trips.isEmpty) {
      return const _DisabledField(
        label: 'الرحلة',
        icon: Icons.directions_bus_filled_outlined,
        hint: 'لا توجد رحلات بعد',
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: trips.any((trip) => trip.id == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الرحلة',
        prefixIcon: Icon(Icons.directions_bus_filled_outlined),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('كل الرحلات')),
        ...trips.map(
          (trip) => DropdownMenuItem(
            value: trip.id,
            child: _TripOptionLabel(
              trip: trip,
              subscriberCount: state.subscriberCountForTrip(trip),
            ),
          ),
        ),
      ],
      onChanged: cubit.selectTrip,
    );
  }
}

class _TripOptionLabel extends StatelessWidget {
  const _TripOptionLabel({required this.trip, required this.subscriberCount});

  final SubscriptionTrip trip;
  final int subscriberCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            arabicDigits(trip.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subscriberCount > 0) ...[
          const SizedBox(width: AppSpacing.small),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.primary.withAlpha(28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              arabicNumber(subscriberCount),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteFilter extends StatelessWidget {
  const _RouteFilter({
    required this.routes,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final Map<String, String> routes;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const _DisabledField(
        label: 'خط السير',
        icon: Icons.alt_route_rounded,
        hint: 'لا توجد خطوط مرتبطة',
      );
    }

    final entries = routes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return DropdownButtonFormField<String?>(
      initialValue: routes.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'خط السير',
        prefixIcon: Icon(Icons.alt_route_rounded),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('كل الخطوط')),
        ...entries.map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _PackageFilter extends StatelessWidget {
  const _PackageFilter({
    required this.packages,
    required this.value,
    required this.onChanged,
  });

  final List<String> packages;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return const _DisabledField(
        label: 'الباقة',
        icon: Icons.inventory_2_outlined,
        hint: 'لا توجد باقات',
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: packages.contains(value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الباقة',
        prefixIcon: Icon(Icons.inventory_2_outlined),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('كل الباقات')),
        ...packages.map(
          (name) => DropdownMenuItem(
            value: name,
            child: Text(name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _UnpaidToggle extends StatelessWidget {
  const _UnpaidToggle({required this.selected, required this.onChanged});

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onChanged,
      avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
      label: const Text('عليه مستحقات'),
    );
  }
}

class _SortControl extends StatelessWidget {
  const _SortControl({required this.state, required this.cubit});

  final SubscriptionsLoaded state;
  final SubscriptionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    // A trip board is ordered by check-in state, which is more useful there
    // than any column sort — so the control steps aside rather than lying.
    if (state.tripBoard != null) return const SizedBox.shrink();

    return PopupMenuButton<SubscriptionSortField>(
      tooltip: 'ترتيب القائمة',
      onSelected: cubit.sortBy,
      itemBuilder: (context) => [
        for (final field in SubscriptionSortField.values)
          PopupMenuItem(
            value: field,
            child: Row(
              children: [
                Icon(
                  state.sortField == field
                      ? (state.sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                      : Icons.swap_vert_rounded,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(field.label),
              ],
            ),
          ),
      ],
      // Styled as a button but not one: PopupMenuButton owns the tap, so
      // nesting a real button here would swallow it.
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(120),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xSmall),
            Text('ترتيب: ${state.sortField.label}'),
          ],
        ),
      ),
    );
  }
}

/// A filter with nothing to choose from renders disabled and says why, instead
/// of showing an empty dropdown that looks broken.
class _DisabledField extends StatelessWidget {
  const _DisabledField({
    required this.label,
    required this.icon,
    required this.hint,
  });

  final String label;
  final IconData icon;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        isDense: true,
        enabled: false,
      ),
      child: Text(
        hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
