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
class AssignedTripsHeader extends StatelessWidget {
  const AssignedTripsHeader({
    super.key,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      // Leaves room for the greeting and date to grow with the text scale.
      expandedHeight: 156,
      backgroundColor: CaptainColors.primary,
      foregroundColor: Colors.white,
      titleSpacing: CaptainDesignTokens.s20,
      title: Text(
        'لوحة القيادة',
        style: CaptainTypography.titleMedium(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
      ),
      actions: [
        CaptainNotificationBell(onTap: onNotificationsTap),
        GestureDetector(onTap: onAvatarTap, child: const _HeaderAvatar()),
        const SizedBox(width: CaptainDesignTokens.s20),
      ],
      flexibleSpace: const FlexibleSpaceBar(
        background: _HeaderBackground(),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
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
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          CaptainDesignTokens.s20,
          topInset + kToolbarHeight,
          CaptainDesignTokens.s20,
          CaptainDesignTokens.s20,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_Greeting(), SizedBox(height: 2), _TodayLabel()],
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
          style: CaptainTypography.headlineSmall(
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
      style: CaptainTypography.bodyMedium(context).copyWith(
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
      child: const AppAvatar(initials: 'ك'),
    );
  }
}
