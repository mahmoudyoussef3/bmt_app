import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

/// The profile's chrome: a back affordance that never scrolls away, and the
/// office's name arriving in the bar exactly as the masthead carrying it
/// leaves the screen.
///
/// The bar floats over the brand band rather than sitting above it, so the
/// gradient runs to the top of the display. That is also why the name is not
/// printed here from the start — it would say the same thing as the masthead
/// two centimetres below it.
class OfficeProfileTopBar extends StatelessWidget {
  const OfficeProfileTopBar({
    super.key,
    required this.title,
    required this.progress,
  });

  final String title;

  /// 0 while the masthead is on screen, 1 once its identity has scrolled past.
  final double progress;

  /// Toolbar height below the status bar. The masthead reserves this much room
  /// at its top so nothing is born underneath the bar.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final solid = ClientColors.heroTopFor(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      
      value: SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        decoration: BoxDecoration(
          color: solid.withAlpha((t * 255).round()),
          boxShadow: t > 0.95 ? ClientElevation.sm(context) : null,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              const SizedBox(width: ClientSpacing.xs),
              _BackButton(scrim: 1 - t),
              const SizedBox(width: ClientSpacing.xs),
              Expanded(
                child: Opacity(
                  opacity: t,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.headingSmall(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ClientSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Back, in a glass disc that dissolves as the solid bar takes over: the disc
/// is what makes a white arrow legible over artwork, and it has no work left
/// once there is a bar behind it.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.scrim});

  final double scrim;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha((scrim * 46).round()),
          ),
          alignment: Alignment.center,
          child: const DirectionalIcon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
