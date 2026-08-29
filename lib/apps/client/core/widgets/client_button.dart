import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// The standard call-to-action for the client app.
///
/// The four variants are the design file's four button constants, one to one:
///
/// - `ClientButton` — `BTN_PRIMARY`: filled brand, with the coloured
///   `--primary-tint` lift the design puts under a primary action instead of a
///   neutral shadow.
/// - `ClientButton.secondary` — `BTN_OUTLINE`: a 1.5px brand outline on no
///   fill.
/// - `ClientButton.danger` — `BTN_DANGER`: the same outline in `--danger`, for
///   cancel-booking and other destructive confirmations.
/// - `ClientButton.text` — the inline link treatment.
///
/// All variants share one geometry (14px radius, 52px tall, 700-weight label)
/// and support an inline [isLoading] state that replaces the label with a
/// spinner and disables the tap target. [dense] drops that geometry to the
/// 44pt control a card-sized action needs.
class ClientButton extends StatelessWidget {
  const ClientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.dense = false,
  }) : _variant = _ClientButtonVariant.primary;

  const ClientButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.dense = false,
  }) : _variant = _ClientButtonVariant.secondary;

  const ClientButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.dense = false,
  }) : _variant = _ClientButtonVariant.danger;

  const ClientButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.dense = false,
  }) : _variant = _ClientButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  /// When `true` (default) the button stretches to fill its parent's width.
  final bool expand;

  /// The compact control: 44pt instead of 52, on tighter padding and a 14px
  /// label. For actions that sit *inside* a card — a list row's "book" — where
  /// the full CTA would outweigh the card carrying it. Still above the 44pt
  /// minimum tap target, so it is smaller without being harder to hit.
  final bool dense;

  final _ClientButtonVariant _variant;

  /// `padding:15px` on a 15px/1.4 label — the design's CTA height.
  static const double _height = 52;

  /// The [dense] control's height — Material's minimum comfortable tap target.
  static const double _denseHeight = 44;

  double get _controlHeight => dense ? _denseHeight : _height;

  @override
  Widget build(BuildContext context) {
    final effective = isLoading ? null : onPressed;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ClientRadius.control),
    );
    final minSize = expand
        ? Size.fromHeight(_controlHeight)
        : Size(0, _controlHeight);

    Widget button = switch (_variant) {
      _ClientButtonVariant.primary => _filled(context, effective, minSize),
      _ClientButtonVariant.secondary => _outlined(
        context,
        effective,
        minSize,
        shape,
        ClientColors.primaryFor(context),
      ),
      _ClientButtonVariant.danger => _outlined(
        context,
        effective,
        minSize,
        shape,
        ClientColors.journeyRedFor(context),
      ),
      _ClientButtonVariant.text => TextButton(
        onPressed: effective,
        style: TextButton.styleFrom(
          foregroundColor: ClientColors.primaryFor(context),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.xs),
          ),
          textStyle: _labelStyle(context),
        ),
        child: _buildChild(context),
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _filled(BuildContext context, VoidCallback? effective, Size minSize) {
    final enabled = effective != null;
    final foreground = enabled
        ? ClientColors.onPrimaryFor(context)
        : ClientColors.textDisabledFor(context);

    return PressableScale(
      onTap: effective,
      scale: 0.96,
      child: Container(
        constraints: BoxConstraints(minHeight: minSize.height),
        padding: EdgeInsets.symmetric(horizontal: dense ? 18 : 24),
        decoration: BoxDecoration(
          color: enabled
              ? ClientColors.primaryFor(context)
              : ClientColors.surfaceMutedFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.control),
          // The design lifts a live CTA with the brand tint, not with neutral
          // shadow — a disabled button is flat because it is not an offer.
          boxShadow: enabled ? ClientElevation.primary(context) : null,
        ),
        // `heightFactor: 1` keeps the button at its content height instead of
        // filling the parent: a bare `alignment` stretches to the incoming
        // max height, which swallows whole screens in bounded slots such as
        // Scaffold's `bottomNavigationBar`.
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: DefaultTextStyle(
            style: _labelStyle(context).copyWith(color: foreground),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 18),
              child: _buildChild(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _outlined(
    BuildContext context,
    VoidCallback? effective,
    Size minSize,
    OutlinedBorder shape,
    Color accent,
  ) {
    return OutlinedButton(
      onPressed: effective,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        disabledForegroundColor: ClientColors.textDisabledFor(context),
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isLoading ? accent.withValues(alpha: 0.4) : accent,
          width: 1.5,
        ),
        minimumSize: minSize,
        shape: shape,
        textStyle: _labelStyle(context),
      ),
      child: _buildChild(context),
    );
  }

  /// `font-weight:700;font-size:15px;letter-spacing:.2px`.
  TextStyle _labelStyle(BuildContext context) =>
      ClientTypography.labelLarge(context).copyWith(
        fontSize: dense ? 14 : 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      );

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _ClientButtonVariant.primary
                ? ClientColors.onPrimaryFor(context)
                : _variant == _ClientButtonVariant.danger
                ? ClientColors.journeyRedFor(context)
                : ClientColors.primaryFor(context),
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

enum _ClientButtonVariant { primary, secondary, danger, text }
