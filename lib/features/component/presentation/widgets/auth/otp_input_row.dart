import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bmt_app/core/theme/colors.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final borderColor = widget.hasError ? scheme.error : scheme.outline;
    final focusedColor = widget.hasError ? scheme.error : scheme.primary;

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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: borderColor.withAlpha(180),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: focusedColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.error, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.error, width: 2),
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
    final color = isSuccess ? AppColors.secondary : AppColors.destructive;
    final icon = isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
