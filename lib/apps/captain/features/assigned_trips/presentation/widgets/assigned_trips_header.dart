import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_root_header.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_cubit.dart';
import 'package:bmt_app/apps/captain/features/profile/presentation/cubit/driver_profile_state.dart';

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
        children: [_Greeting(), _TodayLabel()],
      ),
      onAvatarTap: onAvatarTap,
      onNotificationsTap: onNotificationsTap,
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
