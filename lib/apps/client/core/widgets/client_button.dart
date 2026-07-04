import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// The standard call-to-action button for the client app.
///
/// Comes in three variants:
/// - `ClientButton` (default) — primary filled, full-width by default
/// - `ClientButton.secondary` — outlined, full-width by default
/// - `ClientButton.text` — text-only, no background
///
/// All variants support an inline [isLoading] state that replaces the label
/// with a [CircularProgressIndicator] and disables the tap target.
class ClientButton extends StatelessWidget {
  const ClientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : _variant = _ClientButtonVariant.primary;

  const ClientButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : _variant = _ClientButtonVariant.secondary;

  const ClientButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : _variant = _ClientButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  /// When `true` (default) the button stretches to fill its parent's width.
  final bool expand;

  final _ClientButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final effective = isLoading ? null : onPressed;
    final child = _buildChild(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final minSize = expand ? const Size.fromHeight(52) : const Size(0, 52);

    Widget button = switch (_variant) {
      _ClientButtonVariant.primary => PressableScale(
        onTap: effective,
        scale: 0.96,
        child: Container(
          constraints: BoxConstraints(minHeight: minSize.height),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: effective == null
                ? null
                : ClientColors.primaryGradientFor(context),
            color: effective == null
                ? Theme.of(context).colorScheme.primary.withAlpha(100)
                : null,
            borderRadius: BorderRadius.circular(ClientRadius.md),
            boxShadow: effective == null ? null : ClientElevation.sm(context),
          ),
          child: DefaultTextStyle(
            style: ClientTypography.labelLarge(context).copyWith(
              color: effective == null
                  ? Theme.of(context).colorScheme.onPrimary.withAlpha(180)
                  : Theme.of(context).colorScheme.onPrimary,
            ),
            child: IconTheme(
              data: IconThemeData(
                color: effective == null
                    ? Theme.of(context).colorScheme.onPrimary.withAlpha(180)
                    : Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
      _ClientButtonVariant.secondary => OutlinedButton(
        onPressed: effective,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(
            color: isLoading
                ? Theme.of(context).colorScheme.primary.withAlpha(80)
                : Theme.of(context).colorScheme.primary,
          ),
          minimumSize: minSize,
          shape: shape,
          textStyle: ClientTypography.labelLarge(context),
        ),
        child: child,
      ),
      _ClientButtonVariant.text => TextButton(
        onPressed: effective,
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          minimumSize: const Size(0, 44),
          shape: shape,
          textStyle: ClientTypography.labelLarge(context),
        ),
        child: child,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _ClientButtonVariant.primary
                ? ClientColors.textInverse
                : ClientColors.primary,
          ),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

enum _ClientButtonVariant { primary, secondary, text }
