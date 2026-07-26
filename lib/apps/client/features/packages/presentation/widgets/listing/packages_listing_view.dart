import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/packages_cubit.dart';
import '../../cubit/packages_state.dart';
import '../../routes/subscription_arguments.dart';
import 'package_card.dart';
import 'packages_empty_state.dart';
import 'packages_filter_tabs.dart';
import 'packages_office_filter_bar.dart';

/// Step one: the filterable package marketplace — mixed sellers by default, with
/// a duration strip and an office lens above the list.
class PackagesListingView extends StatelessWidget {
  const PackagesListingView({
    super.key,
    required this.state,
    required this.arguments,
  });

  final PackagesLoaded state;
  final SubscriptionArguments arguments;

  @override
  Widget build(BuildContext context) {
    final packages = state.visiblePackages;

    return Column(
      children: [
        PackagesFilterTabs(selected: state.filter),
        PackagesOfficeFilterBar(state: state),
        Expanded(
          child: packages.isEmpty
              ? _EmptyState(state: state)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  physics: const BouncingScrollPhysics(),
                  itemCount: packages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (_, index) => PackageCard(
                    package: packages[index],
                    arguments: arguments,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Picks the empty copy and escape hatch that fits *why* the list is empty:
/// nothing in the marketplace, nothing from the chosen office, or nothing at the
/// chosen duration.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final PackagesLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (state.packages.isEmpty) {
      return PackagesEmptyState(
        title: l10n.packages_emptyMarketplaceTitle,
        body: l10n.packages_emptyMarketplaceBody,
        icon: Icons.storefront_outlined,
        actionLabel: l10n.packages_exploreTrips,
        onAction: () =>
            Navigator.of(context).pushNamed(BookingRoutes.popularRoutes),
      );
    }

    if (state.officeFilter != null) {
      return PackagesEmptyState(
        title: l10n.packages_emptyOfficeTitle,
        body: l10n.packages_emptyOfficeBody,
        icon: Icons.storefront_outlined,
        actionLabel: l10n.packages_viewAllOffices,
        onAction: () => context.read<PackagesCubit>().selectOffice(null),
      );
    }

    return PackagesEmptyState(
      title: l10n.packages_emptyTitle,
      body: l10n.packages_emptyBody,
    );
  }
}
