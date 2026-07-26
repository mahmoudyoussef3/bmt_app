import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_logo_avatar.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../../domain/entities/package_office.dart';

/// The searchable office picker for the packages marketplace.
///
/// Returns the chosen office id through `Navigator.pop`, or the empty string for
/// the "all offices" row. A `null` pop (dismiss) leaves the current filter as
/// it was — the caller distinguishes the two.
class PackagesOfficePickerSheet extends StatefulWidget {
  const PackagesOfficePickerSheet({
    super.key,
    required this.offices,
    required this.selectedId,
  });

  final List<PackageOffice> offices;
  final String? selectedId;

  /// Opens the picker and resolves to `''` (all offices), an office id, or
  /// `null` when dismissed without a choice.
  static Future<String?> show(
    BuildContext context, {
    required List<PackageOffice> offices,
    required String? selectedId,
  }) {
    return showClientBottomSheet<String>(
      context: context,
      builder: (_) =>
          PackagesOfficePickerSheet(offices: offices, selectedId: selectedId),
    );
  }

  @override
  State<PackagesOfficePickerSheet> createState() =>
      _PackagesOfficePickerSheetState();
}

class _PackagesOfficePickerSheetState extends State<PackagesOfficePickerSheet> {
  String _query = '';

  /// A search box only earns its space once the list is long enough to scan.
  bool get _searchable => widget.offices.length > 6;

  List<PackageOffice> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.offices;
    return widget.offices
        .where((office) => office.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filtered;

    return ClientBottomSheet(
      title: l10n.packages_filterByOffice,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_searchable) ...[
            TextField(
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.packages_officeSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: ClientColors.surfaceSubtleFor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: ClientSpacing.sm),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: filtered.isEmpty
                  ? _NoMatch(query: _query)
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        // "All offices" always leads, and is never filtered out.
                        _AllOfficesRow(
                          isSelected: widget.selectedId == null,
                          onTap: () => Navigator.of(context).pop(''),
                        ),
                        for (final office in filtered)
                          _OfficeRow(
                            office: office,
                            isSelected: office.id == widget.selectedId,
                            onTap: () => Navigator.of(context).pop(office.id),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllOfficesRow extends StatelessWidget {
  const _AllOfficesRow({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _RowShell(
      isSelected: isSelected,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.apps_rounded, color: scheme.primary),
      ),
      title: context.l10n.packages_allOffices,
      subtitle: null,
    );
  }
}

class _OfficeRow extends StatelessWidget {
  const _OfficeRow({
    required this.office,
    required this.isSelected,
    required this.onTap,
  });

  final PackageOffice office;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      isSelected: isSelected,
      onTap: onTap,
      leading: OfficeLogoAvatar(logoUrl: office.logoUrl, size: 40),
      title: office.name,
      subtitle: context.l10n.packages_officePackagesCount(office.packageCount),
      trailing: office.hasRating
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  office.rating.toStringAsFixed(1),
                  style: ClientTypography.labelMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            )
          : null,
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: ClientSpacing.xs),
      child: Material(
        color: isSelected ? scheme.primary.withAlpha(18) : Colors.transparent,
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ClientRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClientTypography.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClientTypography.labelSmall(context).copyWith(
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                const SizedBox(width: 4),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: scheme.primary)
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.xl),
      child: Text(
        context.l10n.packages_noOfficeMatch(query.trim()),
        textAlign: TextAlign.center,
        style: ClientTypography.bodyMedium(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context)),
      ),
    );
  }
}
