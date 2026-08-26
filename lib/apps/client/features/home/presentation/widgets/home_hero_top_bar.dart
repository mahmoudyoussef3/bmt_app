import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/notifications/presentation/cubit/notification_badge_cubit.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The hero's top row: the app's own brand mark on the leading side, the
/// notification bell on the trailing one.
///
/// Home no longer greets the rider by name up here — the headline below does
/// the talking — so this row is purely wayfinding: what app you are in, and
/// whether anything is waiting for you.
class HomeHeroTopBar extends StatelessWidget {
  const HomeHeroTopBar({super.key, required this.onOpenNotifications});

  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandMark(),
        const Spacer(),
        _NotificationBell(
          tooltip: context.l10n.common_notifications,
          onTap: onOpenNotifications,
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandGlyph(),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EWT',
              style: ClientTypography.headingSmall(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            Text(
              l10n.home_brandTagline,
              style: ClientTypography.labelSmall(context).copyWith(
                color: Colors.white.withAlpha(190),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The system's own mark on the hero gradient.
///
/// `brand_glyph.png` is a white-on-transparent silhouette, so it is tinted
/// rather than drawn as-is; the bus icon stays only as the fallback for a
/// missing asset.
class _BrandGlyph extends StatelessWidget {
  const _BrandGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Image.asset(
        'assets/branding/brand_glyph.png',
        width: 22,
        height: 22,
        color: Colors.white,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// The bell, carrying the unread count from the always-alive
/// [NotificationBadgeCubit].
///
/// The badge is dropped entirely at zero rather than rendered empty: a rider
/// with nothing waiting should see a plain bell.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBadgeCubit, int>(
      builder: (context, unread) {
        return Tooltip(
          message: tooltip,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: Colors.white.withAlpha(26),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(45)),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),
              if (unread > 0)
                PositionedDirectional(
                  top: -2,
                  end: -2,
                  child: IgnorePointer(child: _UnreadBadge(count: unread)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9
        ? '${FormatUtil.number(context, 9)}+'
        : FormatUtil.number(context, count);

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientColors.journeyAmberFor(context),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: ClientTypography.labelSmall(context).copyWith(
          // Dark ink on amber, as the design specifies. White on the dark
          // theme's lighter `--warning` was the one unreadable pair on the
          // hero.
          color: const Color(0xFF1A1300),
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
