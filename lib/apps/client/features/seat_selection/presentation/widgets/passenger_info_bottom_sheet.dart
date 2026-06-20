import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Passenger details bottom sheet (UI placeholder — no validation logic).
Future<void> showPassengerInfoBottomSheet(
  BuildContext context, {
  String? seatLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClientColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _PassengerInfoSheet(seatLabel: seatLabel),
    ),
  );
}

class _PassengerInfoSheet extends StatelessWidget {
  const _PassengerInfoSheet({this.seatLabel});

  final String? seatLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ClientColors.borderFor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Passenger information',
              style: ClientTypography.headingMedium(context),
            ),
            if (seatLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                'Seat $seatLabel',
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Contact details',
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const _PassengerField(
              label: 'Passenger name',
              hint: 'Full name as on ID',
              icon: Icons.person_outline_rounded,
              showValid: true,
            ),
            const SizedBox(height: 14),
            const _PassengerField(
              label: 'Passenger phone number',
              hint: '+20 10 1234 5678',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: ClientColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'We will use this number for trip updates.',
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClientButton(
              label: 'Save details',
              expand: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerField extends StatelessWidget {
  const _PassengerField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.showValid = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool showValid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 8),
        TextField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ClientColors.primary),
            suffixIcon: showValid
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: ClientColors.primary,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: ClientColors.borderFor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: ClientColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
