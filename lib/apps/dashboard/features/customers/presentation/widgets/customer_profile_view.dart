import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../cubit/customer_profile_cubit.dart';
import '../cubit/customer_profile_state.dart';
import 'customer_activity_tab.dart';
import 'customer_overview_tab.dart';
import 'customer_payments_tab.dart';
import 'customer_profile_header.dart';
import 'customer_subscriptions_tab.dart';
import 'customer_trips_tab.dart';

/// One customer's full-width workspace.
///
/// The hierarchy the operator reads down: back → header → summary → tabs. The
/// tab strip sits at the card's bottom edge, against the panel it switches, and
/// does not fold — a tab bar that can be collapsed is navigation that can be
/// hidden.
class CustomerProfileView extends StatelessWidget {
  const CustomerProfileView({
    super.key,
    required this.onBack,
    this.fallbackName = '',
  });

  final VoidCallback onBack;

  /// The name from the directory row, shown while the profile is still loading
  /// and on the error screen. Without it, "تعذر تحميل ملف العميل" does not say
  /// whose.
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerProfileCubit, CustomerProfileState>(
      builder: (context, state) => switch (state) {
        CustomerProfileLoadingState() => _Frame(
          title: fallbackName,
          onBack: onBack,
          // Not scrollable: `_Frame` is already a ListView, and a nested
          // vertical viewport gets unbounded height and fails to lay out.
          child: const DashboardLoading(rows: 5, scrollable: false),
        ),
        CustomerProfileErrorState(:final message) => _Frame(
          title: fallbackName,
          onBack: onBack,
          child: DashboardErrorState(
            title: 'تعذر تحميل ملف العميل',
            message: message,
            onRetry: () => context.read<CustomerProfileCubit>().load(),
          ),
        ),
        CustomerProfileLoadedState() => _LoadedProfile(
          state: state,
          onBack: onBack,
        ),
      },
    );
  }
}

/// The back bar, shown in every state so the operator is never stranded on a
/// failed profile with no way out but the sidebar.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _BackBar(title: title, onBack: onBack),
        const SizedBox(height: AppSpacing.medium),
        child,
      ],
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(DashboardIcons.back, size: 18),
          label: const Text('العودة إلى العملاء'),
        ),
        if (title.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              '· $title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: DashboardColors.mutedInk(context)),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _LoadedProfile extends StatelessWidget {
  const _LoadedProfile({required this.state, required this.onBack});

  final CustomerProfileLoadedState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerProfileCubit>();
    final now = DateTime.now();
    final failed = state.failedSources;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _BackBar(
          title: state.profile.client.fullName,
          onBack: onBack,
          trailing: FilledButton.tonalIcon(
            onPressed: state.refreshing ? null : cubit.refresh,
            icon: state.refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('تحديث'),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: CustomerProfileHeader(
                  profile: state.profile,
                  now: now,
                  onOpenTab: (index) =>
                      cubit.setTab(CustomerProfileTab.values[index]),
                ),
              ),
              _TabStrip(current: state.tab, onChanged: cubit.setTab),
            ],
          ),
        ),
        if (failed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          DashboardPartialDataNotice(sources: failed),
        ],
        const SizedBox(height: AppSpacing.medium),
        switch (state.tab) {
          CustomerProfileTab.overview => CustomerOverviewTab(
            state: state,
            now: now,
          ),
          CustomerProfileTab.trips => CustomerTripsTab(state: state),
          CustomerProfileTab.subscriptions => CustomerSubscriptionsTab(
            state: state,
            now: now,
          ),
          CustomerProfileTab.payments => CustomerPaymentsTab(state: state),
          CustomerProfileTab.activity => CustomerActivityTab(
            state: state,
            now: now,
          ),
        },
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.current, required this.onChanged});

  final CustomerProfileTab current;
  final ValueChanged<CustomerProfileTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: DashboardColors.divider(context)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          children: [
            for (final tab in CustomerProfileTab.values) ...[
              _Tab(
                label: tab.label,
                selected: tab == current,
                onTap: () => onChanged(tab),
                scheme: scheme,
              ),
              const SizedBox(width: AppSpacing.xSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? scheme.primary.withAlpha(30) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected
                  ? scheme.primary
                  : DashboardColors.mutedInk(context),
            ),
          ),
        ),
      ),
    );
  }
}
