import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/captain_onboarding_models.dart';

/// Which office the captain is asking to drive for.
///
/// This used to be a bare [DropdownButtonFormField], which threw away
/// everything that distinguishes one office from another: an office has a logo
/// and a description, and the captain is choosing an employer — a menu of
/// single-line names is the wrong instrument for a decision that has to be
/// right the first time (a request filed against the wrong office is rejected
/// by an operator who has never heard of them).
///
/// It also could not show *why* it was empty. A sheet can: while the list is
/// still loading the control says so and refuses the tap, instead of opening on
/// nothing.
class CaptainOfficePicker extends StatelessWidget {
  const CaptainOfficePicker({
    super.key,
    required this.offices,
    required this.value,
    required this.onChanged,
    this.loading = false,
    this.enabled = true,
  });

  final List<OnboardingOffice> offices;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool loading;
  final bool enabled;

  OnboardingOffice? get _selected {
    for (final office in offices) {
      if (office.id == value) return office;
    }
    return null;
  }

  Future<void> _open(BuildContext context, FormFieldState<String> field) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfficeSheet(offices: offices, selectedId: value),
    );
    if (picked == null) return;
    field.didChange(picked);
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: (v) => (v == null || v.isEmpty) ? 'اختر المكتب' : null,
      builder: (field) {
        // The parent owns the value; re-sync so a reset from above (an office
        // that vanished from the list) clears the error with it.
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }

        final hasError = field.hasError;
        final selected = _selected;
        final tappable = enabled && !loading && offices.isNotEmpty;

        final borderColor = hasError
            ? CaptainColors.dangerFor(context)
            : CaptainColors.borderFor(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: CaptainDesignTokens.s4,
                bottom: CaptainDesignTokens.s8,
              ),
              child: Text(
                'المكتب',
                style: CaptainTypography.labelMedium(context).copyWith(
                  color: CaptainColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Material(
              color: CaptainColors.surfaceAltFor(context),
              shape: RoundedRectangleBorder(
                borderRadius: CaptainDesignTokens.br12,
                side: BorderSide(color: borderColor, width: hasError ? 1.5 : 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: tappable ? () => _open(context, field) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s12,
                    vertical: CaptainDesignTokens.s16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 20,
                        color: hasError
                            ? CaptainColors.dangerFor(context)
                            : CaptainColors.textSecondaryFor(context),
                      ),
                      const SizedBox(width: CaptainDesignTokens.s12),
                      Expanded(
                        child: Text(
                          loading
                              ? 'جارٍ تحميل المكاتب…'
                              : selected?.name ?? 'اختر من القائمة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CaptainTypography.bodyMedium(context).copyWith(
                            color: selected == null
                                ? CaptainColors.textSecondaryFor(context)
                                : CaptainColors.textPrimaryFor(context),
                            fontWeight: selected == null
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: CaptainDesignTokens.s8),
                      if (loading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CaptainColors.textSecondaryFor(context),
                          ),
                        )
                      else
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: CaptainColors.textSecondaryFor(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  CaptainDesignTokens.s4,
                  CaptainDesignTokens.s8,
                  CaptainDesignTokens.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: CaptainColors.dangerFor(context),
                    ),
                    const SizedBox(width: CaptainDesignTokens.s4 + 2),
                    Expanded(
                      child: Text(
                        field.errorText!,
                        style: CaptainTypography.bodySmall(context).copyWith(
                          color: CaptainColors.dangerFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OfficeSheet extends StatelessWidget {
  const _OfficeSheet({required this.offices, required this.selectedId});

  final List<OnboardingOffice> offices;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: const BorderRadius.vertical(
            top: CaptainDesignTokens.r32,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: CaptainDesignTokens.s12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CaptainColors.dividerFor(context),
                borderRadius: CaptainDesignTokens.brPill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CaptainDesignTokens.s20),
              child: Text(
                'اختر المكتب',
                style: CaptainTypography.titleMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsetsDirectional.fromSTEB(
                  CaptainDesignTokens.s16,
                  0,
                  CaptainDesignTokens.s16,
                  CaptainDesignTokens.s24,
                ),
                itemCount: offices.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: CaptainDesignTokens.s8),
                itemBuilder: (context, index) => _OfficeTile(
                  office: offices[index],
                  selected: offices[index].id == selectedId,
                  onTap: () => Navigator.of(context).pop(offices[index].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeTile extends StatelessWidget {
  const _OfficeTile({
    required this.office,
    required this.selected,
    required this.onTap,
  });

  final OnboardingOffice office;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = CaptainColors.primaryInkFor(context);

    return Material(
      color: selected
          ? accent.withValues(alpha: 0.08)
          : CaptainColors.surfaceAltFor(context),
      shape: RoundedRectangleBorder(
        borderRadius: CaptainDesignTokens.br16,
        side: BorderSide(
          color: selected ? accent : CaptainColors.borderFor(context),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CaptainDesignTokens.s12),
          child: Row(
            children: [
              _OfficeAvatar(office: office),
              const SizedBox(width: CaptainDesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      office.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CaptainTypography.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: CaptainColors.textPrimaryFor(context),
                      ),
                    ),
                    if (office.description case final String note
                        when note.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CaptainTypography.labelSmall(context).copyWith(
                          color: CaptainColors.textSecondaryFor(context),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: CaptainDesignTokens.s8),
                Icon(Icons.check_circle_rounded, size: 20, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficeAvatar extends StatelessWidget {
  const _OfficeAvatar({required this.office});

  final OnboardingOffice office;

  @override
  Widget build(BuildContext context) {
    final accent = CaptainColors.primaryInkFor(context);
    final logo = office.logoUrl;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: CaptainDesignTokens.br12,
      ),
      child: logo == null || logo.isEmpty
          ? Icon(Icons.apartment_rounded, size: 20, color: accent)
          : Image.network(
              logo,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.apartment_rounded, size: 20, color: accent),
            ),
    );
  }
}
