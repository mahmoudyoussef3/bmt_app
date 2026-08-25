import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_root_header.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';

/// The home header: a quiet greeting line, then the captain's name at the top
/// of the type scale.
///
/// The design puts the greeting *above* the name and at half its weight. Time
/// of day and today's date are context the captain glances at; their own name
/// is what tells them the app is signed in as them — so the name is the thing
/// that reads first.
class AssignedTripsHeader extends StatelessWidget {
  const AssignedTripsHeader({
    super.key,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  final VoidCallback? onAvatarTap;

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return CaptainRootHeader(
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_GreetingLine(), _CaptainName()],
      ),
      onAvatarTap: onAvatarTap,
      onNotificationsTap: onNotificationsTap,
    );
  }
}

class _GreetingLine extends StatelessWidget {
  const _GreetingLine();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Text(
      '${_greetingForHour(now.hour)} · ${CaptainFormats.dayAndMonth(now)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CaptainTypography.bodySmall(context).copyWith(
        color: CaptainColors.textSecondaryFor(context),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _greetingForHour(int hour) {
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'طاب يومك';
    return 'مساء الخير';
  }
}

class _CaptainName extends StatelessWidget {
  const _CaptainName();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DriverProfileCubit, DriverProfileState, String?>(
      selector: (state) =>
          state is DriverProfileLoaded ? state.profile.name : null,
      builder: (context, name) {
        return Text(
          name == null ? 'كابتن 👋' : 'كابتن $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CaptainTypography.headlineSmall(context).copyWith(
            color: CaptainColors.textPrimaryFor(context),
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        );
      },
    );
  }
}
