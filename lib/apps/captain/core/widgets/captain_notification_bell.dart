import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/notifications/presentation/cubit/captain_notification_badge_cubit.dart';
import '../theme/captain_colors.dart';
import '../theme/captain_typography.dart';

class CaptainNotificationBell extends StatelessWidget {
  const CaptainNotificationBell({
    super.key,
    required this.onTap,
    this.color = Colors.white,
  });

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaptainNotificationBadgeCubit, int>(
      builder: (context, unread) {
        return IconButton(
          onPressed: onTap,
          tooltip: 'الإشعارات',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, color: color, size: 26),
              if (unread > 0)
                PositionedDirectional(
                  top: -3,
                  end: -3,
                  child: _UnreadDot(count: unread),
                ),
            ],
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
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: CaptainColors.error,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: CaptainTypography.labelSmall(context).copyWith(
          color: Colors.white,
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
