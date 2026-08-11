import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';

import '../../domain/entities/station_passenger.dart';
import '../formatters/station_labels.dart';

/// What the captain decided about a rider who did not board.
typedef NoShowResolution = ({NoShowReason reason, String? note});

/// Asks *why* a passenger is not travelling.
///
/// This is the whole of the "missing passenger" flow, and it exists so that the
/// alternative to waiting is never a single unlabelled tap. The captain names a
/// reason, that reason is stored against the rider with their own id and the
/// time, and only then does the station's boarding requirement clear.
///
/// Shared with the manifest screen so there is exactly one way to record a
/// no-show in the app, matching the single way to record one in the database.
Future<NoShowResolution?> showNoShowReasonSheet(
  BuildContext context, {
  required String passengerName,
  String? seatLabel,
}) {
  return showModalBottomSheet<NoShowResolution>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _NoShowReasonSheet(
      passengerName: passengerName,
      seatLabel: seatLabel,
    ),
  );
}

class _NoShowReasonSheet extends StatefulWidget {
  const _NoShowReasonSheet({required this.passengerName, this.seatLabel});

  final String passengerName;
  final String? seatLabel;

  @override
  State<_NoShowReasonSheet> createState() => _NoShowReasonSheetState();
}

class _NoShowReasonSheetState extends State<_NoShowReasonSheet> {
  NoShowReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// "Other" without an explanation is a skip with extra steps, and the database
  /// refuses it too — so the button is dead until there is something to record.
  bool get _canSubmit {
    final reason = _reason;
    if (reason == null) return false;
    return !reason.requiresNote || _note.text.trim().isNotEmpty;
  }

  void _submit() {
    if (!_canSubmit) return;
    final note = _note.text.trim();
    Navigator.pop(context, (
      reason: _reason!,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seatLabel;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CaptainColors.surfaceFor(context),
          borderRadius: const BorderRadius.vertical(
            top: CaptainDesignTokens.r32,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          CaptainDesignTokens.s24,
          CaptainDesignTokens.s16,
          CaptainDesignTokens.s24,
          CaptainDesignTokens.s32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Grabber(),
              const SizedBox(height: CaptainDesignTokens.s24),
              Text(
                'راكب لم يصعد',
                style: CaptainTypography.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: CaptainDesignTokens.s4),
              Text(
                seat == null || seat.isEmpty
                    ? widget.passengerName
                    : '${widget.passengerName} · مقعد $seat',
                style: CaptainTypography.bodyMedium(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: CaptainDesignTokens.s20),
              Text(
                'سبب عدم الصعود — سيتم تسجيله باسمك',
                style: CaptainTypography.labelSmall(context).copyWith(
                  color: CaptainColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              for (final reason in NoShowReason.values)
                _ReasonOption(
                  reason: reason,
                  isSelected: _reason == reason,
                  onTap: () => setState(() => _reason = reason),
                ),
              if (_reason?.requiresNote ?? false) ...[
                const SizedBox(height: CaptainDesignTokens.s8),
                TextField(
                  controller: _note,
                  onChanged: (_) => setState(() {}),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'اكتب السبب',
                    border: OutlineInputBorder(
                      borderRadius: CaptainDesignTokens.br16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: CaptainDesignTokens.s24),
              CaptainButton(
                label: 'تسجيل عدم الصعود',
                icon: Icons.person_off_rounded,
                variant: CaptainButtonVariant.danger,
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  final NoShowReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CaptainDesignTokens.s12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: CaptainDesignTokens.br16,
          child: Container(
            padding: const EdgeInsets.all(CaptainDesignTokens.s16),
            decoration: BoxDecoration(
              color: isSelected
                  ? CaptainColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: CaptainDesignTokens.br16,
              border: Border.all(
                color: isSelected
                    ? CaptainColors.primary
                    : CaptainColors.dividerFor(context),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: isSelected
                      ? CaptainColors.primary
                      : CaptainColors.textSecondaryFor(context),
                ),
                const SizedBox(width: CaptainDesignTokens.s12),
                Expanded(
                  child: Text(
                    StationLabels.noShowReason(reason),
                    style: CaptainTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: CaptainColors.textPrimaryFor(context),
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

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: CaptainColors.dividerFor(context),
          borderRadius: CaptainDesignTokens.br8,
        ),
      ),
    );
  }
}
