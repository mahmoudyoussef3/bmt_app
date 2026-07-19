import 'package:flutter/material.dart';

import '../../cubit/packages_state.dart';
import '../../routes/subscription_arguments.dart';
import 'package_card.dart';
import 'packages_empty_state.dart';
import 'packages_filter_tabs.dart';

/// Step one: the filterable package catalogue.
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
        Expanded(
          child: packages.isEmpty
              ? const PackagesEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
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
