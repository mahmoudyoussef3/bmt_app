import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import '../../domain/entities/assigned_trip.dart';
import 'captain_focus_card_parts.dart';

/// The one thing the captain should act on now: the running trip, or the next
/// scheduled one. Deliberately the loudest element on the home screen.
class CaptainFocusCard extends StatelessWidget {
  const CaptainFocusCard({super.key, required this.trip, required this.onOpen});

  final AssignedTrip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isRunning = trip.status.isRunning;

    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CaptainColors.primary,
            CaptainColors.primary.withValues(alpha: 0.85),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: [
          BoxShadow(
            color: CaptainColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusEyebrow(isRunning: isRunning),
          const SizedBox(height: CaptainDesignTokens.s12),
          Text(
            trip.route,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CaptainTypography.titleLarge(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Row(
            children: [
              FocusFact(
                icon: Icons.schedule_rounded,
                text: _departureLabel(DateTime.now()),
              ),
              const SizedBox(width: CaptainDesignTokens.s16),
              FocusFact(
                icon: Icons.people_alt_rounded,
                text: '${trip.boardedCount}/${trip.passengerCount} راكب',
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s20),
          FocusAction(
            label: isRunning ? 'متابعة الرحلة' : 'بدء الرحلة',
            icon: isRunning
                ? Icons.play_circle_fill_rounded
                : Icons.navigation_rounded,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }

  String _departureLabel(DateTime now) {
    if (trip.status == AssignedTripStatus.inProgress) return 'جارية الآن';
    if (trip.status == AssignedTripStatus.boarding) return 'الصعود جارٍ';

    final until = trip.departureTime.difference(now);
    if (until.isNegative) return 'تأخر الانطلاق';
    if (until.inMinutes < 1) return 'تنطلق الآن';
    if (until.inMinutes < 60) return 'تنطلق بعد ${until.inMinutes} دقيقة';

    final minutes = until.inMinutes % 60;
    if (minutes == 0) return 'تنطلق بعد ${until.inHours} ساعة';
    return 'تنطلق بعد ${until.inHours} س و $minutes د';
  }
}
