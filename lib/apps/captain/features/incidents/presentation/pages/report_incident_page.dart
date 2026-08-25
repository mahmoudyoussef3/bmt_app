import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_section_label.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/incident_report.dart';
import '../cubit/incident_cubit.dart';
import '../cubit/incident_state.dart';

/// Reporting an incident, as the design lays it out: pick the kind from a row
/// of chips, then say what happened.
///
/// The kind used to be a dropdown. A dropdown hides every option until it is
/// opened and costs two taps to answer a question with six answers — and this
/// is a form the captain fills in at the roadside, often one-handed, sometimes
/// in an actual emergency. Chips put all six on screen at once and make it one
/// tap.
class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({
    super.key,
    required this.tripId,
    this.initialType = IncidentType.delay,
  });

  final String tripId;
  final IncidentType initialType;

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  static const _minDescription = 8;

  late IncidentType _type;
  String _description = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  void _submit(BuildContext context) {
    final description = _description.trim();
    if (description.length < _minDescription) {
      AppSnackbar.warning(context, 'اكتب وصفاً واضحاً قبل إرسال البلاغ');
      return;
    }
    setState(() => _submitting = true);
    context.read<IncidentCubit>().submit(
      IncidentReport(
        tripId: widget.tripId,
        type: _type,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IncidentCubit>(
      create: (_) => captainGetIt<IncidentCubit>(),
      child: Scaffold(
        backgroundColor: CaptainColors.backgroundFor(context),
        body: CustomScrollView(
          slivers: [
            const CaptainSliverHeader(title: 'الإبلاغ عن حادثة'),
            BlocConsumer<IncidentCubit, IncidentState>(
              listener: (context, state) {
                if (state is IncidentReady && state.submitted) {
                  AppSnackbar.success(context, 'تم إرسال البلاغ إلى العمليات');
                  context.closeScreen();
                }
                if (state is IncidentError) {
                  setState(() => _submitting = false);
                  AppSnackbar.error(context, state.message);
                }
              },
              builder: (context, state) {
                final busy = state is IncidentSubmitting || _submitting;

                return SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    CaptainDesignTokens.s20,
                    CaptainDesignTokens.s20,
                    CaptainDesignTokens.s20,
                    CaptainDesignTokens.s32,
                  ),
                  sliver: SliverList.list(
                    children: [
                      const CaptainSectionLabel('نوع الحادثة'),
                      _TypeChips(
                        selected: _type,
                        enabled: !busy,
                        onSelect: (type) => setState(() => _type = type),
                      ),
                      const SizedBox(height: CaptainDesignTokens.s24),
                      const CaptainSectionLabel('ماذا حدث؟'),
                      _DescriptionField(
                        enabled: !busy,
                        onChanged: (value) => _description = value,
                      ),
                      const SizedBox(height: CaptainDesignTokens.s20),
                      CaptainButton(
                        label: 'إرسال البلاغ',
                        icon: Icons.send_rounded,
                        isLoading: busy,
                        height: 52,
                        onPressed: busy ? null : () => _submit(context),
                      ),
                      const SizedBox(height: CaptainDesignTokens.s12),
                      const _Reassurance(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final IncidentType selected;
  final bool enabled;
  final ValueChanged<IncidentType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CaptainDesignTokens.s8,
      runSpacing: CaptainDesignTokens.s8,
      children: [
        for (final type in IncidentType.values)
          _TypeChip(
            label: incidentTypeLabel(type),
            isSelected: type == selected,
            onTap: enabled ? () => onSelect(type) : null,
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainDesignTokens.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? CaptainColors.primary
                : CaptainColors.surfaceAltFor(context),
            borderRadius: CaptainDesignTokens.brPill,
            border: Border.all(
              color: isSelected
                  ? CaptainColors.primary
                  : CaptainColors.borderFor(context),
            ),
          ),
          child: Text(
            label,
            style: CaptainTypography.labelMedium(context).copyWith(
              color: isSelected
                  ? CaptainColors.onPrimary
                  : CaptainColors.textPrimaryFor(context),
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      minLines: 4,
      maxLines: 7,
      enabled: enabled,
      textAlignVertical: TextAlignVertical.top,
      style: CaptainTypography.bodySmall(context),
      decoration: InputDecoration(
        hintText: 'اكتب ما حدث بوضوح لفريق العمليات',
        hintStyle: CaptainTypography.bodySmall(
          context,
        ).copyWith(color: CaptainColors.textSecondaryFor(context)),
        contentPadding: const EdgeInsets.all(CaptainDesignTokens.s12),
      ),
      onChanged: onChanged,
    );
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: CaptainColors.textSecondaryFor(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'يصل البلاغ إلى العمليات فوراً، ويبقى مرتبطاً بهذه الرحلة.',
            style: CaptainTypography.labelSmall(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

/// The Arabic name of an incident kind.
String incidentTypeLabel(IncidentType type) => switch (type) {
  IncidentType.passengerIssue => 'مشكلة مع راكب',
  IncidentType.vehicleIssue => 'مشكلة في المركبة',
  IncidentType.delay => 'تأخير',
  IncidentType.emergency => 'طوارئ',
  IncidentType.routeBlockage => 'انسداد الطريق',
  IncidentType.other => 'أخرى',
};
