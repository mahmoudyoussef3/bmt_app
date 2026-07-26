import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_office.dart';
import '../../cubit/packages_cubit.dart';
import '../../cubit/packages_state.dart';
import 'packages_office_picker_sheet.dart';

/// The office lens above the catalogue: a pill that opens the searchable office
/// picker, and — once a seller is chosen — a context line naming it with a clear
/// "show all" action. Hidden entirely when a single office sells everything, so
/// the default marketplace view stays uncluttered.
class PackagesOfficeFilterBar extends StatelessWidget {
  const PackagesOfficeFilterBar({super.key, required this.state});

  final PackagesLoaded state;

  Future<void> _openPicker(BuildContext context) async {
    final cubit = context.read<PackagesCubit>();
    final choice = await PackagesOfficePickerSheet.show(
      context,
      offices: state.offices,
      selectedId: state.officeFilter,
    );
    // Dismissed without choosing → leave the filter untouched.
    if (choice == null) return;
    cubit.selectOffice(choice.isEmpty ? null : choice);
  }

  @override
  Widget build(BuildContext context) {
    if (!state.hasMultipleOffices) return const SizedBox.shrink();

    final l10n = context.l10n;
    final selected = state.selectedOffice;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterPill(
            selected: selected,
            allOfficesLabel: l10n.packages_allOffices,
            onTap: () => _openPicker(context),
          ),
          if (selected != null) ...[
            const SizedBox(height: ClientSpacing.xs),
            _SelectedContext(
              label: l10n.packages_fromOffice(selected.name),
              clearLabel: l10n.packages_showAllOffices,
              onClear: () => context.read<PackagesCubit>().selectOffice(null),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.selected,
    required this.allOfficesLabel,
    required this.onTap,
  });

  final PackageOffice? selected;
  final String allOfficesLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFiltered = selected != null;

    return Material(
      color: isFiltered
          ? scheme.primary.withAlpha(20)
          : ClientColors.surfaceSubtleFor(context),
      borderRadius: BorderRadius.circular(ClientRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClientRadius.md),
            border: Border.all(
              color: isFiltered
                  ? scheme.primary.withAlpha(90)
                  : ClientColors.borderFor(context),
            ),
          ),
          child: Row(
            children: [
              if (selected != null)
                OfficeLogoAvatar(logoUrl: selected!.logoUrl, size: 26)
              else
                Icon(Icons.storefront_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected?.name ?? allOfficesLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isFiltered
                        ? scheme.primary
                        : ClientColors.textPrimaryFor(context),
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: ClientColors.textSecondaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedContext extends StatelessWidget {
  const _SelectedContext({
    required this.label,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ),
        TextButton(
          onPressed: onClear,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            clearLabel,
            style: ClientTypography.labelMedium(context).copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
