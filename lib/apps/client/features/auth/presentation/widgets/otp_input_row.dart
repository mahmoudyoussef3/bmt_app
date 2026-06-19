import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Six-digit OTP input row with focus chaining (visual only).
class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.hasError = false,
    this.enabled = true,
    this.onCompleted,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final bool enabled;
  final VoidCallback? onCompleted;

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? Theme.of(context).colorScheme.error
        : ClientColors.borderFor(context);
    final focusedColor = widget.hasError
        ? Theme.of(context).colorScheme.error
        : ClientColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: widget.controllers[index],
            focusNode: widget.focusNodes[index],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: ClientTypography.headingMedium(
              context,
            ).copyWith(letterSpacing: 0),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: ClientColors.surfaceMutedFor(context),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: focusedColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                widget.focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                widget.focusNodes[index - 1].requestFocus();
              }
              final code = widget.controllers.map((c) => c.text).join();
              if (code.length == 6) {
                widget.onCompleted?.call();
              }
              setState(() {});
            },
          ),
        );
      }),
    );
  }
}

/// Status banner for OTP success / error presentation states.
class OtpStatusBanner extends StatelessWidget {
  const OtpStatusBanner.success({super.key, required this.message})
    : isSuccess = true;

  const OtpStatusBanner.error({super.key, required this.message})
    : isSuccess = false;

  final bool isSuccess;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess
        ? ClientColors.journeyGreen
        : ClientColors.journeyRed;
    final bgColor = isSuccess
        ? ClientColors.journeyGreenLight
        : ClientColors.journeyRedLight;
    final icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: ClientTypography.bodyMedium(context)),
          ),
        ],
      ),
    );
  }
}
