import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_filter.dart';
import 'packages_filter_tab.dart';

/// The duration filter strip above the catalogue.
class PackagesFilterTabs extends StatelessWidget {
  const PackagesFilterTabs({super.key, required this.selected});

  final PackageFilter selected;

  String _label(BuildContext context, PackageFilter filter) => switch (filter) {
    PackageFilter.all => context.l10n.packages_all,
    PackageFilter.weekly => context.l10n.packages_weekly,
    PackageFilter.monthly => context.l10n.packages_monthly,
    PackageFilter.quarterly => context.l10n.packages_quarterly,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      // Wrap, not a fixed Row: on a small phone the widest Arabic label ("ربع
      // سنوية") would push the four tabs past the edge, so they flow onto a
      // second line instead of overflowing.
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final filter in PackageFilter.values)
            PackagesFilterTab(
              filter: filter,
              label: _label(context, filter),
              isSelected: filter == selected,
            ),
        ],
      ),
    );
  }
}
