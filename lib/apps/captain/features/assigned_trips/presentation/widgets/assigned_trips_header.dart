import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/widgets/widgets.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_notification_bell.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';

/// Home header: who the captain is, what day it is, and their notifications.
///
/// Stays pinned while the trip list scrolls, so the bell is always reachable.
/// The greeting is the title — a separate "لوحة القيادة" line above it only
/// named the tab the captain had just tapped, and paying an expanded height to
/// keep both cost the top third of the screen for one useful line of text.
class AssignedTripsHeader extends StatelessWidget {
  const AssignedTripsHeader({
    super.key,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  /// Null in release builds: the avatar's only action is the development
  /// app-mode switcher, so outside debug it is an emblem, not a button.
  final VoidCallback? onAvatarTap;

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    // Greeting over date, both inside the toolbar — so it grows with the user's
    // text scale rather than clipping.
    final toolbarHeight = math.max(
      kToolbarHeight,
      MediaQuery.textScalerOf(context).scale(64),
    );

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: toolbarHeight,
      backgroundColor: CaptainColors.primary,
      foregroundColor: Colors.white,
      titleSpacing: CaptainDesignTokens.s20,
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_Greeting(), _TodayLabel()],
      ),
      actions: [
        CaptainNotificationBell(onTap: onNotificationsTap),
        // Centred because `AppBar` stretches its actions to the full toolbar
        // height, which would leave the avatar's ring off-centre in the slot.
        Center(
          child: onAvatarTap == null
              ? const _HeaderAvatar()
              : GestureDetector(
                  onTap: onAvatarTap,
                  child: const _HeaderAvatar(),
                ),
        ),
        const SizedBox(width: CaptainDesignTokens.s20),
      ],
      flexibleSpace: const _HeaderBackground(),
    );
  }
}

/// The brand gradient behind the bar — the only thing the old expanded hero
/// still earns its keep for, now at toolbar height.
class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CaptainColors.primary,
            CaptainColors.primary.withValues(alpha: 0.82),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DriverProfileCubit, DriverProfileState, String?>(
      selector: (state) =>
          state is DriverProfileLoaded ? state.profile.name : null,
      builder: (context, name) {
        final greeting = _greetingForHour(DateTime.now().hour);
        return Text(
          name == null ? '$greeting كابتن 👋' : '$greeting، $name 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.titleMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        );
      },
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'طاب يومك';
    return 'مساء الخير';
  }
}

class _TodayLabel extends StatelessWidget {
  const _TodayLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      CaptainFormats.dayAndMonth(DateTime.now()),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.labelMedium(context).copyWith(
        color: Colors.white.withValues(alpha: 0.85),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: const AppAvatar(initials: 'ك', radius: 16),
    );
  }
}
