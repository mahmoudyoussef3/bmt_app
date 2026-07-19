import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';

import '../../../domain/entities/package_filter.dart';
import '../../cubit/packages_cubit.dart';

class PackagesFilterTab extends StatelessWidget {
  const PackagesFilterTab({
    super.key,
    required this.filter,
    required this.label,
    required this.isSelected,
  });

  final PackageFilter filter;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => context.read<PackagesCubit>().selectFilter(filter),
        child: AnimatedContainer(
          duration: ClientMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(ClientRadius.lg),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? scheme.onPrimary
                  : scheme.onSurface.withAlpha(180),
            ),
          ),
        ),
      ),
    );
  }
}
