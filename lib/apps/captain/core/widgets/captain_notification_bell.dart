import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import '../theme/captain_colors.dart';
import '../theme/captain_design_tokens.dart';
import '../theme/captain_typography.dart';

/// The design's bell: a 44×44 `--surface` tile with a hairline border, not a
/// bare glyph floating on a coloured app bar.
///
/// The tile is what makes it hittable — a plain 26px icon is well under the
/// 44dp touch target a driver has to find one-handed — and the border is what
/// lets it sit on the page instead of on a header band.
class CaptainNotificationBell extends StatelessWidget {
  const CaptainNotificationBell({super.key, required this.onTap});

  static const double size = 44;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaptainNotificationBadgeCubit, int>(
      builder: (context, unread) {
        return Semantics(
          button: true,
          label: unread > 0 ? 'الإشعارات، $unread غير مقروء' : 'الإشعارات',
          child: InkWell(
            onTap: onTap,
            borderRadius: CaptainDesignTokens.br14,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: CaptainColors.surfaceFor(context),
                borderRadius: CaptainDesignTokens.br14,
                border: CaptainDesignTokens.hairline(context),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 21,
                    color: CaptainColors.textPrimaryFor(context),
                  ),
                  if (unread > 0)
                    // On the tile's corner, not over its face: the badge was
                    // sitting on the bell and taking a bite out of the glyph.
                    PositionedDirectional(
                      top: -1,
                      end: -1,
                      child: _UnreadDot(count: unread),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: CaptainColors.dangerFor(context),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CaptainColors.surfaceFor(context), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: CaptainTypography.labelSmall(context).copyWith(
          color: Colors.white,
          fontSize: 9.5,
          height: 1.1,
          letterSpacing: 0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
